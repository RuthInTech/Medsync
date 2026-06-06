import os
from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

# On Render, point DATABASE_URL to the persistent disk path:
# sqlite:////data/siyaphila.db (four slashes = absolute path)
SQLALCHEMY_DATABASE_URL = os.environ.get(
    "DATABASE_URL", "sqlite:////data/siyaphila.db"
)

connect_args = {"check_same_thread": False} if SQLALCHEMY_DATABASE_URL.startswith("sqlite") else {}
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args=connect_args)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    pass


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
