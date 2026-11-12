# A receita da API. Quem constrói a imagem é o serviço de nuvem (o Render): nada
# disto precisa de Docker na sua máquina.

# Comece de uma base pronta: um Python já instalado. A versão é a que o
# pyproject.toml exige (>=3.13): com uma menor, o poetry install recusa.
FROM python:3.13-slim

# A pasta de trabalho, dentro do contêiner.
WORKDIR /codigo

# Instale os pacotes do projeto, sem os de desenvolvimento (o pytest fica fora).
# O poetry.lock garante as MESMAS versões que foram testadas. O --no-root instala
# só as dependências: o projeto não é um pacote, é uma pasta com a pasta app/.
COPY pyproject.toml poetry.lock ./
RUN pip install --no-cache-dir poetry \
    && poetry config virtualenvs.create false \
    && poetry install --only main --no-root --no-interaction

# Copie o código. O .dockerignore diz o que não entra.
COPY . .

# Ao ligar: crie ou atualize as tabelas (alembic) e suba a API. O serviço de
# nuvem diz a porta na variável PORT; sem ela, a 8000.
CMD ["sh", "-c", "alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
