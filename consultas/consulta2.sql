--- Pergunta: quais árbitros apitaram mais de 8 horas de jogo (28800 segundos)?
--- Técnicas: SUM, INNER JOIN, GROUP BY, HAVING.

SELECT a.nome,
       SUM(p.duracao) AS segundos_arbitrados
FROM partida p
INNER JOIN serie s ON s.id_serie = p.id_serie
INNER JOIN arbitro a ON a.id_arbitro = s.id_arbitro
GROUP BY a.nome
HAVING SUM(p.duracao) > 28800;
