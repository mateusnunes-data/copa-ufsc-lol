--- Pergunta: qual a vitória mais curta e a mais longa de cada curso que venceu 5 partidas ou mais?
--- Técnicas: MIN, MAX, INNER JOIN, GROUP BY, HAVING.

SELECT c.nome AS curso,
       MIN(p.duracao) AS vitoria_mais_curta,
       MAX(p.duracao) AS vitoria_mais_longa
FROM partida p
INNER JOIN equipe e ON e.id_equipe = p.id_equipe_vencedora
INNER JOIN curso c ON c.id_curso = e.id_curso
GROUP BY c.nome
HAVING COUNT(*) >= 5;
