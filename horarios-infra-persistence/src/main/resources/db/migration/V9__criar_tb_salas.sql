CREATE TABLE tb_salas (
                          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                          escola_id UUID NOT NULL REFERENCES tb_escolas (id),
                          nome VARCHAR(100) NOT NULL,
                          tipo VARCHAR(20) NOT NULL DEFAULT 'SALA_COMUM'
                              CHECK (tipo IN ('SALA_COMUM', 'LABORATORIO', 'QUADRA', 'OUTRO')),
                          capacidade INTEGER CHECK (capacidade > 0),
                          data_criacao TIMESTAMP NOT NULL DEFAULT now(),
                          data_atualizacao TIMESTAMP NOT NULL DEFAULT now(),
                          CONSTRAINT uk_salas_escola_nome UNIQUE (escola_id, nome)
);

CREATE INDEX idx_salas_escola ON tb_salas (escola_id);