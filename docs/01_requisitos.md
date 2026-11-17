# 01 — Modelo de Requisitos

**Campeonato universitário de League of Legends — UFSC, campus Florianópolis**

CIN 8003 – Bancos de Dados e Aplicações · Prof. Moisés Lima Dutra · Aluno: Mateus Nunes Oliveira · Versão final (15/11/2026)

> Documento feito a partir do cenário aprovado, no molde da Atividade Prática 01. Nesta etapa não há tabelas de banco, chaves nem SQL: tudo está em linguagem de usuário.

---

## 1. Descrição do domínio

League of Legends (LoL) é um jogo eletrônico em que duas equipes de cinco jogadores se enfrentam. Cada jogador ocupa uma **função** (Topo, Selva, Meio, Atirador ou Suporte) e controla um **campeão**, escolhido de um catálogo de cerca de 170 personagens. Antes de cada partida há a **seleção de campeões**: as equipes alternam **banimentos** (campeões que ninguém poderá usar) e **escolhas**. Uma equipe joga do lado azul e a outra do lado vermelho do mapa.

O cliente quer um campeonato em que cada curso de graduação presencial do campus Florianópolis seja representado por uma equipe, com **64 vagas**. Cada curso pertence a um **Centro de Ensino**. Um **organizador** cria o campeonato e aprova as **inscrições**. Cada equipe tem 6 jogadores do próprio curso (5 titulares e 1 reserva), um deles capitão, e pode ter um coach.

O campeonato tem três **fases**, cada uma dividida em **rodadas**. Cada rodada reúne **séries**, que são confrontos entre duas equipes disputados em uma ou mais **partidas**:

- **Play-in:** eliminatória simples em duas rodadas, séries em melhor de 3 (Md3). Passam 16 equipes.
- **Fase Suíça:** séries em melhor de 1 (Md1) entre equipes com o mesmo retrospecto. Quem chega a 3 vitórias se classifica e quem chega a 3 derrotas é eliminado. Passam 8 equipes.
- **Playoffs:** eliminatória simples. Quartas e semifinais em Md3, final em melhor de 5 (Md5).

Em cada série, um **árbitro** registra a escalação, os lados, os banimentos, as escolhas, o vencedor e a duração de cada partida. Condutas indevidas geram **punições**. A **premiação** é paga com as cotas dos **patrocinadores**. O público acompanha pelas transmissões e consulta os resultados.

**Fora do escopo:** a transmissão, a venda de ingressos, o pagamento da premiação e as estatísticas internas do jogo (abates, ouro etc.).

---

## 2. Stakeholders e suas responsabilidades

| Stakeholder | Responsabilidades |
|---|---|
| **Jogadores** | Manter matrícula ativa no curso; informar dados e Riot ID corretos; comparecer no horário; respeitar as regras. |
| **Capitães** | Enviar a inscrição; responder pela equipe; informar a escalação; escolher o lado quando tiverem esse direito; confirmar ou contestar resultados. |
| **Coaches** | Orientar a equipe; acompanhar os campeões já usados na série e as suspensões. |
| **Centros acadêmicos / coordenações** | Dar aval de que a equipe representa o curso e de que seus membros são alunos dele. |
| **Organizadores** | Criar o campeonato; aprovar inscrições; fazer os sorteios; gerar rodadas e chaveamento; designar árbitros; julgar contestações; desqualificar equipes; definir a premiação. |
| **Árbitros** | Conduzir as séries; registrar escalação, seleção de campeões, resultado e W.O.; aplicar advertências. |
| **Patrocinadores** | Pagar as cotas que financiam a premiação. |
| **Espectadores** | Acompanhar as transmissões; consultar calendário, resultados e classificação. |

---

## 3. Necessidades por stakeholder e requisitos funcionais

### 3.1 Necessidades

- **Jogador:** "Quero saber se minha inscrição foi aprovada e ver meu histórico de partidas."
- **Capitão:** "Preciso inscrever a equipe no prazo, saber contra quem jogamos e confirmar o resultado."
- **Coach:** "Preciso saber quais campeões já foram usados na série e quem está suspenso."
- **Centro acadêmico / coordenação:** "Quero garantir que quem joga pelo curso é aluno do curso."
- **Organizador:** "Preciso saber quantas inscrições faltam, gerar as rodadas sem erro e designar árbitros sem conflito de interesse."
- **Árbitro:** "Preciso registrar a partida inteira de uma vez, e o sistema deve recusar escolhas inválidas."
- **Patrocinador:** "Quero saber quem foi premiado e quanto o campeonato movimentou."
- **Espectador:** "Quero ver tabela, resultados e classificação atualizados."

### 3.2 Requisitos funcionais

| RF | O sistema deve permitir... | Regras |
|---|---|---|
| RF01 | que o organizador crie um campeonato com nome, edição, prazo de inscrições, fases e rodadas. | RN09, RN10–RN16 |
| RF02 | manter a lista de cursos, seus Centros de Ensino, os campeões do jogo e as cinco funções. | RN01, RN02 |
| RF03 | que o capitão inscreva a equipe com os 6 jogadores (função de cada titular, reserva, capitão) e o coach, se houver. | RN01–RN07, RN31 |
| RF04 | cadastrar jogadores e coaches com seus dados, Riot ID, comprovante de matrícula e, para menores de 18 anos, a autorização do responsável. | RN03, RN05, RN08, RN29 |
| RF05 | que o centro acadêmico ou a coordenação dê o aval à inscrição. | RN30 |
| RF06 | que o organizador aprove ou recuse a inscrição (com motivo) e que o capitão reenvie uma inscrição recusada dentro do prazo. | RN09 |
| RF07 | registrar os sorteios e gerar os confrontos de cada rodada das três fases. | RN10–RN15 |
| RF08 | calcular a classificação da Fase Suíça com os critérios de desempate. | RN14 |
| RF09 | agendar cada série e designar o árbitro, recusando conflitos de horário e de interesse. | RN23, RN24 |
| RF10 | que o árbitro registre, em cada partida, os lados, a escalação, os banimentos e as escolhas, o vencedor, a duração e a captura de tela do resultado. | RN17–RN22, RN25, RN32 |
| RF11 | que o árbitro registre W.O., inclusive W.O. duplo. | RN26, RN33 |
| RF12 | que cada capitão confirme ou conteste o resultado e que o organizador julgue a contestação. | RN25 |
| RF13 | registrar advertências, suspensões, penalidades e desqualificações. | RN21, RN27, RN34 |
| RF14 | cadastrar patrocinadores e suas cotas, definir a premiação e apurar as equipes premiadas. | RN28, RN35 |
| RF15 | que qualquer pessoa consulte calendário, chaveamento, resultados, seleção de campeões e classificação. | — |
| RF16 | que jogadores, capitães e coaches consultem o histórico da equipe, os campeões já usados na série e as suspensões. | RN21, RN22 |
| RF17 | que cada pessoa consulte e corrija os próprios dados e peça a eliminação dos que não forem mais necessários. | Seção 8 |

---

## 4. Informações que precisam ser mantidas

Categorias de fatos, **não colunas**:

- **Sobre o campeonato:** nome, edição, prazo de inscrições, datas, organizador, situação.
- **Sobre fases e rodadas:** qual fase, número da rodada, formato das séries (Md1, Md3 ou Md5), datas.
- **Sobre uma série:** as duas equipes, data e hora, árbitro, placar, vencedora, se foi por W.O.
- **Sobre uma partida:** número na série, lado de cada equipe, duração, vencedora, situação do resultado (pendente, contestado ou oficial), captura de tela.
- **Sobre uma equipe:** curso que representa, capitão, coach, situação (ativa, eliminada ou desqualificada), colocação final.
- **Sobre cursos e Centros de Ensino:** nome do curso e centro ao qual pertence.
- **Sobre um jogador:** nome, nome de exibição, matrícula, curso, e-mail, data de nascimento, Riot ID, função de titular ou reserva, comprovante de matrícula e, se for menor, os dados do responsável e a autorização.
- **Sobre um coach:** nome, matrícula, curso, contato.
- **Sobre uma inscrição:** data de envio, aval do curso, situação, data da decisão, motivo da recusa.
- **Sobre a escalação:** quais jogadores atuaram em cada partida e em qual função.
- **Sobre a seleção de campeões:** em cada partida, a equipe, o tipo (banimento ou escolha), o campeão, a ordem e o jogador (na escolha).
- **Sobre a classificação da Fase Suíça:** vitórias, derrotas, adversários enfrentados, posição.
- **Sobre árbitros e organizadores:** nome, contato e, para o árbitro, os cursos com os quais tem vínculo.
- **Sobre punições:** tipo, quem foi punido, partida, motivo, data, quem aplicou.
- **Sobre patrocínio e premiação:** patrocinador, valor da cota, valor de cada colocação, equipe premiada.

**Distinções importantes:**
- **Campeão ≠ seleção de campeão.** O campeão é um personagem do jogo; a seleção é o ato de escolhê-lo ou bani-lo em uma partida específica.
- **Série ≠ partida.** Uma série Md3 tem 2 ou 3 partidas; uma série vencida por W.O. não tem nenhuma.
- **Equipe ≠ curso.** O curso é permanente; a equipe existe só dentro de um campeonato.

---

## 5. Regras de negócio

As regras **RN01 a RN28** vêm do cenário aprovado, com a mesma numeração, reescritas para serem verificáveis. As regras **RN29 a RN35** são complementares: foram encontradas na pesquisa, aprovadas pelo cliente e numeradas na ordem em que foram criadas. Cada uma aparece no fim do tópico a que pertence.

### 5.1 Equipes e elegibilidade

- **RN01** — Cada equipe representa exatamente um curso de graduação presencial do campus Florianópolis, e cada curso tem no máximo uma equipe por campeonato.
- **RN02** — Cada equipe tem exatamente 6 jogadores: 5 titulares, um para cada função (Topo, Selva, Meio, Atirador e Suporte), e 1 reserva.
- **RN03** — Todo jogador tem matrícula ativa no curso da equipe, comprovada por atestado de matrícula do semestre vigente.
- **RN04** — Um estudante joga em no máximo uma equipe por campeonato. Quem tem dois cursos escolhe um deles para representar.
- **RN05** — Todo jogador informa um Riot ID verificado pelo organizador. Dois jogadores do mesmo campeonato não podem ter o mesmo Riot ID.
- **RN06** — Cada equipe tem exatamente um capitão, que pode ser qualquer um dos 6 jogadores, inclusive o reserva.
- **RN07** — Cada equipe tem no máximo um coach. O coach deve ter matrícula ativa no curso da equipe e não pode ser jogador de nenhuma equipe do campeonato.
- **RN08** — Jogador com menos de 18 anos na data da inscrição só é aprovado com autorização assinada pelo responsável legal.
- **RN09** — A inscrição só é aceita dentro do prazo e só vale depois de aprovada pelo organizador. A inscrição recusada pode ser corrigida e reenviada dentro do prazo. São 64 vagas, uma por curso. Ao fim do prazo, o campeonato começa se houver pelo menos 16 inscrições aprovadas; com menos de 16, o organizador prorroga o prazo ou cancela o campeonato.
- **RN29** — Depois da aprovação da inscrição, o Riot ID do jogador só muda com autorização do organizador.
- **RN30** — A inscrição só é aprovada com o aval do centro acadêmico ou da coordenação do curso.
- **RN31** — Depois da aprovação, a troca de um jogador só é permitida antes do início do Play-in e com autorização do organizador.

### 5.2 Formato do campeonato

- **RN10** — O Play-in tem duas rodadas de eliminatória simples, com séries em Md3, e o primeiro confronto sai de sorteio supervisionado pelo organizador. As vagas são distribuídas em 16 chaves de 4. Se houver menos de 64 equipes, o sorteio garante pelo menos uma equipe em cada chave, e a equipe sem adversário avança sem jogar (folga). As 16 vencedoras avançam à Fase Suíça.
- **RN11** — A Fase Suíça tem 16 equipes e séries Md1. Os confrontos da 1ª rodada são sorteados; nas seguintes, cada equipe enfrenta outra com o mesmo número de vitórias e de derrotas.
- **RN12** — Na Fase Suíça, quem chega a 3 vitórias está classificado e quem chega a 3 derrotas está eliminado. Ao fim de 5 rodadas, há exatamente 8 classificadas.
- **RN13** — Duas equipes não se enfrentam mais de uma vez na Fase Suíça.
- **RN14** — A classificação da Fase Suíça (1º ao 8º) segue o retrospecto: 3-0, depois 3-1, depois 3-2. Em caso de empate, vale, nesta ordem: (a) maior soma de vitórias dos adversários enfrentados; (b) confronto direto; (c) sorteio.
- **RN15** — As quartas dos Playoffs são 1º×8º, 4º×5º, 2º×7º e 3º×6º. Os vencedores de 1º×8º e 4º×5º se enfrentam numa semifinal, e os de 2º×7º e 3º×6º na outra. Assim, o 1º e o 2º só podem se encontrar na final.
- **RN16** — Quartas e semifinais são em Md3, e a final em Md5. Não há disputa de 3º lugar.
- **RN17** — A série termina quando uma equipe vence a maioria das partidas (1 em Md1, 2 em Md3, 3 em Md5). As partidas restantes não são jogadas.

### 5.3 Partidas

- **RN18** — Uma série envolve duas equipes diferentes, ambas aprovadas e ainda ativas no campeonato.
- **RN19** — Em cada partida, uma equipe joga no lado azul e a outra no vermelho, e o lado azul faz a primeira escolha da seleção de campeões. Na 1ª partida da série, o lado é sorteado no Play-in e na Fase Suíça; nos Playoffs, escolhe a equipe mais bem colocada na Fase Suíça. Da 2ª partida em diante, escolhe a perdedora da partida anterior.
- **RN20** — Cada equipe escala exatamente 5 jogadores por partida, um por função, entre os seus 6. O reserva pode entrar e os titulares podem trocar de função entre as partidas, nunca durante uma partida.
- **RN21** — Jogador suspenso não pode ser escalado. Na mesma partida, cada campeão aparece no máximo uma vez entre todos os banimentos e escolhas.
- **RN22** — Regra de originalidade (*fearless draft*): em séries Md3 e Md5, um campeão escolhido em uma partida não pode ser escolhido por **nenhuma das duas equipes** nas partidas seguintes da mesma série. Banimentos não contam.
- **RN23** — Uma equipe não pode ter duas partidas no mesmo horário: uma série só começa depois do término previsto da série anterior da equipe.

### 5.4 Arbitragem e resultados

- **RN24** — Cada série tem um árbitro, que não pode ser jogador nem coach do campeonato, nem ter vínculo com os cursos das duas equipes da série.
- **RN25** — O árbitro registra o vencedor e a duração de cada partida. Os dois capitães confirmam ou contestam logo após a partida. O resultado se torna oficial com as duas confirmações, ou 24 horas após o registro se ninguém contestar. Uma contestação é julgada pelo organizador. Partida reiniciada por falha técnica não é registrada: só a partida válida conta.
- **RN26** — A equipe que não estiver completa até 15 minutos após o horário marcado perde a série por W.O. O placar fica 1×0 em Md1, 2×0 em Md3 e 3×0 em Md5.
- **RN32** — Todo resultado registrado vem acompanhado da captura de tela do fim da partida.
- **RN33** — W.O. duplo: se nenhuma das duas equipes comparecer, as duas são eliminadas e a equipe que aguarda na próxima rodada avança direto. Na Fase Suíça, as duas somam uma derrota.

### 5.5 Punições, premiação e patrocínio

- **RN27** — As punições são advertência (dada à equipe), suspensão de jogador e desqualificação. A cada 3 advertências acumuladas, a equipe é suspensa da partida seguinte e perde essa partida. O árbitro ou o organizador pode suspender um jogador por 1 partida por conduta grave. A desqualificação remove a equipe, e as adversárias vencem por W.O. as séries pendentes contra ela. Na Fase Suíça, a equipe desqualificada continua sendo emparelhada e perde por W.O. até completar 3 derrotas.
- **RN28** — Antes do início do campeonato, a soma das cotas dos patrocinadores deve ser maior ou igual ao valor total da premiação. São premiadas a campeã, a vice-campeã e as duas semifinalistas, estas com o mesmo valor. Equipe desqualificada não recebe prêmio.
- **RN34** — O árbitro também pode aplicar perda da escolha de lado ou perda de um banimento na partida seguinte.
- **RN35** — Não são aceitos patrocinadores de apostas, tabaco, armas, bebidas alcoólicas, criptomoedas ou campanhas políticas, categorias vedadas pela Riot Games em torneios comunitários.

---

## 6. Estimativas de volume e frequência

**Premissas:** campeonato de cerca de 4 semanas, com jogos nos fins de semana em 4 turnos por dia (10h, 13h, 16h e 19h). Uma partida dura de 30 a 40 minutos.

### 6.1 Cadastros (cenário máximo: 64 equipes)

| Item | Conta | Volume |
|---|---|---|
| Cursos / Centros de Ensino | Apêndice A | 64 / 11 |
| Equipes | 1 por curso | 64 |
| Jogadores | 64 × 6 | 384 |
| Coaches | 0 a 1 por equipe | até 64 |
| Árbitros | 8 séries simultâneas + folga | ~12 |
| Campeões / funções | catálogo do jogo | ~170 / 5 |
| Patrocinadores | hipótese | 3 a 10 |

### 6.2 Séries e partidas

Mínimo: toda série termina no menor número possível de partidas. Máximo: toda série vai até a última partida.

| Fase | Séries | Formato | Partidas (mín.) | Partidas (máx.) |
|---|---|---|---|---|
| Play-in R1 | 32 | Md3 | 32 × 2 = 64 | 32 × 3 = 96 |
| Play-in R2 | 16 | Md3 | 16 × 2 = 32 | 16 × 3 = 48 |
| Fase Suíça (R1 a R5: 8 + 8 + 8 + 6 + 3) | 33 | Md1 | 33 | 33 |
| Quartas | 4 | Md3 | 8 | 12 |
| Semifinais | 2 | Md3 | 4 | 6 |
| Final | 1 | Md5 | 3 | 5 |
| **Total (64 equipes)** | **88** | | **144** | **200** |

- **Cenário mínimo (16 equipes):** o Play-in não tem partidas, pois todas avançam por folga. São 40 séries e de 48 a 56 partidas.
- **Comparação de formatos:** se todas as 88 séries fossem Md1, seriam 88 partidas; se fossem Md5, até 440.

### 6.3 Registros por partida e punições

| Item | Por partida | Campeonato (144 a 200 partidas) |
|---|---|---|
| Escalação (2 equipes × 5 jogadores) | 10 | 1.440 a 2.000 |
| Banimentos + escolhas (10 + 10) | 20 | 2.880 a 4.000 |
| Confirmações dos capitães | 2 | 288 a 400 |

**Punições (hipótese):** de 1 advertência a cada 10 partidas até 1 a cada 4, ou seja, de cerca de 15 a 50 advertências. Somam-se 0 a 5 suspensões e 0 a 2 desqualificações.

**Crescimento:** cada edição repete esse volume; em 5 edições, cerca de 1.000 partidas. O volume é pequeno, e o desafio do banco é garantir as regras.

### 6.4 Situações críticas

1. **1ª rodada do Play-in:** 32 séries em um dia, com até 8 árbitros registrando ao mesmo tempo (até 96 partidas e 1.920 banimentos e escolhas no dia).
2. **Registro simultâneo:** um árbitro não pode apagar o registro de outro, e uma partida não pode ficar salva pela metade.
3. **Fim de rodada da Fase Suíça:** a rodada seguinte só pode ser gerada quando todos os resultados estiverem oficiais.
4. **Final:** pico de consultas dos espectadores enquanto a série Md5 é registrada.

---

## 7. Casos de uso críticos

### UC01 — Registrar o resultado de uma partida

**Ator:** árbitro. **Participantes:** capitães.

| # | Passo | Informação | Regra | Restrição | Exceção |
|---|---|---|---|---|---|
| 1 | Abrir a série e a partida | Equipes, formato, placar | RN17, RN24 | Só o árbitro da série | Série já encerrada: bloqueia |
| 2 | Conferir a presença | Horário marcado | RN26, RN33 | Tolerância de 15 min | Ausência: W.O. (ou W.O. duplo) |
| 3 | Registrar os lados | Lado de cada equipe | RN19 | Uma equipe em cada lado | — |
| 4 | Registrar a escalação | Jogador e função | RN20, RN21 | 5 por equipe, um por função | Jogador suspenso: recusado |
| 5 | Registrar banimentos e escolhas | Campeão, tipo, ordem | RN21, RN22 | 10 banimentos e 10 escolhas, sem repetição | Campeão já escolhido na série: recusado |
| 6 | Registrar o resultado | Vencedor, duração, captura de tela | RN25, RN32 | Duração maior que zero | Partida reiniciada: só a válida é registrada |
| 7 | Pedir a confirmação | Confirmações dos capitães | RN25 | Logo após a partida | Contestação: o organizador julga |

**Resultado:** partida registrada por inteiro; série e classificação atualizadas quando o resultado fica oficial.

### UC02 — Aprovar uma inscrição

**Ator:** organizador. **Participantes:** capitão, centro acadêmico ou coordenação.

| # | Passo | Informação | Regra | Restrição | Exceção |
|---|---|---|---|---|---|
| 1 | Receber a inscrição | Curso, data de envio | RN09 | Dentro do prazo | Fora do prazo: recusada |
| 2 | Verificar o curso | Outras inscrições do curso | RN01 | Uma equipe por curso | Curso já tem equipe: recusa |
| 3 | Verificar o elenco | 6 jogadores, funções, capitão, coach | RN02, RN06, RN07 | 5 funções + 1 reserva | Elenco incompleto: recusa |
| 4 | Verificar matrículas e aval | Atestados, aval do curso | RN03, RN30 | Matrícula ativa no curso | Atestado inválido: recusa |
| 5 | Verificar duplicidades | Jogadores e Riot IDs | RN04, RN05 | Um por campeonato | Jogador em outra equipe: recusa |
| 6 | Verificar menores de idade | Data de nascimento, autorização | RN08 | Autorização obrigatória | Sem autorização: recusa |
| 7 | Decidir | Situação, data, motivo | RN09 | Recusa sempre com motivo | Recusada: pode reenviar no prazo |

**Resultado:** inscrição aprovada ou recusada; contagem de vagas atualizada.

---

## 8. Requisitos não funcionais e restrições legais, de privacidade e de segurança

### 8.1 Requisitos não funcionais

| RNF | Requisito |
|---|---|
| RNF01 | Consultas de resultados e classificação respondem em até 2 segundos em 95% dos casos, com até 300 acessos simultâneos. |
| RNF02 | O registro de uma partida é tudo ou nada: se algum item falhar, nada é gravado. |
| RNF03 | Até 8 árbitros registram ao mesmo tempo sem perda de dados. |
| RNF04 | Toda alteração em inscrição, resultado ou punição guarda quem fez, quando e o valor anterior. |
| RNF05 | Uma cópia de segurança é feita antes de cada rodada e ao fim de cada dia de jogos. |
| RNF06 | Datas e horas ficam no horário de Brasília, com precisão de minutos (para a tolerância de 15 minutos e o prazo de 24 horas). |
| RNF07 | O banco é SQLite, usado pelo SQLite Online e pelo Python (`sqlite3`), conforme a disciplina. |

### 8.2 Privacidade (LGPD)

- **Coletar só o necessário:** nome, nome de exibição, matrícula, curso, e-mail, data de nascimento (para identificar menores), Riot ID e atestado de matrícula; para menores, também os dados do responsável e a autorização. **Não coletar** CPF, RG, endereço, foto ou dados sensíveis.
- **Consentimento:** dado na inscrição, com um aviso de privacidade em linguagem simples e um termo de uso de imagem para as transmissões.
- **Menores de 18 anos:** os dados são tratados no melhor interesse do adolescente, com autorização do responsável. Publicamente aparece só o Riot ID ou o nome de exibição, nunca o nome completo nem a idade.
- **Direitos do titular:** acessar, corrigir e pedir a eliminação dos próprios dados.
- **Retenção:** atestados, autorizações, e-mails e datas de nascimento são apagados até 90 dias após o fim do campeonato. Resultados, seleção de campeões e classificação ficam guardados como histórico.
- **Carga de dados:** partidas profissionais públicas servem só de base para campeões, seleções e durações. Os nomes de jogadores reais são trocados por nomes fictícios.

### 8.3 Quem acessa o quê

| Dados | Quem acessa |
|---|---|
| Equipes, Riot IDs, escalações, seleção de campeões, resultados, classificação, punições | Todos (públicos) |
| Nome completo e e-mail dos jogadores | O próprio jogador, o capitão e o coach da equipe, o organizador |
| Matrícula, atestado, data de nascimento, autorização | O próprio titular e o organizador; o centro acadêmico ou a coordenação só confirma o vínculo |
| Cotas de patrocínio e histórico de alterações | Organizador (cada patrocinador vê a própria cota) |

### 8.4 Restrições da Riot Games

- O torneio é comunitário: deve deixar claro que **não é evento oficial** da Riot Games.
- Patrocinadores devem respeitar a RN35.
- A transmissão pode ser on-line, mas não em TV aberta.

---

## 9. Dúvidas para o cliente

Dúvidas levantadas durante a análise e a resposta do cliente para cada uma.

| # | Dúvida | Resposta do cliente |
|---|---|---|
| D01 | São mesmo 64 cursos? | Conferir no Anexo A1 do Vestibular 2027: 63 cursos no Vestibular Unificado + Letras-Libras (vestibular próprio) = 64 (Apêndice A). |
| D02 | A regra de originalidade vale para a própria equipe ou para as duas? | Para as duas equipes (RN22). |
| D03 | A advertência é dada ao jogador ou à equipe? | À equipe (RN27). |
| D04 | Quando os capitães confirmam o resultado? | Logo após a partida (RN25). |
| D05 | O que acontece no W.O. duplo? | A equipe que aguarda na próxima rodada passa direto (RN33). |
| D06 | Equipe desqualificada na Fase Suíça sai do emparelhamento? | Não: continua emparelhada e perde por W.O. (RN27). |
| D07 | As semifinalistas recebem o mesmo valor? | Sim (RN28). |
| D08 | Titulares podem trocar de função entre partidas? | Sim (RN20). |
| D09 | O campeonato adota a "First Selection" de 2026 da Riot? | Não: o lado azul faz a primeira escolha (RN19). |
| D10 | Inscrição recusada pode ser reenviada? | Sim, dentro do prazo (RN09). |
| D11 | E se não houver 64 inscrições? | Com pelo menos 16, o campeonato começa; com menos, o prazo é prorrogado ou o campeonato é cancelado (RN09, RN10). |
| D12 | Partida reiniciada por falha técnica é registrada? | Só a partida válida (RN25). |
| D13 | O coach precisa ser aluno do curso? O reserva pode ser capitão? | Sim e sim (RN07, RN06). |
| D14 | Em qual Centro fica o curso de Ciência de Dados? | CED (Apêndice A). |

---

## 10. Referências

AUTORIDADE NACIONAL DE PROTEÇÃO DE DADOS (Brasil). **Enunciado CD/ANPD nº 1, de 22 de maio de 2023**. Brasília, DF: ANPD, 2023. Disponível em: https://www.gov.br/anpd/pt-br/assuntos/noticias/anpd-divulga-enunciado-sobre-o-tratamento-de-dados-pessoais-de-criancas-e-adolescentes/Enunciado1ANPD.pdf. Acesso em: 15 nov. 2026.

BRASIL. **Lei nº 13.709, de 14 de agosto de 2018**. Lei Geral de Proteção de Dados Pessoais (LGPD). Brasília, DF: Presidência da República, 2018. Disponível em: https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm. Acesso em: 15 nov. 2026.

BRASIL. **Lei nº 8.069, de 13 de julho de 1990**. Estatuto da Criança e do Adolescente. Brasília, DF: Presidência da República, 1990. Disponível em: https://www.planalto.gov.br/ccivil_03/leis/l8069.htm. Acesso em: 15 nov. 2026.

DUTRA, Moisés Lima. **Levantamento e análise de requisitos**. Florianópolis: UFSC, 2026. Material da disciplina CIN 8003 – Bancos de Dados e Aplicações (Aula 02).

INSTITUTO FEDERAL DE PERNAMBUCO. **Regulamento específico League of Legends**: Jogos Eletrônicos das Instituições Federais, edição 2021. Vitória de Santo Antão: IFPE, 2021. Disponível em: https://portal.ifpe.edu.br/wp-content/uploads/repositoriolegado/vitoria/documentos/copy_of_RegulamentoLoLVITRIA.pdf. Acesso em: 15 nov. 2026.

RIOT GAMES. **2023 Mid-Season Invitational: official rule set**. [S. l.]: Riot Games, 2023. Disponível em: https://assets.contentstack.io/v3/assets/bltad9188aa9a70543a/blt79206b2e169458e4/644324171d4d37184e1cda9c/2023_MSI_Rule_Set_vFinal_(EN).pdf. Acesso em: 15 nov. 2026.

RIOT GAMES. **LoL Esports Community Competition Guidelines**. [S. l.]: LoL Esports, 2026. Disponível em: https://lolesports.com/en-US/news/lol-esports-community-competition-guidelines. Acesso em: 15 nov. 2026.

RIOT GAMES. **LoL Esports in 2025**. [S. l.]: LoL Esports, 2025. Disponível em: https://lolesports.com/en-US/news/lol-esports-in-2025. Acesso em: 15 nov. 2026.

UNIVERSIDADE FEDERAL DE SANTA CATARINA. **Guia de cursos UFSC**. Florianópolis: UFSC, 2023. Disponível em: https://feiradecursos.paginas.ufsc.br/files/2023/08/Guia-de-cursos-UFSC-16Revisado-com-ISBN_compressed-1.pdf. Acesso em: 15 nov. 2026.

UNIVERSIDADE FEDERAL DE SANTA CATARINA. Comissão Permanente do Vestibular. **Vestibular Unificado UFSC/IFC 2027**: Anexos A1 e A2 – quadro de cursos e vagas da UFSC. Florianópolis: COPERVE, 2026.

UNIVERSIDADE FEDERAL DE SANTA CATARINA. Comissão Permanente do Vestibular. **Edital Vestibular Letras-Libras UFSC 2027**. Florianópolis: COPERVE, 2026. Disponível em: https://vestibularlibras2027.ufsc.br/files/2026/07/Edital-Letras-Libras-2027.pdf. Acesso em: 15 nov. 2026.

UNIVERSIDADE FEDERAL DE UBERLÂNDIA. **Regulamento específico: modalidade e-sports – League of Legends (LoL)**. Olimpíada Universitária UFU 2021. Uberlândia: UFU, 2021. Disponível em: https://proae.ufu.br/sites/proae.ufu.br/files/media/arquivo/regulamento_especifico_-_league_of_legends.pdf. Acesso em: 15 nov. 2026.

---

## Apêndice A — Cursos de graduação do campus Florianópolis

**Contagem no Anexo A1 do Vestibular Unificado UFSC/IFC 2027:**
- 77 linhas (ofertas) de Florianópolis, porque alguns cursos aparecem em mais de um turno ou modalidade (ex.: Administração matutino e noturno; Física bacharelado e licenciatura);
- **63 cursos distintos**, depois de unir os turnos e as modalidades de um mesmo curso;
- **+ Letras-Libras**, presencial em Florianópolis, que tem vestibular próprio e por isso não está no Anexo A1;
- **= 64 cursos**, exatamente as vagas do cenário.

Fica de fora a Licenciatura em Educação do Campo, que tem vestibular próprio e funciona em regime de alternância. A distribuição por Centro segue o Guia de Cursos UFSC (2023); Ciência de Dados, curso novo, foi colocado no CED por decisão do cliente.

| Centro de Ensino | Cursos | Qtd. |
|---|---|---|
| **CCA** – Ciências Agrárias | Agronomia; Ciência e Tecnologia de Alimentos; Engenharia de Aquicultura; Zootecnia | 4 |
| **CCB** – Ciências Biológicas | Ciências Biológicas | 1 |
| **CCE** – Comunicação e Expressão | Animação; Artes Cênicas; Cinema; Design; Design de Produto; Jornalismo; Letras – Alemão; Letras – Espanhol; Letras – Francês; Letras – Inglês; Letras – Italiano; Letras – Libras; Letras – Português; Secretariado Executivo | 14 |
| **CCJ** – Ciências Jurídicas | Direito | 1 |
| **CCS** – Ciências da Saúde | Enfermagem; Farmácia; Fonoaudiologia; Medicina; Nutrição; Odontologia | 6 |
| **CDS** – Desportos | Educação Física | 1 |
| **CED** – Ciências da Educação | Arquivologia; Biblioteconomia; Ciência da Informação; Ciência de Dados; Pedagogia | 5 |
| **CFH** – Filosofia e Ciências Humanas | Antropologia; Ciências Sociais; Filosofia; Geografia; Geologia; História; Museologia; Psicologia | 8 |
| **CFM** – Ciências Físicas e Matemáticas | Física; Matemática; Meteorologia; Oceanografia; Química; Química Tecnológica | 6 |
| **CSE** – Socioeconômico | Administração; Ciências Contábeis; Ciências Econômicas; Relações Internacionais; Serviço Social | 5 |
| **CTC** – Tecnológico | Arquitetura e Urbanismo; Ciência da Computação; Engenharia Civil; Engenharia de Alimentos; Engenharia de Controle e Automação; Engenharia de Materiais; Engenharia de Produção; Engenharia Elétrica; Engenharia Eletrônica; Engenharia Mecânica; Engenharia Química; Engenharia Sanitária e Ambiental; Sistemas de Informação | 13 |
| | **Total** | **64** |
