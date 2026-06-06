import json
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
import models
import schemas
from auth import get_current_user

router = APIRouter(prefix="/patients", tags=["patients"])


def _patient_or_404(user: models.User, db: Session) -> models.Patient:
    p = db.query(models.Patient).filter(models.Patient.user_id == user.id).first()
    if not p:
        raise HTTPException(status_code=404, detail="Patient profile not found")
    return p


def _serialize(patient: models.Patient) -> schemas.PatientResponse:
    return schemas.PatientResponse(
        id=patient.id,
        user_id=patient.user_id,
        name=patient.name,
        age=patient.age,
        conditions=json.loads(patient.conditions or "[]"),
        language=patient.language,
        is_onboarded=patient.is_onboarded,
    )


@router.get("/me", response_model=schemas.PatientResponse)
def get_my_profile(
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return _serialize(_patient_or_404(user, db))


@router.put("/me", response_model=schemas.PatientResponse)
def update_my_profile(
    body: schemas.PatientUpdate,
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    patient = _patient_or_404(user, db)
    if body.name is not None:
        patient.name = body.name
    if body.age is not None:
        patient.age = body.age
    if body.conditions is not None:
        patient.conditions = json.dumps(body.conditions)
    if body.language is not None:
        patient.language = body.language
    if body.is_onboarded is not None:
        patient.is_onboarded = body.is_onboarded
    db.commit()
    db.refresh(patient)
    return _serialize(patient)
