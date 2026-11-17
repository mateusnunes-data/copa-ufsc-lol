--- Pergunta: quais partidas duraram mais do que a duração média de todas as partidas?
--- Técnicas: subconsulta escalar no WHERE (devolve um único valor), AVG, ORDER BY DESC.

SELECT id_partida,
       id_serie,
       duracao
FROM partida
WHERE duracao > (SELECT AVG(duracao) FROM partida)
ORDER BY duracao DESC;
