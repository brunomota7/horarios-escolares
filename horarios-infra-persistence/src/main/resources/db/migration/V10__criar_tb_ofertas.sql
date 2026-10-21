CREATE TABLE tb_ofertas (
                            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                            escola_id UUID NOT NULL REFERENCES tb_escolas (id),
                            semestre_id UUID NOT NULL REFERENCES tb_semestres (id),
                            disciplina_id UUID NOT NULL REFERENCES tb_disciplinas (id),
                            turma_id UUID NOT NULL REFERENCES tb_turmas (id),
                            professor_id UUID NOT NULL REFERENCES tb_professores (id),
                            sala_preferencial_id UUID REFERENCES tb_salas (id),
                            carga_semanal INTEGER NOT NULL CHECK (carga_semanal > 0),
                            data_criacao TIMESTAMP NOT NULL DEFAULT now(),
                            data_atualizacao TIMESTAMP NOT NULL DEFAULT now(),
                            CONSTRAINT uk_ofertas_semestre_disciplina_turma
                                UNIQUE (semestre_id, disciplina_id, turma_id)
);

CREATE INDEX idx_ofertas_escola ON tb_ofertas (escola_id);
CREATE INDEX idx_ofertas_semestre ON tb_ofertas (semestre_id);
CREATE INDEX idx_ofertas_professor ON tb_ofertas (professor_id);
CREATE INDEX idx_ofertas_turma ON tb_ofertas (turma_id);