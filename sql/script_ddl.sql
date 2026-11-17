-- =====================================================================
-- Projeto Final - CIN 8003 Bancos de Dados e Aplicacoes (UFSC)
-- Banco: campeonato universitario de League of Legends (campus Florianopolis)
-- Arquivo: sql/script_ddl.sql  (Parte 4 - Projeto Fisico: DDL)
-- Autor: Mateus Nunes Oliveira
-- Data: 16/11/2026
-- SGBD: SQLite 3
--
-- Como executar:
--   SQLite Online: abrir https://sqliteonline.com, colar o script inteiro e clicar em Run.
--   Terminal:      sqlite3 banco/campeonato_lol_ufsc.db < sql/script_ddl.sql
--   Python:        conn.executescript(open('sql/script_ddl.sql', encoding='utf-8').read())
-- O script pode ser executado de novo: ele comeca apagando as tabelas.
--
-- Convencoes:
--   datas 'AAAA-MM-DD'; data e hora 'AAAA-MM-DD HH:MM:SS' no horario de Brasilia (RNF06);
--   dinheiro em centavos (INTEGER); booleanos INTEGER 0/1; duracao em segundos.
--   Regras que dependem de varias linhas ou tabelas sao garantidas pela aplicacao
--   e conferidas por consulta de auditoria (ver docs/04_projeto_fisico.md).
-- =====================================================================

PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------------
-- 0. Limpeza: DROP em ordem reversa de dependencia (filhas antes das maes)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS punicao;
DROP TABLE IF EXISTS escalacao;
DROP TABLE IF EXISTS selecao_campeao;
DROP TABLE IF EXISTS avaliacao_resultado;
DROP TABLE IF EXISTS partida;
DROP TABLE IF EXISTS disputa;
DROP TABLE IF EXISTS serie;
DROP TABLE IF EXISTS classificacao;
DROP TABLE IF EXISTS inscricao;
DROP TABLE IF EXISTS coach;
DROP TABLE IF EXISTS jogador;
DROP TABLE IF EXISTS equipe;
DROP TABLE IF EXISTS rodada;
DROP TABLE IF EXISTS fase;
DROP TABLE IF EXISTS premiacao;
DROP TABLE IF EXISTS patrocinio;
DROP TABLE IF EXISTS campeonato;
DROP TABLE IF EXISTS vinculo_arbitro_curso;
DROP TABLE IF EXISTS curso;
DROP TABLE IF EXISTS patrocinador;
DROP TABLE IF EXISTS campeao;
DROP TABLE IF EXISTS funcao;
DROP TABLE IF EXISTS centro_ensino;
DROP TABLE IF EXISTS arbitro;
DROP TABLE IF EXISTS organizador;

-- =====================================================================
-- 1. Tabelas-raiz (nao referenciam nenhuma outra)
-- =====================================================================

-- ORGANIZADOR: cria o campeonato, decide inscricoes, julga contestacoes,
-- aplica punicoes (RN09, RN25, RN27).
CREATE TABLE organizador (
    id_organizador INTEGER PRIMARY KEY,
    nome           VARCHAR(120) NOT NULL,
    email          VARCHAR(120) NOT NULL UNIQUE,
    telefone       VARCHAR(20),
    CONSTRAINT ck_organizador_email CHECK (email LIKE '%_@_%._%')
);

-- ARBITRO: conduz as series e aplica punicoes (RN24, RN27, RN34).
CREATE TABLE arbitro (
    id_arbitro INTEGER PRIMARY KEY,
    nome       VARCHAR(120) NOT NULL,
    email      VARCHAR(120) NOT NULL UNIQUE,
    telefone   VARCHAR(20),
    CONSTRAINT ck_arbitro_email CHECK (email LIKE '%_@_%._%')
);

-- CENTRO_ENSINO: catalogo dos 11 centros (RN01).
CREATE TABLE centro_ensino (
    id_centro_ensino INTEGER PRIMARY KEY,
    sigla            VARCHAR(10) NOT NULL UNIQUE,
    nome             VARCHAR(80) NOT NULL UNIQUE
);

-- FUNCAO: as cinco funcoes do jogo (RN02, RN20).
CREATE TABLE funcao (
    id_funcao INTEGER PRIMARY KEY,
    nome      VARCHAR(20) NOT NULL UNIQUE,
    CONSTRAINT ck_funcao_nome CHECK (nome IN ('Topo', 'Selva', 'Meio', 'Atirador', 'Suporte'))
);

-- CAMPEAO: catalogo de campeoes do jogo (RN21, RN22).
CREATE TABLE campeao (
    id_campeao INTEGER PRIMARY KEY,
    nome       VARCHAR(40) NOT NULL UNIQUE
);

-- PATROCINADOR: quem paga as cotas (RN28, RN35).
CREATE TABLE patrocinador (
    id_patrocinador INTEGER PRIMARY KEY,
    nome            VARCHAR(120) NOT NULL,
    ramo_atividade  VARCHAR(60)  NOT NULL,
    email           VARCHAR(120) NOT NULL UNIQUE,
    telefone        VARCHAR(20),
    CONSTRAINT ck_patrocinador_email CHECK (email LIKE '%_@_%._%'),
    -- RN35: ramos vedados pela Riot Games
    CONSTRAINT ck_patrocinador_ramo CHECK (lower(ramo_atividade) NOT IN
        ('apostas', 'tabaco', 'armas', 'bebidas_alcoolicas', 'criptomoedas', 'campanhas_politicas'))
);

-- =====================================================================
-- 2. Cursos e arbitragem
-- =====================================================================

-- CURSO: 64 cursos, cada um em um centro (RN01).
CREATE TABLE curso (
    id_curso         INTEGER PRIMARY KEY,
    nome             VARCHAR(80) NOT NULL UNIQUE,
    id_centro_ensino INTEGER NOT NULL,
    -- RESTRICT: nao se apaga um centro que ainda tem cursos
    FOREIGN KEY (id_centro_ensino) REFERENCES centro_ensino (id_centro_ensino)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- VINCULO_ARBITRO_CURSO (N:M): cursos com os quais o arbitro tem vinculo (RN24).
-- PK composta: ninguem referencia esta tabela e a PK ja impede vinculo repetido.
CREATE TABLE vinculo_arbitro_curso (
    id_arbitro INTEGER NOT NULL,
    id_curso   INTEGER NOT NULL,
    PRIMARY KEY (id_arbitro, id_curso),
    -- CASCADE: o vinculo e so uma ligacao; sem o arbitro ou o curso, deixa de existir
    FOREIGN KEY (id_arbitro) REFERENCES arbitro (id_arbitro)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_curso) REFERENCES curso (id_curso)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- =====================================================================
-- 3. Campeonato, patrocinio, premiacao, fases e rodadas
-- =====================================================================

-- CAMPEONATO (RN09).
CREATE TABLE campeonato (
    id_campeonato   INTEGER PRIMARY KEY,
    nome            VARCHAR(120) NOT NULL,
    edicao          INTEGER NOT NULL CHECK (edicao >= 1),
    prazo_inscricao TEXT NOT NULL,                 -- data e hora limite
    data_inicio     TEXT NOT NULL,
    data_fim        TEXT NOT NULL,
    numero_vagas    INTEGER NOT NULL DEFAULT 64,
    situacao        VARCHAR(20) NOT NULL DEFAULT 'inscricoes_abertas',
    id_organizador  INTEGER NOT NULL,
    CONSTRAINT uq_campeonato UNIQUE (nome, edicao),
    -- RN09: 64 vagas no maximo (uma por curso); com menos de 16 nao comeca
    CONSTRAINT ck_campeonato_vagas CHECK (numero_vagas BETWEEN 16 AND 64),
    CONSTRAINT ck_campeonato_situacao CHECK (situacao IN
        ('inscricoes_abertas', 'em_andamento', 'encerrado', 'cancelado')),
    CONSTRAINT ck_campeonato_formato_datas CHECK (
        prazo_inscricao LIKE '____-__-__ __:__:__'
        AND data_inicio LIKE '____-__-__'
        AND data_fim LIKE '____-__-__'),
    -- RN09: inscricoes terminam antes do inicio; o fim nao vem antes do inicio
    CONSTRAINT ck_campeonato_ordem_datas CHECK (prazo_inscricao < data_inicio AND data_inicio <= data_fim),
    -- RESTRICT: o organizador fica no historico do campeonato
    FOREIGN KEY (id_organizador) REFERENCES organizador (id_organizador)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- PATROCINIO (N:M): cota de cada patrocinador em cada edicao (RN28).
-- PK composta: ninguem referencia esta tabela; um patrocinador tem uma cota por edicao.
CREATE TABLE patrocinio (
    id_campeonato   INTEGER NOT NULL,
    id_patrocinador INTEGER NOT NULL,
    valor_cota      INTEGER NOT NULL CHECK (valor_cota > 0),   -- centavos
    PRIMARY KEY (id_campeonato, id_patrocinador),
    -- CASCADE: a cota so existe dentro da edicao
    FOREIGN KEY (id_campeonato) REFERENCES campeonato (id_campeonato)
        ON DELETE CASCADE ON UPDATE CASCADE,
    -- RESTRICT: nao se perde o historico financeiro ao apagar um patrocinador
    FOREIGN KEY (id_patrocinador) REFERENCES patrocinador (id_patrocinador)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- PREMIACAO (fraca de CAMPEONATO): valor de cada colocacao (RN28).
-- colocacao 1 = campea, 2 = vice, 3 = semifinalistas (mesmo valor para as duas).
CREATE TABLE premiacao (
    id_premiacao  INTEGER PRIMARY KEY,
    id_campeonato INTEGER NOT NULL,
    colocacao     INTEGER NOT NULL CHECK (colocacao IN (1, 2, 3)),
    valor         INTEGER NOT NULL CHECK (valor > 0),          -- centavos
    CONSTRAINT uq_premiacao UNIQUE (id_campeonato, colocacao),
    -- CASCADE: entidade fraca, depende do campeonato
    FOREIGN KEY (id_campeonato) REFERENCES campeonato (id_campeonato)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- FASE (fraca de CAMPEONATO): Play-in, Fase Suica, Playoffs (RN10-RN16).
CREATE TABLE fase (
    id_fase       INTEGER PRIMARY KEY,
    id_campeonato INTEGER NOT NULL,
    nome          VARCHAR(20) NOT NULL,
    CONSTRAINT uq_fase UNIQUE (id_campeonato, nome),
    CONSTRAINT ck_fase_nome CHECK (nome IN ('play_in', 'fase_suica', 'playoffs')),
    -- CASCADE: entidade fraca
    FOREIGN KEY (id_campeonato) REFERENCES campeonato (id_campeonato)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- RODADA (fraca de FASE): numero e formato das series (RN10, RN11, RN12, RN16).
CREATE TABLE rodada (
    id_rodada     INTEGER PRIMARY KEY,
    id_fase       INTEGER NOT NULL,
    numero        INTEGER NOT NULL CHECK (numero BETWEEN 1 AND 5),  -- a Fase Suica tem 5
    formato_serie VARCHAR(3) NOT NULL,
    data          TEXT NOT NULL CHECK (data LIKE '____-__-__'),
    CONSTRAINT uq_rodada UNIQUE (id_fase, numero),
    -- RN16: so existem series Md1, Md3 e Md5
    CONSTRAINT ck_rodada_formato CHECK (formato_serie IN ('Md1', 'Md3', 'Md5')),
    -- CASCADE: entidade fraca
    FOREIGN KEY (id_fase) REFERENCES fase (id_fase)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- =====================================================================
-- 4. Equipes e pessoas
-- =====================================================================

-- EQUIPE: uma por curso em cada campeonato (RN01, RN10, RN28).
-- id_capitao e acrescentado depois de JOGADOR (ver ALTER TABLE abaixo).
CREATE TABLE equipe (
    id_equipe           INTEGER PRIMARY KEY,
    chave_play_in       INTEGER CHECK (chave_play_in BETWEEN 1 AND 16),  -- RN10: 16 chaves
    id_campeonato       INTEGER NOT NULL,
    id_curso            INTEGER NOT NULL,
    colocacao_premiacao INTEGER,                                        -- NULL = nao premiada
    -- RN01: cada curso tem no maximo uma equipe por campeonato
    CONSTRAINT uq_equipe_curso UNIQUE (id_campeonato, id_curso),
    -- alvo da FK composta de JOGADOR (garante jogador e equipe no mesmo campeonato)
    CONSTRAINT uq_equipe_campeonato UNIQUE (id_equipe, id_campeonato),
    -- RESTRICT: equipe e curso ficam no historico
    FOREIGN KEY (id_campeonato) REFERENCES campeonato (id_campeonato)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_curso) REFERENCES curso (id_curso)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    -- RN28: FK composta, o premio tem de ser do mesmo campeonato da equipe.
    -- RESTRICT (e nao SET NULL): SET NULL anularia tambem id_campeonato, que e NOT NULL.
    FOREIGN KEY (id_campeonato, colocacao_premiacao) REFERENCES premiacao (id_campeonato, colocacao)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- JOGADOR: 6 por equipe (RN02-RN05, RN08, RN29, RN31).
-- id_campeonato e copia controlada do campeonato da equipe: a FK composta
-- (id_equipe, id_campeonato) impede que fique diferente. Ela permite garantir
-- no DDL a matricula e o Riot ID unicos no campeonato (RN04, RN05).
-- email, data_nascimento e comprovante aceitam NULL porque a LGPD manda
-- apaga-los ate 90 dias apos o campeonato; na inscricao, a aplicacao os exige.
CREATE TABLE jogador (
    id_jogador            INTEGER PRIMARY KEY,
    nome_completo         VARCHAR(120) NOT NULL,
    nome_exibicao         VARCHAR(40)  NOT NULL,
    matricula             VARCHAR(12)  NOT NULL,
    email                 VARCHAR(120),
    data_nascimento       TEXT,
    nome_de_jogo          VARCHAR(16)  NOT NULL,
    tag                   VARCHAR(5)   NOT NULL,
    riot_id_verificado    INTEGER NOT NULL DEFAULT 0 CHECK (riot_id_verificado IN (0, 1)),
    comprovante_matricula VARCHAR(255),
    nome_responsavel      VARCHAR(120),
    contato_responsavel   VARCHAR(120),
    documento_autorizacao VARCHAR(255),
    id_equipe             INTEGER NOT NULL,
    id_campeonato         INTEGER NOT NULL,
    id_funcao             INTEGER,                    -- NULL = reserva (RN02)
    -- RN04: um estudante (matricula) em no maximo uma equipe por campeonato
    CONSTRAINT uq_jogador_matricula UNIQUE (id_campeonato, matricula),
    -- RN05: Riot ID unico no campeonato
    CONSTRAINT uq_jogador_riot_id UNIQUE (id_campeonato, nome_de_jogo, tag),
    -- RN02: no maximo um titular por funcao na equipe (NULL do reserva nao conflita)
    CONSTRAINT uq_jogador_funcao UNIQUE (id_equipe, id_funcao),
    -- RN05: tamanhos aceitos pela Riot (nome 3-16, tag 3-5)
    CONSTRAINT ck_jogador_riot_id CHECK (length(nome_de_jogo) BETWEEN 3 AND 16
                                         AND length(tag) BETWEEN 3 AND 5),
    CONSTRAINT ck_jogador_email CHECK (email IS NULL OR email LIKE '%_@_%._%'),
    CONSTRAINT ck_jogador_nascimento CHECK (data_nascimento IS NULL OR data_nascimento LIKE '____-__-__'),
    -- RN08: dados do responsavel vem completos (menor) ou nao vem (maior)
    CONSTRAINT ck_jogador_responsavel CHECK (
        (nome_responsavel IS NULL AND contato_responsavel IS NULL AND documento_autorizacao IS NULL)
        OR (nome_responsavel IS NOT NULL AND contato_responsavel IS NOT NULL AND documento_autorizacao IS NOT NULL)),
    -- RESTRICT: jogador e historico da equipe (escalacoes, punicoes)
    FOREIGN KEY (id_equipe, id_campeonato) REFERENCES equipe (id_equipe, id_campeonato)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    -- RESTRICT: funcao e catalogo fixo
    FOREIGN KEY (id_funcao) REFERENCES funcao (id_funcao)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Capitao (RN06). EQUIPE e JOGADOR apontam um para o outro (ciclo). Por isso a
-- coluna entra depois que JOGADOR existe. O SQLite aceita ADD COLUMN com
-- REFERENCES desde que o padrao seja NULL; o UNIQUE vem num indice unico,
-- porque ADD COLUMN nao aceita UNIQUE.
-- SET NULL: se o capitao sair (troca, RN31), a equipe fica sem capitao ate escolher outro.
ALTER TABLE equipe ADD COLUMN id_capitao INTEGER
    REFERENCES jogador (id_jogador) ON DELETE SET NULL ON UPDATE CASCADE;
CREATE UNIQUE INDEX uq_equipe_capitao ON equipe (id_capitao);

-- COACH: no maximo um por equipe (RN07).
CREATE TABLE coach (
    id_coach              INTEGER PRIMARY KEY,
    nome                  VARCHAR(120) NOT NULL,
    matricula             VARCHAR(12)  NOT NULL,
    comprovante_matricula VARCHAR(255),           -- NULL permitido pela LGPD (como em JOGADOR)
    email                 VARCHAR(120),
    telefone              VARCHAR(20),
    id_equipe             INTEGER NOT NULL UNIQUE,   -- RN07: 1 coach por equipe
    CONSTRAINT ck_coach_email CHECK (email IS NULL OR email LIKE '%_@_%._%'),
    -- CASCADE: o coach so existe para a equipe e nenhuma tabela o referencia
    FOREIGN KEY (id_equipe) REFERENCES equipe (id_equipe)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- INSCRICAO (fraca de EQUIPE): cada envio, com aval e decisao (RN09, RN30).
CREATE TABLE inscricao (
    id_inscricao      INTEGER PRIMARY KEY,
    id_equipe         INTEGER NOT NULL,
    data_hora_envio   TEXT NOT NULL DEFAULT (datetime('now', '-3 hours')),
    responsavel_aval  VARCHAR(120),
    data_aval         TEXT,
    id_organizador    INTEGER,                         -- NULL enquanto pendente
    resultado_decisao VARCHAR(10) NOT NULL DEFAULT 'pendente',
    data_decisao      TEXT,
    motivo_recusa     VARCHAR(255),
    -- RN09: reenvio = nova linha com outra data_hora_envio
    CONSTRAINT uq_inscricao UNIQUE (id_equipe, data_hora_envio),
    CONSTRAINT ck_inscricao_resultado CHECK (resultado_decisao IN ('pendente', 'aprovada', 'recusada')),
    CONSTRAINT ck_inscricao_formato_datas CHECK (
        data_hora_envio LIKE '____-__-__ __:__:__'
        AND (data_aval IS NULL OR data_aval LIKE '____-__-__')
        AND (data_decisao IS NULL OR data_decisao LIKE '____-__-__ __:__:__')),
    CONSTRAINT ck_inscricao_ordem_datas CHECK (data_decisao IS NULL OR data_decisao >= data_hora_envio),
    -- aval: responsavel e data andam juntos
    CONSTRAINT ck_inscricao_aval CHECK (
        (responsavel_aval IS NULL AND data_aval IS NULL)
        OR (responsavel_aval IS NOT NULL AND data_aval IS NOT NULL)),
    -- RN09: pendente nao tem decisor; aprovada/recusada tem organizador e data
    CONSTRAINT ck_inscricao_decisao CHECK (
        (resultado_decisao = 'pendente' AND id_organizador IS NULL AND data_decisao IS NULL)
        OR (resultado_decisao <> 'pendente' AND id_organizador IS NOT NULL AND data_decisao IS NOT NULL)),
    -- RN09: recusa sempre com motivo; so a recusa tem motivo
    CONSTRAINT ck_inscricao_motivo CHECK (
        (resultado_decisao = 'recusada' AND motivo_recusa IS NOT NULL)
        OR (resultado_decisao <> 'recusada' AND motivo_recusa IS NULL)),
    -- RN30: so e aprovada com o aval do curso
    CONSTRAINT ck_inscricao_aval_aprovacao CHECK (resultado_decisao <> 'aprovada' OR responsavel_aval IS NOT NULL),
    -- CASCADE: entidade fraca, cada envio pertence a equipe
    FOREIGN KEY (id_equipe) REFERENCES equipe (id_equipe)
        ON DELETE CASCADE ON UPDATE CASCADE,
    -- RESTRICT: preserva quem decidiu
    FOREIGN KEY (id_organizador) REFERENCES organizador (id_organizador)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CLASSIFICACAO (fraca de FASE): 1o ao 8o da Fase Suica (RN12, RN14, RN15).
CREATE TABLE classificacao (
    id_classificacao INTEGER PRIMARY KEY,
    id_fase          INTEGER NOT NULL,
    posicao          INTEGER NOT NULL CHECK (posicao BETWEEN 1 AND 8),
    id_equipe        INTEGER NOT NULL UNIQUE,        -- 1:1 com EQUIPE (R08)
    CONSTRAINT uq_classificacao UNIQUE (id_fase, posicao),
    -- CASCADE: entidade fraca
    FOREIGN KEY (id_fase) REFERENCES fase (id_fase)
        ON DELETE CASCADE ON UPDATE CASCADE,
    -- RESTRICT: nao se apaga equipe classificada
    FOREIGN KEY (id_equipe) REFERENCES equipe (id_equipe)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- =====================================================================
-- 5. Series e partidas
-- =====================================================================

-- SERIE: confronto de uma rodada, com arbitro (RN17, RN23, RN24).
CREATE TABLE serie (
    id_serie   INTEGER PRIMARY KEY,
    data_hora  TEXT NOT NULL CHECK (data_hora LIKE '____-__-__ __:__:__'),
    id_rodada  INTEGER NOT NULL,
    id_arbitro INTEGER NOT NULL,                     -- RN24: toda serie tem arbitro
    -- RF09: o arbitro nao pode ter duas series marcadas no mesmo horario
    CONSTRAINT uq_serie_arbitro_horario UNIQUE (id_arbitro, data_hora),
    -- RESTRICT: series jogadas sao historico
    FOREIGN KEY (id_rodada) REFERENCES rodada (id_rodada)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_arbitro) REFERENCES arbitro (id_arbitro)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- DISPUTA (N:M): as equipes de cada serie e o comparecimento (RN18, RN26, RN33).
-- PK composta: ninguem referencia esta tabela e a PK impede a mesma equipe duas vezes.
CREATE TABLE disputa (
    id_serie   INTEGER NOT NULL,
    id_equipe  INTEGER NOT NULL,
    compareceu INTEGER CHECK (compareceu IN (0, 1)),   -- NULL = ainda nao conferido
    PRIMARY KEY (id_serie, id_equipe),
    -- CASCADE: parte da serie
    FOREIGN KEY (id_serie) REFERENCES serie (id_serie)
        ON DELETE CASCADE ON UPDATE CASCADE,
    -- RESTRICT: historico da equipe
    FOREIGN KEY (id_equipe) REFERENCES equipe (id_equipe)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- PARTIDA (fraca de SERIE): lados, vencedora, duracao, julgamento (RN17, RN19, RN25, RN32).
-- Partida sem lados = partida perdida por suspensao (nao jogada).
CREATE TABLE partida (
    id_partida                INTEGER PRIMARY KEY,
    id_serie                  INTEGER NOT NULL,
    numero                    INTEGER NOT NULL CHECK (numero BETWEEN 1 AND 5),  -- Md5 no maximo
    duracao                   INTEGER CHECK (duracao > 0),                      -- segundos
    captura_tela              VARCHAR(255),
    data_hora_registro        TEXT NOT NULL DEFAULT (datetime('now', '-3 hours')),
    id_equipe_azul            INTEGER,
    id_equipe_vermelho        INTEGER,
    id_equipe_vencedora       INTEGER NOT NULL,
    id_organizador_julgamento INTEGER,
    decisao_julgamento        VARCHAR(10) CHECK (decisao_julgamento IN ('mantido', 'alterado')),
    data_julgamento           TEXT,
    CONSTRAINT uq_partida UNIQUE (id_serie, numero),
    CONSTRAINT ck_partida_formato_datas CHECK (
        data_hora_registro LIKE '____-__-__ __:__:__'
        AND (data_julgamento IS NULL OR data_julgamento LIKE '____-__-__ __:__:__')),
    -- RN19 e RN32: ou a partida nao tem lados (perdida por suspensao) e nao tem
    -- duracao nem captura; ou tem os dois lados, diferentes, com duracao e captura
    CONSTRAINT ck_partida_lados CHECK (
        (id_equipe_azul IS NULL AND id_equipe_vermelho IS NULL
         AND duracao IS NULL AND captura_tela IS NULL)
        OR (id_equipe_azul IS NOT NULL AND id_equipe_vermelho IS NOT NULL
            AND id_equipe_azul <> id_equipe_vermelho
            AND duracao IS NOT NULL AND captura_tela IS NOT NULL)),
    -- RN25: quando ha lados, a vencedora e uma delas
    CONSTRAINT ck_partida_vencedora CHECK (
        id_equipe_azul IS NULL OR id_equipe_vencedora IN (id_equipe_azul, id_equipe_vermelho)),
    -- RN25: julgamento completo (quem, decisao, quando) ou nenhum
    CONSTRAINT ck_partida_julgamento CHECK (
        (id_organizador_julgamento IS NULL AND decisao_julgamento IS NULL AND data_julgamento IS NULL)
        OR (id_organizador_julgamento IS NOT NULL AND decisao_julgamento IS NOT NULL AND data_julgamento IS NOT NULL)),
    CONSTRAINT ck_partida_ordem_datas CHECK (data_julgamento IS NULL OR data_julgamento >= data_hora_registro),
    -- CASCADE: entidade fraca, parte da serie
    FOREIGN KEY (id_serie) REFERENCES serie (id_serie)
        ON DELETE CASCADE ON UPDATE CASCADE,
    -- RESTRICT: equipes e organizador ficam no historico
    FOREIGN KEY (id_equipe_azul) REFERENCES equipe (id_equipe)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_equipe_vermelho) REFERENCES equipe (id_equipe)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_equipe_vencedora) REFERENCES equipe (id_equipe)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_organizador_julgamento) REFERENCES organizador (id_organizador)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- AVALIACAO_RESULTADO (N:M): confirmacao ou contestacao de cada capitao (RN25).
-- PK composta: um parecer por jogador por partida; ninguem referencia esta tabela.
CREATE TABLE avaliacao_resultado (
    id_partida        INTEGER NOT NULL,
    id_jogador        INTEGER NOT NULL,
    parecer           VARCHAR(10) NOT NULL CHECK (parecer IN ('confirmado', 'contestado')),
    data_hora_parecer TEXT NOT NULL DEFAULT (datetime('now', '-3 hours'))
                      CHECK (data_hora_parecer LIKE '____-__-__ __:__:__'),
    PRIMARY KEY (id_partida, id_jogador),
    -- CASCADE: parte da partida
    FOREIGN KEY (id_partida) REFERENCES partida (id_partida)
        ON DELETE CASCADE ON UPDATE CASCADE,
    -- RESTRICT: historico do jogador
    FOREIGN KEY (id_jogador) REFERENCES jogador (id_jogador)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- SELECAO_CAMPEAO (fraca de PARTIDA): banimentos e escolhas (RN21, RN22, RN34).
CREATE TABLE selecao_campeao (
    id_selecao_campeao INTEGER PRIMARY KEY,
    id_partida         INTEGER NOT NULL,
    ordem              INTEGER NOT NULL CHECK (ordem BETWEEN 1 AND 20),   -- 10 banimentos + 10 escolhas
    tipo               VARCHAR(10) NOT NULL CHECK (tipo IN ('banimento', 'escolha')),
    id_campeao         INTEGER NOT NULL,
    id_equipe          INTEGER NOT NULL,
    CONSTRAINT uq_selecao_ordem UNIQUE (id_partida, ordem),
    -- RN21: na mesma partida, cada campeao aparece no maximo uma vez
    CONSTRAINT uq_selecao_campeao UNIQUE (id_partida, id_campeao),
    -- CASCADE: entidade fraca
    FOREIGN KEY (id_partida) REFERENCES partida (id_partida)
        ON DELETE CASCADE ON UPDATE CASCADE,
    -- RESTRICT: campeao e equipe ficam no historico
    FOREIGN KEY (id_campeao) REFERENCES campeao (id_campeao)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_equipe) REFERENCES equipe (id_equipe)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ESCALACAO (fraca de PARTIDA e JOGADOR): quem jogou, em que funcao e com
-- qual escolha (RN20; relacionamento R31 do modelo logico).
CREATE TABLE escalacao (
    id_escalacao  INTEGER PRIMARY KEY,
    id_partida    INTEGER NOT NULL,
    id_jogador    INTEGER NOT NULL,
    id_funcao     INTEGER NOT NULL,
    ordem_selecao INTEGER NOT NULL,
    -- RN20: o jogador aparece uma vez por partida
    CONSTRAINT uq_escalacao_jogador UNIQUE (id_partida, id_jogador),
    -- 1:1 com SELECAO_CAMPEAO: cada escolha e usada por um so jogador
    CONSTRAINT uq_escalacao_selecao UNIQUE (id_partida, ordem_selecao),
    -- CASCADE: parte da partida
    FOREIGN KEY (id_partida) REFERENCES partida (id_partida)
        ON DELETE CASCADE ON UPDATE CASCADE,
    -- RESTRICT: historico do jogador
    FOREIGN KEY (id_jogador) REFERENCES jogador (id_jogador)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_funcao) REFERENCES funcao (id_funcao)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    -- FK composta: a escolha tem de ser da mesma partida.
    -- CASCADE: as duas linhas sao partes da mesma partida
    FOREIGN KEY (id_partida, ordem_selecao) REFERENCES selecao_campeao (id_partida, ordem)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- PUNICAO: advertencia, suspensao, desqualificacao, perdas (RN21, RN27, RN34).
-- A suspensao automatica por 3 advertencias nao e uma linha aqui: e conferida
-- pela aplicacao e registrada como partida perdida (partida sem lados).
CREATE TABLE punicao (
    id_punicao             INTEGER PRIMARY KEY,
    tipo                   VARCHAR(20)  NOT NULL,
    motivo                 VARCHAR(255) NOT NULL,
    data_hora              TEXT NOT NULL DEFAULT (datetime('now', '-3 hours'))
                           CHECK (data_hora LIKE '____-__-__ __:__:__'),
    id_jogador             INTEGER,
    id_equipe              INTEGER,
    id_partida_ocorrencia  INTEGER,
    id_partida_cumprimento INTEGER,
    id_arbitro             INTEGER,
    id_organizador         INTEGER,
    CONSTRAINT ck_punicao_tipo CHECK (tipo IN ('advertencia', 'suspensao_jogador', 'desqualificacao',
                                               'perda_escolha_lado', 'perda_banimento')),
    -- RN27: um so alvo; a suspensao recai sobre o jogador, o resto sobre a equipe
    CONSTRAINT ck_punicao_alvo CHECK (
        (tipo = 'suspensao_jogador' AND id_jogador IS NOT NULL AND id_equipe IS NULL)
        OR (tipo <> 'suspensao_jogador' AND id_jogador IS NULL AND id_equipe IS NOT NULL)),
    -- RN27: um so aplicador (arbitro ou organizador)
    CONSTRAINT ck_punicao_aplicador CHECK (
        (id_arbitro IS NOT NULL AND id_organizador IS NULL)
        OR (id_arbitro IS NULL AND id_organizador IS NOT NULL)),
    -- RN27: so o organizador desqualifica
    CONSTRAINT ck_punicao_desqualificacao CHECK (tipo <> 'desqualificacao' OR id_organizador IS NOT NULL),
    -- RN34: perda de lado ou de banimento e aplicada pelo arbitro
    CONSTRAINT ck_punicao_perdas CHECK (tipo NOT IN ('perda_escolha_lado', 'perda_banimento') OR id_arbitro IS NOT NULL),
    -- RN27/RN34: a punicao e cumprida numa partida seguinte, nunca na mesma
    CONSTRAINT ck_punicao_partidas CHECK (id_partida_ocorrencia IS NULL OR id_partida_cumprimento IS NULL
                                          OR id_partida_ocorrencia <> id_partida_cumprimento),
    -- RESTRICT em todas: punicao e historico disciplinar
    FOREIGN KEY (id_jogador) REFERENCES jogador (id_jogador)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_equipe) REFERENCES equipe (id_equipe)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_partida_ocorrencia) REFERENCES partida (id_partida)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_partida_cumprimento) REFERENCES partida (id_partida)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_arbitro) REFERENCES arbitro (id_arbitro)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_organizador) REFERENCES organizador (id_organizador)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Fim do script: 25 tabelas e 1 indice unico (uq_equipe_capitao).
