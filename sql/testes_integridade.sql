-- =====================================================================
-- Projeto Final - CIN 8003 Bancos de Dados e Aplicacoes (UFSC)
-- Arquivo: sql/testes_integridade.sql  (Parte 5 - Atividade 04, passo 11)
-- Autor: Mateus Nunes Oliveira
--
-- Comandos que VIOLAM o esquema de proposito. Cada um deve ser recusado pelo SQLite.
-- Rode sempre sobre uma COPIA do banco (os testes 1 a 11 nao alteram nada, porque o
-- erro desfaz o comando; o teste 12 apaga uma serie de proposito).
-- SQLite Online: rode um teste por vez; depois de um erro ele interrompe o script.
-- Antes de tudo: PRAGMA foreign_keys = ON; (sem isso o SQLite ignora as chaves estrangeiras)
-- =====================================================================

PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------------
-- A) INTEGRIDADE REFERENCIAL
-- ---------------------------------------------------------------------

-- TESTE 1 - filho sem pai: coach de uma equipe que nao existe.
-- Esperado: FOREIGN KEY constraint failed
INSERT INTO coach (nome, matricula, id_equipe)
VALUES ('Coach Sem Equipe', '26999999', 999);

-- TESTE 2 - FK composta (RN04/RN05): jogador da equipe 1 declarado em outro campeonato.
-- O par (id_equipe, id_campeonato) = (1, 2) nao existe em EQUIPE.
-- Esperado: FOREIGN KEY constraint failed
INSERT INTO jogador (nome_completo, nome_exibicao, matricula, nome_de_jogo, tag, id_equipe, id_campeonato)
VALUES ('Jogador Outro Campeonato', 'Jogador O.', '26999998', 'TesteFK', 'BR1', 1, 2);

-- TESTE 3 - exclusao de pai protegido por RESTRICT: equipe com jogadores e series jogadas.
-- Esperado: FOREIGN KEY constraint failed (nada e apagado, nem o coach que seria em cascata)
DELETE FROM equipe WHERE id_equipe = 1;

-- TESTE 4 - exclusao de pai protegido por RESTRICT: campeonato que ja tem equipes.
-- Esperado: FOREIGN KEY constraint failed
DELETE FROM campeonato WHERE id_campeonato = 1;

-- ---------------------------------------------------------------------
-- B) RESTRICAO DE DOMINIO (CHECK)
-- ---------------------------------------------------------------------

-- TESTE 5 - RN35: patrocinador de ramo vedado pela Riot Games.
-- Esperado: CHECK constraint failed: ck_patrocinador_ramo
INSERT INTO patrocinador (nome, ramo_atividade, email)
VALUES ('Casa de Apostas Teste', 'apostas', 'teste@example.com');

-- TESTE 6 - RN09: o campeonato tem no maximo 64 vagas.
-- Esperado: CHECK constraint failed: ck_campeonato_vagas
UPDATE campeonato SET numero_vagas = 100 WHERE id_campeonato = 1;

-- TESTE 7 - RN19: partida com a mesma equipe nos dois lados.
-- Esperado: CHECK constraint failed: ck_partida_lados
INSERT INTO partida (id_serie, numero, duracao, captura_tela, data_hora_registro,
                     id_equipe_azul, id_equipe_vermelho, id_equipe_vencedora)
VALUES (1, 4, 1800, 'capturas/teste.png', '2026-10-03 12:00:00', 21, 21, 21);

-- ---------------------------------------------------------------------
-- C) UNICIDADE (UNIQUE)
-- ---------------------------------------------------------------------

-- TESTE 8 - RN04: a mesma matricula em duas equipes do campeonato.
-- Esperado: UNIQUE constraint failed: jogador.id_campeonato, jogador.matricula
INSERT INTO jogador (nome_completo, nome_exibicao, matricula, nome_de_jogo, tag, id_equipe, id_campeonato)
VALUES ('Jogador Matricula Repetida', 'Jogador M.',
        (SELECT matricula FROM jogador WHERE id_jogador = 1), 'TesteUnico1', 'BR1', 2, 1);

-- TESTE 9 - RN05: o mesmo Riot ID (nome + tag) em dois jogadores do campeonato.
-- Esperado: UNIQUE constraint failed: jogador.id_campeonato, jogador.nome_de_jogo, jogador.tag
INSERT INTO jogador (nome_completo, nome_exibicao, matricula, nome_de_jogo, tag, id_equipe, id_campeonato)
VALUES ('Jogador Riot ID Repetido', 'Jogador R.', '26999997',
        (SELECT nome_de_jogo FROM jogador WHERE id_jogador = 1),
        (SELECT tag FROM jogador WHERE id_jogador = 1), 2, 1);

-- TESTE 10 - RN01: segunda equipe do mesmo curso no campeonato.
-- Esperado: UNIQUE constraint failed: equipe.id_campeonato, equipe.id_curso
INSERT INTO equipe (id_campeonato, id_curso) VALUES (1, 1);

-- TESTE 11 - RN06: o mesmo jogador como capitao de duas equipes (indice unico uq_equipe_capitao).
-- Esperado: UNIQUE constraint failed: equipe.id_capitao
UPDATE equipe SET id_capitao = (SELECT id_capitao FROM equipe WHERE id_equipe = 1)
WHERE id_equipe = 2;

-- ---------------------------------------------------------------------
-- D) CONTRASTE: CASCADE (este teste NAO da erro; ele apaga na copia)
-- ---------------------------------------------------------------------

-- TESTE 12 - apagar a serie 27 (W.O.) leva junto as linhas de DISPUTA (ON DELETE CASCADE).
-- Esperado: 2 linhas de disputa antes, 0 depois.
SELECT COUNT(*) AS disputas_antes FROM disputa WHERE id_serie = 27;
DELETE FROM serie WHERE id_serie = 27;
SELECT COUNT(*) AS disputas_depois FROM disputa WHERE id_serie = 27;
