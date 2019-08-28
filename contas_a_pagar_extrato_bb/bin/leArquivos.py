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

# def PDFToText(arquivos=buscaArquivosEmPasta(caminho="entrada",extensao=(".PDF")), mode = "simple"):
#     for arquivo in arquivos:
#         nome_arquivo = os.path.basename(arquivo)
#         saida = "temp\\" + str(nome_arquivo[0:len(nome_arquivo)-4]) + ".txt"
#         try:
#             comando = f"bin\\pdftotext.exe -{mode} \"{arquivo}\" \"{saida}\""
#             os.system(comando)
#         except Exception as ex:
#             print(f"Nao foi possivel transformar o arquivo \"{saida}\". O erro é: {str(ex)}")

# chama a geração da transformação pra PDF
#PDFToText()

def leLinhasExtrato(arquivos=buscaArquivosEmPasta(caminho="Y:\\18 - DEPARTAMENTO DE PROJETOS\\Elder\\Importador\\Conjunto de Dados\\Layouts\\Financeiro\\_ferramentas\\contas_a_pagar_extrato_bb\\temp", extensao=(".TXT"))):
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

def organizaExtrato(saida="Y:\\18 - DEPARTAMENTO DE PROJETOS\\Elder\\Importador\\Conjunto de Dados\\Layouts\\Financeiro\\_ferramentas\\contas_a_pagar_extrato_bb\\temp\\baixas.csv"):
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

            print(row)
            
            # ---- começa o tratamento de cada campo ----
            data_temp = row[0:15]
            data_temp = funcoesUteis.retornaCampoComoData(data_temp)
            if data_temp is not None:
                data = funcoesUteis.transformaCampoDataParaFormatoBrasileiro(data_temp)

                row = funcoesUteis.trataCampoTexto(row)
                row_divida = row.split()
                print(row_divida)

                data_movimento = row_divida[1]
                data_movimento = funcoesUteis.retornaCampoComoData(data_movimento)
                if data_movimento is None:
                    posicao_agencia = 1
                else:
                    posicao_agencia = 2

                while campos_historicos 

                for campo in row_divida:
                    pass

            # if data == "01/01/1900":
            #     continue

            # documento_temp = funcoesUteis.trataCampoTexto(row[posicao_documento:posicao_documento+12])
            # if documento_temp != "":
            #     documento = documento_temp

            # historico_temp = funcoesUteis.trataCampoTexto(row[posicao_historico:posicao_historico+56])
            # if data_temp is not None and historico_temp != "":
            #     historico = historico_temp
            # if historico_temp.count("SALDO") > 0:
            #     continue

            # valor_temp = funcoesUteis.removerAcentosECaracteresEspeciais(row[posicao_valor:posicao_valor+20])
            # try:
            #     operador_temp = valor_temp[-1]
            # except Exception:
            #     operador_temp = ""
            # valor_temp = funcoesUteis.trataCampoDecimal(valor_temp)
            # if valor_temp > 0:
            #     valor = valor_temp
            #     operador = operador_temp
            #     if operador == "D":
            #         operador = "-"
            #     else:
            #         operador = "+"

            # # lê a próxima linha pra saber se é uma linha com complementação dos dados da atual ou não
            # try:
            #     proxima_linha = linhas[num_row+1]
            # except Exception:
            #     proxima_linha = ""

            # data_temp_proxima_linha = proxima_linha[posicao_data:posicao_data+10]
            # data_temp_proxima_linha = funcoesUteis.retornaCampoComoData(data_temp_proxima_linha)

            # valor_temp_proxima_linha = funcoesUteis.removerAcentosECaracteresEspeciais(proxima_linha[posicao_valor:posicao_valor+20])
            # valor_temp_proxima_linha = funcoesUteis.trataCampoDecimal(valor_temp_proxima_linha)
            
            # # primeira geração dos dados quando todas as informações estão em uma linha apenas
            # if data_temp is not None and data_temp_proxima_linha is not None:
            #     saida.write(f"{data};{documento};{historico};;{valor_temp:.2f};{operador}\n")

            # # limpa dados do fornecedor_cliente
            # if data_temp is not None:
            #     fornecedor_cliente = ""

            # # segunda geração dos dados quando as informações complementares está em APENAS uma LINHA ABAIXO
            # if data_temp is None and valor_temp == 0 and historico_temp != "" and data_temp_proxima_linha is None and valor_temp_proxima_linha == 0:
            #     fornecedor_cliente = fornecedor_cliente + " " + historico_temp
            
            # # terceira geração dos dados quando as informações complementares está em MAIS de uma LINHA ABAIXO
            # if data_temp is None and valor_temp == 0 and historico_temp != "" and data_temp_proxima_linha is not None and valor_temp_proxima_linha > 0:
            #     fornecedor_cliente = fornecedor_cliente + " " + historico_temp
            #     fornecedor_cliente = fornecedor_cliente.strip()

            #     saida.write(f"{data};{documento};{historico};{fornecedor_cliente};{valor:.2f};{operador}\n")
                
    saida.close()

# chama a geração pra organizar o extrato
organizaExtrato()