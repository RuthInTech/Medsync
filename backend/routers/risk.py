from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
import models
import schemas
from auth import get_current_user

router = APIRouter(prefix="/risk", tags=["risk"])


def _compute_risk(events: list[models.DoseEvent], conditions: list[str]) -> schemas.RiskScoreResponse:
    if not events:
        return schemas.RiskScoreResponse(
            score=10.0,
            tier="low",
            factors=[schemas.RiskFactorSchema(label="No history yet — baseline low risk", weight=0)],
            computed_at=datetime.utcnow(),
        )

    total = len(events)
    missed = sum(1 for e in events if e.status in ("missed", "ignored"))
    late = sum(1 for e in events if e.status == "late")
    taken = sum(1 for e in events if e.status == "taken")

    miss_rate = missed / total if total > 0 else 0
    late_rate = late / total if total > 0 else 0

    cutoff_7 = datetime.utcnow() - timedelta(days=7)
    recent = [e for e in events if e.scheduled_for >= cutoff_7]
    recent_missed = sum(1 for e in recent if e.status in ("missed", "ignored"))
    recent_miss_rate = recent_missed / len(recent) if recent else 0

    high_severity = {"hiv", "tuberculosis"}
    severity_boost = 15.0 if any(c in high_severity for c in conditions) else 0.0

    score = (miss_rate * 50) + (late_rate * 15) + (recent_miss_rate * 25) + severity_boost
    score = min(score, 100.0)

    factors = []
    if miss_rate > 0.2:
        factors.append(schemas.RiskFactorSchema(
            label=f"{int(miss_rate * 100)}% of doses missed in last 30 days",
            weight=miss_rate * 50,
        ))
    if recent_miss_rate > 0.3:
        factors.append(schemas.RiskFactorSchema(
            label="Declining adherence trend in last 7 days",
            weight=recent_miss_rate * 25,
        ))
    if late_rate > 0.1:
        factors.append(schemas.RiskFactorSchema(
            label=f"{int(late_rate * 100)}% of doses taken outside scheduled window",
            weight=late_rate * 15,
        ))
    if severity_boost > 0:
        factors.append(schemas.RiskFactorSchema(
            label="Managing high-severity condition (HIV/TB)",
            weight=severity_boost,
        ))
    if not factors:
        factors.append(schemas.RiskFactorSchema(
            label=f"Strong adherence — {taken} doses taken on time",
            weight=-10,
        ))

    tier = "low" if score < 30 else ("medium" if score < 60 else "high")

    return schemas.RiskScoreResponse(
        score=round(score, 1),
        tier=tier,
        factors=factors,
        computed_at=datetime.utcnow(),
    )


@router.get("/me", response_model=schemas.RiskScoreResponse)
def get_my_risk(
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    patient = db.query(models.Patient).filter(models.Patient.user_id == user.id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient profile not found")

    conditions = patient.conditions or []
    cutoff = datetime.utcnow() - timedelta(days=30)
    med_ids = [m.id for m in patient.medications]

    events = db.query(models.DoseEvent).filter(
        models.DoseEvent.medication_id.in_(med_ids),
        models.DoseEvent.scheduled_for >= cutoff,
    ).all() if med_ids else []

    result = _compute_risk(events, conditions)

    risk_record = models.RiskScore(
        patient_id=patient.id,
        score=result.score,
        tier=result.tier,
        factors=[f.model_dump() for f in result.factors],
    )
    db.add(risk_record)
    db.commit()

    return result
