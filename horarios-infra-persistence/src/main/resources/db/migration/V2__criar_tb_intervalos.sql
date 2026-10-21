CREATE TABLE tb_intervalos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    escola_id UUID NOT NULL REFERENCES tb_escolas (id) ON DELETE CASCADE,
    apos_horario INTEGER NOT NULL CHECK (apos_horario >= 1),
    duracao_min INTEGER NOT NULL CHECK (duracao_min > 0),
    descricao VARCHAR(60) NOT NULL,
    data_criacao TIMESTAMP NOT NULL DEFAULT now(),
    data_atualizacao TIMESTAMP NOT NULL DEFAULT now(),
    CONSTRAINT uk_intervalos_escola_apos UNIQUE (escola_id, apos_horario)
);

CREATE INDEX idx_intervalos_escola ON tb_intervalos (escola_id);