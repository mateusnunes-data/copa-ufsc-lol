--- Pergunta: o árbitro 1 registra uma advertência para a equipe 21. Dá para desfazer sem perder nada?
--- Técnicas: transação com BEGIN, SAVEPOINT, ROLLBACK TO e COMMIT.
--- O ROLLBACK TO desfaz tudo antes do COMMIT: o banco termina igual e o arquivo pode rodar quantas vezes precisar.

BEGIN;

-- 1. Marca o ponto de retorno.
SAVEPOINT antes_advertencia;

-- 2. Alteração: registra a advertência.
INSERT INTO punicao (tipo, motivo, id_equipe, id_arbitro)
VALUES ('advertencia', 'Atraso para iniciar a partida', 21, 1);

-- 3. Mostra a alteração: o total de advertências da equipe 21 sobe em 1.
SELECT COUNT(*) AS advertencias_equipe_21
FROM punicao
WHERE tipo = 'advertencia' AND id_equipe = 21;

-- 4. Desfaz tudo o que veio depois do savepoint.
ROLLBACK TO antes_advertencia;

-- 5. Mostra que voltou: o total é o mesmo de antes.
SELECT COUNT(*) AS advertencias_equipe_21
FROM punicao
WHERE tipo = 'advertencia' AND id_equipe = 21;

-- 6. Encerra a transação (não há mais nada a confirmar).
COMMIT;
