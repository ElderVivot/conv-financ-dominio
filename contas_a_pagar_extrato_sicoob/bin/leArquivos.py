import xlrd
import os
import unicodedata
import re
import csv
import time
import sys
#import openpyxl
#import pandas as pd
import datetime

def buscaArquivosEmPasta(caminho="entrada", extensao=(".XLS", "XLSX")):
    arquivos = os.listdir(caminho)
    lista_arquivos = []

    for arquivo in arquivos:
        arquivo = str(arquivo).upper()
        if arquivo.endswith(extensao):
            lista_arquivos.append(caminho+"\\"+arquivo)

    return lista_arquivos

def removerAcentosECaracteresEspeciais(palavra):
    # Unicode normalize transforma um caracter em seu equivalente em latin.
    nfkd = unicodedata.normalize('NFKD', palavra).encode('ASCII', 'ignore').decode('ASCII')
    palavraTratada = u"".join([c for c in nfkd if not unicodedata.combining(c)])

    # Usa expressão regular para retornar a palavra apenas com valores corretos
    return re.sub('[^a-zA-Z0-9.!+:=)$(/*,\-_ \\\]', '', palavraTratada)

# Minimaliza, ou seja, transforma todas as instancias repetidas de espaços em espaços simples.
#   Exemplo, o texto "  cnpj:      09.582.876/0001-68    Espécie Documento          Aceite" viraria
#   "cnpj: 09.582.876/0001-68 Espécie Documento Aceite"
#
# Nota: Ele faz um trim do texto também
def minimalizeSpaces(text):
    _result = text
    while ("  " in _result):
        result = result.replace("  ", " ")
    result = result.strip()
    return _result

def leXls_Xlsx(arquivos=buscaArquivosEmPasta(),saida="temp\\baixas.csv"):
    saida = open(saida, "w", encoding='utf-8')
    lista_dados = []
    dados_linha = []
    for arquivo in arquivos:
        try:
            arquivo = xlrd.open_workbook(arquivo, logfile=open(os.devnull, 'w'))
        except Exception:
            arquivo = xlrd.open_workbook(arquivo, logfile=open(os.devnull, 'w'), encoding_override='Windows-1252')

        # guarda todas as planilhas que tem dentro do arquivo excel
        planilhas = arquivo.sheet_names()

        # lê cada planilha
        for p in planilhas:

            # pega o nome da planilha
            planilha = arquivo.sheet_by_name(p)

            # pega a quantidade de linha que a planilha tem
            max_row = planilha.nrows
            # pega a quantidade de colunca que a planilha tem
            max_column = planilha.ncols

            # lê cada linha e coluna da planilha e imprime
            for i in range(0, max_row):

                valor_linha = planilha.row_values(rowx=i)

                # ignora linhas em branco
                if valor_linha.count("") == max_column:
                    continue

                # lê as colunas
                for j in range(0, max_column):

                    # as linhas abaixo analisa o tipo de dado que está na planilha e retorna no formato correto, sem ".0" para números ou a data no formato numérico
                    tipo_valor = planilha.cell_type(rowx=i, colx=j)
                    valor_celula = removerAcentosECaracteresEspeciais(str(planilha.cell_value(rowx=i, colx=j)))
                    if tipo_valor == 2:
                        valor_casas_decimais = valor_celula.split('.')
                        valor_casas_decimais = valor_casas_decimais[1]
                        if int(valor_casas_decimais) == 0:
                            valor_celula = valor_celula.split('.')
                            valor_celula = valor_celula[0]
                    elif tipo_valor == 3:
                        valor_celula = float(planilha.cell_value(rowx=i, colx=j))
                        valor_celula = xlrd.xldate.xldate_as_datetime(valor_celula, datemode=0)
                        valor_celula = valor_celula.strftime("%d/%m/%Y")

                    # retira espaços e quebra de linha da célula
                    valor_celula = str(valor_celula).strip().replace('\n', '')

                    # gera o resultado num arquivo
                    resultado = valor_celula + ';'
                    resultado = resultado.replace('None', '')
                    saida.write(resultado)

                    # adiciona o valor da célula na lista de dados_linha
                    dados_linha.append(valor_celula)

                # faz uma quebra de linha para passar pra nova linha
                saida.write('\n')

                # copia os dados da linha para o vetor de lista_dados
                lista_dados.append(dados_linha[:])

                # limpa os dados da linha para ler a próxima
                dados_linha.clear()

    # fecha o arquivo
    saida.close()

    # retorna uma lista dos dados
    return lista_dados

def leCsv(arquivos=buscaArquivosEmPasta(extensao=(".csv")),saida="temp\\baixas.csv",separadorCampos=';'):
    saida = open(saida, "w", encoding='utf-8')
    lista_dados = []
    dados_linha = []
    for arquivo in arquivos:
        with open(arquivo, 'rt') as csvfile:
            csvreader = csv.reader(csvfile, delimiter=separadorCampos)
            for row in csvreader:
                for campo in row:
                    valor_celula = removerAcentosECaracteresEspeciais(str(campo))
                    
                    # retira espaços e quebra de linha da célula
                    valor_celula = str(valor_celula).strip().replace('\n', '')

                    # gera o resultado num arquivo
                    resultado = valor_celula + ';'
                    resultado = resultado.replace('None', '')
                    saida.write(resultado)

                    # adiciona o valor da célula na lista de dados_linha
                    dados_linha.append(valor_celula)

                # faz uma quebra de linha para passar pra nova linha
                saida.write('\n')

                # copia os dados da linha para o vetor de lista_dados
                lista_dados.append(dados_linha[:])

                # limpa os dados da linha para ler a próxima
                dados_linha.clear()

    # fecha o arquivo
    saida.close()

    # retorna uma lista dos dados
    return lista_dados

def PDFToText(arquivos=buscaArquivosEmPasta(extensao=(".PDF")), mode = "simple"):
    for arquivo in arquivos:
        nome_arquivo = os.path.basename(arquivo)
        saida = "temp\\" + str(nome_arquivo[0:len(nome_arquivo)-4]) + ".txt"
        try:
            #comando = "{}\\pdftotext.exe -{} \"{}\" \"{}\"".format(os.path.abspath(os.path.dirname(__file__)), mode, arquivo, saida)
            comando = f"bin\\pdftotext.exe -{mode} \"{arquivo}\" \"{saida}\""
            resultado = os.system(comando)
        except Exception as ex:
            print(f"Nao foi possivel transformar o arquivo \"{saida}\". O erro é: {str(ex)}")

def organizaExtrato(arquivos=buscaArquivosEmPasta(caminho="temp", extensao=(".TXT")),separadorCampos=''):
    print(caminho)
    for arquivo in arquivos:
        with open(arquivo, 'rt') as csvfile:
            csvreader = csv.reader(csvfile, delimiter=separadorCampos)
            for row in csvreader:
                print(row)


#leXls_Xlsx()
#leCsv()
PDFToText()
organizaExtrato()