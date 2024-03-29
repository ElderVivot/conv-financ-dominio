import xlrd
import os
import unicodedata
import re
#import openpyxl
#import pandas as pd
import datetime

def buscaArquivosEmPasta(caminho="entrada", extensao=(".xls", "xlsx")):
    arquivos = os.listdir(caminho)
    lista_arquivos = []

    for arquivo in arquivos:
        if arquivo.endswith(extensao):
            lista_arquivos.append(caminho+"\\"+arquivo)

    return lista_arquivos

def removerAcentosECaracteresEspeciais(palavra):
    # Unicode normalize transforma um caracter em seu equivalente em latin.
    nfkd = unicodedata.normalize('NFKD', palavra).encode('ASCII', 'ignore').decode('ASCII')
    palavraTratada = u"".join([c for c in nfkd if not unicodedata.combining(c)])

    # Usa expressão regular para retornar a palavra apenas com valores corretos
    return re.sub('[^a-zA-Z0-9.!+)(/*,\- \\\]', '', palavraTratada)

# Função não sendo utilizada, pois já tem a debaixo que lê XLS também
""" def leXlsx(arquivos=buscaArquivosEmPasta(),saida="D:\\programming\\conv-dominio-awk\\contas_a_pagar_lojas_duilson\\temp\\baixas.csv"):
    saida = open(saida, "w")
    lista_dados = []

    for arquivo in arquivos:

        arquivo = openpyxl.load_workbook(arquivo)
        # guarda todas as planilhas que tem dentro do arquivo excel
        planilhas = arquivo.get_sheet_names()

        # lê cada planilha
        for p in planilhas:

            # pega o nome da planilha
            planilha = arquivo.get_sheet_by_name(p)

            # pega a quantidade de linha que a planilha tem
            max_row = planilha.max_row
            # pega a quantidade de colunca que a planilha tem
            max_column = planilha.max_column

            # lê cada linha e coluna da planilha e imprime
            for i in range(1, max_row + 1):
                # lê as colunas
                for j in range(1, max_column + 1):
                    # pega o valor da célula
                    cell_obj = planilha.cell(row=i, column=j)
                    # gera o resultado num arquivo
                    resultado = str(cell_obj.value).strip().rstrip().replace('\n', '') + ';'
                    resultado = resultado.replace('None', '')
                    saida.write(resultado)

                # faz uma quebra de linha para passar pra nova coluna
                saida.write('\n')
    # fecha o arquivo
    saida.close() """

def leXls_Xlsx(arquivos=buscaArquivosEmPasta(),saida="temp\\baixas.csv"):
    saida = open(saida, "w", encoding='utf-8')
    lista_dados = []
    dados_linha = []
    for arquivo in arquivos:
        arquivo = xlrd.open_workbook(arquivo, logfile=open(os.devnull, 'w'))

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

# Função não sendo utilizada, pois já tem a que lê Excel e retira o \n do meio da célula
""" def excelPandas(arquivos=buscaArquivosEmPasta(), saida = "D:\\programming\\conv-dominio-awk\\contas_a_pagar_lojas_duilson\\temp\\baixas.csv"):
    saida = open(saida, "w")
    for arquivo in arquivos:
        data = pd.read_excel(arquivo, sheet_name=None)

        for valores_planilha in data.values():
            for valor_campo in valores_planilha:
                valor_campo = str(valor_campo).strip()
            valores_planilha.to_csv(saida, sep=";", encoding='utf-8', index=None, float_format='%g', decimal='.')
            #print(valores_planilha)
    print(valor_campo)
    saida.close() """

leXls_Xlsx()
#excelPandas()
#leXlsx()
