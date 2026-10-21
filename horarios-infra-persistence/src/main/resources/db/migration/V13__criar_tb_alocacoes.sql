CREATE TABLE tb_alocacoes (
                              id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                              escola_id UUID NOT NULL REFERENCES tb_escolas (id),
                              grade_id UUID NOT NULL REFERENCES tb_grades (id) ON DELETE CASCADE,
                              oferta_id UUID NOT NULL REFERENCES tb_ofertas (id),
                              dia_semana VARCHAR(10) NOT NULL
                                  CHECK (dia_semana IN ('SEGUNDA', 'TERCA', 'QUARTA', 'QUINTA', 'SEXTA', 'SABADO')),
                              horario_inicial INTEGER NOT NULL CHECK (horario_inicial >= 1),
                              tamanho_bloco INTEGER NOT NULL CHECK (tamanho_bloco BETWEEN 1 AND 4),
                              sala_id UUID REFERENCES tb_salas (id),
                              fixada BOOLEAN NOT NULL DEFAULT FALSE,
                              data_criacao TIMESTAMP NOT NULL DEFAULT now(),
                              data_atualizacao TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_alocacoes_escola ON tb_alocacoes (escola_id);
CREATE INDEX idx_alocacoes_grade_dia_horario
    ON tb_alocacoes (grade_id, dia_semana, horario_inicial);
CREATE INDEX idx_alocacoes_oferta ON tb_alocacoes (oferta_id);
CREATE INDEX idx_alocacoes_sala ON tb_alocacoes (sala_id);