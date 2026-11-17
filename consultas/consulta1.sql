--- Pergunta: quantos cursos cada centro de ensino tem no campeonato?
--- Técnicas: COUNT, INNER JOIN (2 tabelas), GROUP BY, ORDER BY DESC.

SELECT ce.sigla,
       COUNT(c.id_curso) AS total_cursos
FROM centro_ensino ce
INNER JOIN curso c ON c.id_centro_ensino = ce.id_centro_ensino
GROUP BY ce.sigla
ORDER BY total_cursos DESC;
