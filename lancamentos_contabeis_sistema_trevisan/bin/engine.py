#import sqlanydb
import csv
import leArquivos
from operator import itemgetter
import datetime
import re

def trataCampoDecimal(valorCampo, qtdCasaDecimais=2):
    valorCampo = str(valorCampo)
    valorCampo = re.sub('[^0-9.,]', '', valorCampo)
    if valorCampo.count(',') > 0 and valorCampo.count('.') > 0:
        valorCampo = valorCampo.replace('.','')

    if ',' in valorCampo:
        valorCampo = valorCampo.replace(',','.')
    
    try:
        valorCampo = float(valorCampo)
    except Exception as e:
        valorCampo = float(0)

    return valorCampo

def trataCampoData(valor):
    try:
        return datetime.datetime.strptime(valor, "%d/%m/%Y").date()
    except:
        return datetime.datetime.strptime("01/01/1900", "%d/%m/%Y").date()

def organizaDados():
    dados = leArquivos.leXls_Xlsx()
    posicoesCampos = {}
    listaDados = []
    listaDaLinha = {}

    for dado in dados:
        if str(dado[0]).upper().count('LANCTO') > 0:
            posicoesCampos.clear()
            for numPosicaoCampo, nomeCampo in enumerate(dado):
                nomeCampo = str(nomeCampo).upper()
                posicoesCampos[nomeCampo] = numPosicaoCampo
        else:
            try:
                posicaoDebito = posicoesCampos['DEBITO']
            except KeyError:
                posicaoDebito = 1

            try:
                posicaoCredito = posicoesCampos['CREDITO']
            except KeyError:
                posicaoCredito = 2

            try:
                posicaoDataLancamento = posicoesCampos['DATA LCTO']
            except KeyError:
                posicaoDataLancamento = 3

            try:
                posicaoValorLancamento = posicoesCampos['VALOR']
            except KeyError:
                posicaoValorLancamento = 4

            try:
                posicaoCodigoHistorico = posicoesCampos['COD HISTORICO']
            except KeyError:
                posicaoCodigoHistorico = 5

            try:
                posicaoHistorico = posicoesCampos['HIST LANC']
            except KeyError:
                posicaoHistorico = 6

            try:
                posicaoNumDocumento = posicoesCampos['NRDOCUMENTO']
            except KeyError:
                posicaoNumDocumento = 9

            contaDebito = dado[posicaoDebito]

            contaCredito = dado[posicaoCredito]

            if contaDebito == '' and contaCredito == '':
                continue

            dataLancamento = dado[posicaoDataLancamento]
            if dataLancamento == "":
                continue
            else:
                dataLancamento = trataCampoData(dataLancamento)

            valorLancamento = dado[posicaoValorLancamento]
            valorLancamento = trataCampoDecimal(valorLancamento, 2)
            valorLancamento = str(valorLancamento).replace('.',',')

            codigoHistorico = dado[posicaoCodigoHistorico]

            historico = dado[posicaoHistorico]

            numDocumento = dado[posicaoNumDocumento]

            listaDaLinha.clear()

            listaDaLinha['contaDebito'] = contaDebito
            listaDaLinha['contaCredito'] = contaCredito
            listaDaLinha['dataLancamento'] = dataLancamento
            listaDaLinha['valorLancamento'] = valorLancamento
            listaDaLinha['codigoHistorico'] = codigoHistorico
            listaDaLinha['historico'] = historico
            listaDaLinha['numDocumento'] = numDocumento

            listaDados.append(listaDaLinha.copy())

            #print(listaDados)

    listaDados = sorted(listaDados, key=itemgetter('dataLancamento'))
    return listaDados

def exportaDados(saida="saida\\lancamentos.csv"):
    saida = open(saida, "w", encoding='utf-8')
    dados = organizaDados()
    tamanhoListaDados = len(dados)

    for i in range(0,tamanhoListaDados):
        dataLancamento = dados[i]['dataLancamento'].strftime('%d/%m/%Y')
        valorLancamento = dados[i]['valorLancamento']
        if i > 0:
            if dados[i-1]['dataLancamento'] == dados[i]['dataLancamento']:
                dadosExportar = (f"L;{valorLancamento};{dados[i]['contaDebito']};"
                                 f"{dados[i]['contaCredito']};;{dados[i]['historico']}\n")
                saida.write(dadosExportar)
            else:
                # CABEÇALHO DO ARQUIVO
                dadosExportar = (f"I;{dataLancamento};V\n")
                saida.write(dadosExportar)

                # LANÇAMENTOS NORMAIS
                dadosExportar = (f"L;{valorLancamento};{dados[i]['contaDebito']};"
                                 f"{dados[i]['contaCredito']};;{dados[i]['historico']}\n")
                saida.write(dadosExportar)
        else:
            # CABEÇALHO DO ARQUIVO
            dadosExportar = (f"I;{dataLancamento};V\n")
            saida.write(dadosExportar)

            # LANÇAMENTOS NORMAIS
            dadosExportar = (f"L;{dados[i]['valorLancamento']};{dados[i]['contaDebito']};"
                             f"{dados[i]['contaCredito']};;{dados[i]['historico']}\n")
            saida.write(dadosExportar)

    saida.close()

#print(organizaDados())
exportaDados()

