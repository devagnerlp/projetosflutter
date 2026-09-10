import sqlite3

BANCO = "corrigeprovas.db"

ESQUEMA = """
CREATE TABLE IF NOT EXISTS questoes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    simulado_id INTEGER NOT NULL,
    numero INTEGER NOT NULL,
    gabarito TEXT NOT NULL,
    area_conhecimento TEXT,
    assunto TEXT,

    CONSTRAINT fk_questao_simulado
        FOREIGN KEY (simulado_id) 
        REFERENCES simulados(id)
        ON DELETE CASCADE,

    UNIQUE (simulado_id, numero),

    CHECK (gabarito IN ('A', 'B', 'C', 'D', 'E'))
);
"""

QUESTOES_INICIAIS = [
    (1, 1, 1, "A", "Matemática", "Frações"),
    (2, 1, 2, "C", "Matemática", "Porcentagem"),
    (3, 1, 3, "B", "Matemática", None),
    (4, 1, 4, "D", "Matemática", "Equações"),
    (5, 1, 5, "A", "Matemática", "Geometria"),
    (6, 1, 6, "E", "Matemática", "Operações"),
    (7, 1, 7, "B", "Matemática", "Frações"),
    (8, 1, 8, "C", "Matemática", "Álgebra"),
    (9, 1, 9, "D", "Matemática", "Medidas"),
    (10, 1, 10, "A", "Matemática", "Probabilidade"),
]

def conectar(banco=BANCO):
    """Uma conexao com as linhas acessiveis por nome de coluna."""
    conn = sqlite3.connect(banco)
    # Ativa a validação das chaves estrangeiras nesta conexão
    conn.execute("PRAGMA foreign_keys = ON;")
    conn.row_factory = sqlite3.Row
    return conn
def criar_banco(banco=BANCO):
    """Cria as tabelas e o acervo inicial, se ainda nao existirem."""
    conn = conectar(banco)
    try:
        conn.executescript(ESQUEMA)
        vazio = conn.execute("SELECT COUNT(*) FROM questoes").fetchone()[0] == 0
        if vazio:
            conn.executemany(
                "INSERT INTO questoes (id, simulado_id, numero, gabarito, area_conhecimento, assunto) VALUES (?, ?, ?, ?, ?, ?)",
                QUESTOES_INICIAIS,
            )
        conn.commit()
    finally:
        conn.close()

