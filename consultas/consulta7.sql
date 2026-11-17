--- Pergunta: quais séries tiveram alguma partida perdida por suspensão (partida sem lados)?
--- Técnicas: subconsulta com EXISTS, IS NULL (tratamento de nulos).

SELECT s.id_serie,
       s.data_hora
FROM serie s
WHERE EXISTS (SELECT 1
              FROM partida p
              WHERE p.id_serie = s.id_serie
                AND p.id_equipe_azul IS NULL);
