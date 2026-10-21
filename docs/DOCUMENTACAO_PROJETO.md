# Horários Escolares: Gerador e Validador de Grade

> Backend em Java 21 + Spring Boot que permite à gestão de uma escola cadastrar sua estrutura (professores, turmas, disciplinas, salas), gerar automaticamente a grade de horários de um semestre, validar edições manuais e exportar a grade (geral, por professor e por turma).

**Status do documento:** versão 1.0 (planejamento)
**Escopo atual:** somente backend/API. Sem frontend nesta fase.

---

## Sumário

1. [Contexto e problema](#1-contexto-e-problema)
2. [Objetivos e escopo](#2-objetivos-e-escopo)
3. [Decisões de projeto assumidas](#3-decisões-de-projeto-assumidas)
4. [Tecnologias e dependências](#4-tecnologias-e-dependências)
5. [Arquitetura e estrutura em módulos](#5-arquitetura-e-estrutura-em-módulos)
6. [Modelo de domínio (entidades)](#6-modelo-de-domínio-entidades)
7. [Regras de negócio](#7-regras-de-negócio)
8. [Funcionalidades e services por entidade](#8-funcionalidades-e-services-por-entidade)
9. [API REST: rotas](#9-api-rest-rotas)
10. [Segurança e multiescola](#10-segurança-e-multiescola)
11. [Padrão de erros](#11-padrão-de-erros)
12. [Estratégia de testes](#12-estratégia-de-testes)
13. [Roadmap](#13-roadmap)
14. [Pontos em aberto](#14-pontos-em-aberto)

---

## 1. Contexto e problema

O sistema usado hoje para montar o horário escolar é legado, difícil de entender e de operar. Na prática isso gera:

- choques de horário (professor em duas turmas ao mesmo tempo);
- retrabalho a cada ajuste;
- **sobrecarga de professores**, com casos de mais de 5 horários de aula em um único dia;
- dificuldade de lidar com disciplinas de carga maior (blocos duplos, triplos e quádruplos) e com a troca de componentes técnicos a cada semestre.

## 2. Objetivos e escopo

### 2.1 Objetivos

- Reduzir o tempo de montagem do horário.
- Eliminar conflitos por construção (a grade só é publicada se passar nas regras obrigatórias).
- Proteger o professor da sobrecarga diária.
- Entregar um motor de validação independente do gerador, de modo que uma futura interface arrastável possa validar cada movimentação em tempo real.

### 2.2 Dentro do escopo (MVP)

- Cadastro e autenticação da **escola** (não de uma pessoa).
- Cadastros de semestre, professores, turmas, disciplinas, salas/laboratórios e ofertas.
- Geração automática de grade por semestre.
- Validação de grade (gerada ou editada) com lista de violações.
- Edição manual de alocações com validação.
- Exportação em PDF/CSV: grade geral da semana, por professor e por turma.

### 2.3 Fora do escopo por enquanto

- Frontend / quadro interativo (a API já nasce preparada para ele).
- Professor atuando em mais de uma escola com checagem cruzada entre escolas.
- Integrações com sistemas da SEDUC.
- Substituição automática de professores faltosos.

---

## 3. Decisões de projeto assumidas

Para fechar o documento, assumi as decisões abaixo. Todas são configuráveis ou fáceis de mudar:

| Tema | Decisão |
|---|---|
| **Semestre** | Toda grade pertence a um semestre. Disciplinas técnicas são ofertadas por semestre; a base comum pode ser reaproveitada entre semestres. |
| **Fonte da carga horária** | A carga da **oferta** (disciplina + turma + professor) é a fonte da verdade. A carga do professor é **calculada** (soma das ofertas) e comparada com a contratada. Divergência gera alerta, não bloqueio. |
| **Blocos** | Cada oferta define seus blocos: simples (1), duplo (2), triplo (3) ou quádruplo (4). Ex.: carga 4 = 2 blocos duplos **ou** 1 quádruplo. |
| **Intervalos (recreio/almoço)** | Modelados como pontos de corte na grade ("depois do horário N"). Um bloco **não pode atravessar** um intervalo. |
| **Limite diário do professor** | Padrão de **5 horários/dia**, configurável por escola e por professor. Pode ser **alerta** (soft) ou **teto rígido** (hard), por configuração da escola. |
| **Turnos** | A escola tem uma única malha de horários por dia (N horários de X minutos). Turno da turma é informativo no MVP. |
| **Modalidade** | Integral/Parcial define apenas valores padrão no cadastro (quantidade de horários/dia). Regras específicas por modalidade ficam para depois do MVP. |
| **Dias letivos** | Segunda a sexta. O enum já prevê sábado para o futuro. |
| **Geração** | Síncrona no MVP, com limite de tempo configurável. Evolui para execução assíncrona (job) se o tempo crescer. |

---

## 4. Tecnologias e dependências

### 4.1 Stack

| Camada | Tecnologia |
|---|---|
| Linguagem | Java 21 (LTS) |
| Framework | Spring Boot 3.x |
| Build | Maven (multi-módulo) |
| Banco (dev/teste) | H2 em memória |
| Banco (produção/demonstração) | PostgreSQL |
| Migrações | Flyway |
| Autenticação | Spring Security + JWT |
| Documentação da API | OpenAPI / Swagger UI (springdoc) |
| Exportação | OpenPDF (PDF) e Apache Commons CSV |
| Testes | JUnit 5, AssertJ, Mockito, Testcontainers, ArchUnit |
| Qualidade | JaCoCo (cobertura), Checkstyle ou Spotless (formatação) |
| Containerização | Docker + docker-compose (app + PostgreSQL) |

### 4.2 Dependências por módulo

> Versões de Spring ficam sob gestão do `spring-boot-starter-parent` / BOM. Fixe as demais no `<dependencyManagement>` do POM pai.

| Módulo | Dependências principais |
|---|---|
| `horarios-domain` | Nenhuma de framework. Apenas JDK (e opcionalmente `jakarta.validation-api` para anotações) |
| `horarios-engine` | `horarios-domain`; JUnit 5 e AssertJ (test) |
| `horarios-application` | `horarios-domain`, `horarios-engine`, `spring-context`, `spring-tx` |
| `horarios-infra-persistence` | `horarios-application`, `spring-boot-starter-data-jpa`, `flyway-core`, `postgresql`, `h2` (runtime/test) |
| `horarios-infra-export` | `horarios-application`, `com.github.librepdf:openpdf`, `commons-csv` |
| `horarios-api` | todos os módulos acima, `spring-boot-starter-web`, `spring-boot-starter-validation`, `spring-boot-starter-security`, `spring-boot-starter-actuator`, `jjwt-api/impl/jackson`, `springdoc-openapi-starter-webmvc-ui` |

Dependências de teste (no módulo que for usar): `spring-boot-starter-test`, `spring-security-test`, `testcontainers` (junit-jupiter + postgresql), `archunit-junit5`.

Opcional: MapStruct para mapeamento DTO ↔ entidade. Se preferir menos "mágica", use mapeadores manuais ou `record`s com métodos estáticos.

### 4.3 Boas práticas adotadas

- DTOs como `record` Java.
- Entidades de domínio **separadas** das entidades JPA (o domínio não conhece JPA).
- Senhas com BCrypt, nunca em texto puro.
- Migrações versionadas com Flyway (nada de `ddl-auto=update` em produção).
- Perfis Spring: `dev` (H2), `test`, `prod` (PostgreSQL).

---

## 5. Arquitetura e estrutura em módulos

### 5.1 Estrutura nova ou a de costume?

Recomendo **adotar uma estrutura nova**: **Maven multi-módulo com arquitetura hexagonal (ports and adapters)**, em vez da clássica em camadas num único módulo (`controller / service / repository / model`).

| Critério | Em camadas (clássica) | Multi-módulo hexagonal (recomendada) |
|---|---|---|
| Simplicidade inicial | Alta | Média |
| Isolamento das regras de negócio | Baixo (regras se misturam com JPA/Spring) | **Alto** (domínio e motor são Java puro) |
| Testar o gerador e o validador sem subir Spring | Difícil | **Fácil** |
| Troca de banco, web ou exportador | Custosa | Isolada nos adaptadores |
| Valor no portfólio | Comum | **Diferencial** |
| Reaproveitar o motor num futuro frontend/desktop | Complicado | Natural |

**Por quê aqui:** o coração do projeto é o motor (validador + gerador). Mantê-lo em Java puro, fora do Spring, o torna testável, rápido e demonstrável. A API REST vira apenas mais um "adaptador" de entrada.

> Se por "a que já usamos continuamente" você se referia a algum padrão específico seu, me diga e eu adapto. Neste documento, a camada clássica pode ser retomada dentro do módulo `horarios-api` (controllers) e `horarios-application` (services).

### 5.2 Módulos

```
horarios-escolares/
├── pom.xml                          # POM pai (BOM, versões, plugins)
├── docker-compose.yml
├── README.md
├── docs/
│   └── DOCUMENTACAO_PROJETO.md
│
├── horarios-domain/                 # Núcleo: Java puro
├── horarios-engine/                 # Validador + Gerador: Java puro
├── horarios-application/            # Casos de uso e portas (interfaces)
├── horarios-infra-persistence/      # Adaptador de saída: JPA + Flyway
├── horarios-infra-export/           # Adaptador de saída: PDF/CSV
└── horarios-api/                    # Adaptador de entrada: REST + segurança + main
```

### 5.3 Regra de dependência

As setas apontam "depende de". **Nada no núcleo depende de fora.**

```
horarios-api ───────────────┐
horarios-infra-persistence ─┼──► horarios-application ──► horarios-engine ──► horarios-domain
horarios-infra-export ──────┘                    └─────────────────────────────►
```

- `domain` não depende de ninguém.
- `engine` depende só de `domain`.
- `application` depende de `domain` e `engine`, e **define as portas** (interfaces de repositório e de exportação).
- `infra-*` **implementam** essas portas.
- `api` conecta tudo (injeção de dependência) e expõe HTTP.

Essa regra é **verificada por teste** com ArchUnit (ver seção 12).

### 5.4 Organização interna de cada módulo

#### `horarios-domain`
```
br.edu.horarios.domain
├── escola/        Escola, Modalidade, ConfiguracaoGrade, Intervalo
├── semestre/      Semestre, StatusSemestre
├── professor/     Professor, DisponibilidadeProfessor
├── turma/         Turma, Turno
├── disciplina/    Disciplina, TipoDisciplina
├── sala/          Sala, TipoSala
├── oferta/        Oferta, BlocoOferta
├── grade/         Grade, Alocacao, StatusGrade, DiaSemana
└── shared/        value objects (HorarioSlot, EmailInstitucional), exceções de domínio
```

#### `horarios-engine`
```
br.edu.horarios.engine
├── validator/
│   ├── Regra.java                  # interface: List<Violacao> avaliar(ContextoGrade)
│   ├── Violacao.java               # record: codigo, severidade, mensagem, alocacoesEnvolvidas
│   ├── ValidadorDeGrade.java       # orquestra as regras
│   ├── hard/                       # ConflitoProfessor, ConflitoTurma, ConflitoSala,
│   │                               # BlocoContiguo, Indisponibilidade, CargaCompleta, ...
│   └── soft/                       # LimiteDiarioProfessor, JanelasProfessor,
│                                   # DistribuicaoSemanal, ConcentracaoDeDias
├── solver/
│   ├── GeradorDeGrade.java         # interface
│   ├── BacktrackingSolver.java     # etapa 1: solução viável
│   ├── BuscaLocalOtimizador.java   # etapa 2: reduz penalidade soft
│   └── heuristica/                 # ordenação de ofertas (mais restritas primeiro)
└── pontuacao/                      # cálculo do score e pesos
```

> O `solver` pode usar o `validator`, mas o `validator` **nunca** depende do `solver`.

#### `horarios-application`
```
br.edu.horarios.application
├── escola/        CadastrarEscolaUseCase, AtualizarEscolaUseCase, ...
├── professor/     ProfessorService, DisponibilidadeService
├── turma/         TurmaService
├── disciplina/    DisciplinaService
├── sala/          SalaService
├── semestre/      SemestreService
├── oferta/        OfertaService
├── grade/         GerarGradeUseCase, ValidarGradeUseCase, EditarAlocacaoUseCase,
│                  PublicarGradeUseCase, RelatorioCargaUseCase
├── exportacao/    ExportarGradeUseCase
└── port/
    ├── out/       EscolaRepository, ProfessorRepository, ..., GradeRepository,
    │              ExportadorPdfPort, ExportadorCsvPort, SenhaHasherPort
    └── dto/       comandos e resultados (records)
```

#### `horarios-infra-persistence`
```
br.edu.horarios.infra.persistence
├── entity/        EscolaJpa, ProfessorJpa, ... (anotações JPA)
├── repository/    interfaces Spring Data (JPA)
├── adapter/       implementações das portas do application
├── mapper/        domínio ↔ JPA
└── resources/db/migration/   V1__criar_escola.sql, V2__..., ...
```

#### `horarios-infra-export`
```
br.edu.horarios.infra.export
├── pdf/           GradeGeralPdf, GradeProfessorPdf, GradeTurmaPdf
└── csv/           GradeCsvExportador
```

#### `horarios-api`
```
br.edu.horarios.api
├── HorariosApplication.java       # @SpringBootApplication
├── config/        SecurityConfig, OpenApiConfig, JacksonConfig
├── security/      JwtService, JwtAuthFilter, EscolaAutenticada
├── controller/    AuthController, EscolaController, ProfessorController, ...
├── dto/           request/response (records) + validações Bean Validation
├── exception/     GlobalExceptionHandler (ProblemDetail)
└── resources/     application.yml, application-dev.yml, application-prod.yml
```

---

## 6. Modelo de domínio (entidades)

Convenções: todas as entidades (exceto `Escola`) carregam `escola_id` (isolamento multiescola). Identificadores `UUID`. Datas em UTC com `criado_em`/`atualizado_em` nas tabelas persistidas.

### 6.1 Escola

Cadastrada pela gestão: o sistema cadastra **a escola**, não o usuário.

| Campo | Tipo | Regras |
|---|---|---|
| id | UUID | PK |
| nome | String | obrigatório, 3 a 150 caracteres |
| portaria | String | obrigatório (portaria de criação/autorização) |
| ure | String | obrigatório (Unidade Regional de Educação) |
| municipio | String | obrigatório |
| modalidade | Enum `INTEGRAL`, `PARCIAL` | obrigatório |
| horariosPorDia | int | obrigatório, 1 a 12 |
| duracaoHorarioMin | int | obrigatório, 30 a 120 (ex.: 50) |
| horaInicioAulas | LocalTime | obrigatório (para imprimir os horários reais) |
| emailInstitucional | String | obrigatório, formato válido, **único** |
| senhaHash | String | BCrypt; senha em texto: mínimo 8 caracteres, nunca persistida |
| ativa | boolean | padrão `true` |

**Intervalo** (coleção da Escola):

| Campo | Tipo | Regras |
|---|---|---|
| apos​Horario | int | intervalo ocorre depois do horário N (1 ≤ N < horariosPorDia) |
| duracaoMin | int | duração do intervalo (ex.: 20, 60) |
| descricao | String | "Recreio", "Almoço" |

**ConfiguracaoGrade** (1:1 com Escola):

| Campo | Tipo | Padrão |
|---|---|---|
| limiteDiarioPadrao | int | 5 |
| limiteDiarioRigido | boolean | `false` (alerta) |
| pesoLimiteDiario | int | 100 |
| pesoJanelas | int | 30 |
| pesoDistribuicao | int | 10 |
| pesoConcentracaoDias | int | 5 |
| tempoMaximoGeracaoSeg | int | 30 |

### 6.2 Semestre (período letivo)

| Campo | Tipo | Regras |
|---|---|---|
| id | UUID | PK |
| escolaId | UUID | FK |
| rotulo | String | obrigatório, único por escola (ex.: `2026.2`) |
| dataInicio / dataFim | LocalDate | fim > início |
| status | Enum `PLANEJAMENTO`, `ATIVO`, `ENCERRADO` | |

### 6.3 Professor

| Campo | Tipo | Regras |
|---|---|---|
| id | UUID | PK |
| escolaId | UUID | FK |
| nome | String | obrigatório |
| matricula | String | opcional, única por escola |
| email | String | opcional |
| cargaContratadaSemanal | int | horários/semana contratados (> 0) |
| limiteDiarioHorarios | Integer | opcional; se nulo, usa o padrão da escola |
| ativo | boolean | |

**DisponibilidadeProfessor** (indisponibilidades):

| Campo | Tipo | Regras |
|---|---|---|
| id | UUID | PK |
| professorId | UUID | FK |
| semestreId | UUID | FK (pode variar por semestre) |
| diaSemana | Enum | `SEGUNDA` … `SEXTA` |
| horarioInicial / horarioFinal | int | índices de horário (1..horariosPorDia) |
| motivo | String | opcional |

### 6.4 Turma

| Campo | Tipo | Regras |
|---|---|---|
| id | UUID | PK |
| escolaId | UUID | FK |
| nome | String | obrigatório, único por escola (ex.: `3º A, PJDI`) |
| serie | int | 1 a 3 |
| turno | Enum `MATUTINO`, `VESPERTINO`, `INTEGRAL`, `NOTURNO` | informativo no MVP |
| curso | String | opcional (ex.: "Programação de Jogos Digitais") |
| ativa | boolean | |

### 6.5 Disciplina

| Campo | Tipo | Regras |
|---|---|---|
| id | UUID | PK |
| escolaId | UUID | FK |
| nome | String | obrigatório |
| sigla | String | opcional |
| tipo | Enum `BASE_COMUM`, `BASE_TECNICA` | obrigatório |

### 6.6 Sala / Laboratório

| Campo | Tipo | Regras |
|---|---|---|
| id | UUID | PK |
| escolaId | UUID | FK |
| nome | String | obrigatório, único por escola |
| tipo | Enum `SALA_COMUM`, `LABORATORIO`, `QUADRA`, `OUTRO` | |
| capacidade | Integer | opcional |

### 6.7 Oferta (componente curricular no semestre)

A oferta amarra **disciplina + turma + professor + semestre**.

| Campo | Tipo | Regras |
|---|---|---|
| id | UUID | PK |
| escolaId | UUID | FK |
| semestreId | UUID | FK |
| disciplinaId | UUID | FK |
| turmaId | UUID | FK |
| professorId | UUID | FK |
| salaPreferencialId | UUID | opcional (ex.: laboratório) |
| cargaSemanal | int | total de horários por semana (> 0) |
| blocos | lista de **BlocoOferta** | soma `tamanho × quantidade` = `cargaSemanal` |

**BlocoOferta:**

| Campo | Tipo | Regras |
|---|---|---|
| tamanho | int | 1 (simples), 2 (duplo), 3 (triplo) ou 4 (quádruplo) |
| quantidade | int | ≥ 1 |

Exemplo: carga 6 = `{tamanho: 2, quantidade: 3}` (três blocos duplos) ou `{4,1}` + `{2,1}`.

Unicidade: não pode haver duas ofertas iguais de (semestre, disciplina, turma).

### 6.8 Grade

| Campo | Tipo | Regras |
|---|---|---|
| id | UUID | PK |
| escolaId | UUID | FK |
| semestreId | UUID | FK |
| versao | int | incrementa a cada geração/publicação |
| status | Enum `RASCUNHO`, `PUBLICADA`, `ARQUIVADA` | só uma `PUBLICADA` por semestre |
| origem | Enum `GERADA`, `MANUAL` | |
| scorePenalidade | int | menor é melhor |
| totalViolacoesHard / totalAlertasSoft | int | do último cálculo |
| criadaEm | Instant | |

### 6.9 Alocação

| Campo | Tipo | Regras |
|---|---|---|
| id | UUID | PK |
| gradeId | UUID | FK |
| ofertaId | UUID | FK |
| diaSemana | Enum | |
| horarioInicial | int | 1..horariosPorDia |
| tamanhoBloco | int | 1 a 4 |
| salaId | UUID | opcional |
| fixada | boolean | se `true`, o gerador não move esta alocação |

### 6.10 Violação (não persistida, resultado do validador)

| Campo | Tipo |
|---|---|
| codigo | String (ex.: `HARD-01`, `SOFT-01`) |
| severidade | Enum `HARD`, `SOFT` |
| mensagem | String legível |
| alocacoesEnvolvidas | List<UUID> |
| professorId / turmaId / salaId | opcionais, para destacar na interface |

### 6.11 Diagrama de relacionamentos

```
Escola 1──* Professor 1──* DisponibilidadeProfessor
Escola 1──* Turma
Escola 1──* Disciplina
Escola 1──* Sala
Escola 1──1 ConfiguracaoGrade
Escola 1──* Intervalo
Escola 1──* Semestre 1──* Oferta *──1 Disciplina
                              │  *──1 Turma
                              │  *──1 Professor
                              │  *──0..1 Sala (preferencial)
                              └──* BlocoOferta
Semestre 1──* Grade 1──* Alocacao *──1 Oferta
                              └──0..1 Sala
```

---

## 7. Regras de negócio

### 7.1 Regras obrigatórias (HARD): a grade não é válida se violar

| Código | Regra |
|---|---|
| HARD-01 | Um professor leciona em **no máximo uma turma** por horário |
| HARD-02 | Uma turma tem **no máximo uma aula** por horário |
| HARD-03 | Uma sala/laboratório atende **no máximo uma turma** por horário |
| HARD-04 | Blocos (duplo, triplo, quádruplo) são **contíguos** e **não atravessam intervalo** |
| HARD-05 | Todo bloco cabe dentro do dia (não ultrapassa `horariosPorDia`) |
| HARD-06 | Respeita as **indisponibilidades** do professor |
| HARD-07 | A carga semanal de cada oferta está **totalmente alocada**, com os blocos no formato definido |
| HARD-08 | *(se `limiteDiarioRigido = true`)* o professor não excede seu limite diário |

### 7.2 Regras desejáveis (SOFT): geram penalidade e alertas

| Código | Regra |
|---|---|
| SOFT-01 | Professor acima do limite diário (padrão 5 horários/dia). **Regra de destaque do projeto** |
| SOFT-02 | Evitar "janelas" (buracos) na agenda do professor no dia |
| SOFT-03 | Distribuir a disciplina ao longo da semana, sem empilhar no mesmo dia |
| SOFT-04 | Concentrar o professor em menos dias (opcional) |
| SOFT-05 | Divergência entre carga contratada e carga das ofertas (alerta informativo) |

### 7.3 Resultado da validação

```json
{
  "valida": true,
  "totalHard": 0,
  "totalSoft": 3,
  "scorePenalidade": 130,
  "violacoes": [
    {
      "codigo": "SOFT-01",
      "severidade": "SOFT",
      "mensagem": "Prof. João Silva tem 6 horários na quarta-feira (limite: 5).",
      "alocacoesEnvolvidas": ["…"],
      "professorId": "…"
    }
  ]
}
```

`valida` é `true` quando `totalHard = 0`. Uma grade **só pode ser publicada** se for válida.

### 7.4 Algoritmo do gerador

1. **Pré-processamento:** expande cada oferta em seus blocos e ordena do mais restrito para o menos restrito (blocos maiores, professores com pouca disponibilidade, salas escassas).
2. **Etapa 1, backtracking com poda:** posiciona bloco a bloco, testando as regras HARD a cada tentativa; volta atrás em caso de beco sem saída.
3. **Etapa 2, busca local:** troca/move alocações não fixadas para reduzir a pontuação de penalidade SOFT, mantendo a grade válida.
4. **Limite de tempo:** interrompe em `tempoMaximoGeracaoSeg` e devolve a melhor grade encontrada (ou a lista de ofertas que não coube, se não houver solução).

---

## 8. Funcionalidades e services por entidade

| Entidade | Service / caso de uso | Funcionalidades |
|---|---|---|
| **Escola** | `CadastrarEscolaUseCase`, `AtualizarEscolaUseCase`, `ConfiguracaoGradeService` | cadastrar (validando e-mail único e hash da senha), consultar a própria escola, atualizar dados, gerenciar intervalos e configuração de regras/pesos |
| **Autenticação** | `AutenticarEscolaUseCase` | login por e-mail institucional + senha, emissão e renovação de JWT, troca de senha |
| **Semestre** | `SemestreService` | criar, listar, ativar, encerrar, **copiar** ofertas de um semestre para outro |
| **Professor** | `ProfessorService`, `DisponibilidadeService` | CRUD, inativar, cadastrar/remover indisponibilidades, consultar carga calculada x contratada |
| **Turma** | `TurmaService` | CRUD, inativar |
| **Disciplina** | `DisciplinaService` | CRUD, filtro por tipo (base comum/técnica) |
| **Sala** | `SalaService` | CRUD |
| **Oferta** | `OfertaService` | CRUD, validação de blocos (soma = carga), checagem de unicidade, listagem por semestre/professor/turma |
| **Grade** | `GerarGradeUseCase` | gerar grade do semestre (síncrono, com limite de tempo), opção de manter alocações fixadas |
| | `ValidarGradeUseCase` | validar grade existente e devolver violações + score |
| | `EditarAlocacaoUseCase` | mover/trocar/remover alocação; modo **simulação** (valida sem gravar) para uso futuro do quadro arrastável |
| | `PublicarGradeUseCase` | publicar (só se válida), arquivar a anterior |
| | `RelatorioCargaUseCase` | horários por dia/semana de cada professor, destacando quem passa do limite |
| **Exportação** | `ExportarGradeUseCase` | PDF/CSV: grade geral da semana, por professor, por turma |

---

## 9. API REST: rotas

**Base:** `/api/v1`. Formato: JSON. Autenticação: `Authorization: Bearer <jwt>` (exceto rotas públicas). O `escolaId` vem do token, **nunca** da URL.

### 9.1 Autenticação e escola

| Método | Rota | Descrição | Acesso |
|---|---|---|---|
| POST | `/auth/escolas` | Cadastra uma escola | Público |
| POST | `/auth/login` | Login (e-mail institucional + senha) | Público |
| POST | `/auth/refresh` | Renova o token | Público (com refresh token) |
| PUT | `/auth/senha` | Altera a senha | Autenticado |
| GET | `/escola` | Dados da escola logada | Autenticado |
| PUT | `/escola` | Atualiza dados da escola | Autenticado |
| GET / PUT | `/escola/configuracao` | Lê/atualiza limites e pesos das regras | Autenticado |
| GET / POST | `/escola/intervalos` | Lista/cria intervalos | Autenticado |
| PUT / DELETE | `/escola/intervalos/{id}` | Atualiza/remove intervalo | Autenticado |

**Exemplo: `POST /auth/escolas`**
```json
{
  "nome": "CEM Maria José Aragão",
  "portaria": "Portaria nº 000/0000",
  "ure": "URE São Luís",
  "municipio": "São Luís",
  "modalidade": "INTEGRAL",
  "horariosPorDia": 9,
  "duracaoHorarioMin": 50,
  "horaInicioAulas": "07:30",
  "emailInstitucional": "escola@exemplo.edu.br",
  "senha": "********"
}
```
> Os valores acima são apenas ilustrativos.

### 9.2 Cadastros

Mesmo padrão para as cinco coleções abaixo:

| Método | Padrão de rota | Descrição |
|---|---|---|
| GET | `/{recurso}` | Lista (paginada, com filtros) |
| GET | `/{recurso}/{id}` | Detalhe |
| POST | `/{recurso}` | Cria |
| PUT | `/{recurso}/{id}` | Atualiza |
| DELETE | `/{recurso}/{id}` | Remove (ou inativa, se houver vínculos) |

Recursos: `/semestres`, `/professores`, `/turmas`, `/disciplinas`, `/salas`.

Rotas adicionais:

| Método | Rota | Descrição |
|---|---|---|
| POST | `/semestres/{id}/ativar` | Torna o semestre ativo |
| POST | `/semestres/{id}/encerrar` | Encerra o semestre |
| POST | `/semestres/{id}/copiar-ofertas` | Copia ofertas de outro semestre (`origemId` no corpo) |
| GET | `/professores/{id}/carga?semestreId=` | Carga calculada x contratada |
| GET / POST | `/professores/{id}/disponibilidades` | Lista/cria indisponibilidades |
| DELETE | `/professores/{id}/disponibilidades/{dispId}` | Remove indisponibilidade |
| GET | `/disciplinas?tipo=BASE_TECNICA` | Filtro por tipo |

### 9.3 Ofertas

| Método | Rota | Descrição |
|---|---|---|
| GET | `/ofertas?semestreId=&professorId=&turmaId=` | Lista com filtros |
| GET | `/ofertas/{id}` | Detalhe |
| POST | `/ofertas` | Cria (valida blocos e unicidade) |
| PUT | `/ofertas/{id}` | Atualiza |
| DELETE | `/ofertas/{id}` | Remove |

**Exemplo: `POST /ofertas`**
```json
{
  "semestreId": "…",
  "disciplinaId": "…",
  "turmaId": "…",
  "professorId": "…",
  "salaPreferencialId": "…",
  "cargaSemanal": 4,
  "blocos": [{ "tamanho": 2, "quantidade": 2 }]
}
```

### 9.4 Grades

| Método | Rota | Descrição |
|---|---|---|
| GET | `/semestres/{id}/grades` | Lista as versões da grade do semestre |
| POST | `/semestres/{id}/grades/gerar` | Gera nova grade (`manterFixadas`, `tempoMaximoSeg` opcionais) |
| GET | `/grades/{id}` | Grade completa com alocações |
| GET | `/grades/{id}/alocacoes?professorId=&turmaId=&dia=` | Alocações filtradas |
| POST | `/grades/{id}/validar` | Valida e devolve violações + score |
| POST | `/grades/{id}/alocacoes` | Cria alocação manual |
| PUT | `/grades/{id}/alocacoes/{alocId}` | Move/altera alocação (valida e grava) |
| POST | `/grades/{id}/alocacoes/{alocId}/simular` | **Simula** a mudança sem gravar e devolve violações |
| POST | `/grades/{id}/alocacoes/trocar` | Troca duas alocações (`alocacaoAId`, `alocacaoBId`) |
| PATCH | `/grades/{id}/alocacoes/{alocId}/fixar` | Fixa/desfixa alocação |
| DELETE | `/grades/{id}/alocacoes/{alocId}` | Remove alocação |
| POST | `/grades/{id}/publicar` | Publica (exige grade válida) |
| GET | `/grades/{id}/relatorios/carga` | Relatório de carga por professor/dia |

### 9.5 Exportação

| Método | Rota | Descrição |
|---|---|---|
| GET | `/grades/{id}/exportar/geral.pdf` | Grade da semana completa (todas as turmas) |
| GET | `/grades/{id}/exportar/professores/{professorId}.pdf` | Horário individual do professor |
| GET | `/grades/{id}/exportar/turmas/{turmaId}.pdf` | Horário da turma |
| GET | `/grades/{id}/exportar/geral.csv` | Grade completa em CSV |

### 9.6 Utilitários

| Método | Rota | Descrição |
|---|---|---|
| GET | `/actuator/health` | Saúde da aplicação |
| GET | `/swagger-ui.html` | Documentação interativa (OpenAPI) |
| GET | `/v3/api-docs` | Especificação OpenAPI |

---

## 10. Segurança e multiescola

- **Autenticação:** login com e-mail institucional + senha; JWT de curta duração (ex.: 30 min) + refresh token.
- **Senhas:** BCrypt (custo ≥ 10). Nunca registradas em log.
- **Isolamento de dados:** o `escolaId` é extraído do JWT e aplicado em **todas** as consultas. Acesso a recurso de outra escola retorna `404` (não `403`, para não vazar existência).
- **Validação de entrada:** Bean Validation nos DTOs + validações de domínio.
- **CORS e HTTPS:** configurados por perfil; em produção, apenas HTTPS.
- **Dados pessoais:** o sistema armazena nomes e e-mails de professores. Aplicar o princípio de minimização (LGPD): campos opcionais só quando necessários.

---

## 11. Padrão de erros

Respostas de erro seguem o **RFC 7807 (Problem Details)**:

```json
{
  "type": "https://horarios.local/erros/oferta-invalida",
  "title": "Oferta inválida",
  "status": 422,
  "detail": "A soma dos blocos (3) difere da carga semanal (4).",
  "instance": "/api/v1/ofertas",
  "erros": [{ "campo": "blocos", "mensagem": "…" }]
}
```

| Status | Uso |
|---|---|
| 400 | Requisição malformada |
| 401 | Não autenticado / token inválido |
| 404 | Recurso inexistente ou de outra escola |
| 409 | Conflito (e-mail já cadastrado, oferta duplicada) |
| 422 | Regra de negócio violada |
| 500 | Erro inesperado (sem detalhes internos) |

---

## 12. Estratégia de testes

| Tipo | Foco | Ferramentas |
|---|---|---|
| **Unitários do domínio** | validações das entidades e value objects | JUnit 5, AssertJ |
| **Unitários do engine** | **cada regra** (HARD/SOFT) isolada, com grades pequenas montadas à mão | JUnit 5, AssertJ |
| **Propriedade do gerador** | toda grade gerada passa em todas as regras HARD | JUnit 5 (testes parametrizados com várias sementes) |
| **Integração (persistência)** | repositórios e migrações Flyway | Testcontainers + PostgreSQL |
| **Integração (API)** | fluxos completos com segurança | `@SpringBootTest`, MockMvc, `spring-security-test` |
| **Arquitetura** | regra de dependência entre módulos/pacotes | ArchUnit |
| **Benchmark** | tempo e qualidade para escolas de 10, 30 e 60 turmas | classe de benchmark simples (resultados no README) |

Meta de cobertura: **≥ 80%** em `domain` e `engine` (medida com JaCoCo).

Exemplos de regras ArchUnit:
- `domain` não importa `org.springframework..` nem `jakarta.persistence..`;
- `engine.validator` não depende de `engine.solver`;
- `application` não depende de `infra..` nem de `api..`.

---

## 13. Roadmap

| Fase | Entrega | Módulos envolvidos |
|---|---|---|
| 1 | Esqueleto Maven multi-módulo, domínio de Escola, cadastro/login, testes | domain, application, infra-persistence, api |
| 2 | Cadastros: semestre, professor, turma, disciplina, sala, oferta | todos |
| 3 | Validador com regras HARD | engine |
| 4 | Gerador (backtracking) | engine |
| 5 | Regras SOFT + busca local + relatório de carga | engine, application |
| 6 | Edição de alocações + simulação + publicação | application, api |
| 7 | Exportação PDF/CSV | infra-export |
| 8 | Docker, README forte, diagramas, dados de exemplo, benchmark | docs |

**Ordem sugerida de trabalho dentro de cada fase:** teste primeiro para as regras do engine (TDD), depois implementação, depois exposição na API.

---

## 14. Pontos em aberto

Itens que adotei como padrão na seção 3 e que vale revisar com a realidade da escola:

1. Há **mais de um turno** com malhas de horário diferentes na mesma escola?
2. O **limite diário** deve ser teto rígido ou apenas alerta?
3. Professores que atuam em **mais de uma escola**: precisamos considerar isso já no MVP?
4. A modalidade **integral** impõe regras (ex.: aulas técnicas só à tarde)?
5. Salas/laboratórios: o gerador deve **escolher** a sala ou usar sempre a preferencial da oferta?
6. Alguma exigência **oficial** (SEDUC/URE) sobre o formato do horário impresso?
