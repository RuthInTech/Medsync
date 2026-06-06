#!/usr/bin/env python3
"""
Siyaphila API — seed + integration test runner.

Usage:
    python seed_test.py                          # targets deployed Render backend
    python seed_test.py --url http://localhost:8000   # targets local backend

What it does:
  1. Registers 3 patients (low / medium / high risk profiles) + 1 clinician
  2. Sets up each patient's profile and medications
  3. Seeds realistic 30-day dose history directly into the local SQLite DB
     (only when targeting localhost — skipped against Render since the DB is remote)
  4. Runs every API endpoint and prints PASS / FAIL with response details
"""

import argparse
import json
import sys
from datetime import datetime, timedelta, date
from typing import Optional

import requests

BASE_URL = "https://siyaphila-api.onrender.com"

# ── ANSI colours ──────────────────────────────────────────────────────────────
GREEN  = "\033[92m"
RED    = "\033[91m"
YELLOW = "\033[93m"
BLUE   = "\033[94m"
BOLD   = "\033[1m"
RESET  = "\033[0m"

passed = failed = 0


def ok(label: str, detail: str = "") -> None:
    global passed
    passed += 1
    print(f"  {GREEN}✓{RESET} {label}", f"{YELLOW}{detail}{RESET}" if detail else "")


def fail(label: str, detail: str = "") -> None:
    global failed
    failed += 1
    print(f"  {RED}✗{RESET} {label}", f"{RED}{detail}{RESET}" if detail else "")


def section(title: str) -> None:
    print(f"\n{BOLD}{BLUE}── {title} {'─' * (50 - len(title))}{RESET}")


def _parse(r: requests.Response) -> dict:
    try:
        return r.json()
    except Exception:
        return {"_raw": r.text[:200]}


def post(path: str, body: dict, token: Optional[str] = None, expected_status: int = 200) -> tuple:
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    r = requests.post(f"{BASE_URL}{path}", json=body, headers=headers, timeout=60)
    return r.status_code, _parse(r)


def get(path: str, token: Optional[str] = None, params: dict = None) -> tuple:
    headers = {}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    r = requests.get(f"{BASE_URL}{path}", headers=headers, params=params, timeout=60)
    return r.status_code, _parse(r)


def put(path: str, body: dict, token: Optional[str] = None) -> tuple:
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    r = requests.put(f"{BASE_URL}{path}", json=body, headers=headers, timeout=60)
    return r.status_code, _parse(r)


# ── Test data ─────────────────────────────────────────────────────────────────

PATIENTS = [
    {
        "email": "nomsa.dlamini@test.com",
        "password": "Test1234!",
        "name": "Nomsa Dlamini",
        "role": "patient",
        "profile": {
            "age": 45,
            "conditions": ["diabetes", "hypertension"],
            "language": "en",
            "is_onboarded": True,
        },
        "medications": [
            {
                "name": "Metformin",
                "condition": "diabetes",
                "dosage_amount": "500 mg",
                "schedule_times": [{"hour": 8, "minute": 0}, {"hour": 20, "minute": 0}],
                "proof_method": "tap",
                "window_minutes": 60,
                "instructions": "Take with food",
            },
            {
                "name": "Amlodipine",
                "condition": "hypertension",
                "dosage_amount": "5 mg",
                "schedule_times": [{"hour": 8, "minute": 0}],
                "proof_method": "tap",
                "window_minutes": 90,
                "instructions": "Take in the morning",
            },
        ],
        "risk_label": "LOW RISK",
    },
    {
        "email": "sipho.ndlovu@test.com",
        "password": "Test1234!",
        "name": "Sipho Ndlovu",
        "role": "patient",
        "profile": {
            "age": 32,
            "conditions": ["hiv", "highCholesterol"],
            "language": "en",
            "is_onboarded": True,
        },
        "medications": [
            {
                "name": "ART (TLD)",
                "condition": "hiv",
                "dosage_amount": "1 tablet",
                "schedule_times": [{"hour": 21, "minute": 0}],
                "proof_method": "photo",
                "window_minutes": 60,
                "instructions": "Take at night, do not skip",
            },
            {
                "name": "Atorvastatin",
                "condition": "highCholesterol",
                "dosage_amount": "20 mg",
                "schedule_times": [{"hour": 20, "minute": 0}],
                "proof_method": "tap",
                "window_minutes": 60,
                "instructions": "Take with evening meal",
            },
        ],
        "risk_label": "MEDIUM RISK",
    },
    {
        "email": "thabo.molefe@test.com",
        "password": "Test1234!",
        "name": "Thabo Molefe",
        "role": "patient",
        "profile": {
            "age": 58,
            "conditions": ["tuberculosis", "hypertension", "hiv"],
            "language": "en",
            "is_onboarded": True,
        },
        "medications": [
            {
                "name": "TB Regimen (RHZE)",
                "condition": "tuberculosis",
                "dosage_amount": "4 tablets",
                "schedule_times": [{"hour": 7, "minute": 30}],
                "proof_method": "qrScan",
                "window_minutes": 60,
                "instructions": "Take on empty stomach. Critical: do not miss.",
            },
            {
                "name": "ART (TLD)",
                "condition": "hiv",
                "dosage_amount": "1 tablet",
                "schedule_times": [{"hour": 21, "minute": 0}],
                "proof_method": "photo",
                "window_minutes": 60,
                "instructions": "Take at night",
            },
            {
                "name": "Lisinopril",
                "condition": "hypertension",
                "dosage_amount": "10 mg",
                "schedule_times": [{"hour": 9, "minute": 0}],
                "proof_method": "tap",
                "window_minutes": 90,
                "instructions": "Take with or without food",
            },
        ],
        "risk_label": "HIGH RISK",
    },
]

CLINICIAN = {
    "email": "dr.mokoena@test.com",
    "password": "Clinic1234!",
    "name": "Dr. Sarah Mokoena",
    "role": "clinician",
}


# ── Local DB seeder (SQLite only) ─────────────────────────────────────────────

def seed_dose_history(patient_email: str, adherence_rate: float) -> None:
    """Insert 30 days of synthetic dose events directly into the local SQLite DB."""
    try:
        import sys, os
        sys.path.insert(0, os.path.dirname(__file__))
        from database import SessionLocal
        import models

        db = SessionLocal()
        user = db.query(models.User).filter(models.User.email == patient_email).first()
        if not user or not user.patient:
            print(f"    {YELLOW}⚠ DB seed skipped — user not found in local DB{RESET}")
            return

        patient = user.patient
        today = date.today()

        inserted = 0
        for day_offset in range(1, 31):          # last 30 days (not today)
            d = today - timedelta(days=day_offset)
            for med in patient.medications:
                for t in json.loads(med.schedule_times):
                    when = datetime(d.year, d.month, d.day, t["hour"], t["minute"])
                    existing = db.query(models.DoseEvent).filter(
                        models.DoseEvent.medication_id == med.id,
                        models.DoseEvent.scheduled_for == when,
                    ).first()
                    if existing:
                        continue

                    import random
                    roll = random.random()
                    if roll < adherence_rate:
                        delay = random.randint(-10, 45)
                        confirmed_at = when + timedelta(minutes=delay)
                        status = "taken" if abs(delay) <= med.window_minutes else "late"
                    elif roll < adherence_rate + 0.10:
                        delay = random.randint(med.window_minutes + 1, med.window_minutes + 60)
                        confirmed_at = when + timedelta(minutes=delay)
                        status = "late"
                    else:
                        confirmed_at = None
                        status = "missed"

                    event = models.DoseEvent(
                        medication_id=med.id,
                        scheduled_for=when,
                        status=status,
                        confirmed_at=confirmed_at,
                        proof_method=med.proof_method if confirmed_at else None,
                        alert_delivered=True,
                    )
                    db.add(event)
                    inserted += 1

        db.commit()
        db.close()
        print(f"    {GREEN}↳ Seeded {inserted} historical dose events (adherence ~{int(adherence_rate*100)}%){RESET}")
    except Exception as e:
        print(f"    {YELLOW}⚠ DB seed skipped: {e}{RESET}")


# ── Test runners ──────────────────────────────────────────────────────────────

def run_health_check() -> None:
    section("Health check")
    status, body = get("/health")
    if status == 200 and body.get("status") == "healthy":
        ok("/health", body.get("service", ""))
    else:
        fail("/health", f"status={status} body={body}")


def register_or_login(user: dict) -> Optional[str]:
    status, body = post("/auth/register", {
        "email": user["email"],
        "password": user["password"],
        "name": user["name"],
        "role": user["role"],
    }, expected_status=201)

    if status == 201:
        ok(f"Registered  {user['name']}", f"id={body.get('user_id')}")
        return body.get("access_token")
    elif status == 400 and "already registered" in str(body.get("detail", "")):
        # already exists — log in instead
        status2, body2 = post("/auth/login", {
            "email": user["email"],
            "password": user["password"],
        })
        if status2 == 200:
            ok(f"Logged in   {user['name']}", "(already existed)")
            return body2.get("access_token")
    fail(f"Register/login {user['name']}", f"status={status} {body}")
    return None


def run_auth_tests() -> dict:
    section("Auth — register & login")
    tokens = {}

    for p in PATIENTS:
        t = register_or_login(p)
        if t:
            tokens[p["email"]] = t

    t = register_or_login(CLINICIAN)
    if t:
        tokens[CLINICIAN["email"]] = t

    # Wrong password
    section("Auth — error cases")
    s, b = post("/auth/login", {"email": PATIENTS[0]["email"], "password": "wrong"})
    if s == 401:
        ok("Wrong password → 401", b.get("detail", ""))
    else:
        fail("Wrong password should be 401", f"got {s}")

    # Duplicate email
    s, b = post("/auth/register", {
        "email": PATIENTS[0]["email"], "password": "x", "name": "Dup", "role": "patient"
    })
    if s == 400:
        ok("Duplicate email → 400", b.get("detail", ""))
    else:
        fail("Duplicate email should be 400", f"got {s}")

    return tokens


def run_patient_tests(tokens: dict) -> None:
    section("Patients — profile setup")
    for p in PATIENTS:
        token = tokens.get(p["email"])
        if not token:
            fail(f"No token for {p['name']}")
            continue

        # GET profile
        s, b = get("/patients/me", token)
        if s == 200:
            ok(f"GET /patients/me  ({p['name']})", f"onboarded={b.get('is_onboarded')}")
        else:
            fail(f"GET /patients/me  ({p['name']})", f"status={s}")

        # PUT profile (onboarding)
        s, b = put("/patients/me", p["profile"], token)
        if s == 200 and b.get("is_onboarded"):
            ok(f"PUT /patients/me  ({p['name']})", f"age={b.get('age')} conditions={b.get('conditions')}")
        else:
            fail(f"PUT /patients/me  ({p['name']})", f"status={s} {b}")


def run_medication_tests(tokens: dict) -> None:
    section("Medications — create & list")
    for p in PATIENTS:
        token = tokens.get(p["email"])
        if not token:
            continue

        # Check if meds already exist
        s, existing = get("/medications/", token)
        if s == 200 and len(existing) >= len(p["medications"]):
            ok(f"Medications already set  ({p['name']})", f"{len(existing)} active")
            continue

        created = 0
        for med in p["medications"]:
            s, b = post("/medications/", med, token, expected_status=201)
            if s == 201:
                created += 1
            else:
                fail(f"Create {med['name']} for {p['name']}", f"status={s} {b}")

        if created:
            ok(f"Created {created} medications  ({p['name']})")

        # List
        s, b = get("/medications/", token)
        if s == 200:
            ok(f"GET /medications/  ({p['name']})", f"{len(b)} returned")
        else:
            fail(f"GET /medications/  ({p['name']})", f"status={s}")


def run_dose_tests(tokens: dict) -> None:
    section("Doses — today & history")
    for p in PATIENTS:
        token = tokens.get(p["email"])
        if not token:
            continue

        s, b = get("/doses/today", token)
        if s == 200:
            ok(f"GET /doses/today  ({p['name']})", f"{len(b)} events")
        else:
            fail(f"GET /doses/today  ({p['name']})", f"status={s}")

        # Confirm the first due/upcoming dose if any
        due = [e for e in (b if isinstance(b, list) else [])
               if e.get("status") in ("due", "upcoming")]
        if due:
            first = due[0]
            s2, b2 = post(f"/doses/{first['id']}/confirm",
                          {"proof_method": "tap"}, token)
            if s2 == 200:
                ok(f"POST /doses/confirm  ({p['name']})", f"→ {b2.get('status')}")
            else:
                fail(f"POST /doses/confirm  ({p['name']})", f"status={s2} {b2}")
        else:
            ok(f"No due doses to confirm today  ({p['name']})")

        s, b = get("/doses/history", token, {"days": 7})
        if s == 200:
            ok(f"GET /doses/history?days=7  ({p['name']})", f"{len(b)} events")
        else:
            fail(f"GET /doses/history  ({p['name']})", f"status={s}")


def run_risk_tests(tokens: dict) -> None:
    section("Risk — scoring")
    for p in PATIENTS:
        token = tokens.get(p["email"])
        if not token:
            continue
        s, b = get("/risk/me", token)
        if s == 200:
            ok(
                f"GET /risk/me  ({p['name']})",
                f"score={b.get('score')}  tier={b.get('tier')}  "
                f"factors={len(b.get('factors', []))}  [{p['risk_label']}]",
            )
        else:
            fail(f"GET /risk/me  ({p['name']})", f"status={s} {b}")


def run_clinician_tests(tokens: dict) -> None:
    section("Clinician — roster & alerts")
    c_token = tokens.get(CLINICIAN["email"])
    p_token = tokens.get(PATIENTS[0]["email"])

    if c_token:
        s, b = get("/clinician/roster", c_token)
        if s == 200:
            ok("GET /clinician/roster", f"{len(b)} onboarded patients")
            for pt in b:
                tier_color = RED if pt["risk_tier"] == "high" else (YELLOW if pt["risk_tier"] == "medium" else GREEN)
                print(f"      {tier_color}●{RESET} {pt['name']:20s}  score={pt['risk_score']:5.1f}  "
                      f"tier={pt['risk_tier']:6s}  adherence={pt['adherence_rate']:.0%}")
        else:
            fail("GET /clinician/roster", f"status={s}")

        s, b = get("/clinician/alerts", c_token)
        if s == 200:
            ok("GET /clinician/alerts", f"{len(b)} high-risk patients")
        else:
            fail("GET /clinician/alerts", f"status={s}")

    # Patient trying to access clinician endpoint → must be 403
    if p_token:
        s, b = get("/clinician/roster", p_token)
        if s == 403:
            ok("Patient → clinician endpoint → 403", b.get("detail", ""))
        else:
            fail("Patient should get 403 on clinician route", f"got {s}")


# ── Entry point ───────────────────────────────────────────────────────────────

def main() -> None:
    global BASE_URL

    parser = argparse.ArgumentParser(description="Siyaphila API seed + test runner")
    parser.add_argument("--url", default=BASE_URL, help="Backend base URL")
    parser.add_argument("--seed-db", action="store_true",
                        help="Seed 30-day dose history directly into local SQLite DB "
                             "(only works when --url is localhost)")
    args = parser.parse_args()
    BASE_URL = args.url.rstrip("/")

    print(f"\n{BOLD}Siyaphila API Test Suite{RESET}")
    print(f"Target: {BLUE}{BASE_URL}{RESET}\n")

    run_health_check()
    tokens = run_auth_tests()

    if not any(tokens.values()):
        print(f"\n{RED}No tokens obtained — aborting.{RESET}")
        sys.exit(1)

    run_patient_tests(tokens)
    run_medication_tests(tokens)

    # Seed local DB with historical dose data for richer risk scores
    if args.seed_db or "localhost" in BASE_URL or "127.0.0.1" in BASE_URL:
        section("DB seed — 30-day dose history (local only)")
        adherence_rates = {
            PATIENTS[0]["email"]: 0.92,   # Nomsa  → low risk
            PATIENTS[1]["email"]: 0.58,   # Sipho  → medium risk
            PATIENTS[2]["email"]: 0.28,   # Thabo  → high risk
        }
        for email, rate in adherence_rates.items():
            name = next(p["name"] for p in PATIENTS if p["email"] == email)
            print(f"  Seeding {name}...")
            seed_dose_history(email, rate)

    run_dose_tests(tokens)
    run_risk_tests(tokens)
    run_clinician_tests(tokens)

    # ── Summary ───────────────────────────────────────────────────────────────
    total = passed + failed
    print(f"\n{'─' * 56}")
    print(f"{BOLD}Results: {GREEN}{passed} passed{RESET}  {RED if failed else ''}{failed} failed{RESET}  / {total} total")
    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
