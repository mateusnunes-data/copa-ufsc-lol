--- Pergunta: quanto cada patrocinador pagou de cota? Quem não patrocinou também aparece.
--- Técnicas: LEFT JOIN com 3 tabelas, COALESCE (tratamento de nulos), ORDER BY DESC.

SELECT pa.nome AS patrocinador,
       COALESCE(c.nome, 'sem patrocínio') AS campeonato,
       COALESCE(pt.valor_cota, 0) / 100 AS cota_em_reais
FROM patrocinador pa
LEFT JOIN patrocinio pt ON pt.id_patrocinador = pa.id_patrocinador
LEFT JOIN campeonato c ON c.id_campeonato = pt.id_campeonato
ORDER BY cota_em_reais DESC;
