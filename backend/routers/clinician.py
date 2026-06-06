from datetime import datetime, timedelta
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db
import models
import schemas
from auth import require_clinician
from routers.risk import _compute_risk

router = APIRouter(prefix="/clinician", tags=["clinician"])


def _adherence_rate(events: list[models.DoseEvent]) -> float:
    due = [e for e in events if e.status not in ("upcoming",)]
    if not due:
        return 1.0
    adherent = sum(1 for e in due if e.status in ("taken", "late"))
    return round(adherent / len(due), 3)


@router.get("/roster", response_model=list[schemas.ClinicianPatientResponse])
def get_roster(
    _: models.User = Depends(require_clinician),
    db: Session = Depends(get_db),
):
    patients = db.query(models.Patient).filter(models.Patient.is_onboarded == True).all()
    cutoff = datetime.utcnow() - timedelta(days=30)
    result = []

    for p in patients:
        conditions = p.conditions or []
        med_ids = [m.id for m in p.medications]
        events = db.query(models.DoseEvent).filter(
            models.DoseEvent.medication_id.in_(med_ids),
            models.DoseEvent.scheduled_for >= cutoff,
        ).all() if med_ids else []

        risk = _compute_risk(events, conditions)
        adherence = _adherence_rate(events)

        last_activity = None
        confirmed = [e for e in events if e.confirmed_at is not None]
        if confirmed:
            last_activity = max(e.confirmed_at for e in confirmed)

        result.append(schemas.ClinicianPatientResponse(
            patient_id=p.id,
            name=p.name,
            age=p.age,
            conditions=conditions,
            risk_score=risk.score,
            risk_tier=risk.tier,
            adherence_rate=adherence,
            last_activity=last_activity,
        ))

    result.sort(key=lambda x: x.risk_score, reverse=True)
    return result


@router.get("/alerts", response_model=list[schemas.ClinicianPatientResponse])
def get_alerts(
    clinician: models.User = Depends(require_clinician),
    db: Session = Depends(get_db),
):
    all_patients = get_roster(clinician, db)
    return [p for p in all_patients if p.risk_tier == "high"]
