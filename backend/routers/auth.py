from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from database import get_db
import models
import schemas
from auth import hash_password, verify_password, create_access_token

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=schemas.TokenResponse, status_code=201)
def register(body: schemas.RegisterRequest, db: Session = Depends(get_db)):
    if db.query(models.User).filter(models.User.email == body.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")

    user = models.User(
        email=body.email,
        hashed_password=hash_password(body.password),
        role=body.role,
    )
    db.add(user)
    db.flush()

    patient = models.Patient(user_id=user.id, name=body.name)
    db.add(patient)
    db.commit()
    db.refresh(user)

    token = create_access_token({"sub": str(user.id), "role": user.role})
    return schemas.TokenResponse(
        access_token=token,
        role=user.role,
        user_id=user.id,
        is_onboarded=False,
    )


@router.post("/login", response_model=schemas.TokenResponse)
def login(body: schemas.LoginRequest, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == body.email).first()
    if not user or not verify_password(body.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
        )

    is_onboarded = False
    if user.patient:
        is_onboarded = user.patient.is_onboarded

    token = create_access_token({"sub": str(user.id), "role": user.role})
    return schemas.TokenResponse(
        access_token=token,
        role=user.role,
        user_id=user.id,
        is_onboarded=is_onboarded,
    )
