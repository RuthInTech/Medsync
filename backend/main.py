from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import engine, Base
from routers import auth, patients, medications, doses, risk, clinician

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Siyaphila API",
    description="AI Chronic Adherence Platform — Harvard HSIL & UCT Hackathon",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(patients.router)
app.include_router(medications.router)
app.include_router(doses.router)
app.include_router(risk.router)
app.include_router(clinician.router)


@app.get("/health")
def health_check():
    return {"status": "healthy", "service": "Siyaphila API"}
