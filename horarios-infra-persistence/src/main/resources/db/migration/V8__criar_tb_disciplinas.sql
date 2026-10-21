CREATE TABLE tb_disciplinas (
                                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                escola_id UUID NOT NULL REFERENCES tb_escolas (id),
                                nome VARCHAR(150) NOT NULL,
                                sigla VARCHAR(20),
                                tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('BASE_COMUM', 'BASE_TECNICA')),
                                data_criacao TIMESTAMP NOT NULL DEFAULT now(),
                                data_atualizacao TIMESTAMP NOT NULL DEFAULT now(),
                                CONSTRAINT uk_disciplinas_escola_nome UNIQUE (escola_id, nome)
);

CREATE INDEX idx_disciplinas_escola ON tb_disciplinas (escola_id);