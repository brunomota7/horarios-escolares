CREATE TABLE tb_disponibilidades_professor (
                                               id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                               escola_id UUID NOT NULL REFERENCES tb_escolas (id),
                                               professor_id UUID NOT NULL REFERENCES tb_professores (id) ON DELETE CASCADE,
                                               semestre_id UUID NOT NULL REFERENCES tb_semestres (id),
                                               dia_semana VARCHAR(10) NOT NULL
                                                   CHECK (dia_semana IN ('SEGUNDA', 'TERCA', 'QUARTA', 'QUINTA', 'SEXTA', 'SABADO')),
                                               horario_inicial INTEGER NOT NULL CHECK (horario_inicial >= 1),
                                               horario_final INTEGER NOT NULL,
                                               motivo VARCHAR(200),
                                               data_criacao TIMESTAMP NOT NULL DEFAULT now(),
                                               data_atualizacao TIMESTAMP NOT NULL DEFAULT now(),
                                               CONSTRAINT ck_disponibilidades_faixa CHECK (horario_final >= horario_inicial)
);

CREATE INDEX idx_disponibilidades_escola ON tb_disponibilidades_professor (escola_id);
CREATE INDEX idx_disponibilidades_professor_semestre
    ON tb_disponibilidades_professor (professor_id, semestre_id);