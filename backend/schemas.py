from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, EmailStr


# ── Auth ──────────────────────────────────────────────────────────────────────

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    name: str
    role: str = "patient"   # "patient" | "clinician"


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str
    user_id: int
    is_onboarded: bool


# ── Patient ───────────────────────────────────────────────────────────────────

class PatientUpdate(BaseModel):
    name: Optional[str] = None
    age: Optional[int] = None
    conditions: Optional[List[str]] = None
    language: Optional[str] = None
    is_onboarded: Optional[bool] = None


class PatientResponse(BaseModel):
    id: int
    user_id: int
    name: str
    age: int
    conditions: List[str]
    language: str
    is_onboarded: bool

    class Config:
        from_attributes = True


# ── Medication ────────────────────────────────────────────────────────────────

class DoseTimeSchema(BaseModel):
    hour: int
    minute: int


class MedicationCreate(BaseModel):
    name: str
    condition: str
    dosage_amount: str = "1 tablet"
    schedule_times: List[DoseTimeSchema] = []
    proof_method: str = "tap"
    window_minutes: int = 60
    instructions: str = ""


class MedicationUpdate(BaseModel):
    name: Optional[str] = None
    condition: Optional[str] = None
    dosage_amount: Optional[str] = None
    schedule_times: Optional[List[DoseTimeSchema]] = None
    proof_method: Optional[str] = None
    window_minutes: Optional[int] = None
    instructions: Optional[str] = None
    active: Optional[bool] = None


class MedicationResponse(BaseModel):
    id: int
    patient_id: int
    name: str
    condition: str
    dosage_amount: str
    schedule_times: List[DoseTimeSchema]
    proof_method: str
    window_minutes: int
    instructions: str
    active: bool

    class Config:
        from_attributes = True


# ── Dose Events ───────────────────────────────────────────────────────────────

class DoseConfirmRequest(BaseModel):
    proof_method: str = "tap"


class DoseEventResponse(BaseModel):
    id: int
    medication_id: int
    scheduled_for: datetime
    status: str
    confirmed_at: Optional[datetime]
    proof_method: Optional[str]
    alert_delivered: bool

    class Config:
        from_attributes = True


# ── Risk ──────────────────────────────────────────────────────────────────────

class RiskFactorSchema(BaseModel):
    label: str
    weight: float


class RiskScoreResponse(BaseModel):
    score: float
    tier: str
    factors: List[RiskFactorSchema]
    computed_at: datetime

    class Config:
        from_attributes = True


# ── Clinician ─────────────────────────────────────────────────────────────────

class ClinicianPatientResponse(BaseModel):
    patient_id: int
    name: str
    age: int
    conditions: List[str]
    risk_score: float
    risk_tier: str
    adherence_rate: float
    last_activity: Optional[datetime]
