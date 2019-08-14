#import sqlanydb
import csv
import leArquivos
from operator import itemgetter
import datetime
import funcoesUteis

def organizaDados():
    dados = leArquivos.leXls_Xlsx()
    posicoesCampos = {}
    listaDados = []
    listaDaLinha = {}

    for dado in dados:
        # lê o cabeçalho
        if str(dado[0]).upper().count('NOME DO FAVORECIDO') > 0:
            posicoesCampos.clear()
            for numPosicaoCampo, nomeCampo in enumerate(dado):
                nomeCampo = str(nomeCampo).upper()
                posicoesCampos[nomeCampo] = numPosicaoCampo
        else:
            posicaoNomeFornecedor = funcoesUteis.buscaPosicaoCampo(posicoesCampos, "Nome do favorecido", 1)
            posicaoCNPJFornecedor = funcoesUteis.buscaPosicaoCampo(posicoesCampos, "CPF/CNPJ", 2)
            posicaoTipoPagamento = funcoesUteis.buscaPosicaoCampo(posicoesCampos, "Tipo de pagamento", 3)
            posicaoDataPagamento = funcoesUteis.buscaPosicaoCampo(posicoesCampos, "Data de pagamento", 5)
            posicaoValorPagamento = funcoesUteis.buscaPosicaoCampo(posicoesCampos, "Valor do pagamento (R$)", 6)
            posicaoStatusPagamento = funcoesUteis.buscaPosicaoCampo(posicoesCampos, "Status", 7)

            nomeFornecedor = funcoesUteis.trataCampoTexto(dado[posicaoNomeFornecedor])
            CNPJFornecedor = funcoesUteis.trataCampoNumero(dado[posicaoCNPJFornecedor])
            tipoPagamento = funcoesUteis.trataCampoTexto(dado[posicaoTipoPagamento])
            dataPagamento = funcoesUteis.transformaCampoDataParaFormatoBrasileiro(funcoesUteis.retornaCampoComoData(dado[posicaoDataPagamento]))
            valorPagamento = funcoesUteis.trataCampoDecimal(dado[posicaoValorPagamento])
            statusPagamento = funcoesUteis.trataCampoTexto(dado[posicaoStatusPagamento])

            # se não for um pagamento válido pula de linha
            if dataPagamento == None:
                continue

            listaDaLinha.clear()

            listaDaLinha['nomeFornecedor'] = nomeFornecedor
            listaDaLinha['CNPJFornecedor'] = CNPJFornecedor
            listaDaLinha['tipoPagamento'] = tipoPagamento
            listaDaLinha['dataPagamento'] = dataPagamento
            listaDaLinha['valorPagamento'] = valorPagamento
            listaDaLinha['statusPagamento'] = statusPagamento

            listaDados.append(listaDaLinha.copy())

            #print(listaDados)

    #listaDados = sorted(listaDados, key=itemgetter('nomeFornecedor'))
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

