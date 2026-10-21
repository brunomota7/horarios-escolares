CREATE TABLE tb_professores (
                                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                escola_id UUID NOT NULL REFERENCES tb_escolas (id),
                                nome VARCHAR(150) NOT NULL,
                                matricula VARCHAR(30),
                                email VARCHAR(180),
                                carga_contratada_semanal INTEGER NOT NULL CHECK (carga_contratada_semanal > 0),
                                limite_diario_horarios INTEGER CHECK (limite_diario_horarios > 0),
                                ativo BOOLEAN NOT NULL DEFAULT TRUE,
                                data_criacao TIMESTAMP NOT NULL DEFAULT now(),
                                data_atualizacao TIMESTAMP NOT NULL DEFAULT now(),
                                CONSTRAINT uk_professores_escola_matricula UNIQUE (escola_id, matricula)
);

CREATE INDEX idx_professores_escola ON tb_professores (escola_id);