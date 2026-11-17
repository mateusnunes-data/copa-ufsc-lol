--- Pergunta: qual a duração média das partidas em cada fase e formato de série?
--- Técnicas: AVG, GROUP BY com duas colunas (fase e formato), ORDER BY ASC.

SELECT f.nome AS fase,
       r.formato_serie,
       AVG(p.duracao) AS duracao_media
FROM partida p
INNER JOIN serie s ON s.id_serie = p.id_serie
INNER JOIN rodada r ON r.id_rodada = s.id_rodada
INNER JOIN fase f ON f.id_fase = r.id_fase
GROUP BY f.nome, r.formato_serie
ORDER BY duracao_media ASC;
