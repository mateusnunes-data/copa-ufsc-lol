# 04 — Projeto Físico (SQLite)

**Campeonato universitário de League of Legends — UFSC, campus Florianópolis**

CIN 8003 – Bancos de Dados e Aplicações · Prof. Moisés Lima Dutra · Aluno: Mateus Nunes Oliveira

> Feito a partir do esquema relacional (Parte 3). O script é `sql/script_ddl.sql`: 25 tabelas, 44 chaves estrangeiras e 1 índice único. As seções 8 a 10 descrevem a carga de dados, a auditoria das regras e os testes de integridade.

---

## 1. Visão geral

**Ordem de criação** (nenhuma tabela referencia outra que ainda não existe):

1. **Raízes:** organizador, arbitro, centro_ensino, funcao, campeao, patrocinador
2. curso → vinculo_arbitro_curso
3. campeonato → patrocinio, premiacao, fase → rodada
4. equipe → jogador → *ALTER TABLE equipe ADD COLUMN id_capitao* → coach, inscricao, classificacao
5. serie → disputa, partida → avaliacao_resultado, selecao_campeao → escalacao → punicao

O script começa com `PRAGMA foreign_keys = ON;` e com `DROP TABLE IF EXISTS` na ordem inversa, para poder ser executado de novo.

**Como executar:** no SQLite Online, colar o script e clicar em *Run*; no terminal, `sqlite3 banco/campeonato_lol_ufsc.db < sql/script_ddl.sql`.

---

## 2. Mapeamento de tipos

O SQLite guarda os valores por **afinidade**. O tipo declarado (ex.: `VARCHAR(120)`) documenta a intenção e o tamanho esperado; a afinidade de `VARCHAR` é TEXT.

| Tipo declarado | Afinidade | Colunas |
|---|---|---|
| INTEGER PRIMARY KEY | INTEGER | id_<tabela> das 21 tabelas com chave própria (alias do rowid) |
| INTEGER | INTEGER | todas as demais colunas id_* (FKs) |
| INTEGER (número) | INTEGER | campeonato.edicao, numero_vagas; rodada.numero; partida.numero; selecao_campeao.ordem; escalacao.ordem_selecao; classificacao.posicao; premiacao.colocacao; equipe.colocacao_premiacao, chave_play_in |
| INTEGER (segundos) | INTEGER | partida.duracao |
| INTEGER (centavos) | INTEGER | premiacao.valor; patrocinio.valor_cota |
| INTEGER (0/1) | INTEGER | jogador.riot_id_verificado; disputa.compareceu |
| TEXT `AAAA-MM-DD` | TEXT | campeonato.data_inicio, data_fim; rodada.data; jogador.data_nascimento; inscricao.data_aval |
| TEXT `AAAA-MM-DD HH:MM:SS` | TEXT | campeonato.prazo_inscricao; serie.data_hora; inscricao.data_hora_envio, data_decisao; partida.data_hora_registro, data_julgamento; avaliacao_resultado.data_hora_parecer; punicao.data_hora |
| VARCHAR(3) | TEXT | rodada.formato_serie |
| VARCHAR(5) | TEXT | jogador.tag |
| VARCHAR(10) | TEXT | centro_ensino.sigla; inscricao.resultado_decisao; partida.decisao_julgamento; avaliacao_resultado.parecer; selecao_campeao.tipo |
| VARCHAR(12) | TEXT | jogador.matricula; coach.matricula |
| VARCHAR(16) | TEXT | jogador.nome_de_jogo |
| VARCHAR(20) | TEXT | telefone (organizador, arbitro, patrocinador, coach); funcao.nome; fase.nome; campeonato.situacao; punicao.tipo |
| VARCHAR(40) | TEXT | campeao.nome; jogador.nome_exibicao |
| VARCHAR(60) | TEXT | patrocinador.ramo_atividade |
| VARCHAR(80) | TEXT | centro_ensino.nome; curso.nome |
| VARCHAR(120) | TEXT | nome (organizador, arbitro, patrocinador, coach, campeonato); jogador.nome_completo, nome_responsavel, contato_responsavel; inscricao.responsavel_aval; email (organizador, arbitro, patrocinador, jogador, coach) |
| VARCHAR(255) | TEXT | caminho do arquivo: jogador.comprovante_matricula, documento_autorizacao; coach.comprovante_matricula; partida.captura_tela. Texto livre: inscricao.motivo_recusa; punicao.motivo |

- **Dinheiro em centavos:** inteiro não tem erro de arredondamento (R$ 2.000,00 = 200000).
- **Datas em TEXT ISO 8601:** nesse formato, a ordem alfabética é a ordem cronológica, então `<` e `>=` funcionam nos CHECK. O formato é conferido com `LIKE '____-__-__'`.
- **Horário de Brasília (RNF06):** os valores-padrão de data e hora usam `datetime('now', '-3 hours')`, porque `CURRENT_TIMESTAMP` grava em UTC.

---

## 3. Chaves primárias

- **Tabelas com chave própria:** `id_<tabela> INTEGER PRIMARY KEY`.
- **Entidades fracas** (FASE, RODADA, PARTIDA, INSCRICAO, ESCALACAO, SELECAO_CAMPEAO, CLASSIFICACAO, PREMIACAO): a PK composta do lógico virou a chave substituta `id_<tabela>` + `UNIQUE(PK da dona, discriminador)` + FK para a dona com `ON DELETE CASCADE`. O UNIQUE mantém a regra da PK composta, e as tabelas que referenciam a fraca usam uma FK simples (ex.: `id_partida`, em vez do par `id_serie, numero_partida`).
- **Associativas N:M** (DISPUTA, VINCULO_ARBITRO_CURSO, PATROCINIO, AVALIACAO_RESULTADO): **PK composta**. Nenhuma tabela as referencia, então uma chave substituta não simplificaria nada. A PK composta já impede o par repetido (ex.: a mesma equipe duas vezes na série).

**FKs compostas.** Ficaram só três, todas para garantir "do mesmo campeonato" ou "da mesma partida". Elas apontam para um UNIQUE da tabela-mãe:

| FK | Garante |
|---|---|
| jogador (id_equipe, id_campeonato) → equipe | o campeonato do jogador é o da equipe |
| equipe (id_campeonato, colocacao_premiacao) → premiacao | o prêmio é do campeonato da equipe |
| escalacao (id_partida, ordem_selecao) → selecao_campeao (id_partida, ordem) | a escolha usada é da mesma partida |

**Mudanças de nome em relação ao lógico** (efeito da chave substituta):

| Lógico | Físico |
|---|---|
| FASE (id_campeonato, nome) | + id_fase; UNIQUE(id_campeonato, nome) |
| RODADA: (id_campeonato, nome_fase) | id_fase; + id_rodada; UNIQUE(id_fase, numero) |
| SERIE: (id_campeonato, nome_fase, numero_rodada) | id_rodada |
| CLASSIFICACAO: (id_campeonato, nome_fase) | id_fase; + id_classificacao |
| PREMIACAO, INSCRICAO, PARTIDA, SELECAO_CAMPEAO, ESCALACAO | + id_premiacao, id_inscricao, id_partida, id_selecao_campeao, id_escalacao |
| (id_serie, numero_partida) em AVALIACAO_RESULTADO, SELECAO_CAMPEAO, ESCALACAO | id_partida |
| PUNICAO: (id_serie_ocorrencia, numero_partida_ocorrencia) e (…_cumprimento) | id_partida_ocorrencia, id_partida_cumprimento |
| JOGADOR | + id_campeonato (cópia controlada pela FK composta; permite RN04 e RN05 no DDL) |

**Ciclo EQUIPE ↔ JOGADOR.** EQUIPE aponta para o capitão (JOGADOR) e JOGADOR aponta para a equipe. Por isso EQUIPE é criada sem `id_capitao`; depois de JOGADOR, a coluna entra com `ALTER TABLE equipe ADD COLUMN id_capitao INTEGER REFERENCES jogador ...`. O SQLite aceita `ADD COLUMN` com `REFERENCES` quando o padrão é NULL, mas não aceita UNIQUE ali. Por isso, o 1:1 é garantido por `CREATE UNIQUE INDEX uq_equipe_capitao`.

---

## 4. Nulabilidade e valores-padrão

Todo atributo é `NOT NULL`, exceto:

| Aceita NULL | Por quê |
|---|---|
| FKs opcionais do lógico: inscricao.id_organizador, jogador.id_funcao, partida.id_equipe_azul/vermelho, id_organizador_julgamento, equipe.colocacao_premiacao, todas as FKs de punicao | participação mínima 0. Em punicao, os CHECK exigem exatamente um alvo e um aplicador |
| equipe.id_capitao | fica vazio até o elenco ser cadastrado (ciclo) |
| Preenchidos depois: equipe.chave_play_in; disputa.compareceu; inscricao.responsavel_aval, data_aval, data_decisao, motivo_recusa; partida.decisao_julgamento, data_julgamento | o fato ainda não aconteceu (sorteio, série, aval, decisão, julgamento) |
| partida.duracao, captura_tela | só na partida perdida por suspensão, que não é jogada (CHECK ck_partida_lados) |
| jogador.email, data_nascimento, comprovante_matricula; coach.email, comprovante_matricula | a LGPD (Requisitos 8.2) manda apagá-los até 90 dias após o campeonato. Na inscrição, a aplicação os exige |
| telefones; jogador.nome_responsavel, contato_responsavel, documento_autorizacao | contato opcional; dados do responsável só existem para menores |

| DEFAULT | Valor | Motivo |
|---|---|---|
| campeonato.numero_vagas | 64 | uma vaga por curso (RN09) |
| campeonato.situacao | 'inscricoes_abertas' | estado inicial |
| jogador.riot_id_verificado | 0 | o organizador ainda não verificou (RN05) |
| inscricao.resultado_decisao | 'pendente' | estado inicial (RN09) |
| inscricao.data_hora_envio, partida.data_hora_registro, avaliacao_resultado.data_hora_parecer, punicao.data_hora | `datetime('now', '-3 hours')` | momento do registro, no horário de Brasília |

---

## 5. Ações referenciais

**ON UPDATE CASCADE em todas as FKs.** As chaves são substitutas e não mudam; se uma correção mudar alguma, os filhos acompanham.

| ON DELETE | Onde | Por quê |
|---|---|---|
| **CASCADE** | Entidades fracas → dona: premiacao, fase → campeonato; rodada, classificacao → fase; inscricao → equipe; partida → serie; selecao_campeao, escalacao → partida; escalacao → selecao_campeao | dependência forte: a linha não tem sentido sem a dona |
| **CASCADE** | Associativas, do lado da dona: patrocinio → campeonato; disputa → serie; avaliacao_resultado → partida; vinculo_arbitro_curso → arbitro e curso | a associação é parte da dona |
| **CASCADE** | coach → equipe | o coach só existe para a equipe e ninguém o referencia |
| **RESTRICT** | As outras 28 FKs: as que apontam para organizador, arbitro, centro_ensino, curso, funcao, campeao, patrocinador, campeonato (em equipe), equipe, jogador, rodada e premiacao, e todas as de punicao | preservar o histórico: não se apaga uma equipe que jogou, um jogador escalado, um organizador que decidiu, uma punição aplicada |
| **SET NULL** | equipe.id_capitao → jogador | vínculo opcional: se o capitão sai (troca, RN31), a equipe fica sem capitão até escolher outro |

Dois casos para explicar:
- **escalacao → jogador é RESTRICT**, mesmo sendo fraca: a dona principal é a partida; apagar um jogador não pode apagar quem jogou.
- **equipe → premiacao é RESTRICT, não SET NULL:** a FK é composta, e SET NULL anularia também `id_campeonato`, que é NOT NULL.

Como as cadeias terminam em RESTRICT, apagar um campeonato com equipes é bloqueado: o histórico tem prioridade.

---

## 6. Matriz das regras de negócio

**Legenda:** "DDL" = garantida pelo banco. "Aplicação" = não garantível só com DDL, porque depende de várias linhas ou tabelas: garantida pela aplicação e auditada por consulta. Inclui as regras complementares RN29 a RN35 dos Requisitos.

| RN | No banco (DDL) | Aplicação + auditoria | Situação |
|---|---|---|---|
| RN01 | `UNIQUE(id_campeonato, id_curso)` em equipe; id_curso NOT NULL + FK | — | DDL |
| RN02 | funcao.nome `CHECK IN` (5 funções) + UNIQUE; `UNIQUE(id_equipe, id_funcao)` em jogador (no máximo 1 titular por função; o reserva tem NULL) | exatamente 6 jogadores e 1 reserva | parcial |
| RN03 | matricula NOT NULL; coluna do comprovante | matrícula ativa no curso da equipe | parcial |
| RN04 | `UNIQUE(id_campeonato, matricula)` em jogador | aluno com dois cursos (duas matrículas) | parcial |
| RN05 | `UNIQUE(id_campeonato, nome_de_jogo, tag)`; CHECK de tamanho; riot_id_verificado 0/1, DEFAULT 0 | exigir verificado = 1 na aprovação | parcial |
| RN06 | id_capitao FK + índice único (cada equipe tem um capitão; ninguém é capitão de duas) | capitão ser da própria equipe; preenchido na aprovação | parcial |
| RN07 | coach.id_equipe NOT NULL UNIQUE (no máximo 1 coach); matricula NOT NULL | coach do curso da equipe e não ser jogador | parcial |
| RN08 | CHECK ck_jogador_responsavel (dados do responsável completos ou ausentes) | menor na data da inscrição exige autorização | parcial |
| RN09 | resultado_decisao `CHECK IN`, DEFAULT 'pendente'; CHECK decisão com organizador e data; CHECK recusa com motivo; `UNIQUE(id_equipe, data_hora_envio)` permite reenvio; numero_vagas 16–64; CHECK prazo < início | envio dentro do prazo; mínimo de 16 aprovadas | parcial |
| RN10 | chave_play_in 1–16; fase.nome `CHECK IN`; formato `CHECK IN` | sorteio, 4 por chave, folga, Md3 no Play-in | parcial |
| RN11 | — | emparelhamento por retrospecto (várias séries) | aplicação |
| RN12 | classificacao.posicao 1–8 | 3 vitórias / 3 derrotas | aplicação |
| RN13 | — | confronto repetido na Fase Suíça | aplicação |
| RN14 | `UNIQUE(id_fase, posicao)`; id_equipe UNIQUE | critérios de desempate | parcial |
| RN15 | — | montar 1º×8º, 4º×5º, 2º×7º, 3º×6º | aplicação |
| RN16 | formato_serie `CHECK IN ('Md1','Md3','Md5')` | formato certo em cada rodada | parcial |
| RN17 | partida.numero 1–5; `UNIQUE(id_serie, numero)` | parar quando há vencedor | parcial |
| RN18 | PK de disputa (a mesma equipe não entra duas vezes); CHECK azul ≠ vermelho | 2 equipes, aprovadas e ativas | parcial |
| RN19 | CHECK ck_partida_lados (dois lados diferentes) | quem escolhe o lado | parcial |
| RN20 | `UNIQUE(id_partida, id_jogador)` em escalacao; id_funcao NOT NULL | 5 por equipe, um por função | parcial |
| RN21 | `UNIQUE(id_partida, id_campeao)` em selecao_campeao | jogador suspenso não escalado | parcial |
| RN22 | — | *fearless draft*: depende das partidas anteriores da série | aplicação |
| RN23 | — | choque de horário da equipe | aplicação |
| RN24 | serie.id_arbitro NOT NULL; `UNIQUE(id_arbitro, data_hora)` | conflito de interesse (vínculo com os cursos) | parcial |
| RN25 | vencedora NOT NULL; CHECK vencedora é um dos lados; duracao > 0; parecer `CHECK IN`; PK (partida, jogador); CHECK julgamento completo e posterior ao registro | só capitães avaliam; prazo de 24 h | parcial |
| RN26 | compareceu `CHECK IN (0,1)` | tolerância de 15 min; placar do W.O. | parcial |
| RN27 | tipo `CHECK IN`; CHECK um alvo coerente com o tipo; CHECK um aplicador; desqualificação só pelo organizador; cumprimento ≠ ocorrência | suspensão automática por 3 advertências; desqualificada perde por W.O. | parcial |
| RN28 | colocacao `CHECK IN (1,2,3)` (um valor para as duas semifinalistas); valor > 0; valor_cota > 0; FK composta equipe → premiacao | soma das cotas ≥ premiação; desqualificada sem prêmio | parcial |
| RN29 | — | troca de Riot ID só com autorização | aplicação |
| RN30 | CHECK aprovada exige responsavel_aval; CHECK aval completo | — | DDL |
| RN31 | equipe.id_capitao ON DELETE SET NULL | troca só antes do Play-in, com autorização | parcial |
| RN32 | CHECK ck_partida_lados (partida com lados tem captura) | — | DDL |
| RN33 | compareceu = 0 nas duas linhas da série | quem avança; derrota das duas na Fase Suíça | parcial |
| RN34 | tipos perda_escolha_lado e perda_banimento; CHECK aplicadas pelo árbitro | — | DDL |
| RN35 | CHECK `lower(ramo_atividade) NOT IN (...)` | grafia diferente da lista (vocabulário controlado) | DDL |

**Resumo:** 5 regras totalmente no DDL, 23 parciais, 7 só na aplicação. As 7 dependem de comparar várias linhas (séries anteriores, contagens, horários), o que um CHECK não faz.

---

## 7. Execução

Executado com o `sqlite3` do Python (SQLite 3.53.1), duas vezes seguidas no mesmo arquivo:

| Verificação | Resultado |
|---|---|
| 1ª execução | OK, sem erros |
| 2ª execução (reexecução) | OK, sem erros |
| `PRAGMA foreign_keys` | 1 (ligado) |
| Tabelas em `sqlite_master` | 25 |
| Índice explícito | uq_equipe_capitao |
| FKs em `PRAGMA foreign_key_list` | 44 restrições, com as ações da seção 5 (o PRAGMA mostra 47 linhas, porque as 3 FKs compostas ocupam uma linha por coluna) |
| `PRAGMA foreign_key_check` / `integrity_check` | sem violações / ok |

---

## 8. Carga de dados

**Como foi feito.** O arquivo `python/gerar_dados.py` (só biblioteca padrão do Python, semente fixa `20261116`) simula o campeonato inteiro, na ordem em que ele acontece, e escreve `sql/script_dml.sql`. Rodar duas vezes gera exatamente o mesmo arquivo. O script também monta `banco/campeonato_lol_ufsc.db`: executa o `script_ddl.sql` e depois o `script_dml.sql`, com `PRAGMA foreign_keys = ON`.

**Ordem do `script_dml.sql`:** as 25 tabelas, pais antes de filhos, em INSERTs de até 50 linhas, com comentário por tabela. O ciclo EQUIPE ↔ JOGADOR é fechado com 64 comandos `UPDATE equipe SET id_capitao = ...` logo depois da carga de jogador. O arquivo tem cerca de 324 KB e roda sem erro depois do `script_ddl.sql`.

**O que é real e o que é sintético:**

| Real | Sintético |
|---|---|
| Centros de ensino e os 64 cursos de graduação do campus Florianópolis; as 5 funções; 171 nomes de campeões do jogo | Nomes de pessoas, matrículas, Riot IDs, e-mails (`@...example.com`), telefones `(48) 90000-xxxx`, patrocinadores fictícios, caminhos de arquivos, todas as datas e resultados |

Nenhum dado pessoal real foi usado (LGPD).

**Linhas por tabela** (total: 6.251):

| Tabela | Linhas | Tabela | Linhas |
|---|---|---|---|
| organizador | 2 | inscricao | 70 |
| arbitro | 12 | classificacao | 8 |
| centro_ensino | 11 | serie | 87 |
| funcao | 5 | disputa | 174 |
| campeao | 171 | partida | 157 |
| patrocinador | 6 | avaliacao_resultado | 276 |
| curso | 64 | selecao_campeao | 3.099 |
| vinculo_arbitro_curso | 21 | escalacao | 1.550 |
| campeonato | 1 | punicao | 24 |
| patrocinio | 5 | equipe | 64 |
| premiacao | 3 | jogador | 384 |
| fase | 3 | coach | 44 |
| rodada | 10 | | |

**Cenário simulado (campeonato `encerrado`, edição 2026):** inscrições até 30/09, primeira série em 03/10, última em 14/11. Foram 47 séries no Play-in (16 chaves de 4), 33 na Fase Suíça (16 equipes) e 7 nos Playoffs (8 equipes). Campeã: Ciência de Dados; vice: Engenharia Civil; semifinalistas premiadas: Animação e Engenharia Eletrônica.

**Casos de borda colocados de propósito** (além dos NULL legítimos):

| Caso | Regra | Como aparece nos dados |
|---|---|---|
| W.O. simples | RN26, RN33 | Play-in, série 27: uma equipe com `compareceu = 0` |
| W.O. duplo | RN33 | Play-in, série 28: as duas equipes com `compareceu = 0`; a chave não tem 2ª rodada |
| Advertências que geram suspensão | RN27 | 20 advertências; uma equipe com 3 advertências perde a partida seguinte (partida sem lados, sem duração e sem captura) |
| Jogador suspenso | RN21, RN27 | 1 `suspensao_jogador`; na partida seguinte o reserva o substitui |
| Perda de banimento e de escolha de lado | RN34 | 1 `perda_banimento` (4 banimentos na partida seguinte) e 1 `perda_escolha_lado` |
| Desqualificação | RN27 | 1 `desqualificacao`; a equipe perde por W.O. as séries seguintes até 3 derrotas |
| Contestações de resultado | RN25 | 6 partidas julgadas: 4 `mantido` e 2 `alterado` |
| Inscrição recusada e reenviada | RN09 | 6 recusas seguidas de nova inscrição aprovada (70 inscrições para 64 equipes) |
| Menores de idade | RN08 | 6 jogadores com responsável e documento de autorização |
| Dados eliminados pela LGPD | Requisitos 8.2 | 5 jogadores com e-mail, nascimento ou comprovante `NULL` |
| Final em 5 partidas | RN16, RN17 | série Md5 decidida na 5ª partida |
| Árbitros com vínculo a cursos | RN24 | 12 árbitros, 21 vínculos; nenhum apita série de curso com que tem vínculo |

---

## 9. Auditoria das regras que o DDL não garante

O arquivo `sql/verificacao_regras.sql` tem **30 consultas**, uma por regra marcada "aplicação" ou "parcial" na seção 6 que pode ser conferida pelos dados. Cada uma devolve `(regra, violacoes)`; o esperado é **0**. As regras RN29 e RN31 (trocas) não podem ser auditadas porque o banco não guarda histórico, e os sorteios (RN10, RN11, RN14) e a escolha do lado (RN19) são aleatórios ou decisões humanas.

Resultado da execução sobre `banco/campeonato_lol_ufsc.db`: **as 30 consultas devolveram 0 violações** (RN02 a RN28, RN33, RN34 e RN35). Para provar que as consultas funcionam, cada uma foi também executada sobre uma cópia do banco com um erro plantado de propósito, e todas passaram a devolver mais de 0.

---

## 10. Relatório de testes de integridade (Atividade 04)

Os comandos estão em `sql/testes_integridade.sql`. Cada um foi executado em uma **cópia** do banco, com `PRAGMA foreign_keys = ON` e `sqlite3` do Python (SQLite 3.53.1). Sem esse PRAGMA, o SQLite ignora as chaves estrangeiras e aceitaria os testes 1 a 4. O banco original continuou com 64 equipes e todas as linhas.

### A) Integridade referencial

| # | Comando | Mensagem do SQLite | Como o banco protegeu a regra |
|---|---|---|---|
| 1 | `INSERT INTO coach (nome, matricula, id_equipe) VALUES ('Coach Sem Equipe', '26999999', 999);` | `FOREIGN KEY constraint failed` | A FK coach → equipe não aceita filho sem pai: não existe equipe 999. |
| 2 | `INSERT INTO jogador (..., id_equipe, id_campeonato) VALUES (..., 1, 2);` | `FOREIGN KEY constraint failed` | A FK composta (id_equipe, id_campeonato) → equipe exige que o campeonato do jogador seja o da sua equipe. O par (1, 2) não existe (RN04, RN05). |
| 3 | `DELETE FROM equipe WHERE id_equipe = 1;` | `FOREIGN KEY constraint failed` | `ON DELETE RESTRICT` nas FKs de jogador e de disputa: não se apaga uma equipe com jogadores e séries disputadas. O coach, que seria apagado em cascata, também ficou intacto. |
| 4 | `DELETE FROM campeonato WHERE id_campeonato = 1;` | `FOREIGN KEY constraint failed` | `ON DELETE RESTRICT` em equipe → campeonato: o histórico do campeonato não pode ser apagado. |

### B) CHECK

| # | Comando | Mensagem do SQLite | Como o banco protegeu a regra |
|---|---|---|---|
| 5 | `INSERT INTO patrocinador (nome, ramo_atividade, email) VALUES ('Casa de Apostas Teste', 'apostas', 'teste@example.com');` | `CHECK constraint failed: ck_patrocinador_ramo` | RN35: ramos vedados pela Riot Games (apostas) não podem patrocinar. |
| 6 | `UPDATE campeonato SET numero_vagas = 100 WHERE id_campeonato = 1;` | `CHECK constraint failed: ck_campeonato_vagas` | RN09: o campeonato tem de 16 a 64 vagas, uma por curso. |
| 7 | `INSERT INTO partida (...) VALUES (1, 4, 1800, 'capturas/teste.png', '2026-10-03 12:00:00', 21, 21, 21);` | `CHECK constraint failed: ck_partida_lados` | RN19: uma equipe não joga contra ela mesma; os lados azul e vermelho precisam ser diferentes. |

### C) UNIQUE

| # | Comando | Mensagem do SQLite | Como o banco protegeu a regra |
|---|---|---|---|
| 8 | `INSERT INTO jogador (...) ` com a matrícula do jogador 1, em outra equipe do mesmo campeonato | `UNIQUE constraint failed: jogador.id_campeonato, jogador.matricula` | RN04: um estudante só pode estar em uma equipe por campeonato. |
| 9 | `INSERT INTO jogador (...)` com o nome de jogo e a tag do jogador 1 | `UNIQUE constraint failed: jogador.id_campeonato, jogador.nome_de_jogo, jogador.tag` | RN05: o Riot ID (nome + tag) identifica uma pessoa no campeonato. |
| 10 | `INSERT INTO equipe (id_campeonato, id_curso) VALUES (1, 1);` | `UNIQUE constraint failed: equipe.id_campeonato, equipe.id_curso` | RN01: um curso tem uma única equipe por campeonato. |
| 11 | `UPDATE equipe SET id_capitao = (capitão da equipe 1) WHERE id_equipe = 2;` | `UNIQUE constraint failed: equipe.id_capitao` | RN06: ninguém é capitão de duas equipes (índice único `uq_equipe_capitao`). |

### D) Contraste: CASCADE

| # | Comando | Resultado | O que mostra |
|---|---|---|---|
| 12 | `DELETE FROM serie WHERE id_serie = 27;` | sem erro; `disputa` da série 27 passou de 2 linhas para 0 | `ON DELETE CASCADE` em disputa → serie: a associação é parte da série e some com ela. Executado só na cópia. |

**Conclusão.** Os testes 1 a 11 foram recusados com a mensagem prevista, e o teste 12 mostra o contraste com o CASCADE. Dessa forma, o banco protege sozinho as regras que o DDL consegue expressar; as demais ficam com a aplicação e com as consultas da seção 9.
