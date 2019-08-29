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

        posicao_historico = 0
        posicao_data = 0

        data = datetime.datetime.strptime("01/01/1900", "%d/%m/%Y").date()
        data = data.strftime("%d/%m/%Y")
        documento = ""
        valor = 0
        operador = ""
        fornecedor_cliente = ""
        historico = ""

        for num_row, row in enumerate(linhas):

            posicao_data_temp = row.upper().find("DT.")
            if posicao_data_temp > 0:
                if posicao_data_temp > 5:
                    posicao_data = posicao_data_temp-5
                else:
                    posicao_data = 0

            # lê a próxima linha pra saber se é uma linha com complementação dos dados da atual ou não
            try:
                proxima_linha = linhas[num_row+1]
            except Exception:
                proxima_linha = ""

            data_temp_proxima_linha = proxima_linha[posicao_data:posicao_data+17]
            data_temp_proxima_linha = funcoesUteis.retornaCampoComoData(data_temp_proxima_linha)

            # ---- começa o tratamento de cada campo ----
            data_temp = row[posicao_data:posicao_data+17]
            data_temp = funcoesUteis.retornaCampoComoData(data_temp)
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

                # vai servir apenas pra identificar em qual posição está a agência
                data_movimento = row_dividida[1]
                data_movimento = funcoesUteis.retornaCampoComoData(data_movimento)

                # serve pra sabermos onde começar o processamento do histórico
                posicao_agencia = 0
                if data_movimento is None:
                    posicao_agencia = 1
                else:
                    posicao_agencia = 2

                # ------ INICIO POSICAO_OPERACAO - serve pra sabermos até onde o histórico vai
                try:
                    posicao_operacao_debito = row_dividida.index('D')
                except Exception:
                    posicao_operacao_debito = 0
                try:
                    posicao_operacao_credito = row_dividida.index('C')
                except Exception:
                    posicao_operacao_credito = 0
                
                posicao_operacao = 0
                
                if posicao_operacao_debito > 0:
                    if posicao_operacao_credito == 0:
                        posicao_operacao = posicao_operacao_debito
                    else:
                        if posicao_operacao_debito <= posicao_operacao_credito:
                            posicao_operacao = posicao_operacao_debito
                        else:
                            posicao_operacao = posicao_operacao_credito
                if posicao_operacao_credito > 0:
                    if posicao_operacao_debito == 0:
                        posicao_operacao = posicao_operacao_credito
                    else:
                        if posicao_operacao_credito <= posicao_operacao_debito:
                            posicao_operacao = posicao_operacao_credito
                        else:
                            posicao_operacao = posicao_operacao_debito
                # ------------- FIM POSICAO_OPERACAO

                primeiro_campo_historico = funcoesUteis.trocaCaracteresTextoPraLetraX(row_dividida[posicao_agencia+2])
                if primeiro_campo_historico.count('X') > 0:
                    posicao_inicio = posicao_agencia+2
                else:
                    posicao_inicio = posicao_agencia+3
                
                historico = ""
                for i in range(posicao_inicio,posicao_operacao-2):
                    historico = historico + " " + funcoesUteis.trataCampoTexto(row_dividida[i])
                historico = historico.strip()

                # ignora as linhas que são referente à saldos
                if historico.count("SALDO") > 0:
                    continue

                documento = funcoesUteis.trataCampoTexto(row_dividida[posicao_operacao-2])

                valor = funcoesUteis.trataCampoDecimal(row_dividida[posicao_operacao-1])
                
                operador = row_dividida[posicao_operacao]
                if operador == "D":
                   operador = "-"
                else:
                   operador = "+"
                
                fornecedor_cliente = ""

                # primeira geração dos dados quando todas as informações estão em uma linha apenas, ou seja, a próxima linha também já outro campo com data
                if data_temp_proxima_linha is not None and valor > 0:
                    saida.write(f"{data};{documento};{historico};{fornecedor_cliente};{valor:.2f};{operador}\n")
            
            # DAQUI PRA BAIXO analisando a complementação do depósito
            posicao_historico_temp = row.upper().find("HISTÓRICO")
            if posicao_historico_temp > 0:
                posicao_historico = posicao_historico_temp - 10 # pega 10 posições a menos pra questão de 'segurança'

            historico_temp = funcoesUteis.trataCampoTexto(row[posicao_historico:posicao_historico+65])

            fornecedor_cliente_temp = ""
            # segunda geração dos dados quando as informações complementares está em APENAS uma LINHA ABAIXO
            if data_temp is None and historico_temp != "" and data_temp_proxima_linha is None and valor > 0:
                fornecedor_cliente_temp = fornecedor_cliente_temp + " " + historico_temp
                fornecedor_cliente_temp = fornecedor_cliente_temp.strip()

                if historico.count('TED') > 0 or historico.count('TRANSF') > 0 or historico.count('DOC CR') > 0:
                    fornecedor_cliente_dividido = fornecedor_cliente_temp.split()

                    for campo in fornecedor_cliente_dividido:
                        if funcoesUteis.trocaCaracteresTextoPraLetraX(campo).count('X') > 0:
                            fornecedor_cliente = fornecedor_cliente + " " + campo

                    fornecedor_cliente = fornecedor_cliente.strip()
                else:
                    fornecedor_cliente = fornecedor_cliente_temp

                # analisa se na verdade é um histórico válido, pois pode ser uma linha que contenha um tanto de carecter que não serve pra nada. Então considera como
                # histórico somente se conter o historico_temp válido
                historico_temp_inicio = funcoesUteis.trataCampoTexto(row[0:posicao_historico])
                if len(historico_temp_inicio) > 0:
                    fornecedor_cliente = ""

            # terceira geração dos dados quando as informações complementares está em MAIS DE UMA LINHA ABAIXO
            if data_temp is None and historico_temp != "" and data_temp_proxima_linha is not None and valor > 0:
                fornecedor_cliente_temp = fornecedor_cliente_temp + " " + historico_temp
                fornecedor_cliente_temp = fornecedor_cliente_temp.strip()

                if historico.count('TED') > 0 or historico.count('TRANSF') > 0 or historico.count('DOC CR') > 0:
                    fornecedor_cliente_dividido = fornecedor_cliente_temp.split()

                    for campo in fornecedor_cliente_dividido:
                        if funcoesUteis.trocaCaracteresTextoPraLetraX(campo).count('X') > 0:
                            fornecedor_cliente = fornecedor_cliente + " " + campo

                    fornecedor_cliente = fornecedor_cliente.strip()
                else:
                    fornecedor_cliente = fornecedor_cliente_temp
                
                # analisa se na verdade é um histórico válido, pois pode ser uma linha que contenha um tanto de carecter que não serve pra nada. Então considera como
                # histórico somente se conter o historico_temp válido
                historico_temp_inicio = funcoesUteis.trataCampoTexto(row[0:posicao_historico])
                if len(historico_temp_inicio) > 0:
                    fornecedor_cliente = ""

                saida.write(f"{data};{documento};{historico};{fornecedor_cliente};{valor:.2f};{operador}\n")
                
    saida.close()

# chama a geração pra organizar o extrato
organizaExtrato()