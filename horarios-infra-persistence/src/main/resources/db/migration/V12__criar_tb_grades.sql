CREATE TABLE tb_grades (
                           id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                           escola_id UUID NOT NULL REFERENCES tb_escolas (id),
                           semestre_id UUID NOT NULL REFERENCES tb_semestres (id),
                           versao INTEGER NOT NULL CHECK (versao >= 1),
                           status VARCHAR(20) NOT NULL DEFAULT 'RASCUNHO'
                               CHECK (status IN ('RASCUNHO', 'PUBLICADA', 'ARQUIVADA')),
                           origem VARCHAR(20) NOT NULL CHECK (origem IN ('GERADA', 'MANUAL')),
                           score_penalidade INTEGER NOT NULL DEFAULT 0,
                           total_violacoes_hard INTEGER NOT NULL DEFAULT 0,
                           total_alertas_soft INTEGER NOT NULL DEFAULT 0,
                           data_criacao TIMESTAMP NOT NULL DEFAULT now(),
                           data_atualizacao TIMESTAMP NOT NULL DEFAULT now(),
                           CONSTRAINT uk_grades_semestre_versao UNIQUE (semestre_id, versao)
);

-- só pode existir uma grade PUBLICADA por semestre
CREATE UNIQUE INDEX ux_grades_publicada_por_semestre
    ON tb_grades (semestre_id) WHERE status = 'PUBLICADA';

CREATE INDEX idx_grades_escola ON tb_grades (escola_id);