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
import funcoesUteis
import platform

def buscaArquivosEmPasta(caminho="", extensao=(".XLS", "XLSX")):
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

def leXls_Xlsx(arquivos=buscaArquivosEmPasta(caminho="entrada"),saida="temp\\baixas.csv"):
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
                    valor_celula = funcoesUteis.removerAcentosECaracteresEspeciais(str(planilha.cell_value(rowx=i, colx=j)))
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

def leCsv(arquivos=buscaArquivosEmPasta(caminho="entrada",extensao=(".csv")),saida="temp\\baixas.csv",separadorCampos=';'):
    saida = open(saida, "w", encoding='utf-8')
    lista_dados = []
    dados_linha = []
    for arquivo in arquivos:
        with open(arquivo, 'rt') as csvfile:
            csvreader = csv.reader(csvfile, delimiter=separadorCampos)
            for row in csvreader:
                for campo in row:
                    valor_celula = funcoesUteis.removerAcentosECaracteresEspeciais(str(campo))
                    
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

def PDFToText(arquivos=buscaArquivosEmPasta(caminho="entrada",extensao=(".PDF")), mode = "simple"):
    for arquivo in arquivos:
        nome_arquivo = os.path.basename(arquivo)
        saida = "temp\\" + str(nome_arquivo[0:len(nome_arquivo)-4]) + ".txt"
        try:
           # verifica se o Windows é 32 ou 64 bits
            architecture = platform.architecture()
            if architecture[0].count('32') > 0:
                pdftotext = "pdftotext32.exe"
            else:
                pdftotext = "pdftotext64.exe"
            
            # chama o comando pra transformação do PDF
            comando = f"bin\\{pdftotext} -{mode} \"{arquivo}\" \"{saida}\""
            os.system(comando)
        except Exception as ex:
            print(f"Nao foi possivel transformar o arquivo \"{saida}\". O erro é: {str(ex)}")

# chama a geração da transformação pra PDF
PDFToText()

def leLinhasExtrato(arquivos=buscaArquivosEmPasta(caminho="temp", extensao=(".TXT"))):
    lista_arquivos = {}
    lista_linha = []
    
    for arquivo in arquivos:
        # pra cada arquivo criar uma posição no dicionário
        lista_arquivos[arquivo] = lista_linha[:]
        
        # le o arquivo e grava num vetor
        with open(arquivo, 'rt') as txtfile:
            for linha in txtfile:
                linha = str(linha).replace("\n", "")
                lista_linha.append(linha)
            lista_arquivos[arquivo] = lista_linha[:]
            lista_linha.clear()
        txtfile.close()

    return lista_arquivos

def organizaExtrato(saida="temp\\baixas.csv"):
    saida = open(saida, "w", encoding='utf-8')
    saida.write("Data;Documento;Historico;Historico Complementar;Valor;Operacao\n")

    lista_arquivos = leLinhasExtrato()
    
    for linhas in lista_arquivos.values():

        posicao_data = 0
        posicao_documento = 0
        posicao_historico = 0
        posicao_valor = 0

        data = datetime.datetime.strptime("01/01/1900", "%d/%m/%Y").date()
        data = data.strftime("%d/%m/%Y")
        documento = ""
        historico = ""
        valor = 0
        operador = ""
        fornecedor_cliente = ""

        for num_row, row in enumerate(linhas):
            
            # ---- pega as posições onde estão os dados ----
            posicao_data_temp = row.upper().find("DATA")
            if posicao_data_temp > 0:
                posicao_data = posicao_data_temp

            posicao_documento_temp = row.upper().find("DOCUMENTO")
            if posicao_documento_temp > 0:
                posicao_documento = posicao_documento_temp

            posicao_historico_temp = row.upper().find("HISTÓRICO")
            if posicao_historico_temp > 0:
                posicao_historico = posicao_historico_temp

            posicao_valor_temp = row.upper().find("VALOR")
            if posicao_valor_temp > 0:
                posicao_valor = posicao_valor_temp-10 # pega 10 posições atrás da palavra valor
            # ---- termina de pegar os dados das posições
            
            # ---- começa o tratamento de cada campo ----
            data_temp = row[posicao_data:posicao_data+10]
            data_temp = funcoesUteis.retornaCampoComoData(data_temp)
            if data_temp is not None:
                data = funcoesUteis.transformaCampoDataParaFormatoBrasileiro(data_temp)
            if data == "01/01/1900":
                continue

            documento_temp = funcoesUteis.trataCampoTexto(row[posicao_documento:posicao_documento+12])
            if documento_temp != "" and data_temp is not None:
                documento = documento_temp

            historico_temp = funcoesUteis.trataCampoTexto(row[posicao_historico:posicao_historico+56])
            if data_temp is not None and historico_temp != "":
                historico = historico_temp
            if historico_temp.count("SALDO") > 0:
                continue

            valor_temp = funcoesUteis.removerAcentosECaracteresEspeciais(row[posicao_valor:posicao_valor+20])
            try:
                operador_temp = valor_temp[-1]
            except Exception:
                operador_temp = ""
            valor_temp = funcoesUteis.trataCampoDecimal(valor_temp)
            if valor_temp > 0 and data_temp is not None:
                valor = valor_temp
                operador = operador_temp
                if operador == "D":
                    operador = "-"
                else:
                    operador = "+"

            # lê a próxima linha pra saber se é uma linha com complementação dos dados da atual ou não
            try:
                proxima_linha = linhas[num_row+1]
            except Exception:
                proxima_linha = ""

            data_temp_proxima_linha = proxima_linha[posicao_data:posicao_data+10]
            data_temp_proxima_linha = funcoesUteis.retornaCampoComoData(data_temp_proxima_linha)

            valor_temp_proxima_linha = funcoesUteis.removerAcentosECaracteresEspeciais(proxima_linha[posicao_valor:posicao_valor+20])
            valor_temp_proxima_linha = funcoesUteis.trataCampoDecimal(valor_temp_proxima_linha)
            
            # primeira geração dos dados quando todas as informações estão em uma linha apenas
            if data_temp is not None and data_temp_proxima_linha is not None:
                saida.write(f"{data};{documento};{historico};;{valor:.2f};{operador}\n")

            # limpa dados do fornecedor_cliente
            if data_temp is not None:
                fornecedor_cliente = ""

            # segunda geração dos dados quando as informações complementares está em APENAS uma LINHA ABAIXO
            if data_temp is None and valor_temp == 0 and historico_temp != "" and data_temp_proxima_linha is None and valor_temp_proxima_linha == 0:
                fornecedor_cliente = fornecedor_cliente + " " + historico_temp

                # analisa se na verdade é um histórico válido, pois pode ser uma linha que contenha um tanto de carecter que não serve pra nada. Então considera como
                # histórico somente se conter o historico_temp válido
                historico_temp_inicio = funcoesUteis.trataCampoTexto(row[0:posicao_historico])
                if len(historico_temp_inicio) > 0:
                    fornecedor_cliente = ""
            
            # terceira geração dos dados quando as informações complementares está em MAIS de uma LINHA ABAIXO
            if data_temp is None and valor_temp == 0 and historico_temp != "" and data_temp_proxima_linha is not None and valor_temp_proxima_linha > 0:
                fornecedor_cliente = fornecedor_cliente + " " + historico_temp
                fornecedor_cliente = fornecedor_cliente.strip()

                # analisa se na verdade é um histórico válido, pois pode ser uma linha que contenha um tanto de carecter que não serve pra nada. Então considera como
                # histórico somente se conter o historico_temp válido
                historico_temp_inicio = funcoesUteis.trataCampoTexto(row[0:posicao_historico])
                if len(historico_temp_inicio) > 0:
                    fornecedor_cliente = ""

                saida.write(f"{data};{documento};{historico};{fornecedor_cliente};{valor:.2f};{operador}\n")
                
    saida.close()

# chama a geração pra organizar o extrato
organizaExtrato()