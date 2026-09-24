import os
import sys
from logging.config import fileConfig

from alembic import context
from sqlalchemy import engine_from_config, pool

# a raiz do projeto (onde fica a pasta app/) precisa estar no path,
# senao "from app.database import ..." nao encontra nada.
sys.path.insert(0, os.getcwd())

from app.database import Base, URL

# so' o import ja' basta: e' isso que registra cada tabela em Base.metadata.
# Se faltar um destes, o autogenerate simplesmente nao ve aquela tabela --
# e pode ate' gerar uma migracao que apaga tudo.
from app.usuarios import models as usuarios_models  # noqa: F401
from app.simulados import models as simulados_models  # noqa: F401
from app.questoes import models as questoes_models  # noqa: F401

config = context.config

# A MESMA URL que o resto da aplicacao usa -- nao existe uma segunda fonte
# de verdade, e a senha nunca fica escrita no alembic.ini. O `%` dobrado e'
# porque o arquivo .ini trata `%` como caractere especial de interpolacao;
# se a senha do banco tiver esse simbolo, sem o escape a leitura quebra.
config.set_main_option("sqlalchemy.url", URL.replace("%", "%%"))

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata

# O SQLite quase nao sabe alterar tabela (o ALTER TABLE dele e' minimo). Em
# modo batch o Alembic recria a tabela por baixo dos panos -- e a mesma
# migracao que funciona no SQLite funciona igual no PostgreSQL.
BATCH = True


def run_migrations_offline():
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        render_as_batch=BATCH,
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online():
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            render_as_batch=BATCH,
        )
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()