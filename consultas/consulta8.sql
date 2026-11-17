--- Pergunta: quantas vitórias tiveram as 8 equipes classificadas da Fase Suíça?
--- Técnicas: CTE (WITH) para contar vitórias, subconsulta com IN, INNER JOIN, ORDER BY DESC.

WITH vitorias AS (
    SELECT id_equipe_vencedora AS id_equipe,
           COUNT(*) AS total
    FROM partida
    GROUP BY id_equipe_vencedora
)
SELECT c.nome AS curso,
       v.total AS vitorias
FROM vitorias v
INNER JOIN equipe e ON e.id_equipe = v.id_equipe
INNER JOIN curso c ON c.id_curso = e.id_curso
WHERE v.id_equipe IN (SELECT id_equipe FROM classificacao)
ORDER BY vitorias DESC;
