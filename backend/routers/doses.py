from datetime import datetime, date
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
import models
import schemas
from auth import get_current_user

router = APIRouter(prefix="/doses", tags=["doses"])


def _patient_or_404(user: models.User, db: Session) -> models.Patient:
    p = db.query(models.Patient).filter(models.Patient.user_id == user.id).first()
    if not p:
        raise HTTPException(status_code=404, detail="Patient profile not found")
    return p


def _serialize(event: models.DoseEvent) -> schemas.DoseEventResponse:
    return schemas.DoseEventResponse(
        id=event.id,
        medication_id=event.medication_id,
        scheduled_for=event.scheduled_for,
        status=event.status,
        confirmed_at=event.confirmed_at,
        proof_method=event.proof_method,
        alert_delivered=event.alert_delivered,
    )


@router.get("/today", response_model=list[schemas.DoseEventResponse])
def get_todays_doses(
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    patient = _patient_or_404(user, db)
    today = date.today()
    start = datetime(today.year, today.month, today.day, 0, 0, 0)
    end = datetime(today.year, today.month, today.day, 23, 59, 59)

    med_ids = [m.id for m in db.query(models.Medication).filter(
        models.Medication.patient_id == patient.id,
        models.Medication.active == True,
    ).all()]

    events = db.query(models.DoseEvent).filter(
        models.DoseEvent.medication_id.in_(med_ids),
        models.DoseEvent.scheduled_for >= start,
        models.DoseEvent.scheduled_for <= end,
    ).order_by(models.DoseEvent.scheduled_for).all()

    return [_serialize(e) for e in events]


@router.get("/history", response_model=list[schemas.DoseEventResponse])
def get_dose_history(
    days: int = 30,
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    patient = _patient_or_404(user, db)
    from datetime import timedelta
    cutoff = datetime.utcnow() - timedelta(days=days)

    med_ids = [m.id for m in db.query(models.Medication).filter(
        models.Medication.patient_id == patient.id,
    ).all()]

    events = db.query(models.DoseEvent).filter(
        models.DoseEvent.medication_id.in_(med_ids),
        models.DoseEvent.scheduled_for >= cutoff,
    ).order_by(models.DoseEvent.scheduled_for.desc()).all()

    return [_serialize(e) for e in events]


@router.post("/{dose_id}/confirm", response_model=schemas.DoseEventResponse)
def confirm_dose(
    dose_id: int,
    body: schemas.DoseConfirmRequest,
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    patient = _patient_or_404(user, db)
    event = db.query(models.DoseEvent).filter(models.DoseEvent.id == dose_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Dose event not found")

    med = db.query(models.Medication).filter(
        models.Medication.id == event.medication_id,
        models.Medication.patient_id == patient.id,
    ).first()
    if not med:
        raise HTTPException(status_code=403, detail="Not authorized for this dose")

    now = datetime.utcnow()
    delay_minutes = abs((now - event.scheduled_for).total_seconds() / 60)
    event.status = "taken" if delay_minutes <= med.window_minutes else "late"
    event.confirmed_at = now
    event.proof_method = body.proof_method
    db.commit()
    db.refresh(event)
    return _serialize(event)
