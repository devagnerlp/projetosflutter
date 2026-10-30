import os

# Valores só para os testes: não dependem do .env de ninguém.
# Precisam estar definidos ANTES de o app ser importado.
os.environ.setdefault("SECRET_KEY", "chave-so-para-os-testes-com-mais-de-32-bytes")
os.environ.setdefault("DATABASE_URL", "sqlite:///:memory:")

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.database import Base
from app.alunos import models as _alunos  # noqa: F401
from app.questoes import models as _questoes  # noqa: F401
from app.respostas import models as _respostas  # noqa: F401
from app.simulados import models as _simulados  # noqa: F401
from app.turma import models as _turma  # noqa: F401
from app.usuarios import models as _usuarios  # noqa: F401


@pytest.fixture
def db():
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    sessao = sessionmaker(bind=engine, autoflush=False)()
    yield sessao
    sessao.close()
    engine.dispose()