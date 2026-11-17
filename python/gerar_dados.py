#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
gerar_dados.py - Simula o campeonato inteiro e grava sql/script_dml.sql.

Projeto Final - CIN 8003 Bancos de Dados e Aplicacoes (UFSC)
Autor: Mateus Nunes Oliveira

O que o programa faz (da esquerda para a direita no campeonato):
  1. cria os cadastros: cursos, centros, campeoes, arbitros, patrocinadores...
  2. cria as 64 equipes, com 6 jogadores cada, e as inscricoes;
  3. simula o Play-in, a Fase Suica e os Playoffs, partida por partida,
     respeitando as regras de negocio (RN01 a RN35);
  4. escreve tudo como comandos INSERT em sql/script_dml.sql;
  5. constroi banco/campeonato_lol_ufsc.db (DDL + DML) e confere a integridade.

Como executar (na raiz do repositorio):
    python3 python/gerar_dados.py

So usa a biblioteca padrao. A SEMENTE fixa faz o programa gerar sempre os
mesmos dados: rodar duas vezes produz arquivos identicos.

Todos os nomes de pessoas, Riot IDs, e-mails, telefones e datas sao SINTETICOS.
Cursos e Centros de Ensino sao os reais da UFSC; os campeoes sao os do jogo.
"""
import os
import random
import sqlite3
import unicodedata
from datetime import datetime, timedelta
from math import exp

# ---------------------------------------------------------------------
# 0. Configuracao
# ---------------------------------------------------------------------
SEMENTE = 20261116                      # mesma semente = mesmos dados
rng = random.Random(SEMENTE)            # TODO o sorteio passa por este objeto
CAMPEA_ESPERADA = "Ciência de Dados"     # enredo escolhido: campea e vice
VICE_ESPERADA = "Engenharia Civil"

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CAMINHO_DDL = os.path.join(RAIZ, "sql", "script_ddl.sql")
CAMINHO_DML = os.path.join(RAIZ, "sql", "script_dml.sql")
CAMINHO_DB = os.path.join(RAIZ, "banco", "campeonato_lol_ufsc.db")

ID_CAMPEONATO = 1
LINHAS_POR_INSERT = 50                  # quantas linhas em cada comando INSERT


# ---------------------------------------------------------------------
# 1. Catalogos reais: centros, cursos e campeoes
# ---------------------------------------------------------------------
CENTROS = [  # (sigla, nome)
    ("CCA", "Centro de Ciências Agrárias"),
    ("CCB", "Centro de Ciências Biológicas"),
    ("CCE", "Centro de Comunicação e Expressão"),
    ("CCJ", "Centro de Ciências Jurídicas"),
    ("CCS", "Centro de Ciências da Saúde"),
    ("CDS", "Centro de Desportos"),
    ("CED", "Centro de Ciências da Educação"),
    ("CFH", "Centro de Filosofia e Ciências Humanas"),
    ("CFM", "Centro de Ciências Físicas e Matemáticas"),
    ("CSE", "Centro Socioeconômico"),
    ("CTC", "Centro Tecnológico"),
]

CURSOS_POR_CENTRO = {  # 64 cursos (Apendice A do documento de requisitos)
    "CCA": ["Agronomia", "Ciência e Tecnologia de Alimentos", "Engenharia de Aquicultura", "Zootecnia"],
    "CCB": ["Ciências Biológicas"],
    "CCE": ["Animação", "Artes Cênicas", "Cinema", "Design", "Design de Produto", "Jornalismo",
            "Letras – Alemão", "Letras – Espanhol", "Letras – Francês", "Letras – Inglês",
            "Letras – Italiano", "Letras – Libras", "Letras – Português", "Secretariado Executivo"],
    "CCJ": ["Direito"],
    "CCS": ["Enfermagem", "Farmácia", "Fonoaudiologia", "Medicina", "Nutrição", "Odontologia"],
    "CDS": ["Educação Física"],
    "CED": ["Arquivologia", "Biblioteconomia", "Ciência da Informação", "Ciência de Dados", "Pedagogia"],
    "CFH": ["Antropologia", "Ciências Sociais", "Filosofia", "Geografia", "Geologia", "História",
            "Museologia", "Psicologia"],
    "CFM": ["Física", "Matemática", "Meteorologia", "Oceanografia", "Química", "Química Tecnológica"],
    "CSE": ["Administração", "Ciências Contábeis", "Ciências Econômicas", "Relações Internacionais",
            "Serviço Social"],
    "CTC": ["Arquitetura e Urbanismo", "Ciência da Computação", "Engenharia Civil",
            "Engenharia de Alimentos", "Engenharia de Controle e Automação", "Engenharia de Materiais",
            "Engenharia de Produção", "Engenharia Elétrica", "Engenharia Eletrônica",
            "Engenharia Mecânica", "Engenharia Química", "Engenharia Sanitária e Ambiental",
            "Sistemas de Informação"],
}

FUNCOES = ["Topo", "Selva", "Meio", "Atirador", "Suporte"]      # id_funcao 1 a 5

CAMPEOES = sorted([
    "Aatrox", "Ahri", "Akali", "Akshan", "Alistar", "Ambessa", "Amumu", "Anivia", "Annie", "Aphelios",
    "Ashe", "Aurelion Sol", "Aurora", "Azir", "Bard", "Bel'Veth", "Blitzcrank", "Brand", "Braum",
    "Briar", "Caitlyn", "Camille", "Cassiopeia", "Cho'Gath", "Corki", "Darius", "Diana", "Dr. Mundo",
    "Draven", "Ekko", "Elise", "Evelynn", "Ezreal", "Fiddlesticks", "Fiora", "Fizz", "Galio",
    "Gangplank", "Garen", "Gnar", "Gragas", "Graves", "Gwen", "Hecarim", "Heimerdinger", "Hwei",
    "Illaoi", "Irelia", "Ivern", "Janna", "Jarvan IV", "Jax", "Jayce", "Jhin", "Jinx", "K'Sante",
    "Kai'Sa", "Kalista", "Karma", "Karthus", "Kassadin", "Katarina", "Kayle", "Kayn", "Kennen",
    "Kha'Zix", "Kindred", "Kled", "Kog'Maw", "LeBlanc", "Lee Sin", "Leona", "Lillia", "Lissandra",
    "Lucian", "Lulu", "Lux", "Malphite", "Malzahar", "Maokai", "Master Yi", "Mel", "Milio",
    "Miss Fortune", "Mordekaiser", "Morgana", "Naafiri", "Nami", "Nasus", "Nautilus", "Neeko",
    "Nidalee", "Nilah", "Nocturne", "Nunu & Willump", "Olaf", "Orianna", "Ornn", "Pantheon", "Poppy",
    "Pyke", "Qiyana", "Quinn", "Rakan", "Rammus", "Rek'Sai", "Rell", "Renata Glasc", "Renekton",
    "Rengar", "Riven", "Rumble", "Ryze", "Samira", "Sejuani", "Senna", "Seraphine", "Sett", "Shaco",
    "Shen", "Shyvana", "Singed", "Sion", "Sivir", "Skarner", "Smolder", "Sona", "Soraka", "Swain",
    "Sylas", "Syndra", "Tahm Kench", "Taliyah", "Talon", "Taric", "Teemo", "Thresh", "Tristana",
    "Trundle", "Tryndamere", "Twisted Fate", "Twitch", "Udyr", "Urgot", "Varus", "Vayne", "Veigar",
    "Vel'Koz", "Vex", "Vi", "Viego", "Viktor", "Vladimir", "Volibear", "Warwick", "Wukong", "Xayah",
    "Xerath", "Xin Zhao", "Yasuo", "Yone", "Yorick", "Yunara", "Yuumi", "Zac", "Zed", "Zeri", "Ziggs",
    "Zilean", "Zoe", "Zyra",
], key=str.lower)

# Campeoes tipicos de cada funcao: deixa as escolhas verossimeis
# (Topo com Darius, Suporte com Thresh...). Banimentos saem do catalogo inteiro.
POOLS_NOMES = {
    "Topo": ["Aatrox", "Camille", "Darius", "Dr. Mundo", "Fiora", "Gangplank", "Garen", "Gnar", "Gwen",
             "Illaoi", "Irelia", "Jax", "Jayce", "K'Sante", "Kayle", "Kennen", "Kled", "Malphite",
             "Mordekaiser", "Nasus", "Ornn", "Pantheon", "Poppy", "Quinn", "Renekton", "Riven", "Rumble",
             "Sett", "Shen", "Singed", "Sion", "Teemo", "Tryndamere", "Urgot", "Volibear", "Yorick",
             "Ambessa", "Aurora", "Olaf", "Tahm Kench", "Cho'Gath", "Vladimir", "Wukong", "Maokai"],
    "Selva": ["Amumu", "Bel'Veth", "Briar", "Diana", "Ekko", "Elise", "Evelynn", "Fiddlesticks", "Gragas",
              "Graves", "Hecarim", "Ivern", "Jarvan IV", "Karthus", "Kayn", "Kha'Zix", "Kindred",
              "Lee Sin", "Lillia", "Master Yi", "Nidalee", "Nocturne", "Nunu & Willump", "Olaf", "Rammus",
              "Rek'Sai", "Rengar", "Sejuani", "Shaco", "Shyvana", "Skarner", "Taliyah", "Udyr", "Vi",
              "Viego", "Volibear", "Warwick", "Xin Zhao", "Zac", "Wukong", "Trundle", "Naafiri"],
    "Meio": ["Ahri", "Akali", "Akshan", "Anivia", "Annie", "Aurelion Sol", "Azir", "Cassiopeia", "Corki",
             "Diana", "Ekko", "Fizz", "Galio", "Hwei", "Irelia", "Kassadin", "Katarina", "LeBlanc",
             "Lissandra", "Lux", "Malzahar", "Naafiri", "Neeko", "Orianna", "Qiyana", "Ryze", "Sylas",
             "Syndra", "Taliyah", "Talon", "Twisted Fate", "Veigar", "Vex", "Viktor", "Vladimir",
             "Xerath", "Yasuo", "Yone", "Zed", "Ziggs", "Zoe", "Swain", "Mel", "Brand", "Zilean"],
    "Atirador": ["Aphelios", "Ashe", "Caitlyn", "Draven", "Ezreal", "Jhin", "Jinx", "Kai'Sa", "Kalista",
                 "Kog'Maw", "Lucian", "Miss Fortune", "Nilah", "Samira", "Sivir", "Smolder", "Tristana",
                 "Twitch", "Varus", "Vayne", "Xayah", "Zeri", "Yunara", "Corki", "Senna", "Akshan",
                 "Jayce"],
    "Suporte": ["Alistar", "Bard", "Blitzcrank", "Brand", "Braum", "Janna", "Karma", "Leona", "Lulu",
                "Milio", "Morgana", "Nami", "Nautilus", "Pyke", "Rakan", "Rell", "Renata Glasc",
                "Seraphine", "Senna", "Sona", "Soraka", "Taric", "Thresh", "Yuumi", "Zilean", "Zyra",
                "Lux", "Xerath", "Swain", "Vel'Koz", "Heimerdinger", "Maokai", "Neeko"],
}
ID_CAMPEAO = {nome: i + 1 for i, nome in enumerate(CAMPEOES)}
IDS_CAMPEOES = list(ID_CAMPEAO.values())
POOL_IDS = {}                                   # id_funcao -> lista de id_campeao
for _i, _f in enumerate(FUNCOES, start=1):
    POOL_IDS[_i] = [ID_CAMPEAO[n] for n in POOLS_NOMES[_f]]     # KeyError se algum nome estiver errado


# ---------------------------------------------------------------------
# 2. Listas para gerar pessoas sinteticas
# ---------------------------------------------------------------------
PRIMEIROS = [
    "Ana", "Beatriz", "Bruna", "Camila", "Carolina", "Clara", "Daniela", "Eduarda", "Fernanda",
    "Gabriela", "Helena", "Isabela", "Júlia", "Larissa", "Laura", "Letícia", "Luana", "Luiza",
    "Manuela", "Mariana", "Melissa", "Natália", "Paula", "Rafaela", "Renata", "Sabrina", "Tatiana",
    "Valentina", "Vitória", "Yasmin", "Alexandre", "André", "Arthur", "Bruno", "Caio", "Carlos",
    "Daniel", "Davi", "Diego", "Eduardo", "Felipe", "Fernando", "Gabriel", "Guilherme", "Gustavo",
    "Henrique", "Igor", "João", "Leonardo", "Lucas", "Marcelo", "Matheus", "Miguel", "Murilo",
    "Nicolas", "Otávio", "Pedro", "Rafael", "Rodrigo", "Samuel", "Thiago", "Vinícius", "Vítor",
]
SOBRENOMES = [
    "Silva", "Souza", "Costa", "Santos", "Pereira", "Ferreira", "Rodrigues", "Almeida", "Lima",
    "Gomes", "Ribeiro", "Carvalho", "Martins", "Araújo", "Barbosa", "Rocha", "Dias", "Moreira",
    "Cardoso", "Teixeira", "Correia", "Mendes", "Nogueira", "Freitas", "Castro", "Pinto", "Monteiro",
    "Cavalcanti", "Melo", "Campos", "Machado", "Vieira", "Borges", "Azevedo", "Fonseca", "Moura",
    "Batista", "Farias", "Duarte", "Tavares", "Andrade", "Ramos", "Lopes", "Cunha", "Siqueira",
    "Medeiros", "Prado", "Guimarães", "Xavier", "Salgado",
]
APELIDOS = [
    "Sombra", "Raio", "Lobo", "Fenix", "Drako", "Neblina", "Tempest", "Pixel", "Turbo", "Zen", "Nyx",
    "Kaze", "Blitz", "Onix", "Vulcan", "Apolo", "Zeta", "Cometa", "Lince", "Corvo", "Ember", "Nova",
    "Orbit", "Rune", "Titan", "Viper", "Atlas", "Brisa", "Duna", "Eclipse", "Fumaca", "Gelo", "Halo",
    "Ibis", "Jade", "Kraken", "Luna", "Magma", "Nimbus", "Prisma",
]
SUFIXOS = ["", "BR", "Sul", "FLN", "Pro", "X", "Jr", "One", "GG"]
TAGS = ["BR1", "FLN", "SC48", "UFSC", "LOL", "GG1", "PRO1", "ILHA", "CAMP", "MAN"]


def tirar_acentos(texto):
    """'Júlia' -> 'Julia' (para montar e-mails)."""
    base = unicodedata.normalize("NFD", texto)
    return "".join(c for c in base if unicodedata.category(c) != "Mn")


def slug(texto):
    return tirar_acentos(texto).lower().replace(" ", "").replace("'", "")


# ---------------------------------------------------------------------
# 3. "Memoria" onde as linhas ficam ate serem escritas no .sql
# ---------------------------------------------------------------------
COLUNAS = {  # mesma ordem das colunas do DDL (equipe sem id_capitao: entra por UPDATE)
    "organizador": ["id_organizador", "nome", "email", "telefone"],
    "arbitro": ["id_arbitro", "nome", "email", "telefone"],
    "centro_ensino": ["id_centro_ensino", "sigla", "nome"],
    "funcao": ["id_funcao", "nome"],
    "campeao": ["id_campeao", "nome"],
    "patrocinador": ["id_patrocinador", "nome", "ramo_atividade", "email", "telefone"],
    "curso": ["id_curso", "nome", "id_centro_ensino"],
    "vinculo_arbitro_curso": ["id_arbitro", "id_curso"],
    "campeonato": ["id_campeonato", "nome", "edicao", "prazo_inscricao", "data_inicio", "data_fim",
                   "numero_vagas", "situacao", "id_organizador"],
    "patrocinio": ["id_campeonato", "id_patrocinador", "valor_cota"],
    "premiacao": ["id_premiacao", "id_campeonato", "colocacao", "valor"],
    "fase": ["id_fase", "id_campeonato", "nome"],
    "rodada": ["id_rodada", "id_fase", "numero", "formato_serie", "data"],
    "equipe": ["id_equipe", "chave_play_in", "id_campeonato", "id_curso", "colocacao_premiacao"],
    "jogador": ["id_jogador", "nome_completo", "nome_exibicao", "matricula", "email", "data_nascimento",
                "nome_de_jogo", "tag", "riot_id_verificado", "comprovante_matricula", "nome_responsavel",
                "contato_responsavel", "documento_autorizacao", "id_equipe", "id_campeonato", "id_funcao"],
    "coach": ["id_coach", "nome", "matricula", "comprovante_matricula", "email", "telefone", "id_equipe"],
    "inscricao": ["id_inscricao", "id_equipe", "data_hora_envio", "responsavel_aval", "data_aval",
                  "id_organizador", "resultado_decisao", "data_decisao", "motivo_recusa"],
    "classificacao": ["id_classificacao", "id_fase", "posicao", "id_equipe"],
    "serie": ["id_serie", "data_hora", "id_rodada", "id_arbitro"],
    "disputa": ["id_serie", "id_equipe", "compareceu"],
    "partida": ["id_partida", "id_serie", "numero", "duracao", "captura_tela", "data_hora_registro",
                "id_equipe_azul", "id_equipe_vermelho", "id_equipe_vencedora",
                "id_organizador_julgamento", "decisao_julgamento", "data_julgamento"],
    "avaliacao_resultado": ["id_partida", "id_jogador", "parecer", "data_hora_parecer"],
    "selecao_campeao": ["id_selecao_campeao", "id_partida", "ordem", "tipo", "id_campeao", "id_equipe"],
    "escalacao": ["id_escalacao", "id_partida", "id_jogador", "id_funcao", "ordem_selecao"],
    "punicao": ["id_punicao", "tipo", "motivo", "data_hora", "id_jogador", "id_equipe",
                "id_partida_ocorrencia", "id_partida_cumprimento", "id_arbitro", "id_organizador"],
}
dados = {tabela: [] for tabela in COLUNAS}      # tabela -> lista de dicionarios (uma linha cada)
contadores = {}                                  # tabela -> ultimo id usado


def novo_id(tabela):
    contadores[tabela] = contadores.get(tabela, 0) + 1
    return contadores[tabela]


def inserir(tabela, **valores):
    """Guarda uma linha. Confere se nenhuma coluna ficou faltando ou sobrando."""
    assert set(valores) == set(COLUNAS[tabela]), (tabela, set(valores) ^ set(COLUNAS[tabela]))
    linha = dict(valores)
    dados[tabela].append(linha)
    return linha


def dh(momento):
    """datetime -> 'AAAA-MM-DD HH:MM:SS' (formato ISO 8601 do banco)."""
    return momento.strftime("%Y-%m-%d %H:%M:%S")


def dia(momento):
    return momento.strftime("%Y-%m-%d")


def telefone():
    """Numero inexistente (prefixo 90000) para nao coincidir com ninguem."""
    return "(48) 90000-%04d" % rng.randint(0, 9999)


# ---------------------------------------------------------------------
# 4. Cadastros: organizadores, arbitros, centros, cursos, campeoes, patrocinadores
# ---------------------------------------------------------------------
nomes_usados = set()
matriculas_usadas = set()
emails_usados = set()


def nome_pessoa():
    """Nome completo sintetico e unico no banco inteiro."""
    while True:
        primeiro = rng.choice(PRIMEIROS)
        s1, s2 = rng.sample(SOBRENOMES, 2)
        nome = "%s %s %s" % (primeiro, s1, s2)
        if nome not in nomes_usados:
            nomes_usados.add(nome)
            return nome


def matricula():
    """8 digitos (ano de ingresso + numero), unica."""
    while True:
        m = "%d%06d" % (rng.randint(20, 26), rng.randint(100000, 999999))
        if m not in matriculas_usadas:
            matriculas_usadas.add(m)
            return m


def email_de(nome, dominio):
    partes = nome.split()
    while True:
        e = "%s.%s%d@%s" % (slug(partes[0]), slug(partes[-1]), rng.randint(1, 99), dominio)
        if e not in emails_usados:
            emails_usados.add(e)
            return e


def criar_cadastros():
    # Organizadores: 1 cria o campeonato e decide a maioria; 2 divide as decisoes.
    for i in (1, 2):
        nome = nome_pessoa()
        inserir("organizador", id_organizador=i, nome=nome,
                email=email_de(nome, "organizacao.example.com"), telefone=telefone())

    # Centros de Ensino e cursos (id_curso = posicao na lista; id_equipe sera o mesmo numero)
    id_curso = 0
    for id_centro, (sigla, nome) in enumerate(CENTROS, start=1):
        inserir("centro_ensino", id_centro_ensino=id_centro, sigla=sigla, nome=nome)
        for nome_curso in CURSOS_POR_CENTRO[sigla]:
            id_curso += 1
            inserir("curso", id_curso=id_curso, nome=nome_curso, id_centro_ensino=id_centro)
    assert id_curso == 64

    for i, nome in enumerate(FUNCOES, start=1):
        inserir("funcao", id_funcao=i, nome=nome)
    for nome, i in ID_CAMPEAO.items():
        inserir("campeao", id_campeao=i, nome=nome)

    # Arbitros: 12, cada um com vinculo com 1 a 3 cursos (RN24: nao apita esses cursos)
    vinculos = {}
    for i in range(1, 13):
        nome = nome_pessoa()
        inserir("arbitro", id_arbitro=i, nome=nome, email=email_de(nome, "arbitragem.example.com"),
                telefone=telefone() if i % 4 else None)          # alguns sem telefone (NULL)
        vinculos[i] = set(rng.sample(range(1, 65), rng.randint(1, 3)))
        for c in sorted(vinculos[i]):
            inserir("vinculo_arbitro_curso", id_arbitro=i, id_curso=c)
    return vinculos


def criar_patrocinio_e_premiacao():
    patrocinadores = [  # (nome fictício, ramo, e-mail, cota em centavos ou None)
        ("Ilha Gamer Hardware", "hardware", "contato@ilhagamer.example.com", 600000),
        ("Sul Digital Telecom", "telecomunicacoes", "contato@suldigital.example.com", 450000),
        ("Manezinho Café e Lanches", "alimentacao", "contato@manezinhocafe.example.com", 300000),
        ("Floripa Energy Drink", "bebidas_nao_alcoolicas", "contato@floripaenergy.example.com", 250000),
        ("Cursinho Aprova Já", "educacao", "contato@aprovaja.example.com", 200000),
        ("Barriga Verde Seguros", "seguros", "contato@barrigaverde.example.com", None),  # sem cota nesta edição
    ]
    for i, (nome, ramo, email, cota) in enumerate(patrocinadores, start=1):
        inserir("patrocinador", id_patrocinador=i, nome=nome, ramo_atividade=ramo, email=email,
                telefone=telefone() if cota else None)
        if cota:
            inserir("patrocinio", id_campeonato=ID_CAMPEONATO, id_patrocinador=i, valor_cota=cota)
    # RN28: premiacao = 8.000 + 4.000 + 2 x 2.000 = 16.000 reais; cotas somam 18.000
    for colocacao, valor in ((1, 800000), (2, 400000), (3, 200000)):
        inserir("premiacao", id_premiacao=colocacao, id_campeonato=ID_CAMPEONATO,
                colocacao=colocacao, valor=valor)


# ---------------------------------------------------------------------
# 5. Equipes, jogadores, coaches e inscricoes
# ---------------------------------------------------------------------
EQUIPES = {}     # id_equipe -> dados da equipe usados na simulacao
CAPITAO = {}     # id_equipe -> id_jogador


def criar_equipes(chaves):
    riot_ids = set()
    id_jogador = 0
    for id_equipe in range(1, 65):
        chave = next(c for c, ts in chaves.items() if id_equipe in ts)
        inserir("equipe", id_equipe=id_equipe, chave_play_in=chave, id_campeonato=ID_CAMPEONATO,
                id_curso=id_equipe, colocacao_premiacao=None)    # colocacao entra no fim da simulacao
        titulares = {}
        todos = []
        for id_funcao in (1, 2, 3, 4, 5, None):                  # None = reserva
            id_jogador += 1
            nome = nome_pessoa()
            while True:                                          # Riot ID unico no campeonato (RN05)
                nome_de_jogo = rng.choice(APELIDOS) + rng.choice(SUFIXOS) + str(rng.randint(1, 99))
                tag = rng.choice(TAGS)
                if len(nome_de_jogo) <= 16 and (nome_de_jogo, tag) not in riot_ids:
                    riot_ids.add((nome_de_jogo, tag))
                    break
            mat = matricula()
            partes = nome.split()
            inserir("jogador", id_jogador=id_jogador, nome_completo=nome,
                    nome_exibicao="%s %s." % (partes[0], partes[-1][0]), matricula=mat,
                    email=email_de(nome, "aluno.example.com"),
                    data_nascimento="%d-%02d-%02d" % (rng.randint(2000, 2007), rng.randint(1, 12), rng.randint(1, 28)),
                    nome_de_jogo=nome_de_jogo, tag=tag, riot_id_verificado=1,
                    comprovante_matricula="comprovantes/%s.pdf" % mat,
                    nome_responsavel=None, contato_responsavel=None, documento_autorizacao=None,
                    id_equipe=id_equipe, id_campeonato=ID_CAMPEONATO, id_funcao=id_funcao)
            todos.append(id_jogador)
            if id_funcao:
                titulares[id_funcao] = id_jogador
        reserva = todos[-1]
        CAPITAO[id_equipe] = rng.choice(todos)                   # qualquer um dos 6 (RN06)
        EQUIPES[id_equipe] = {"titulares": titulares, "reserva": reserva, "todos": todos,
                              "forca": rng.gauss(0, 1)}


def fixar_favoritas():
    """Define o enredo: Ciencia de Dados e a mais forte e Engenharia Civil a segunda mais forte.
    So muda a 'forca' das duas equipes; as partidas continuam sendo sorteadas pela formula de vitoria."""
    id_curso = {c["nome"]: c["id_curso"] for c in dados["curso"]}
    equipe_do_curso = {e["id_curso"]: e["id_equipe"] for e in dados["equipe"]}
    EQUIPES[equipe_do_curso[id_curso[CAMPEA_ESPERADA]]]["forca"] = 5.0
    EQUIPES[equipe_do_curso[id_curso[VICE_ESPERADA]]]["forca"] = 4.0


def ajustar_jogadores_especiais():
    """Menores de idade (RN08) e pedidos de eliminacao de dados (LGPD, RF17)."""
    jogadores = dados["jogador"]
    # 6 menores de idade, em 6 equipes diferentes (nascidos entre 10/2008 e 08/2009: 17 anos em set/2026)
    equipes_menores = rng.sample(range(1, 65), 6)
    menores = []
    for eq in equipes_menores:
        j = jogadores[EQUIPES[eq]["todos"][rng.randint(0, 4)] - 1]
        j["data_nascimento"] = "%d-%02d-%02d" % (rng.choice([2008, 2009]), rng.randint(10, 12), rng.randint(1, 28))
        if j["data_nascimento"].startswith("2009"):
            j["data_nascimento"] = "2009-%02d-%02d" % (rng.randint(1, 8), rng.randint(1, 28))
        nome_resp = nome_pessoa()
        j["nome_responsavel"] = nome_resp
        j["contato_responsavel"] = telefone()
        j["documento_autorizacao"] = "autorizacoes/%s.pdf" % j["matricula"]
        menores.append(eq)
    # 5 jogadores maiores pediram a eliminacao dos dados pessoais (e-mail, nascimento, comprovante = NULL)
    candidatos = [j for j in jogadores if j["nome_responsavel"] is None]
    for j in rng.sample(candidatos, 5):
        j["email"] = None
        j["data_nascimento"] = None
        j["comprovante_matricula"] = None
    return menores


def criar_coaches():
    equipes_com_coach = sorted(rng.sample(range(1, 65), 44))     # as outras 20 equipes ficam sem coach
    for i, eq in enumerate(equipes_com_coach, start=1):
        nome = nome_pessoa()
        mat = matricula()                                        # matricula propria: nao e jogador (RN07)
        inserir("coach", id_coach=i, nome=nome, matricula=mat,
                comprovante_matricula="comprovantes/%s.pdf" % mat if i % 11 else None,
                email=email_de(nome, "aluno.example.com") if i % 7 else None,
                telefone=telefone() if i % 3 else None, id_equipe=eq)


def criar_inscricoes(equipes_menores):
    prazo = datetime(2026, 9, 30, 23, 59, 0)
    recusas = [  # (motivo, a recusa tambem deixa o aval em branco?)
        ("Aval do centro acadêmico ausente", True),
        ("Atestado de matrícula do semestre anterior", False),
        ("Riot ID de um jogador ainda não verificado", False),
        ("Matrícula de um jogador inativa no curso", False),
        ("Falta a função de um titular no formulário", False),
        ("Autorização do responsável ausente para jogador menor de 18 anos", False),
    ]
    # a recusa por falta de autorizacao precisa de uma equipe com jogador menor
    eq_menor = equipes_menores[0]
    outras = rng.sample([e for e in range(1, 65) if e != eq_menor], 5)
    recusadas = dict(zip(outras, recusas[:5]))
    recusadas[eq_menor] = recusas[5]
    id_insc = 0
    for eq in range(1, 65):
        curso = dados["curso"][eq - 1]["nome"]
        quem = rng.choice(["Coordenação do curso de %s", "Centro Acadêmico de %s"]) % curso
        org = rng.choice([1, 1, 2])
        if eq in recusadas:
            motivo, sem_aval = recusadas[eq]
            envio1 = datetime(2026, 9, rng.randint(1, 12), rng.randint(8, 21), rng.randint(0, 59), rng.randint(0, 59))
            decisao1 = envio1 + timedelta(days=rng.randint(1, 3), hours=rng.randint(0, 5))
            id_insc += 1
            inserir("inscricao", id_inscricao=id_insc, id_equipe=eq, data_hora_envio=dh(envio1),
                    responsavel_aval=None if sem_aval else quem,
                    data_aval=None if sem_aval else dia(envio1 - timedelta(days=rng.randint(0, 2))),
                    id_organizador=org, resultado_decisao="recusada", data_decisao=dh(decisao1),
                    motivo_recusa=motivo)
            envio = decisao1 + timedelta(days=rng.randint(1, 5), hours=rng.randint(1, 6))   # reenvio
        else:
            envio = datetime(2026, 9, rng.randint(1, 28), rng.randint(8, 21), rng.randint(0, 59), rng.randint(0, 59))
        assert envio <= prazo
        decisao = envio + timedelta(days=rng.randint(1, 4), hours=rng.randint(0, 6))
        id_insc += 1
        inserir("inscricao", id_inscricao=id_insc, id_equipe=eq, data_hora_envio=dh(envio),
                responsavel_aval=quem, data_aval=dia(envio - timedelta(days=rng.randint(0, 3))),
                id_organizador=org, resultado_decisao="aprovada", data_decisao=dh(decisao), motivo_recusa=None)


# ---------------------------------------------------------------------
# 6. Planos especiais (casos de borda das regras)
# ---------------------------------------------------------------------
# Um "plano" diz como a serie de uma equipe-foco termina, partida a partida:
#   "W" = a equipe-foco vence a partida;  "L" = perde;
#   "S" = perde SEM JOGAR, por estar suspensa (3 advertencias, RN27).
PLANOS = {}
EVENTOS = {}      # (fase, rodada, equipe, numero_da_partida) -> lista de ocorrencias
CHAVE_WO = 5            # Play-in R1: uma equipe nao comparece (W.O. simples, RN26)
CHAVE_WO_DUPLO = 11     # Play-in R1: nenhuma comparece (W.O. duplo, RN33)


def definir_planos(chaves):
    t_jogador_susp = chaves[2][0]    # jogador suspenso 1 partida (RN21/RN27)
    t_susp_md3 = chaves[3][0]        # 3 advertencias no Play-in -> partida perdida no meio de uma Md3
    t_susp_md1 = chaves[8][0]        # 3 advertencias (a 3a na Fase Suica) -> serie Md1 perdida
    t_desq = chaves[14][0]           # desqualificada depois da 2a rodada da Fase Suica
    PLANOS[("play_in", 1, t_jogador_susp)] = ["W", "L", "W"]
    EVENTOS[("play_in", 1, t_jogador_susp, 1)] = ["suspensao_jogador"]
    PLANOS[("play_in", 1, t_susp_md3)] = ["W", "W"]
    PLANOS[("play_in", 2, t_susp_md3)] = ["W", "S", "W"]
    EVENTOS[("play_in", 1, t_susp_md3, 1)] = ["advertencia"]
    EVENTOS[("play_in", 1, t_susp_md3, 2)] = ["advertencia"]
    EVENTOS[("play_in", 2, t_susp_md3, 1)] = ["advertencia"]            # a 3a
    PLANOS[("play_in", 1, t_susp_md1)] = ["W", "W"]
    PLANOS[("play_in", 2, t_susp_md1)] = ["W", "W"]
    PLANOS[("fase_suica", 1, t_susp_md1)] = ["W"]
    PLANOS[("fase_suica", 2, t_susp_md1)] = ["S"]
    EVENTOS[("play_in", 1, t_susp_md1, 1)] = ["advertencia"]
    EVENTOS[("play_in", 2, t_susp_md1, 1)] = ["advertencia"]
    EVENTOS[("fase_suica", 1, t_susp_md1, 1)] = ["advertencia"]         # a 3a
    PLANOS[("play_in", 1, t_desq)] = ["W", "W"]
    PLANOS[("play_in", 2, t_desq)] = ["W", "W"]
    PLANOS[("fase_suica", 1, t_desq)] = ["W"]
    PLANOS[("fase_suica", 2, t_desq)] = ["L"]
    return {"jogador_susp": t_jogador_susp, "susp_md3": t_susp_md3, "susp_md1": t_susp_md1, "desq": t_desq}


def conflito_plano(fase, numero, a, b):
    """Duas equipes com plano na mesma rodada nao se enfrentam (os planos se contradiriam)."""
    return (fase, numero, a) in PLANOS and (fase, numero, b) in PLANOS


# ---------------------------------------------------------------------
# 7. Simulacao: series e partidas
# ---------------------------------------------------------------------
FASE_ID = {"play_in": 1, "fase_suica": 2, "playoffs": 3}
MAIORIA = {"Md1": 1, "Md3": 2, "Md5": 3}
MOTIVOS_ADVERTENCIA = [
    "Atraso na confirmação da escalação", "Linguagem imprópria no chat da partida",
    "Pausa não autorizada durante a partida", "Descumprimento do protocolo de seleção de campeões",
    "Comportamento antidesportivo contra adversários", "Uso de programa de terceiros não permitido na transmissão",
]
POSICAO_SUICA = {}          # id_equipe -> posicao (1 a 8) na classificacao da Fase Suica
ARBITRO_DA_SERIE = {}
SERIES = {}                 # id_serie -> informacoes para os passos finais
PARTIDAS = {}               # id_partida -> informacoes
ULTIMA_PARTIDA = {}         # (fase, rodada, equipe) -> {"serie": id, "partidas": [ids]}
SUSPENSO_PENDENTE = {}      # equipe -> (jogador, linha da punicao) a cumprir na proxima partida
ADV_PENDENTE = {}           # equipe -> linha da 3a advertencia, cumprida na proxima partida
ADV_CONTADOR = {}           # equipe -> numero de advertencias
ARBITRO_VINCULOS = {}


def sortear_arbitros(grupo):
    """Um arbitro diferente para cada serie do mesmo horario, sem vinculo com os dois cursos (RN24)."""
    for _ in range(500):
        usados, escolhidos, ok = set(), [], True
        for c in grupo:
            candidatos = [a for a in range(1, 13)
                          if a not in usados and not (ARBITRO_VINCULOS[a] & {c["a"], c["b"]})]
            if not candidatos:
                ok = False
                break
            a = rng.choice(candidatos)
            usados.add(a)
            escolhidos.append(a)
        if ok:
            return escolhidos
    raise RuntimeError("nao foi possivel designar arbitros")


def montar_escala(eq, numero, fora):
    """Quem joga a partida: os 5 titulares, com trocas de funcao e o reserva em alguns casos (RN20)."""
    e = EQUIPES[eq]
    escala = dict(e["titulares"])                     # funcao -> jogador
    if fora:                                          # suspenso nao joga: o reserva entra (RN21)
        for f, j in escala.items():
            if j in fora:
                escala[f] = e["reserva"]
        return escala
    if numero >= 2:                                   # trocas so entre partidas, nunca durante uma
        if rng.random() < 0.12:
            f1, f2 = rng.sample(list(escala), 2)
            escala[f1], escala[f2] = escala[f2], escala[f1]
        if rng.random() < 0.10:
            escala[rng.choice(list(escala))] = e["reserva"]
    return escala


# Ordem da selecao de campeoes (20 passos): 'a' = lado azul, 'v' = vermelho.
# O azul abre a selecao (RN19): banimentos 1-6, escolhas 7-12, banimentos 13-16, escolhas 17-20.
ORDEM_LADO = {1: "a", 2: "v", 3: "a", 4: "v", 5: "a", 6: "v", 7: "a", 8: "v", 9: "v", 10: "a", 11: "a",
              12: "v", 13: "v", 14: "a", 15: "v", 16: "a", 17: "v", 18: "a", 19: "a", 20: "v"}
ORDEM_TIPO = {o: ("banimento" if o in (1, 2, 3, 4, 5, 6, 13, 14, 15, 16) else "escolha") for o in range(1, 21)}


def sortear_selecao(id_partida, azul, vermelho, escala, bloqueados):
    """Gera os 20 passos da selecao e a escalacao. Devolve os campeoes escolhidos (nao os banidos)."""
    time_do_lado = {"a": azul, "v": vermelho}
    funcao_da_ordem = {}
    for lado, eq in time_do_lado.items():
        ordens = [o for o in range(1, 21) if ORDEM_TIPO[o] == "escolha" and ORDEM_LADO[o] == lado]
        funcoes = list(escala[eq])
        rng.shuffle(funcoes)
        funcao_da_ordem.update(zip(ordens, funcoes))
    usados, escolhidos = set(), set()
    for o in range(1, 21):
        eq = time_do_lado[ORDEM_LADO[o]]
        if ORDEM_TIPO[o] == "banimento":
            opcoes = [c for c in IDS_CAMPEOES if c not in usados and c not in bloqueados]
        else:
            f = funcao_da_ordem[o]
            opcoes = [c for c in POOL_IDS[f] if c not in usados and c not in bloqueados]
            if not opcoes:
                opcoes = [c for c in IDS_CAMPEOES if c not in usados and c not in bloqueados]
        campeao = rng.choice(opcoes)
        usados.add(campeao)
        inserir("selecao_campeao", id_selecao_campeao=novo_id("selecao_campeao"), id_partida=id_partida,
                ordem=o, tipo=ORDEM_TIPO[o], id_campeao=campeao, id_equipe=eq)
        if ORDEM_TIPO[o] == "escolha":
            escolhidos.add(campeao)
            inserir("escalacao", id_escalacao=novo_id("escalacao"), id_partida=id_partida,
                    id_jogador=escala[eq][f], id_funcao=f, ordem_selecao=o)
    return escolhidos


def lados_da_partida(nome_fase, numero, ta, tb, perdedora_anterior):
    """Quem joga de azul (RN19). Devolve ((azul, vermelho), equipe_que_escolheu_ou_None)."""
    if numero == 1 and nome_fase != "playoffs":
        return ((ta, tb) if rng.random() < 0.5 else (tb, ta)), None         # sorteio
    if numero == 1:
        escolhe = ta if POSICAO_SUICA[ta] < POSICAO_SUICA[tb] else tb       # melhor colocada na Fase Suica
    else:
        escolhe = perdedora_anterior                                         # perdedora da partida anterior
    outro = tb if escolhe == ta else ta
    if rng.random() < 0.75:                                                  # quem escolhe prefere o azul
        return (escolhe, outro), escolhe
    return (outro, escolhe), escolhe


def registrar_punicao(tipo, motivo, momento, **alvo):
    linha = {"id_punicao": None, "tipo": tipo, "motivo": motivo, "data_hora": dh(momento),
             "id_jogador": None, "id_equipe": None, "id_partida_ocorrencia": None,
             "id_partida_cumprimento": None, "id_arbitro": None, "id_organizador": None}
    linha.update(alvo)
    dados["punicao"].append(linha)
    return linha


def advertir(equipe, id_partida, id_serie, momento):
    linha = registrar_punicao("advertencia", rng.choice(MOTIVOS_ADVERTENCIA), momento, id_equipe=equipe,
                              id_partida_ocorrencia=id_partida, id_arbitro=ARBITRO_DA_SERIE[id_serie])
    ADV_CONTADOR[equipe] = ADV_CONTADOR.get(equipe, 0) + 1
    if ADV_CONTADOR[equipe] % 3 == 0:                  # 3 advertencias: suspensa da proxima partida
        ADV_PENDENTE[equipe] = linha
    return linha


def jogar_serie(nome_fase, numero_rodada, formato, inicio, id_rodada, id_arbitro, c):
    """Cria a serie, as duas linhas de disputa e (se nao for W.O.) as partidas. Devolve o resultado."""
    ta, tb = c["a"], c["b"]
    id_serie = novo_id("serie")
    inserir("serie", id_serie=id_serie, data_hora=dh(inicio), id_rodada=id_rodada, id_arbitro=id_arbitro)
    ARBITRO_DA_SERIE[id_serie] = id_arbitro
    wo = c.get("wo")                                   # None, 'a' (a faltou), 'b' (b faltou) ou 'dupla'
    SERIES[id_serie] = {"fase": nome_fase, "rodada": numero_rodada, "a": ta, "b": tb, "inicio": inicio,
                        "formato": formato, "partidas": [], "wo": wo}
    ULTIMA_PARTIDA[(nome_fase, numero_rodada, ta)] = {"serie": id_serie, "partidas": []}
    ULTIMA_PARTIDA[(nome_fase, numero_rodada, tb)] = {"serie": id_serie, "partidas": []}

    if wo:                                             # nao ha partidas: so o comparecimento (RN26, RN33)
        if wo == "a":
            comp_a, comp_b = 0, 1
        elif wo == "b":
            comp_a, comp_b = 1, 0
        else:
            comp_a, comp_b = 0, 0
        inserir("disputa", id_serie=id_serie, id_equipe=ta, compareceu=comp_a)
        inserir("disputa", id_serie=id_serie, id_equipe=tb, compareceu=comp_b)
        if wo == "dupla":
            return {"serie": id_serie, "vencedora": None, "perdedora": None, "wo": wo}
        venc, perd = (tb, ta) if wo == "a" else (ta, tb)
        return {"serie": id_serie, "vencedora": venc, "perdedora": perd, "wo": wo}

    inserir("disputa", id_serie=id_serie, id_equipe=ta, compareceu=1)
    inserir("disputa", id_serie=id_serie, id_equipe=tb, compareceu=1)

    maioria = MAIORIA[formato]
    plano_a = PLANOS.get((nome_fase, numero_rodada, ta))
    plano_b = PLANOS.get((nome_fase, numero_rodada, tb))
    assert not (plano_a and plano_b), "dois planos na mesma serie"
    foco, plano = (ta, plano_a) if plano_a else ((tb, plano_b) if plano_b else (None, None))
    vitorias = {ta: 0, tb: 0}
    bloqueados = set()                                  # campeoes escolhidos antes na serie (RN22)
    perdedora_anterior = None
    n = 0
    while max(vitorias.values()) < maioria:
        n += 1
        suspensa = None
        if plano:
            token = plano[n - 1]
            outro = tb if foco == ta else ta
            venc = foco if token == "W" else outro
            if token == "S":
                suspensa = foco
        else:
            p_a = 1 / (1 + exp(-(EQUIPES[ta]["forca"] - EQUIPES[tb]["forca"]) * 0.9))
            venc = ta if rng.random() < p_a else tb
        perd = tb if venc == ta else ta
        vitorias[venc] += 1
        id_partida = novo_id("partida")
        inicio_p = inicio + timedelta(minutes=55 * (n - 1))
        if suspensa:                                    # partida perdida por suspensao: sem lados (RN27)
            registro = inicio_p + timedelta(minutes=5)
            inserir("partida", id_partida=id_partida, id_serie=id_serie, numero=n, duracao=None,
                    captura_tela=None, data_hora_registro=dh(registro), id_equipe_azul=None,
                    id_equipe_vermelho=None, id_equipe_vencedora=venc, id_organizador_julgamento=None,
                    decisao_julgamento=None, data_julgamento=None)
            ADV_PENDENTE.pop(suspensa)["id_partida_cumprimento"] = id_partida
            PARTIDAS[id_partida] = {"serie": id_serie, "numero": n, "azul": None, "vermelho": None,
                                    "venc": venc, "inicio": inicio_p, "registro": registro}
        else:
            (azul, vermelho), escolhe = lados_da_partida(nome_fase, n, ta, tb, perdedora_anterior)
            fora = {}
            for eq in (azul, vermelho):
                if eq in SUSPENSO_PENDENTE:             # jogador suspenso: cumpre nesta partida
                    jogador, linha = SUSPENSO_PENDENTE.pop(eq)
                    linha["id_partida_cumprimento"] = id_partida
                    fora[eq] = {jogador}
            escala = {eq: montar_escala(eq, n, fora.get(eq, set())) for eq in (azul, vermelho)}
            duracao = int(min(2700, max(1500, rng.gauss(2000, 330))))
            registro = inicio_p + timedelta(minutes=10, seconds=duracao + 120)
            inserir("partida", id_partida=id_partida, id_serie=id_serie, numero=n, duracao=duracao,
                    captura_tela="capturas/serie%03d_partida%d.png" % (id_serie, n),
                    data_hora_registro=dh(registro), id_equipe_azul=azul, id_equipe_vermelho=vermelho,
                    id_equipe_vencedora=venc, id_organizador_julgamento=None, decisao_julgamento=None,
                    data_julgamento=None)
            escolhidos = sortear_selecao(id_partida, azul, vermelho, escala, bloqueados)
            if formato != "Md1":
                bloqueados |= escolhidos                # RN22: vale para as duas equipes
            PARTIDAS[id_partida] = {"serie": id_serie, "numero": n, "azul": azul, "vermelho": vermelho,
                                    "venc": venc, "inicio": inicio_p, "registro": registro, "escolhe": escolhe}
            avaliar(id_partida, azul, vermelho, registro)
            # ocorrencias planejadas (advertencias e suspensao de jogador)
            for eq in (azul, vermelho):
                for tipo in EVENTOS.get((nome_fase, numero_rodada, eq, n), []):
                    momento = inicio_p + timedelta(minutes=25)
                    if tipo == "advertencia":
                        advertir(eq, id_partida, id_serie, momento)
                    else:                               # suspensao do titular de Meio por conduta grave
                        jogador = EQUIPES[eq]["titulares"][3]
                        linha = registrar_punicao(
                            "suspensao_jogador", "Conduta antidesportiva grave contra adversário no chat",
                            momento, id_jogador=jogador, id_partida_ocorrencia=id_partida,
                            id_arbitro=id_arbitro)
                        SUSPENSO_PENDENTE[eq] = (jogador, linha)
        SERIES[id_serie]["partidas"].append(id_partida)
        ULTIMA_PARTIDA[(nome_fase, numero_rodada, ta)]["partidas"].append(id_partida)
        ULTIMA_PARTIDA[(nome_fase, numero_rodada, tb)]["partidas"].append(id_partida)
        perdedora_anterior = perd
    if plano:
        assert n == len(plano), ("plano nao bate com a serie", nome_fase, numero_rodada, foco, plano, n)
    venc = ta if vitorias[ta] == maioria else tb
    return {"serie": id_serie, "vencedora": venc, "perdedora": tb if venc == ta else ta, "wo": None}


def avaliar(id_partida, azul, vermelho, registro):
    """Capitaes confirmam o resultado logo apos a partida (RN25). Alguns nao respondem."""
    r = rng.random()
    capitaes = [CAPITAO[azul], CAPITAO[vermelho]]
    if r < 0.08:
        respondem = []                                  # ninguem respondeu: oficial em 24 h
    elif r < 0.20:
        respondem = [rng.choice(capitaes)]
    else:
        respondem = capitaes
    for j in respondem:
        inserir("avaliacao_resultado", id_partida=id_partida, id_jogador=j, parecer="confirmado",
                data_hora_parecer=dh(registro + timedelta(minutes=rng.randint(1, 20), seconds=rng.randint(0, 59))))


def jogar_rodada(nome_fase, numero, formato, data, horarios, confrontos):
    """Agenda os confrontos nos horarios, designa arbitros e simula cada serie."""
    id_rodada = novo_id("rodada")
    inserir("rodada", id_rodada=id_rodada, id_fase=FASE_ID[nome_fase], numero=numero,
            formato_serie=formato, data=data)
    ordem = confrontos[:]
    rng.shuffle(ordem)
    por_horario = -(-len(ordem) // len(horarios))      # divisao para cima
    for k, hora in enumerate(horarios):
        grupo = ordem[k * por_horario:(k + 1) * por_horario]
        if not grupo:
            continue
        inicio = datetime.strptime("%s %s" % (data, hora), "%Y-%m-%d %H:%M")
        for c, arbitro in zip(grupo, sortear_arbitros(grupo)):
            c["res"] = jogar_serie(nome_fase, numero, formato, inicio, id_rodada, arbitro, c)
    return confrontos


# ---------------------------------------------------------------------
# 8. As tres fases
# ---------------------------------------------------------------------
def fase_play_in(chaves):
    # Rodada 1: em cada chave de 4 equipes, dois confrontos (RN10)
    confrontos = []
    for c in range(1, 17):
        t = chaves[c]
        wo1 = "b" if c == CHAVE_WO else ("dupla" if c == CHAVE_WO_DUPLO else None)
        confrontos.append({"chave": c, "n": 1, "a": t[0], "b": t[1], "wo": wo1})
        confrontos.append({"chave": c, "n": 2, "a": t[2], "b": t[3], "wo": None})
    jogar_rodada("play_in", 1, "Md3", "2026-10-03", ["10:00", "13:00", "16:00", "19:00"], confrontos)
    resultado = {(c["chave"], c["n"]): c["res"] for c in confrontos}
    # Rodada 2: vencedora x vencedora da mesma chave; no W.O. duplo a outra avanca direto (folga)
    segunda, avancam = [], []
    for c in range(1, 17):
        v1, v2 = resultado[(c, 1)]["vencedora"], resultado[(c, 2)]["vencedora"]
        if v1 is None:
            avancam.append(v2)
        else:
            assert v2 is not None
            segunda.append({"chave": c, "n": 1, "a": v1, "b": v2, "wo": None})
    jogar_rodada("play_in", 2, "Md3", "2026-10-04", ["10:00", "13:00"], segunda)
    avancam += [c["res"]["vencedora"] for c in segunda]
    assert len(avancam) == 16
    return avancam


def emparelhar(grupo, proibido):
    """Sorteia pares dentro do grupo sem repetir confronto (RN13). Usa tentativa e erro com retrocesso."""
    def casar(lista):
        if not lista:
            return []
        a = lista[0]
        candidatos = [b for b in lista[1:] if not proibido(a, b)]
        rng.shuffle(candidatos)
        for b in candidatos:
            resto = [x for x in lista if x != a and x != b]
            r = casar(resto)
            if r is not None:
                return [(a, b)] + r
        return None
    for _ in range(300):
        lista = grupo[:]
        rng.shuffle(lista)
        pares = casar(lista)
        if pares is not None:
            return pares
    raise RuntimeError("sem emparelhamento possivel")


def fase_suica(times, desq):
    campanha = {t: [0, 0] for t in times}          # [vitorias, derrotas]
    adversarios = {t: [] for t in times}
    ja_jogaram = set()
    h2h = {}                                       # frozenset({a, b}) -> vencedora
    desqualificadas = set()
    datas = {1: "2026-10-17", 2: "2026-10-18", 3: "2026-10-24", 4: "2026-10-25", 5: "2026-10-31"}
    horarios = {1: ["13:00", "16:00"], 2: ["13:00", "16:00"], 3: ["13:00", "16:00"],
                4: ["13:00", "16:00"], 5: ["16:00"]}
    for numero in range(1, 6):
        ativos = [t for t in times if campanha[t][0] < 3 and campanha[t][1] < 3]
        grupos = {}
        for t in ativos:
            grupos.setdefault(tuple(campanha[t]), []).append(t)    # mesmo retrospecto (RN11)
        proibido = lambda a, b: frozenset((a, b)) in ja_jogaram or conflito_plano("fase_suica", numero, a, b)
        confrontos = []
        for chave in sorted(grupos):
            for a, b in emparelhar(grupos[chave], proibido):
                wo = "a" if a in desqualificadas else ("b" if b in desqualificadas else None)
                confrontos.append({"a": a, "b": b, "wo": wo})
        jogar_rodada("fase_suica", numero, "Md1", datas[numero], horarios[numero], confrontos)
        for c in confrontos:
            v, p = c["res"]["vencedora"], c["res"]["perdedora"]
            campanha[v][0] += 1
            campanha[p][1] += 1
            adversarios[c["a"]].append(c["b"])
            adversarios[c["b"]].append(c["a"])
            ja_jogaram.add(frozenset((c["a"], c["b"])))
            h2h[frozenset((c["a"], c["b"]))] = v
        if numero == 2:                            # a organizacao descobre o problema e desqualifica (RN27)
            desqualificadas.add(desq)
            partida = ULTIMA_PARTIDA[("fase_suica", 2, desq)]["partidas"][0]
            registrar_punicao(
                "desqualificacao",
                "Jogador escalado sem matrícula ativa no curso (RN03), identificado após a 2ª rodada",
                datetime(2026, 10, 18, 22, 0, 0), id_equipe=desq, id_partida_ocorrencia=partida,
                id_organizador=1)
    qualificadas = [t for t in times if campanha[t][0] == 3]
    assert len(qualificadas) == 8, len(qualificadas)
    assert all(campanha[t][0] == 3 or campanha[t][1] == 3 for t in times)
    # Classificacao (RN14): retrospecto; depois soma das vitorias dos adversarios; depois confronto direto; depois sorteio
    soma_adv = {t: sum(campanha[a][0] for a in adversarios[t]) for t in times}
    ordem = sorted(qualificadas, key=lambda t: (campanha[t][1], -soma_adv[t], rng.random()))
    final, i = [], 0
    while i < len(ordem):
        j = i
        while j < len(ordem) and (campanha[ordem[j]][1], soma_adv[ordem[j]]) == (campanha[ordem[i]][1], soma_adv[ordem[i]]):
            j += 1
        empate = ordem[i:j]                        # equipes empatadas ate aqui: confronto direto decide
        if len(empate) > 1:
            def vitorias_diretas(t):
                return sum(1 for o in empate if o != t and h2h.get(frozenset((t, o))) == t)
            empate.sort(key=lambda t: -vitorias_diretas(t))
        final += empate
        i = j
    return final, campanha


def fase_playoffs(classificacao):
    pos = {t: i + 1 for i, t in enumerate(classificacao)}
    POSICAO_SUICA.update(pos)
    seeds = {p: t for t, p in pos.items()}
    quartas = [{"a": seeds[1], "b": seeds[8], "wo": None}, {"a": seeds[4], "b": seeds[5], "wo": None},
               {"a": seeds[2], "b": seeds[7], "wo": None}, {"a": seeds[3], "b": seeds[6], "wo": None}]
    jogar_rodada("playoffs", 1, "Md3", "2026-11-07", ["10:00", "13:00", "16:00", "19:00"], quartas)
    v = [c["res"]["vencedora"] for c in quartas]
    semis = [{"a": v[0], "b": v[1], "wo": None}, {"a": v[2], "b": v[3], "wo": None}]   # 1x8 com 4x5; 2x7 com 3x6
    jogar_rodada("playoffs", 2, "Md3", "2026-11-08", ["14:00", "17:00"], semis)
    finalistas = [c["res"]["vencedora"] for c in semis]
    semifinalistas = [c["res"]["perdedora"] for c in semis]
    campea_prevista = rng.choice(finalistas)       # final emocionante: vai as 5 partidas (3 x 2)
    PLANOS[("playoffs", 3, campea_prevista)] = rng.sample(["W", "W", "L", "L"], 4) + ["W"]
    final = [{"a": finalistas[0], "b": finalistas[1], "wo": None}]
    jogar_rodada("playoffs", 3, "Md5", "2026-11-14", ["17:00"], final)
    res = final[0]["res"]
    return res["vencedora"], res["perdedora"], semifinalistas


# ---------------------------------------------------------------------
# 9. Ocorrencias sorteadas depois da simulacao
# ---------------------------------------------------------------------
def punicoes_e_contestacoes(planejadas):
    equipes_planejadas = set(planejadas.values())
    jogadas = [(pid, p) for pid, p in PARTIDAS.items() if p["azul"] is not None]
    # 1) advertencias avulsas (no maximo 2 por equipe: nao chegam a 3)
    fases_da_partida = {pid: SERIES[p["serie"]]["fase"] for pid, p in PARTIDAS.items()}
    candidatas = [(pid, p) for pid, p in jogadas if fases_da_partida[pid] != "playoffs"]
    rng.shuffle(candidatas)
    feitas = 0
    for pid, p in candidatas:
        eq = rng.choice([p["azul"], p["vermelho"]])
        if eq in equipes_planejadas or ADV_CONTADOR.get(eq, 0) >= 2:
            continue
        advertir(eq, pid, p["serie"], p["inicio"] + timedelta(minutes=rng.randint(15, 35)))
        feitas += 1
        if feitas == 14:
            break
    # 2) perda de banimento e perda da escolha de lado (RN34), em Md3 do Play-in com 2 partidas jogadas
    series_md3 = []
    for sid, s in SERIES.items():
        if s["fase"] == "play_in" and len(s["partidas"]) >= 2 and all(PARTIDAS[x]["azul"] for x in s["partidas"][:2]):
            if not ({s["a"], s["b"]} & equipes_planejadas):
                series_md3.append(sid)
    rng.shuffle(series_md3)
    # 2a) perda de banimento: a equipe perde 1 banimento na partida 2
    sid = series_md3.pop()
    s = SERIES[sid]
    p1, p2 = s["partidas"][0], s["partidas"][1]
    infrator = rng.choice([s["a"], s["b"]])
    registrar_punicao("perda_banimento", "Demora excessiva na seleção de campeões",
                      PARTIDAS[p1]["inicio"] + timedelta(minutes=8), id_equipe=infrator,
                      id_partida_ocorrencia=p1, id_partida_cumprimento=p2, id_arbitro=ARBITRO_DA_SERIE[sid])
    bans = [x for x in dados["selecao_campeao"] if x["id_partida"] == p2 and x["id_equipe"] == infrator
            and x["tipo"] == "banimento"]
    dados["selecao_campeao"].remove(max(bans, key=lambda x: x["ordem"]))
    # 2b) perda da escolha de lado: a perdedora da partida 1 deveria escolher o lado, mas fica no vermelho
    for sid in series_md3:
        s = SERIES[sid]
        p1, p2 = s["partidas"][0], s["partidas"][1]
        perdedora = s["a"] if PARTIDAS[p1]["venc"] == s["b"] else s["b"]
        if PARTIDAS[p2]["vermelho"] == perdedora:
            registrar_punicao("perda_escolha_lado", "Atraso para entrar na sala da partida",
                              PARTIDAS[p1]["inicio"] + timedelta(minutes=9), id_equipe=perdedora,
                              id_partida_ocorrencia=p1, id_partida_cumprimento=p2,
                              id_arbitro=ARBITRO_DA_SERIE[sid])
            break
    else:
        raise RuntimeError("nenhuma serie serve para a perda da escolha de lado")
    # 3) contestacoes de resultado julgadas pelo organizador (RN25): 4 mantidas, 2 alteradas
    contestaveis = [(pid, p) for pid, p in jogadas]
    for decisao, qtd in (("mantido", 4), ("alterado", 2)):
        for _ in range(qtd):
            pid, p = contestaveis.pop(rng.randrange(len(contestaveis)))
            venc = p["venc"]
            perd = p["vermelho"] if p["azul"] == venc else p["azul"]
            # alterado: quem contestou foi quem era a perdedora na primeira decisao, hoje vencedora
            quem_contesta, quem_confirma = (perd, venc) if decisao == "mantido" else (venc, perd)
            dados["avaliacao_resultado"][:] = [a for a in dados["avaliacao_resultado"] if a["id_partida"] != pid]
            base = p["registro"]
            inserir("avaliacao_resultado", id_partida=pid, id_jogador=CAPITAO[quem_confirma], parecer="confirmado",
                    data_hora_parecer=dh(base + timedelta(minutes=3)))
            inserir("avaliacao_resultado", id_partida=pid, id_jogador=CAPITAO[quem_contesta], parecer="contestado",
                    data_hora_parecer=dh(base + timedelta(minutes=9)))
            linha = next(x for x in dados["partida"] if x["id_partida"] == pid)
            linha["id_organizador_julgamento"] = rng.choice([1, 2])
            linha["decisao_julgamento"] = decisao
            linha["data_julgamento"] = dh(base + timedelta(hours=rng.randint(4, 20), minutes=rng.randint(0, 59)))


# ---------------------------------------------------------------------
# 10. Escrita do script_dml.sql
# ---------------------------------------------------------------------
def sql_valor(v):
    if v is None:
        return "NULL"
    if isinstance(v, int):
        return str(v)
    return "'" + str(v).replace("'", "''") + "'"


TITULOS = [  # (tabela, comentario) na ordem de dependencia das chaves estrangeiras
    ("organizador", "Quem cria o campeonato e decide inscricoes e contestacoes"),
    ("arbitro", "12 arbitros (alguns sem telefone: NULL permitido)"),
    ("centro_ensino", "Os 11 Centros de Ensino da UFSC"),
    ("funcao", "As 5 funcoes do jogo"),
    ("campeao", "Catalogo de campeoes do jogo"),
    ("patrocinador", "6 patrocinadores ficticios (RN35: nenhum ramo vedado)"),
    ("curso", "Os 64 cursos de graduacao do campus Florianopolis (id_curso = id_equipe)"),
    ("vinculo_arbitro_curso", "Cursos com os quais cada arbitro tem vinculo (RN24)"),
    ("campeonato", "A edicao 1 da Copa UFSC, ja encerrada"),
    ("patrocinio", "Cotas: somam 18.000,00, acima dos 16.000,00 de premiacao (RN28)"),
    ("premiacao", "Valores em centavos: campea, vice e cada semifinalista"),
    ("fase", "Play-in, Fase Suica e Playoffs"),
    ("rodada", "2 rodadas no Play-in, 5 na Fase Suica, 3 nos Playoffs"),
    ("equipe", "64 equipes, uma por curso; chave do Play-in e colocacao final (id_capitao entra no UPDATE abaixo)"),
    ("jogador", "384 jogadores: 5 titulares (um por funcao) + 1 reserva por equipe"),
    ("coach", "44 coaches (20 equipes nao tem coach)"),
    ("inscricao", "70 inscricoes: 64 aprovadas e 6 recusadas que foram reenviadas"),
    ("classificacao", "Os 8 classificados da Fase Suica, em ordem"),
    ("serie", "Todas as series do campeonato, em ordem de data"),
    ("disputa", "As duas equipes de cada serie e o comparecimento (0 = W.O.)"),
    ("partida", "Partidas jogadas; as sem lados foram perdidas por suspensao"),
    ("avaliacao_resultado", "Confirmacoes e contestacoes dos capitaes"),
    ("selecao_campeao", "Banimentos e escolhas de cada partida jogada"),
    ("escalacao", "Quem jogou cada partida, em que funcao e com qual escolha"),
    ("punicao", "Advertencias, suspensao de jogador, perdas e a desqualificacao"),
]


def escrever_dml(capitao_por_equipe):
    linhas = [
        "-- =====================================================================",
        "-- Projeto Final - CIN 8003 Bancos de Dados e Aplicacoes (UFSC)",
        "-- Arquivo: sql/script_dml.sql  (Parte 5 - Dados)",
        "-- Autor: Mateus Nunes Oliveira",
        "-- GERADO por python/gerar_dados.py (semente %d). Nao edite a mao: gere de novo." % SEMENTE,
        "--",
        "-- Executar DEPOIS de sql/script_ddl.sql. Todos os nomes de pessoas, Riot IDs, e-mails,",
        "-- telefones e datas sao sinteticos; cursos, centros e campeoes sao reais.",
        "-- O campeonato simulado esta encerrado: campea, vice e 2 semifinalistas premiadas.",
        "-- As tabelas aparecem na ordem de dependencia das chaves estrangeiras.",
        "-- =====================================================================",
        "",
        "PRAGMA foreign_keys = ON;",
        "",
    ]
    numero = 0
    for tabela, comentario in TITULOS:
        linhas_tab = dados[tabela]
        numero += 1
        linhas += ["-- ---------------------------------------------------------------------",
                   "-- %d. %s (%d linhas): %s" % (numero, tabela.upper(), len(linhas_tab), comentario),
                   "-- ---------------------------------------------------------------------"]
        cols = COLUNAS[tabela]
        for i in range(0, len(linhas_tab), LINHAS_POR_INSERT):
            bloco = linhas_tab[i:i + LINHAS_POR_INSERT]
            linhas.append("INSERT INTO %s (%s) VALUES" % (tabela, ", ".join(cols)))
            valores = ["    (%s)" % ", ".join(sql_valor(l[c]) for c in cols) for l in bloco]
            linhas.append(",\n".join(valores) + ";")
        linhas.append("")
        if tabela == "jogador":                       # fecha o ciclo EQUIPE <-> JOGADOR (RN06)
            linhas += ["-- ---------------------------------------------------------------------",
                       "-- Capitao de cada equipe (RN06): UPDATE depois que os jogadores existem",
                       "-- ---------------------------------------------------------------------"]
            for eq in sorted(capitao_por_equipe):
                linhas.append("UPDATE equipe SET id_capitao = %d WHERE id_equipe = %d;" % (capitao_por_equipe[eq], eq))
            linhas.append("")
    with open(CAMINHO_DML, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(linhas) + "\n")


# ---------------------------------------------------------------------
# 11. Banco SQLite: executa DDL + DML e confere
# ---------------------------------------------------------------------
def construir_banco():
    if os.path.exists(CAMINHO_DB):
        os.remove(CAMINHO_DB)
    con = sqlite3.connect(CAMINHO_DB)
    con.execute("PRAGMA foreign_keys = ON")
    with open(CAMINHO_DDL, encoding="utf-8") as f:
        con.executescript(f.read())
    with open(CAMINHO_DML, encoding="utf-8") as f:
        con.executescript(f.read())
    print("PRAGMA foreign_keys     :", con.execute("PRAGMA foreign_keys").fetchone()[0])
    print("PRAGMA foreign_key_check:", con.execute("PRAGMA foreign_key_check").fetchall() or "sem violacoes")
    print("PRAGMA integrity_check  :", con.execute("PRAGMA integrity_check").fetchone()[0])
    print("\nLinhas por tabela:")
    total = 0
    for tabela, _ in TITULOS:
        n = con.execute("SELECT COUNT(*) FROM %s" % tabela).fetchone()[0]
        total += n
        print("  %-24s %6d" % (tabela, n))
    print("  %-24s %6d" % ("TOTAL", total))
    con.close()


# ---------------------------------------------------------------------
# 12. Programa principal
# ---------------------------------------------------------------------
def main():
    global ARBITRO_VINCULOS
    ARBITRO_VINCULOS = criar_cadastros()
    criar_patrocinio_e_premiacao()

    ordem = list(range(1, 65))
    rng.shuffle(ordem)                                   # sorteio das chaves do Play-in (RN10)
    chaves = {c: ordem[4 * (c - 1):4 * c] for c in range(1, 17)}
    planejadas = definir_planos(chaves)

    # Campeonato e fases
    inserir("campeonato", id_campeonato=ID_CAMPEONATO, nome="Copa UFSC de League of Legends", edicao=1,
            prazo_inscricao="2026-09-30 23:59:00", data_inicio="2026-10-03", data_fim="2026-11-14",
            numero_vagas=64, situacao="encerrado", id_organizador=1)
    for nome, i in FASE_ID.items():
        inserir("fase", id_fase=i, id_campeonato=ID_CAMPEONATO, nome=nome)

    criar_equipes(chaves)
    fixar_favoritas()
    equipes_menores = ajustar_jogadores_especiais()
    criar_coaches()
    criar_inscricoes(equipes_menores)

    # Simulacao do campeonato
    qualificadas_play_in = fase_play_in(chaves)
    classificacao, campanha = fase_suica(qualificadas_play_in, planejadas["desq"])
    campea, vice, semifinalistas = fase_playoffs(classificacao)
    assert planejadas["desq"] not in classificacao

    for i, eq in enumerate(classificacao, start=1):
        inserir("classificacao", id_classificacao=i, id_fase=FASE_ID["fase_suica"], posicao=i, id_equipe=eq)
    colocacao = {campea: 1, vice: 2, semifinalistas[0]: 3, semifinalistas[1]: 3}
    for linha in dados["equipe"]:
        linha["colocacao_premiacao"] = colocacao.get(linha["id_equipe"])

    punicoes_e_contestacoes(planejadas)

    # Renumera para ficar em ordem cronologica e sem buracos
    dados["punicao"].sort(key=lambda p: p["data_hora"])
    for i, p in enumerate(dados["punicao"], start=1):
        p["id_punicao"] = i
    for i, s in enumerate(dados["selecao_campeao"], start=1):
        s["id_selecao_campeao"] = i
    dados["avaliacao_resultado"].sort(key=lambda a: (a["id_partida"], a["id_jogador"]))

    assert len(dados["jogador"]) == 384 and len(dados["coach"]) == 44 and len(dados["inscricao"]) == 70
    escrever_dml(CAPITAO)
    print("Gerado:", CAMINHO_DML, "(%d KB)\n" % (os.path.getsize(CAMINHO_DML) // 1024))
    print("Campea: equipe %d | vice: equipe %d | semifinalistas: %s\n" % (campea, vice, semifinalistas))
    construir_banco()


if __name__ == "__main__":
    main()
