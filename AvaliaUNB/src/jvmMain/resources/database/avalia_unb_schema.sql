
--------------------------------
-- SEMESTRE
--------------------------------

CREATE TABLE IF NOT EXISTS semestre(
	ano INTEGER NOT NULL CHECK (ano >= 0),
	numero_semestre INTEGER NOT NULL CHECK (numero_semestre = 1 OR numero_semestre = 2),
	data_inicio TEXT,
	data_fim TEXT,
	PRIMARY KEY (ano, numero_semestre)
);

--------------------------------
-- ESTUDANTES / USUARIOS 
--------------------------------

CREATE TABLE IF NOT EXISTS usuario(
	matricula TEXT NOT NULL CHECK (length(matricula) = 9),
	nome TEXT NOT NULL,
	curso TEXT,
	email TEXT UNIQUE NOT NULL,
	senha TEXT NOT NULL,
	foto_de_perfil BLOB,
	eh_administrador BOOLEAN DEFAULT FALSE,
	PRIMARY KEY (matricula)
);

--------------------------------
-- DEPARTAMENTOS
--------------------------------

CREATE TABLE IF NOT EXISTS departamento(
	codigo INTEGER NOT NULL CHECK (codigo >= 0),
	nome TEXT NOT NULL,
    ano_semestre INTEGER NOT NULL CHECK (ano_semestre >= 0),
	numero_semestre INTEGER NOT NULL CHECK (numero_semestre = 1 OR numero_semestre = 2),
	cor INTEGER,
	PRIMARY KEY (codigo, ano_semestre, numero_semestre),
	FOREIGN KEY (ano_semestre, numero_semestre) REFERENCES semestre(ano, numero_semestre)
);

--------------------------------
-- DISCIPLINAS
--------------------------------

CREATE TABLE IF NOT EXISTS disciplina(
    id INTEGER NOT NULL,
	codigo TEXT NOT NULL,
	nome TEXT NOT NULL,
    ano_semestre INTEGER NOT NULL CHECK (ano_semestre >= 0),
	numero_semestre INTEGER NOT NULL CHECK (numero_semestre = 1 OR numero_semestre = 2),
	codigo_departamento INTEGER NOT NULL CHECK (codigo_departamento >= 0),
	PRIMARY KEY (id),
	FOREIGN KEY (codigo_departamento, ano_semestre, numero_semestre) REFERENCES departamento(codigo, ano_semestre, numero_semestre)
);

--------------------------------
-- PROFESSORES
--------------------------------

CREATE TABLE IF NOT EXISTS professor(
	nome TEXT NOT NULL,
	codigo_departamento INTEGER NOT NULL CHECK (codigo_departamento >= 0),
    ano_semestre INTEGER NOT NULL CHECK (ano_semestre >= 0),
	numero_semestre INTEGER NOT NULL CHECK (numero_semestre = 1 OR numero_semestre = 2),
	foto_de_perfil BLOB,
	pontuacao REAL CHECK (pontuacao IS NULL OR (pontuacao >= 0 AND pontuacao <= 5)),
	PRIMARY KEY (nome, codigo_departamento),
	FOREIGN KEY (codigo_departamento, ano_semestre, numero_semestre) REFERENCES departamento(codigo, ano_semestre, numero_semestre)
);

--------------------------------
-- TURMAS
--------------------------------

CREATE TABLE IF NOT EXISTS turma(
	id INTEGER NOT NULL,
	codigo_turma TEXT,
    horario TEXT,
    num_horas INTEGER NOT NULL CHECK (num_horas >= 0),
    vagas_total INTEGER NOT NULL CHECK (vagas_total >= 0),
    vagas_ocupadas INTEGER NOT NULL CHECK (vagas_ocupadas >= 0 AND vagas_ocupadas <= vagas_total),
    local_aula TEXT,
    pontuacao REAL CHECK (pontuacao IS NULL OR (pontuacao >= 0 AND pontuacao <= 5)),
    nome_professor TEXT NOT NULL,
	id_disciplina INTEGER NOT NULL,
	codigo_departamento INTEGER NOT NULL CHECK (codigo_departamento >= 0),
	PRIMARY KEY (id),
	FOREIGN KEY (nome_professor, codigo_departamento) REFERENCES professor(nome, codigo_departamento),
	FOREIGN KEY (id_disciplina) REFERENCES disciplina(id)
);

--------------------------------
-- AVALIACOES
--------------------------------

CREATE TABLE IF NOT EXISTS avaliacao(
	id INTEGER NOT NULL,
	comentario TEXT,
	pontuacao INTEGER NOT NULL CHECK (pontuacao >= 0 AND pontuacao <= 5),
	matricula_aluno TEXT NOT NULL CHECK (length(matricula_aluno) = 9),
	PRIMARY KEY (id),
	FOREIGN KEY (matricula_aluno) REFERENCES usuario(matricula)
);

CREATE TABLE IF NOT EXISTS avaliacao_turma(
	id_avaliacao INTEGER NOT NULL,
	id_turma INTEGER NOT NULL,
	PRIMARY KEY (id_avaliacao),
	FOREIGN KEY (id_avaliacao) REFERENCES avaliacao(id),
	FOREIGN KEY (id_turma) REFERENCES turma(id)
);

CREATE TABLE IF NOT EXISTS avaliacao_professor(
	id_avaliacao INTEGER NOT NULL,
	nome_professor TEXT,
	codigo_departamento INTEGER NOT NULL CHECK (codigo_departamento >= 0),
	PRIMARY KEY (id_avaliacao),
	FOREIGN KEY (id_avaliacao) REFERENCES avaliacao(id),
	FOREIGN KEY (nome_professor, codigo_departamento) REFERENCES professor(nome, codigo_departamento)
);

--------------------------------
-- TRIGGERS
--------------------------------

-- Esses triggers atualizam a pontuacao da turma toda vez que uma
-- avalicao for inserida/removida/modificada

CREATE TRIGGER IF NOT EXISTS analise_inserida_atualizar_turma
AFTER INSERT ON avaliacao_turma
BEGIN
    UPDATE turma
    SET pontuacao = (
        SELECT AVG(pontuacao)
        FROM avaliacao
        INNER JOIN avaliacao_turma ON avaliacao.id = avaliacao_turma.id_avaliacao
        WHERE avaliacao_turma.id_turma = turma.id
    )
    WHERE turma.id = NEW.id_turma;
END;

CREATE TRIGGER IF NOT EXISTS analise_removida_atualizar_turma
AFTER DELETE ON avaliacao_turma
BEGIN
    UPDATE turma
    SET pontuacao = (
        SELECT AVG(pontuacao)
        FROM avaliacao
        INNER JOIN avaliacao_turma ON avaliacao.id = avaliacao_turma.id_avaliacao
        WHERE avaliacao_turma.id_turma = turma.id
    )
    WHERE turma.id = OLD.id_turma;
END;

CREATE TRIGGER IF NOT EXISTS analise_modificada_atualizar_pontuacao
AFTER UPDATE ON avaliacao
BEGIN
    UPDATE turma
    SET pontuacao = (
        SELECT AVG(pontuacao)
        FROM avaliacao
        INNER JOIN avaliacao_turma ON avaliacao.id = avaliacao_turma.id_avaliacao
        WHERE avaliacao_turma.id_turma = turma.id
    )
    WHERE turma.id IN (
        SELECT id_turma
        FROM avaliacao_turma
        WHERE id_avaliacao = NEW.id);
END