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
                linha = funcoesUteis.removerAcentos(str(linha).upper().replace("\n", ""))
                # ignora linhas totalmente em branco
                if(funcoesUteis.trataCampoTexto(linha) == ""):
                    continue
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
        linha_ja_impressa = {}

        posicao_historico = 0
        posicao_data = 0
        posicao_documento = 0

        data = datetime.datetime.strptime("01/01/1900", "%d/%m/%Y").date()
        data = data.strftime("%d/%m/%Y")
        documento = ""
        valor = 0
        operador = ""
        fornecedor_cliente = ""
        historico = ""
        ano_extrato = 0

        for num_row, row in enumerate(linhas):

            row = str(row)

            try:
                linha_ja_impressa[num_row] = linha_ja_impressa[num_row]
            except Exception:
                linha_ja_impressa[num_row] = 0

            posicao_data_temp = row.upper().find("DATA")
            if posicao_data_temp > 0:
                if posicao_data_temp > 5:
                    posicao_data = posicao_data_temp-5
                else:
                    posicao_data = 0

            posicao_documento_temp = row.upper().find("DOCUMENTO")
            if posicao_documento_temp > 0:
                posicao_documento = posicao_documento_temp

            # DAQUI PRA BAIXO analisando a complementação do depósito
            posicao_historico_temp = row.upper().find("HISTORICO")
            if posicao_historico_temp > 0:
                # serve pra identificar onde o historico começa, visto que algumas vezes não tem o documento no PDF
                if posicao_documento == 0:
                    posicao_historico = posicao_historico_temp - posicao_data_temp + 8 # pega 8 posições a menos pra questão de 'segurança'
                else:
                    posicao_historico = posicao_historico_temp - 10 # pega 10 posições a menos pra questão de 'segurança'
                if posicao_historico > posicao_historico_temp:
                    posicao_historico = posicao_historico_temp

            historico_temp = funcoesUteis.trataCampoTexto(row[posicao_historico:posicao_historico+65])

            # ignora as linhas que são referente à saldos
            if historico_temp.count("SALDO") > 0:
                historico_temp = " "

            # serve pros extratos que não tem a data com o ano, e sim apenas com o dia e mês
            periodo_temp = row.strip().split(':')
            if periodo_temp[0] == 'PERIODO':
                ano_extrato = periodo_temp[1].split('-')
                ano_extrato = funcoesUteis.trataCampoTexto(ano_extrato[0])
                ano_extrato = ano_extrato[-4:]

            # serve pra identificar o tamanho das datas
            if posicao_documento == 0:
                qtd_char_data = posicao_historico - posicao_data
                if qtd_char_data > 17:
                    qtd_char_data = 17
            else:
                qtd_char_data = posicao_documento - posicao_data
                if qtd_char_data > 17:
                    qtd_char_data = 17

            # lê a próxima linha pra saber se é uma linha com complementação dos dados da atual ou não
            try:
                proxima_linha = linhas[num_row+1]
            except Exception:
                proxima_linha = ""

            data_temp_proxima_linha = proxima_linha[posicao_data:posicao_data+qtd_char_data-1]
            data_temp_proxima_linha = data_temp_proxima_linha.strip()
            # caso a data esteja apenas no forma DD/MM ele coloca o ano
            if len(data_temp_proxima_linha) == 5:
                data_temp_proxima_linha = (f'{data_temp_proxima_linha}/{ano_extrato}')
            data_temp_proxima_linha = funcoesUteis.retornaCampoComoData(data_temp_proxima_linha)

            # ---- começa o tratamento de cada campo ----
            data_temp = row[posicao_data:posicao_data+qtd_char_data-1]
            data_temp = data_temp.strip()
            # caso a data esteja apenas no forma DD/MM ele coloca o ano
            if len(data_temp) == 5:
                data_temp = (f'{data_temp}/{ano_extrato}')
            data_temp = funcoesUteis.retornaCampoComoData(data_temp)

            historico_temp_proxima_linha = funcoesUteis.trataCampoTexto(proxima_linha[posicao_historico:posicao_historico+65])

            # ignora as linhas que são referente à saldos
            if historico_temp_proxima_linha.count("SALDO") > 0:
                historico_temp_proxima_linha = 1
            else:
                historico_temp_proxima_linha = 0

            # verifica se é uma data válida pra começar os tratamentos de cada campo
            if data_temp is not None:
                data = funcoesUteis.transformaCampoDataParaFormatoBrasileiro(data_temp)

                # ignora linhas que não são de pagamentos
                if data == "01/01/1900":
                    continue

                # retira os espaços excessivos
                row = funcoesUteis.trataCampoTexto(row)

                # divide as linhas em espaço pois as posições do BB variam muito, então vamos pegar os dados de acordo a posição base deles (agencia e tipo_operacao(D,C) )
                row_dividida = row.split()
                #print(row_dividida)

                tamanho_linha = len(row_dividida)-1
                
                documento_temp = funcoesUteis.trocaCaracteresTextoPraLetraX(row_dividida[1])
                
                # serve pra sabermos onde começar o processamento do histórico
                posicao_inicio_historico = 0
                if documento_temp.count('X') > 0:
                    posicao_inicio_historico = 1
                    documento = ""
                else:
                    posicao_inicio_historico = 2
                    documento = funcoesUteis.trataCampoTexto(row_dividida[1])

                historico = ""
                for i in range(posicao_inicio_historico,tamanho_linha):
                    historico = historico + " " + funcoesUteis.trataCampoTexto(row_dividida[i])
                historico = historico.strip()

                valor = funcoesUteis.removerAcentosECaracteresEspeciais(row_dividida[tamanho_linha])
                try:
                    operador = valor[-1]
                except Exception:
                    operador = ""
                valor = funcoesUteis.trataCampoDecimal(valor)
                if operador == "D":
                    operador = "-"
                else:
                    operador = "+"
                
                fornecedor_cliente = ""

                if historico_temp_proxima_linha == 1:
                    linha_ja_impressa[num_row+1] = 1

                # primeira geração dos dados quando todas as informações estão em uma linha apenas, ou seja, a próxima linha também já outro campo com data
                if (data_temp_proxima_linha is not None or historico_temp_proxima_linha == 1) and valor > 0:
                    saida.write(f"{data};{documento};{historico};{fornecedor_cliente};{valor:.2f};{operador}\n")
            
            # segunda geração dos dados quando as informações complementares está em APENAS uma LINHA ABAIXO
            if data_temp is None and historico_temp != "" and data_temp_proxima_linha is None and valor > 0 and linha_ja_impressa[num_row] == 0:
                fornecedor_cliente = fornecedor_cliente + " " + historico_temp

                # analisa se na verdade é um histórico válido, pois pode ser uma linha que contenha um tanto de carecter que não serve pra nada. Então considera como
                # histórico somente se conter o historico_temp válido
                historico_temp_inicio = funcoesUteis.trataCampoTexto(row[0:posicao_historico])
                if len(historico_temp_inicio) > 0:
                    fornecedor_cliente = ""

            # segundo geração dos dados quando as informações complementares está na LINHA ABAIXO
            if data_temp is None and historico_temp != "" and data_temp_proxima_linha is not None and valor > 0 and linha_ja_impressa[num_row] == 0:
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