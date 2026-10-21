CREATE TABLE tb_escolas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome VARCHAR(150) NOT NULL,
    portaria VARCHAR(50) NOT NULL,
    ure VARCHAR(100) NOT NULL,
    municipio VARCHAR(150) NOT NULL,
    modalidade VARCHAR(60) NOT NULL DEFAULT 'PARCIAL'
        CHECK (modalidade IN ('INTEGRAL', 'PARCIAL')),
    horarios_por_dia INTEGER NOT NULL CHECK (horarios_por_dia BETWEEN 1 AND 12),
    duracao_horario_min INTEGER NOT NULL CHECK (duracao_horario_min BETWEEN 30 AND 120),
    hora_inicio_aulas TIME NOT NULL,
    email_institucional VARCHAR(180) NOT NULL UNIQUE,
    senha_hash VARCHAR(255) NOT NULL,
    ativa BOOLEAN NOT NULL DEFAULT TRUE,
    data_criacao TIMESTAMP NOT NULL DEFAULT now(),
    data_atualizacao TIMESTAMP NOT NULL DEFAULT now()
);