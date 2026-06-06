from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
import models
import schemas
from auth import get_current_user

router = APIRouter(prefix="/medications", tags=["medications"])


def _patient_or_404(user: models.User, db: Session) -> models.Patient:
    p = db.query(models.Patient).filter(models.Patient.user_id == user.id).first()
    if not p:
        raise HTTPException(status_code=404, detail="Patient profile not found")
    return p


def _serialize(med: models.Medication) -> schemas.MedicationResponse:
    return schemas.MedicationResponse(
        id=med.id,
        patient_id=med.patient_id,
        name=med.name,
        condition=med.condition,
        dosage_amount=med.dosage_amount,
        schedule_times=[schemas.DoseTimeSchema(**t) for t in (med.schedule_times or [])],
        proof_method=med.proof_method,
        window_minutes=med.window_minutes,
        instructions=med.instructions or "",
        active=med.active,
    )


@router.get("/", response_model=list[schemas.MedicationResponse])
def list_medications(
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    patient = _patient_or_404(user, db)
    meds = db.query(models.Medication).filter(
        models.Medication.patient_id == patient.id,
        models.Medication.active == True,
    ).all()
    return [_serialize(m) for m in meds]


@router.post("/", response_model=schemas.MedicationResponse, status_code=201)
def create_medication(
    body: schemas.MedicationCreate,
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    patient = _patient_or_404(user, db)
    med = models.Medication(
        patient_id=patient.id,
        name=body.name,
        condition=body.condition,
        dosage_amount=body.dosage_amount,
        schedule_times=[t.model_dump() for t in body.schedule_times],
        proof_method=body.proof_method,
        window_minutes=body.window_minutes,
        instructions=body.instructions,
    )
    db.add(med)
    db.commit()
    db.refresh(med)
    return _serialize(med)


@router.put("/{med_id}", response_model=schemas.MedicationResponse)
def update_medication(
    med_id: int,
    body: schemas.MedicationUpdate,
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    patient = _patient_or_404(user, db)
    med = db.query(models.Medication).filter(
        models.Medication.id == med_id,
        models.Medication.patient_id == patient.id,
    ).first()
    if not med:
        raise HTTPException(status_code=404, detail="Medication not found")
    if body.name is not None:
        med.name = body.name
    if body.condition is not None:
        med.condition = body.condition
    if body.dosage_amount is not None:
        med.dosage_amount = body.dosage_amount
    if body.schedule_times is not None:
        med.schedule_times = [t.model_dump() for t in body.schedule_times]
    if body.proof_method is not None:
        med.proof_method = body.proof_method
    if body.window_minutes is not None:
        med.window_minutes = body.window_minutes
    if body.instructions is not None:
        med.instructions = body.instructions
    if body.active is not None:
        med.active = body.active
    db.commit()
    db.refresh(med)
    return _serialize(med)


@router.delete("/{med_id}", status_code=204)
def delete_medication(
    med_id: int,
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    patient = _patient_or_404(user, db)
    med = db.query(models.Medication).filter(
        models.Medication.id == med_id,
        models.Medication.patient_id == patient.id,
    ).first()
    if not med:
        raise HTTPException(status_code=404, detail="Medication not found")
    med.active = False
    db.commit()
