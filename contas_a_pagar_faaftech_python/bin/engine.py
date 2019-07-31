#import sqlanydb
import csv
import leArquivos
from operator import itemgetter
import datetime

def trataCampoData(valor):
    try:
        return datetime.datetime.strptime(valor, "%d/%m/%Y").date()
    except:
        return datetime.datetime.strptime("01/01/1900", "%d/%m/%Y").date()

def buscaPosicaoCampo(campoCabecalho, nomeCampo='', posicaoCampo=0):
    nomeCampo = str(leArquivos.removerAcentosECaracteresEspeciais(nomeCampo)).upper()
    try:
        numPosicaoCampo = campoCabecalho[nomeCampo]
    except KeyError:
        numPosicaoCampo = posicaoCampo

    return numPosicaoCampo

def organizaDados():
    dados = leArquivos.leXls_Xlsx()
    posicoesCampos = {}
    listaDados = []
    listaDaLinha = {}

    for dado in dados:
        # lê o cabeçalho
        if str(dado[0]).upper().count('NRO COMPENSACAO') > 0:
            posicoesCampos.clear()
            for numPosicaoCampo, nomeCampo in enumerate(dado):
                nomeCampo = str(nomeCampo).upper()
                posicoesCampos[nomeCampo] = numPosicaoCampo
        else:
            posicaoNomeFornecedor = buscaPosicaoCampo(posicoesCampos, "Nome Parceiro", 3)

            nomeFornecedor = dado[posicaoNomeFornecedor]

            listaDaLinha.clear()

            listaDaLinha['nomeFornecedor'] = nomeFornecedor

            listaDados.append(listaDaLinha.copy())

            #print(listaDados)

    listaDados = sorted(listaDados, key=itemgetter('nomeFornecedor'))
    return listaDados

def exportaDados(saida="saida\\lancamentos.csv"):
    saida = open(saida, "w", encoding='utf-8')
    dados = organizaDados()
    tamanhoListaDados = len(dados)

    for i in range(0,tamanhoListaDados):
        print("teset")

    saida.close()

print(organizaDados())
#exportaDados()

