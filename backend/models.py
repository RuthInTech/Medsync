from datetime import datetime
from sqlalchemy import Boolean, Column, DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship
from database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(String, default="patient")  # "patient" | "clinician"
    created_at = Column(DateTime, default=datetime.utcnow)

    patient = relationship("Patient", back_populates="user", uselist=False)


class Patient(Base):
    __tablename__ = "patients"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    name = Column(String, nullable=False)
    age = Column(Integer, default=30)
    conditions = Column(Text, default="[]")   # JSON array of condition names
    language = Column(String, default="en")
    is_onboarded = Column(Boolean, default=False)

    user = relationship("User", back_populates="patient")
    medications = relationship("Medication", back_populates="patient", cascade="all, delete-orphan")
    risk_scores = relationship("RiskScore", back_populates="patient", cascade="all, delete-orphan")


class Medication(Base):
    __tablename__ = "medications"

    id = Column(Integer, primary_key=True, index=True)
    patient_id = Column(Integer, ForeignKey("patients.id"), nullable=False)
    name = Column(String, nullable=False)
    condition = Column(String, nullable=False)
    dosage_amount = Column(String, default="1 tablet")
    schedule_times = Column(Text, default="[]")   # JSON: [{"hour":8,"minute":0}]
    proof_method = Column(String, default="tap")  # tap | photo | qrScan
    window_minutes = Column(Integer, default=60)
    instructions = Column(Text, default="")
    active = Column(Boolean, default=True)

    patient = relationship("Patient", back_populates="medications")
    dose_events = relationship("DoseEvent", back_populates="medication", cascade="all, delete-orphan")


class DoseEvent(Base):
    __tablename__ = "dose_events"

    id = Column(Integer, primary_key=True, index=True)
    medication_id = Column(Integer, ForeignKey("medications.id"), nullable=False)
    scheduled_for = Column(DateTime, nullable=False)
    status = Column(String, default="upcoming")  # upcoming|due|taken|late|missed|ignored
    confirmed_at = Column(DateTime, nullable=True)
    proof_method = Column(String, nullable=True)
    alert_delivered = Column(Boolean, default=False)

    medication = relationship("Medication", back_populates="dose_events")


class RiskScore(Base):
    __tablename__ = "risk_scores"

    id = Column(Integer, primary_key=True, index=True)
    patient_id = Column(Integer, ForeignKey("patients.id"), nullable=False)
    score = Column(Float, default=0.0)
    tier = Column(String, default="low")   # low | medium | high
    factors = Column(Text, default="[]")   # JSON array of {label, weight}
    computed_at = Column(DateTime, default=datetime.utcnow)

    patient = relationship("Patient", back_populates="risk_scores")
