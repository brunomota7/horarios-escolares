CREATE TABLE tb_semestres (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    escola_id UUID NOT NULL REFERENCES tb_escolas (id),
    rotulo VARCHAR(20) NOT NULL,
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PLANEJAMENTO'
        CHECK (status IN ('PLANEJAMENTO', 'ATIVO', 'ENCERRADO')),
    data_criacao TIMESTAMP NOT NULL DEFAULT now(),
    data_atualizacao TIMESTAMP NOT NULL DEFAULT now(),
    CONSTRAINT uk_semestres_escola_rotulo UNIQUE (escola_id, rotulo),
    CONSTRAINT ck_semestres_datas CHECK (data_fim > data_inicio)
);

CREATE INDEX idx_semestres_escola ON tb_semestres (escola_id);