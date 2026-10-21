CREATE TABLE tb_turmas (
                           id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                           escola_id UUID NOT NULL REFERENCES tb_escolas (id),
                           nome VARCHAR(100) NOT NULL,
                           serie INTEGER NOT NULL CHECK (serie BETWEEN 1 AND 3),
                           turno VARCHAR(20) NOT NULL
                               CHECK (turno IN ('MATUTINO', 'VESPERTINO', 'INTEGRAL', 'NOTURNO')),
                           curso VARCHAR(150),
                           ativa BOOLEAN NOT NULL DEFAULT TRUE,
                           data_criacao TIMESTAMP NOT NULL DEFAULT now(),
                           data_atualizacao TIMESTAMP NOT NULL DEFAULT now(),
                           CONSTRAINT uk_turmas_escola_nome UNIQUE (escola_id, nome)
);

CREATE INDEX idx_turmas_escola ON tb_turmas (escola_id);