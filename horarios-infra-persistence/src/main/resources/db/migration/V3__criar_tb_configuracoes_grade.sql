CREATE TABLE tb_configuracoes_grade (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    escola_id UUID NOT NULL UNIQUE REFERENCES tb_escolas (id) ON DELETE CASCADE,
    limite_diario_padrao INTEGER NOT NULL DEFAULT 5 CHECK (limite_diario_padrao > 0),
    limite_diario_rigido BOOLEAN NOT NULL DEFAULT FALSE,
    peso_limite_diario INTEGER NOT NULL DEFAULT 100 CHECK (peso_limite_diario >= 0),
    peso_janelas INTEGER NOT NULL DEFAULT 30 CHECK (peso_janelas >= 0),
    peso_distribuicao INTEGER NOT NULL DEFAULT 10 CHECK (peso_distribuicao >= 0),
    peso_concentracao_dias INTEGER NOT NULL DEFAULT 5 CHECK (peso_concentracao_dias >= 0),
    tempo_maximo_geracao_seg INTEGER NOT NULL DEFAULT 30 CHECK (tempo_maximo_geracao_seg > 0),
    data_criacao TIMESTAMP NOT NULL DEFAULT now(),
    data_atualizacao TIMESTAMP NOT NULL DEFAULT now()
);