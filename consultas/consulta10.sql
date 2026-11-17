--- Pergunta: o organizador 1 corrige o vencedor da partida 1 após contestação. Dá para desfazer sem perder nada?
--- Técnicas: transação com BEGIN, SAVEPOINT, ROLLBACK TO e COMMIT.
--- O ROLLBACK TO desfaz tudo antes do COMMIT: o banco termina igual e o arquivo pode rodar quantas vezes precisar.

BEGIN;

-- 1. Marca o ponto de retorno.
SAVEPOINT antes_correcao;

-- 2. Alteração: troca a vencedora da partida 1 (da equipe 62 para a 21) e registra o julgamento.
UPDATE partida
SET id_equipe_vencedora = 21,
    id_organizador_julgamento = 1,
    decisao_julgamento = 'alterado',
    data_julgamento = '2026-10-04 12:00:00'
WHERE id_partida = 1;

-- 3. Mostra a alteração: vencedora 21 e decisão 'alterado'.
SELECT id_partida, id_equipe_vencedora, decisao_julgamento
FROM partida
WHERE id_partida = 1;

-- 4. Desfaz tudo o que veio depois do savepoint.
ROLLBACK TO antes_correcao;

-- 5. Mostra que voltou: vencedora 62 e decisão NULL.
SELECT id_partida, id_equipe_vencedora, decisao_julgamento
FROM partida
WHERE id_partida = 1;

-- 6. Encerra a transação (não há mais nada a confirmar).
COMMIT;
