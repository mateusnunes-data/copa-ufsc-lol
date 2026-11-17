-- =====================================================================
-- Projeto Final - CIN 8003 Bancos de Dados e Aplicacoes (UFSC)
-- Arquivo: sql/verificacao_regras.sql  (Parte 5 - auditoria das regras de negocio)
-- Autor: Mateus Nunes Oliveira
--
-- Uma consulta para cada regra de negocio que o DDL NAO consegue garantir sozinho
-- (as regras "parciais" e "so da aplicacao" da matriz do projeto fisico).
-- Cada consulta devolve UMA linha: o nome da regra e quantas violacoes foram achadas.
-- RESULTADO ESPERADO: violacoes = 0 em todas as linhas.
-- Para ver QUEM viola, troque "SELECT ... COUNT(*)" pelo conteudo da subconsulta.
--
-- Fora da auditoria: RN29 e RN31 (troca de Riot ID ou de jogador depois da aprovacao)
-- dependem de um historico de alteracoes que o modelo nao guarda (RNF04 e da aplicacao);
-- o sorteio (RN10, RN11, RN14) e a escolha do lado (RN19) tambem nao deixam rastro.
--
-- Execute depois do script_ddl.sql e do script_dml.sql:
--   SQLite Online: cole e rode uma consulta por vez.
-- =====================================================================

-- ---------------------------------------------------------------------
-- RN02: cada equipe tem 6 jogadores: 5 titulares (uma funcao cada) e 1 reserva.
-- ---------------------------------------------------------------------
SELECT 'RN02 - 6 jogadores: 5 titulares + 1 reserva' AS regra, COUNT(*) AS violacoes
FROM (
    SELECT e.id_equipe
    FROM equipe e
    LEFT JOIN jogador j ON j.id_equipe = e.id_equipe
    GROUP BY e.id_equipe
    HAVING COUNT(j.id_jogador) <> 6
        OR COUNT(j.id_funcao) <> 5            -- 5 titulares (COUNT ignora o NULL do reserva)
        OR COUNT(DISTINCT j.id_funcao) <> 5   -- cada um com uma funcao diferente
);

-- ---------------------------------------------------------------------
-- RN03: todo jogador tem comprovante de matricula. A unica excecao e quem pediu
-- a eliminacao dos dados (LGPD, RF17): e-mail, nascimento e comprovante somem juntos.
-- ---------------------------------------------------------------------
SELECT 'RN03 - comprovante de matricula (so falta se os dados foram eliminados)' AS regra,
       COUNT(*) AS violacoes
FROM jogador
WHERE comprovante_matricula IS NULL
  AND (email IS NOT NULL OR data_nascimento IS NOT NULL);

-- ---------------------------------------------------------------------
-- RN04: um estudante joga em uma so equipe. (A matricula repetida o DDL ja barra;
-- aqui se confere o mesmo nome em duas equipes, ou seja, com duas matriculas.)
-- ---------------------------------------------------------------------
SELECT 'RN04 - mesmo estudante em duas equipes' AS regra, COUNT(*) AS violacoes
FROM (
    SELECT nome_completo
    FROM jogador
    GROUP BY nome_completo
    HAVING COUNT(*) > 1
);

-- ---------------------------------------------------------------------
-- RN05: o Riot ID precisa estar verificado nas equipes aprovadas.
-- ---------------------------------------------------------------------
SELECT 'RN05 - Riot ID verificado em equipe aprovada' AS regra, COUNT(*) AS violacoes
FROM jogador j
JOIN inscricao i ON i.id_equipe = j.id_equipe AND i.resultado_decisao = 'aprovada'
WHERE j.riot_id_verificado = 0;

-- ---------------------------------------------------------------------
-- RN06: cada equipe tem um capitao, e ele e um dos jogadores da propria equipe.
-- ---------------------------------------------------------------------
SELECT 'RN06 - capitao existe e e da propria equipe' AS regra, COUNT(*) AS violacoes
FROM equipe e
LEFT JOIN jogador c ON c.id_jogador = e.id_capitao
WHERE e.id_capitao IS NULL OR c.id_equipe <> e.id_equipe;

-- ---------------------------------------------------------------------
-- RN07: o coach nao pode ser jogador (nem pela matricula, nem pelo nome).
-- ---------------------------------------------------------------------
SELECT 'RN07 - coach que tambem e jogador' AS regra, COUNT(*) AS violacoes
FROM coach c
JOIN jogador j ON j.matricula = c.matricula OR j.nome_completo = c.nome;

-- ---------------------------------------------------------------------
-- RN08: jogador com menos de 18 anos na data da inscricao aprovada precisa de
-- autorizacao do responsavel. (Quem eliminou a data de nascimento fica de fora.)
-- ---------------------------------------------------------------------
SELECT 'RN08 - menor de 18 anos sem autorizacao do responsavel' AS regra, COUNT(*) AS violacoes
FROM jogador j
JOIN inscricao i ON i.id_equipe = j.id_equipe AND i.resultado_decisao = 'aprovada'
WHERE j.data_nascimento IS NOT NULL
  AND date(j.data_nascimento, '+18 years') > date(i.data_hora_envio)
  AND j.nome_responsavel IS NULL;

-- ---------------------------------------------------------------------
-- RN09: inscricao enviada dentro do prazo; cada equipe com 1 inscricao aprovada,
-- decidida antes do inicio; pelo menos 16 aprovadas.
-- ---------------------------------------------------------------------
SELECT 'RN09 - prazo, 1 aprovacao por equipe e minimo de 16' AS regra, COUNT(*) AS violacoes
FROM (
    SELECT i.id_inscricao
    FROM inscricao i
    JOIN equipe e ON e.id_equipe = i.id_equipe
    JOIN campeonato c ON c.id_campeonato = e.id_campeonato
    WHERE i.data_hora_envio > c.prazo_inscricao
       OR (i.resultado_decisao = 'aprovada' AND i.data_decisao > c.data_inicio)
    UNION ALL
    SELECT e.id_equipe
    FROM equipe e
    LEFT JOIN inscricao i ON i.id_equipe = e.id_equipe AND i.resultado_decisao = 'aprovada'
    GROUP BY e.id_equipe
    HAVING COUNT(i.id_inscricao) <> 1
    UNION ALL
    SELECT c.id_campeonato
    FROM campeonato c
    WHERE (SELECT COUNT(*)
           FROM inscricao i JOIN equipe e ON e.id_equipe = i.id_equipe
           WHERE e.id_campeonato = c.id_campeonato AND i.resultado_decisao = 'aprovada') < 16
);

-- ---------------------------------------------------------------------
-- RN10: 16 chaves de no maximo 4 equipes; as series do Play-in sao entre equipes
-- da mesma chave; exatamente 16 equipes chegam a Fase Suica.
-- ---------------------------------------------------------------------
SELECT 'RN10 - chaves do Play-in e 16 equipes na Fase Suica' AS regra, COUNT(*) AS violacoes
FROM (
    SELECT chave_play_in FROM equipe GROUP BY chave_play_in HAVING COUNT(*) > 4
    UNION ALL
    SELECT 1 FROM equipe WHERE chave_play_in IS NULL
    UNION ALL
    SELECT 1 FROM (SELECT COUNT(DISTINCT chave_play_in) AS n FROM equipe) WHERE n <> 16
    UNION ALL
    SELECT s.id_serie
    FROM serie s
    JOIN rodada r ON r.id_rodada = s.id_rodada
    JOIN fase f ON f.id_fase = r.id_fase AND f.nome = 'play_in'
    JOIN disputa d1 ON d1.id_serie = s.id_serie
    JOIN disputa d2 ON d2.id_serie = s.id_serie AND d2.id_equipe > d1.id_equipe
    JOIN equipe e1 ON e1.id_equipe = d1.id_equipe
    JOIN equipe e2 ON e2.id_equipe = d2.id_equipe
    WHERE e1.chave_play_in <> e2.chave_play_in
    UNION ALL
    SELECT 1 FROM (
        SELECT COUNT(DISTINCT d.id_equipe) AS n
        FROM disputa d
        JOIN serie s ON s.id_serie = d.id_serie
        JOIN rodada r ON r.id_rodada = s.id_rodada
        JOIN fase f ON f.id_fase = r.id_fase AND f.nome = 'fase_suica'
    ) WHERE n <> 16
);

-- ---------------------------------------------------------------------
-- RN11: a partir da 2a rodada da Fase Suica, os dois lados da serie tem o mesmo
-- retrospecto (vitorias e derrotas) ate ali.
-- (O bloco WITH abaixo se repete nas consultas RN12 e RN14: serie -> vencedora -> retrospecto.)
-- ---------------------------------------------------------------------
WITH vit AS (
    SELECT id_serie, id_equipe_vencedora AS id_equipe, COUNT(*) AS vitorias
    FROM partida
    GROUP BY id_serie, id_equipe_vencedora
),
vencedora AS (
    -- serie jogada: quem chegou a maioria das partidas
    SELECT v.id_serie, v.id_equipe
    FROM vit v
    JOIN serie s ON s.id_serie = v.id_serie
    JOIN rodada r ON r.id_rodada = s.id_rodada
    WHERE v.vitorias = CASE r.formato_serie WHEN 'Md1' THEN 1 WHEN 'Md3' THEN 2 ELSE 3 END
    UNION
    -- serie por W.O.: quem compareceu contra quem faltou
    SELECT a.id_serie, a.id_equipe
    FROM disputa a
    JOIN disputa b ON b.id_serie = a.id_serie AND b.id_equipe <> a.id_equipe
    WHERE a.compareceu = 1 AND b.compareceu = 0
),
suica AS (
    -- uma linha por equipe e serie da Fase Suica: ganhou (1) ou nao (0)
    SELECT d.id_equipe, r.numero AS rodada, d.id_serie,
           CASE WHEN v.id_equipe = d.id_equipe THEN 1 ELSE 0 END AS vitoria
    FROM disputa d
    JOIN serie s ON s.id_serie = d.id_serie
    JOIN rodada r ON r.id_rodada = s.id_rodada
    JOIN fase f ON f.id_fase = r.id_fase AND f.nome = 'fase_suica'
    LEFT JOIN vencedora v ON v.id_serie = d.id_serie
),
antes AS (
    -- vitorias e derrotas de cada equipe ANTES da rodada em que ela joga
    SELECT a.id_equipe, a.rodada, a.id_serie,
           (SELECT COALESCE(SUM(b.vitoria), 0) FROM suica b
            WHERE b.id_equipe = a.id_equipe AND b.rodada < a.rodada) AS v,
           (SELECT COUNT(*) - COALESCE(SUM(b.vitoria), 0) FROM suica b
            WHERE b.id_equipe = a.id_equipe AND b.rodada < a.rodada) AS d
    FROM suica a
)
SELECT 'RN11 - Fase Suica: mesmo retrospecto nos dois lados da serie' AS regra, COUNT(*) AS violacoes
FROM (
    SELECT id_serie
    FROM antes
    GROUP BY id_serie
    HAVING COUNT(DISTINCT v || '-' || d) > 1
);

-- ---------------------------------------------------------------------
-- RN12: ninguem joga depois de 3 vitorias ou 3 derrotas; exatamente 8 equipes
-- chegam a 3 vitorias; a classificacao tem essas 8 equipes.
-- ---------------------------------------------------------------------
WITH vit AS (
    SELECT id_serie, id_equipe_vencedora AS id_equipe, COUNT(*) AS vitorias
    FROM partida
    GROUP BY id_serie, id_equipe_vencedora
),
vencedora AS (
    SELECT v.id_serie, v.id_equipe
    FROM vit v
    JOIN serie s ON s.id_serie = v.id_serie
    JOIN rodada r ON r.id_rodada = s.id_rodada
    WHERE v.vitorias = CASE r.formato_serie WHEN 'Md1' THEN 1 WHEN 'Md3' THEN 2 ELSE 3 END
    UNION
    SELECT a.id_serie, a.id_equipe
    FROM disputa a
    JOIN disputa b ON b.id_serie = a.id_serie AND b.id_equipe <> a.id_equipe
    WHERE a.compareceu = 1 AND b.compareceu = 0
),
suica AS (
    SELECT d.id_equipe, r.numero AS rodada, d.id_serie,
           CASE WHEN v.id_equipe = d.id_equipe THEN 1 ELSE 0 END AS vitoria
    FROM disputa d
    JOIN serie s ON s.id_serie = d.id_serie
    JOIN rodada r ON r.id_rodada = s.id_rodada
    JOIN fase f ON f.id_fase = r.id_fase AND f.nome = 'fase_suica'
    LEFT JOIN vencedora v ON v.id_serie = d.id_serie
),
antes AS (
    SELECT a.id_equipe, a.rodada, a.id_serie,
           (SELECT COALESCE(SUM(b.vitoria), 0) FROM suica b
            WHERE b.id_equipe = a.id_equipe AND b.rodada < a.rodada) AS v,
           (SELECT COUNT(*) - COALESCE(SUM(b.vitoria), 0) FROM suica b
            WHERE b.id_equipe = a.id_equipe AND b.rodada < a.rodada) AS d
    FROM suica a
),
com_tres_vitorias AS (
    SELECT id_equipe FROM suica GROUP BY id_equipe HAVING SUM(vitoria) = 3
)
SELECT 'RN12 - Fase Suica: 3 vitorias/3 derrotas e 8 classificadas' AS regra, COUNT(*) AS violacoes
FROM (
    SELECT id_serie FROM antes WHERE v >= 3 OR d >= 3                       -- jogou depois de decidido
    UNION ALL
    SELECT 1 FROM (SELECT COUNT(*) AS n FROM com_tres_vitorias) WHERE n <> 8
    UNION ALL
    SELECT 1 FROM (SELECT COUNT(*) AS n FROM classificacao) WHERE n <> 8
    UNION ALL
    SELECT c.id_equipe FROM classificacao c
    WHERE c.id_equipe NOT IN (SELECT id_equipe FROM com_tres_vitorias)      -- classificada sem 3 vitorias
);

-- ---------------------------------------------------------------------
-- RN13: duas equipes nao se enfrentam mais de uma vez na Fase Suica.
-- ---------------------------------------------------------------------
SELECT 'RN13 - confronto repetido na Fase Suica' AS regra, COUNT(*) AS violacoes
FROM (
    SELECT d1.id_equipe, d2.id_equipe
    FROM disputa d1
    JOIN disputa d2 ON d2.id_serie = d1.id_serie AND d2.id_equipe > d1.id_equipe
    JOIN serie s ON s.id_serie = d1.id_serie
    JOIN rodada r ON r.id_rodada = s.id_rodada
    JOIN fase f ON f.id_fase = r.id_fase AND f.nome = 'fase_suica'
    GROUP BY d1.id_equipe, d2.id_equipe
    HAVING COUNT(*) > 1
);

-- ---------------------------------------------------------------------
-- RN14: a classificacao segue o retrospecto (3-0, 3-1, 3-2); no empate, vale a
-- soma das vitorias dos adversarios e depois o confronto direto.
-- ---------------------------------------------------------------------
WITH vit AS (
    SELECT id_serie, id_equipe_vencedora AS id_equipe, COUNT(*) AS vitorias
    FROM partida
    GROUP BY id_serie, id_equipe_vencedora
),
vencedora AS (
    SELECT v.id_serie, v.id_equipe
    FROM vit v
    JOIN serie s ON s.id_serie = v.id_serie
    JOIN rodada r ON r.id_rodada = s.id_rodada
    WHERE v.vitorias = CASE r.formato_serie WHEN 'Md1' THEN 1 WHEN 'Md3' THEN 2 ELSE 3 END
    UNION
    SELECT a.id_serie, a.id_equipe
    FROM disputa a
    JOIN disputa b ON b.id_serie = a.id_serie AND b.id_equipe <> a.id_equipe
    WHERE a.compareceu = 1 AND b.compareceu = 0
),
suica AS (
    SELECT d.id_equipe, r.numero AS rodada, d.id_serie,
           CASE WHEN v.id_equipe = d.id_equipe THEN 1 ELSE 0 END AS vitoria
    FROM disputa d
    JOIN serie s ON s.id_serie = d.id_serie
    JOIN rodada r ON r.id_rodada = s.id_rodada
    JOIN fase f ON f.id_fase = r.id_fase AND f.nome = 'fase_suica'
    LEFT JOIN vencedora v ON v.id_serie = d.id_serie
),
resumo AS (
    SELECT id_equipe, SUM(vitoria) AS v, COUNT(*) - SUM(vitoria) AS d
    FROM suica
    GROUP BY id_equipe
),
soma_adv AS (
    -- desempate (a): soma das vitorias dos adversarios enfrentados
    SELECT a.id_equipe, SUM(r.v) AS soma
    FROM suica a
    JOIN suica b ON b.id_serie = a.id_serie AND b.id_equipe <> a.id_equipe
    JOIN resumo r ON r.id_equipe = b.id_equipe
    GROUP BY a.id_equipe
),
posicoes AS (
    SELECT c.posicao, c.id_equipe, r.d AS derrotas, s.soma
    FROM classificacao c
    JOIN resumo r ON r.id_equipe = c.id_equipe
    JOIN soma_adv s ON s.id_equipe = c.id_equipe
)
SELECT 'RN14 - classificacao: retrospecto, soma dos adversarios, confronto direto' AS regra,
       COUNT(*) AS violacoes
FROM posicoes p1
JOIN posicoes p2 ON p1.posicao < p2.posicao
WHERE p1.derrotas > p2.derrotas                                     -- 3-1 a frente de 3-0, por exemplo
   OR (p1.derrotas = p2.derrotas AND p1.soma < p2.soma)             -- desempate (a)
   OR (p1.derrotas = p2.derrotas AND p1.soma = p2.soma              -- desempate (b): quem venceu o confronto direto
       AND EXISTS (SELECT 1 FROM suica x
                   JOIN suica y ON y.id_serie = x.id_serie AND y.id_equipe <> x.id_equipe
                   WHERE x.id_equipe = p1.id_equipe AND y.id_equipe = p2.id_equipe AND y.vitoria = 1));

-- ---------------------------------------------------------------------
-- RN15: quartas = 1x8, 4x5, 2x7, 3x6 (as posicoes de cada serie somam 9);
-- semifinais cruzam 1x8 com 4x5 e 2x7 com 3x6; 4 quartas, 2 semifinais, 1 final.
-- ---------------------------------------------------------------------
SELECT 'RN15 - chaveamento dos Playoffs pela classificacao' AS regra, COUNT(*) AS violacoes
FROM (
    SELECT s.id_serie
    FROM serie s
    JOIN rodada r ON r.id_rodada = s.id_rodada AND r.numero = 1
    JOIN fase f ON f.id_fase = r.id_fase AND f.nome = 'playoffs'
    WHERE (SELECT COALESCE(SUM(c.posicao), 0)
           FROM disputa d JOIN classificacao c ON c.id_equipe = d.id_equipe
           WHERE d.id_serie = s.id_serie) <> 9
    UNION ALL
    SELECT s.id_serie
    FROM serie s
    JOIN rodada r ON r.id_rodada = s.id_rodada AND r.numero = 2
    JOIN fase f ON f.id_fase = r.id_fase AND f.nome = 'playoffs'
    WHERE (SELECT COUNT(DISTINCT CASE WHEN c.posicao IN (1, 8, 4, 5) THEN 1 ELSE 2 END)
           FROM disputa d JOIN classificacao c ON c.id_equipe = d.id_equipe
           WHERE d.id_serie = s.id_serie) <> 1
    UNION ALL
    SELECT r.id_rodada
    FROM rodada r
    JOIN fase f ON f.id_fase = r.id_fase AND f.nome = 'playoffs'
    LEFT JOIN serie s ON s.id_rodada = r.id_rodada
    GROUP BY r.id_rodada, r.numero
    HAVING COUNT(s.id_serie) <> CASE r.numero WHEN 1 THEN 4 WHEN 2 THEN 2 ELSE 1 END
);

-- ---------------------------------------------------------------------
-- RN16: formato de cada rodada: Play-in Md3, Fase Suica Md1, quartas e semis Md3, final Md5.
-- ---------------------------------------------------------------------
SELECT 'RN16 - formato das series em cada fase' AS regra, COUNT(*) AS violacoes
FROM rodada r
JOIN fase f ON f.id_fase = r.id_fase
WHERE r.formato_serie <> CASE
          WHEN f.nome = 'play_in' THEN 'Md3'
          WHEN f.nome = 'fase_suica' THEN 'Md1'
          WHEN r.numero IN (1, 2) THEN 'Md3'
          ELSE 'Md5' END;

-- ---------------------------------------------------------------------
-- RN17: a serie termina quando uma equipe chega a maioria: a vencedora tem exatamente
-- a maioria, a ultima partida e dela e nao ha partidas depois (numeracao sem buracos).
-- ---------------------------------------------------------------------
WITH conta AS (
    SELECT id_serie, id_equipe_vencedora AS id_equipe, COUNT(*) AS v
    FROM partida
    GROUP BY id_serie, id_equipe_vencedora
),
info AS (
    SELECT s.id_serie,
           CASE r.formato_serie WHEN 'Md1' THEN 1 WHEN 'Md3' THEN 2 ELSE 3 END AS maioria,
           (SELECT MAX(c.v) FROM conta c WHERE c.id_serie = s.id_serie) AS maior,
           (SELECT COUNT(*) FROM partida p WHERE p.id_serie = s.id_serie) AS qtd,
           (SELECT MAX(p.numero) FROM partida p WHERE p.id_serie = s.id_serie) AS ultimo,
           (SELECT p.id_equipe_vencedora FROM partida p
            WHERE p.id_serie = s.id_serie ORDER BY p.numero DESC LIMIT 1) AS vencedora_da_ultima
    FROM serie s
    JOIN rodada r ON r.id_rodada = s.id_rodada
)
SELECT 'RN17 - serie encerrada ao atingir a maioria' AS regra, COUNT(*) AS violacoes
FROM info i
WHERE i.qtd > 0
  AND (i.maior <> i.maioria
       OR i.ultimo <> i.qtd
       OR NOT EXISTS (SELECT 1 FROM conta c
                      WHERE c.id_serie = i.id_serie AND c.id_equipe = i.vencedora_da_ultima
                        AND c.v = i.maioria));

-- ---------------------------------------------------------------------
-- RN18: toda serie tem duas equipes, ambas com inscricao aprovada; e quem perdeu uma
-- serie eliminatoria (Play-in ou Playoffs, inclusive W.O. duplo) nao joga de novo.
-- ---------------------------------------------------------------------
WITH vit AS (
    SELECT id_serie, id_equipe_vencedora AS id_equipe, COUNT(*) AS vitorias
    FROM partida
    GROUP BY id_serie, id_equipe_vencedora
),
vencedora AS (
    SELECT v.id_serie, v.id_equipe
    FROM vit v
    JOIN serie s ON s.id_serie = v.id_serie
    JOIN rodada r ON r.id_rodada = s.id_rodada
    WHERE v.vitorias = CASE r.formato_serie WHEN 'Md1' THEN 1 WHEN 'Md3' THEN 2 ELSE 3 END
    UNION
    SELECT a.id_serie, a.id_equipe
    FROM disputa a
    JOIN disputa b ON b.id_serie = a.id_serie AND b.id_equipe <> a.id_equipe
    WHERE a.compareceu = 1 AND b.compareceu = 0
),
eliminada AS (
    SELECT d.id_equipe, s.data_hora
    FROM disputa d
    JOIN serie s ON s.id_serie = d.id_serie
    JOIN rodada r ON r.id_rodada = s.id_rodada
    JOIN fase f ON f.id_fase = r.id_fase AND f.nome <> 'fase_suica'
    LEFT JOIN vencedora v ON v.id_serie = d.id_serie
    WHERE v.id_equipe IS NULL OR v.id_equipe <> d.id_equipe
)
SELECT 'RN18 - serie com 2 equipes aprovadas e ainda ativas' AS regra, COUNT(*) AS violacoes
FROM (
    SELECT s.id_serie
    FROM serie s
    LEFT JOIN disputa d ON d.id_serie = s.id_serie
    GROUP BY s.id_serie
    HAVING COUNT(d.id_equipe) <> 2
    UNION ALL
    SELECT d.id_serie
    FROM disputa d
    WHERE NOT EXISTS (SELECT 1 FROM inscricao i
                      WHERE i.id_equipe = d.id_equipe AND i.resultado_decisao = 'aprovada')
    UNION ALL
    SELECT d2.id_serie
    FROM eliminada e
    JOIN disputa d2 ON d2.id_equipe = e.id_equipe
    JOIN serie s2 ON s2.id_serie = d2.id_serie
    WHERE s2.data_hora > e.data_hora
);

-- ---------------------------------------------------------------------
-- RN19: as duas equipes da partida sao as da serie; o lado azul abre a selecao
-- de campeoes (a primeira acao e do azul).
-- ---------------------------------------------------------------------
SELECT 'RN19 - equipes da partida = equipes da serie; azul abre a selecao' AS regra,
       COUNT(*) AS violacoes
FROM (
    SELECT p.id_partida
    FROM partida p
    WHERE p.id_equipe_azul IS NOT NULL
      AND (NOT EXISTS (SELECT 1 FROM disputa d WHERE d.id_serie = p.id_serie AND d.id_equipe = p.id_equipe_azul)
           OR NOT EXISTS (SELECT 1 FROM disputa d WHERE d.id_serie = p.id_serie AND d.id_equipe = p.id_equipe_vermelho))
    UNION ALL
    SELECT p.id_partida
    FROM partida p
    WHERE NOT EXISTS (SELECT 1 FROM disputa d WHERE d.id_serie = p.id_serie AND d.id_equipe = p.id_equipe_vencedora)
    UNION ALL
    SELECT sc.id_partida
    FROM selecao_campeao sc
    JOIN partida p ON p.id_partida = sc.id_partida
    WHERE sc.ordem = 1 AND sc.id_equipe <> p.id_equipe_azul
    UNION ALL
    SELECT sc.id_partida
    FROM selecao_campeao sc
    JOIN partida p ON p.id_partida = sc.id_partida
    WHERE sc.id_equipe NOT IN (p.id_equipe_azul, p.id_equipe_vermelho)
);

-- ---------------------------------------------------------------------
-- RN20: cada equipe escala exatamente 5 jogadores por partida, um por funcao, todos
-- da propria equipe; cada escalacao aponta para uma ESCOLHA da mesma equipe.
-- Partida sem lados (perdida por suspensao) nao tem escalacao.
-- ---------------------------------------------------------------------
SELECT 'RN20 - 5 escalados por equipe, um por funcao' AS regra, COUNT(*) AS violacoes
FROM (
    SELECT t.id_partida
    FROM (SELECT id_partida, id_equipe_azul AS id_equipe FROM partida WHERE id_equipe_azul IS NOT NULL
          UNION ALL
          SELECT id_partida, id_equipe_vermelho FROM partida WHERE id_equipe_vermelho IS NOT NULL) t
    LEFT JOIN jogador j ON j.id_equipe = t.id_equipe
    LEFT JOIN escalacao e ON e.id_jogador = j.id_jogador AND e.id_partida = t.id_partida
    GROUP BY t.id_partida, t.id_equipe
    HAVING COUNT(e.id_escalacao) <> 5 OR COUNT(DISTINCT e.id_funcao) <> 5
    UNION ALL
    SELECT e.id_escalacao
    FROM escalacao e
    JOIN partida p ON p.id_partida = e.id_partida
    JOIN jogador j ON j.id_jogador = e.id_jogador
    WHERE p.id_equipe_azul IS NULL
       OR j.id_equipe NOT IN (p.id_equipe_azul, p.id_equipe_vermelho)
    UNION ALL
    SELECT e.id_escalacao
    FROM escalacao e
    JOIN jogador j ON j.id_jogador = e.id_jogador
    JOIN selecao_campeao sc ON sc.id_partida = e.id_partida AND sc.ordem = e.ordem_selecao
    WHERE sc.tipo <> 'escolha' OR sc.id_equipe <> j.id_equipe
);

-- ---------------------------------------------------------------------
-- RN21: jogador suspenso nao e escalado na partida em que cumpre a suspensao,
-- que e uma partida da propria equipe.
-- ---------------------------------------------------------------------
SELECT 'RN21 - jogador suspenso escalado' AS regra, COUNT(*) AS violacoes
FROM (
    SELECT pu.id_punicao
    FROM punicao pu
    JOIN escalacao e ON e.id_partida = pu.id_partida_cumprimento AND e.id_jogador = pu.id_jogador
    WHERE pu.tipo = 'suspensao_jogador'
    UNION ALL
    SELECT pu.id_punicao
    FROM punicao pu
    JOIN jogador j ON j.id_jogador = pu.id_jogador
    WHERE pu.tipo = 'suspensao_jogador'
      AND (pu.id_partida_cumprimento IS NULL
           OR NOT EXISTS (SELECT 1 FROM partida p
                          WHERE p.id_partida = pu.id_partida_cumprimento
                            AND j.id_equipe IN (p.id_equipe_azul, p.id_equipe_vermelho)))
);

-- ---------------------------------------------------------------------
-- RN22: em series Md3 e Md5, um campeao escolhido numa partida nao e escolhido de novo
-- por NENHUMA das duas equipes nas partidas seguintes da mesma serie. (Banimentos nao contam.)
-- Esta consulta tambem cobre o caso "mesma equipe repetindo um campeao".
-- ---------------------------------------------------------------------
SELECT 'RN22 - campeao repetido numa serie Md3/Md5 (fearless draft)' AS regra, COUNT(*) AS violacoes
FROM (
    SELECT p.id_serie, sc.id_campeao
    FROM selecao_campeao sc
    JOIN partida p ON p.id_partida = sc.id_partida
    WHERE sc.tipo = 'escolha'
    GROUP BY p.id_serie, sc.id_campeao
    HAVING COUNT(*) > 1
);

-- ---------------------------------------------------------------------
-- RN23: uma equipe nao tem duas series com menos de 3 horas de diferenca
-- (3 partidas de ate 55 minutos cabem em 3 horas).
-- ---------------------------------------------------------------------
SELECT 'RN23 - choque de horario da mesma equipe' AS regra, COUNT(*) AS violacoes
FROM disputa d1
JOIN serie s1 ON s1.id_serie = d1.id_serie
JOIN disputa d2 ON d2.id_equipe = d1.id_equipe AND d2.id_serie > d1.id_serie
JOIN serie s2 ON s2.id_serie = d2.id_serie
WHERE ABS(julianday(s1.data_hora) - julianday(s2.data_hora)) * 24 < 3;

-- ---------------------------------------------------------------------
-- RN24: o arbitro nao tem vinculo com os cursos das duas equipes e nao e jogador
-- nem coach (comparacao por e-mail e por nome).
-- ---------------------------------------------------------------------
SELECT 'RN24 - arbitro com conflito de interesse' AS regra, COUNT(*) AS violacoes
FROM (
    SELECT s.id_serie
    FROM serie s
    JOIN disputa d ON d.id_serie = s.id_serie
    JOIN equipe e ON e.id_equipe = d.id_equipe
    JOIN vinculo_arbitro_curso v ON v.id_arbitro = s.id_arbitro AND v.id_curso = e.id_curso
    UNION ALL
    SELECT a.id_arbitro
    FROM arbitro a
    JOIN jogador j ON j.email = a.email OR j.nome_completo = a.nome
    UNION ALL
    SELECT a.id_arbitro
    FROM arbitro a
    JOIN coach c ON c.email = a.email OR c.nome = a.nome
);

-- ---------------------------------------------------------------------
-- RN25: so os capitaes das duas equipes avaliam, dentro de 24 h do registro;
-- partida contestada tem julgamento e partida sem contestacao nao tem.
-- ---------------------------------------------------------------------
SELECT 'RN25 - avaliacao pelos capitaes, 24 h e julgamento' AS regra, COUNT(*) AS violacoes
FROM (
    SELECT ar.id_partida
    FROM avaliacao_resultado ar
    JOIN partida p ON p.id_partida = ar.id_partida
    LEFT JOIN equipe e ON e.id_capitao = ar.id_jogador
    WHERE e.id_equipe IS NULL
       OR e.id_equipe NOT IN (p.id_equipe_azul, p.id_equipe_vermelho)
       OR julianday(ar.data_hora_parecer) - julianday(p.data_hora_registro) NOT BETWEEN 0 AND 1
    UNION ALL
    SELECT p.id_partida
    FROM partida p
    WHERE EXISTS (SELECT 1 FROM avaliacao_resultado ar
                  WHERE ar.id_partida = p.id_partida AND ar.parecer = 'contestado')
      AND p.id_organizador_julgamento IS NULL
    UNION ALL
    SELECT p.id_partida
    FROM partida p
    WHERE p.id_organizador_julgamento IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM avaliacao_resultado ar
                      WHERE ar.id_partida = p.id_partida AND ar.parecer = 'contestado')
);

-- ---------------------------------------------------------------------
-- RN26: serie sem partidas e W.O. (alguem nao compareceu); serie com partidas
-- tem as duas equipes presentes.
-- ---------------------------------------------------------------------
SELECT 'RN26 - W.O. coerente com as partidas da serie' AS regra, COUNT(*) AS violacoes
FROM serie s
WHERE (NOT EXISTS (SELECT 1 FROM partida p WHERE p.id_serie = s.id_serie)
       AND NOT EXISTS (SELECT 1 FROM disputa d WHERE d.id_serie = s.id_serie AND d.compareceu = 0))
   OR (EXISTS (SELECT 1 FROM partida p WHERE p.id_serie = s.id_serie)
       AND EXISTS (SELECT 1 FROM disputa d
                   WHERE d.id_serie = s.id_serie AND (d.compareceu IS NULL OR d.compareceu = 0)));

-- ---------------------------------------------------------------------
-- RN27: a cada 3 advertencias, 1 partida perdida por suspensao (partida sem lados
-- em que a equipe perde); toda partida sem lados e cumprimento de uma advertencia;
-- a punicao e cumprida na PROXIMA partida do alvo; quem desqualificada so perde por
-- W.O. depois; o aplicador e o arbitro da serie onde ocorreu.
-- ---------------------------------------------------------------------
SELECT 'RN27 - advertencias, suspensao, desqualificacao e aplicador' AS regra, COUNT(*) AS violacoes
FROM (
    SELECT e.id_equipe
    FROM equipe e
    WHERE (SELECT COUNT(*) FROM punicao pu
           WHERE pu.id_equipe = e.id_equipe AND pu.tipo = 'advertencia') / 3
       <> (SELECT COUNT(*) FROM partida p
           JOIN disputa d ON d.id_serie = p.id_serie AND d.id_equipe = e.id_equipe
           WHERE p.id_equipe_azul IS NULL AND p.id_equipe_vencedora <> e.id_equipe)
    UNION ALL
    SELECT p.id_partida
    FROM partida p
    WHERE p.id_equipe_azul IS NULL
      AND NOT EXISTS (SELECT 1 FROM punicao pu
                      WHERE pu.id_partida_cumprimento = p.id_partida AND pu.tipo = 'advertencia')
    UNION ALL
    SELECT pu.id_punicao
    FROM punicao pu
    LEFT JOIN jogador j ON j.id_jogador = pu.id_jogador
    WHERE pu.id_partida_cumprimento IS NOT NULL
      AND pu.id_partida_cumprimento <> (
            SELECT MIN(p2.id_partida)
            FROM partida p2
            JOIN disputa d2 ON d2.id_serie = p2.id_serie
            WHERE d2.id_equipe = COALESCE(pu.id_equipe, j.id_equipe)
              AND p2.id_partida > pu.id_partida_ocorrencia)
    UNION ALL
    SELECT d.id_serie
    FROM punicao pu
    JOIN disputa d ON d.id_equipe = pu.id_equipe
    JOIN serie s ON s.id_serie = d.id_serie
    WHERE pu.tipo = 'desqualificacao'
      AND s.data_hora > pu.data_hora
      AND (d.compareceu <> 0 OR EXISTS (SELECT 1 FROM partida p WHERE p.id_serie = s.id_serie))
    UNION ALL
    SELECT pu.id_punicao
    FROM punicao pu
    JOIN partida po ON po.id_partida = pu.id_partida_ocorrencia
    JOIN serie s ON s.id_serie = po.id_serie
    LEFT JOIN jogador j ON j.id_jogador = pu.id_jogador
    WHERE (pu.id_arbitro IS NOT NULL AND pu.id_arbitro <> s.id_arbitro)
       OR NOT EXISTS (SELECT 1 FROM disputa d
                      WHERE d.id_serie = s.id_serie
                        AND d.id_equipe = COALESCE(pu.id_equipe, j.id_equipe))
);

-- ---------------------------------------------------------------------
-- RN28: soma das cotas >= premiacao total; campeonato encerrado tem 1 campea,
-- 1 vice e 2 semifinalistas premiadas, que batem com os resultados; equipe
-- desqualificada nao recebe premio.
-- ---------------------------------------------------------------------
WITH vit AS (
    SELECT id_serie, id_equipe_vencedora AS id_equipe, COUNT(*) AS vitorias
    FROM partida
    GROUP BY id_serie, id_equipe_vencedora
),
vencedora AS (
    SELECT v.id_serie, v.id_equipe
    FROM vit v
    JOIN serie s ON s.id_serie = v.id_serie
    JOIN rodada r ON r.id_rodada = s.id_rodada
    WHERE v.vitorias = CASE r.formato_serie WHEN 'Md1' THEN 1 WHEN 'Md3' THEN 2 ELSE 3 END
    UNION
    SELECT a.id_serie, a.id_equipe
    FROM disputa a
    JOIN disputa b ON b.id_serie = a.id_serie AND b.id_equipe <> a.id_equipe
    WHERE a.compareceu = 1 AND b.compareceu = 0
),
resultado_playoffs AS (
    -- colocacao esperada: final (rodada 3) campea=1, vice=2; semifinais (rodada 2) perdedoras=3
    SELECT d.id_equipe,
           CASE WHEN r.numero = 3 AND v.id_equipe = d.id_equipe THEN 1
                WHEN r.numero = 3 THEN 2
                ELSE 3 END AS colocacao
    FROM disputa d
    JOIN serie s ON s.id_serie = d.id_serie
    JOIN rodada r ON r.id_rodada = s.id_rodada AND r.numero IN (2, 3)
    JOIN fase f ON f.id_fase = r.id_fase AND f.nome = 'playoffs'
    LEFT JOIN vencedora v ON v.id_serie = d.id_serie
    WHERE r.numero = 3 OR v.id_equipe <> d.id_equipe
)
SELECT 'RN28 - cotas >= premiacao; premiadas = resultados; desqualificada sem premio' AS regra,
       COUNT(*) AS violacoes
FROM (
    SELECT c.id_campeonato
    FROM campeonato c
    WHERE (SELECT COALESCE(SUM(valor_cota), 0) FROM patrocinio p WHERE p.id_campeonato = c.id_campeonato)
        < (SELECT COALESCE(SUM(CASE colocacao WHEN 3 THEN 2 * valor ELSE valor END), 0)
           FROM premiacao pr WHERE pr.id_campeonato = c.id_campeonato)
    UNION ALL
    SELECT e.id_equipe
    FROM equipe e
    JOIN punicao pu ON pu.id_equipe = e.id_equipe AND pu.tipo = 'desqualificacao'
    WHERE e.colocacao_premiacao IS NOT NULL
    UNION ALL
    SELECT e.id_equipe
    FROM equipe e
    LEFT JOIN resultado_playoffs rp ON rp.id_equipe = e.id_equipe
    JOIN campeonato c ON c.id_campeonato = e.id_campeonato AND c.situacao = 'encerrado'
    WHERE COALESCE(e.colocacao_premiacao, 0) <> COALESCE(rp.colocacao, 0)
);

-- ---------------------------------------------------------------------
-- RN33: W.O. duplo no Play-in: a chave nao tem 2a rodada (a equipe que aguardava
-- avanca direto). Os eliminados nao voltam: coberto pela consulta RN18.
-- ---------------------------------------------------------------------
SELECT 'RN33 - W.O. duplo: chave sem 2a rodada' AS regra, COUNT(*) AS violacoes
FROM serie s
JOIN rodada r ON r.id_rodada = s.id_rodada AND r.numero = 1
JOIN fase f ON f.id_fase = r.id_fase AND f.nome = 'play_in'
JOIN disputa a ON a.id_serie = s.id_serie AND a.compareceu = 0
JOIN disputa b ON b.id_serie = s.id_serie AND b.compareceu = 0 AND b.id_equipe > a.id_equipe
JOIN equipe ea ON ea.id_equipe = a.id_equipe
WHERE EXISTS (SELECT 1
              FROM serie s2
              JOIN rodada r2 ON r2.id_rodada = s2.id_rodada AND r2.numero = 2
              JOIN fase f2 ON f2.id_fase = r2.id_fase AND f2.nome = 'play_in'
              JOIN disputa d2 ON d2.id_serie = s2.id_serie
              JOIN equipe e2 ON e2.id_equipe = d2.id_equipe
              WHERE e2.chave_play_in = ea.chave_play_in);

-- ---------------------------------------------------------------------
-- RN34: em cada partida jogada, cada equipe faz 5 escolhas e 5 banimentos, menos
-- os banimentos perdidos por punicao (perda_banimento cumprida naquela partida).
-- ---------------------------------------------------------------------
SELECT 'RN34 - 5 escolhas e 5 banimentos (menos os perdidos)' AS regra, COUNT(*) AS violacoes
FROM (SELECT id_partida, id_equipe_azul AS id_equipe FROM partida WHERE id_equipe_azul IS NOT NULL
      UNION ALL
      SELECT id_partida, id_equipe_vermelho FROM partida WHERE id_equipe_vermelho IS NOT NULL) t
WHERE (SELECT COUNT(*) FROM selecao_campeao sc
       WHERE sc.id_partida = t.id_partida AND sc.id_equipe = t.id_equipe AND sc.tipo = 'escolha') <> 5
   OR (SELECT COUNT(*) FROM selecao_campeao sc
       WHERE sc.id_partida = t.id_partida AND sc.id_equipe = t.id_equipe AND sc.tipo = 'banimento')
      <> 5 - (SELECT COUNT(*) FROM punicao pu
              WHERE pu.tipo = 'perda_banimento' AND pu.id_equipe = t.id_equipe
                AND pu.id_partida_cumprimento = t.id_partida);

-- ---------------------------------------------------------------------
-- RN35: nenhum patrocinador de ramo vedado, mesmo com grafia diferente da lista do CHECK.
-- ---------------------------------------------------------------------
SELECT 'RN35 - patrocinador de ramo vedado' AS regra, COUNT(*) AS violacoes
FROM patrocinador
WHERE lower(ramo_atividade) LIKE 'aposta%'
   OR lower(ramo_atividade) LIKE 'tabac%'
   OR lower(ramo_atividade) LIKE 'armas%'
   OR lower(ramo_atividade) LIKE '%bebidas_alcoolicas%'
   OR lower(ramo_atividade) LIKE 'cripto%'
   OR lower(ramo_atividade) LIKE '%politic%';
