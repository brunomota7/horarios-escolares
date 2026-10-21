CREATE TABLE tb_blocos_oferta (
                                  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                  escola_id UUID NOT NULL REFERENCES tb_escolas (id),
                                  oferta_id UUID NOT NULL REFERENCES tb_ofertas (id) ON DELETE CASCADE,
                                  tamanho INTEGER NOT NULL CHECK (tamanho BETWEEN 1 AND 4),
                                  quantidade INTEGER NOT NULL CHECK (quantidade >= 1),
                                  CONSTRAINT uk_blocos_oferta_tamanho UNIQUE (oferta_id, tamanho)
);

CREATE INDEX idx_blocos_oferta_escola ON tb_blocos_oferta (escola_id);