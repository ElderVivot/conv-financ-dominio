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

caminho_base = "C:\\Programming\\conversores-financeiro-awk\\contas_a_pagar_grupo_mobi\\"

def PDFToText(arquivos=funcoesUteis.buscaArquivosEmPasta(caminho=f"{caminho_base}entrada",extensao=(".PDF")), mode = "simple"):
    for arquivo in arquivos:
        nome_arquivo = os.path.basename(arquivo)
        saida = f"{caminho_base}temp\\" + str(nome_arquivo[0:len(nome_arquivo)-4]) + ".txt"
        try:

            # verifica se o Windows é 32 ou 64 bits
            architecture = platform.architecture()
            if architecture[0].count('32') > 0:
                pdftotext = "pdftotext32.exe"
            else:
                pdftotext = "pdftotext64.exe"
            
            # chama o comando pra transformação do PDF
            comando = f"{caminho_base}bin\\{pdftotext} -{mode} \"{arquivo}\" \"{saida}\""
            os.system(comando)
        except Exception as ex:
            print(f"Nao foi possivel transformar o arquivo \"{saida}\". O erro é: {str(ex)}")

# chama a geração da transformação pra PDF
PDFToText()

def leLinhasPDF(arquivos=funcoesUteis.buscaArquivosEmPasta(caminho=f"{caminho_base}temp", extensao=(".TXT"))):
    lista_arquivos = {}
    lista_linha = []

    extratos = f"{caminho_base}temp\\extrato_cartao_temp.csv"
    extratos = open(extratos, "a", encoding='utf-8')
    
    for arquivo in arquivos:
        # pra cada arquivo criar uma posição no dicionário
        lista_arquivos[arquivo] = lista_linha[:]
        
        # le o arquivo e grava num vetor
        with open(arquivo, 'rt') as txtfile:
            for linha in txtfile:
                linha = funcoesUteis.removerAcentos(str(linha).upper().replace("\n", ""))
                # linha = linha.strip()
                # ignora linhas totalmente em branco
                if(funcoesUteis.trataCampoTexto(linha) == ""):
                    continue
                lista_linha.append(linha)
                extratos.write(f"{linha}\n")
            lista_arquivos[arquivo] = lista_linha[:]
            lista_linha.clear()
        txtfile.close()

    extratos.close()

    return lista_arquivos

def organizaExtratoSicoob(linhas):
    linhasExtrato = []
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
    conta_corrente = ""

    for num_row, row in enumerate(linhas):

        row = str(row)

        try:
            linha_ja_impressa[num_row] = linha_ja_impressa[num_row]
        except Exception:
            linha_ja_impressa[num_row] = 0

        conta_corrente_temp = row.strip().split(':')
        if conta_corrente_temp[0] == 'CONTA':
            conta_corrente = conta_corrente_temp[1].split('-')
            conta_corrente = funcoesUteis.trataCampoTexto(conta_corrente[0])

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

            valor_imprimir = str(f"{valor:.2f}")
            valor_imprimir = valor_imprimir.replace('.', ',')

            if historico_temp_proxima_linha == 1:
                linha_ja_impressa[num_row+1] = 1

            # primeira geração dos dados quando todas as informações estão em uma linha apenas, ou seja, a próxima linha também já outro campo com data
            if ( data_temp_proxima_linha is not None or historico_temp_proxima_linha == 1) and valor > 0:
                linhasExtrato.append(f"756;{conta_corrente};;{data};{operador};{valor_imprimir};{documento};{historico};{fornecedor_cliente}\n")
        
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

            linhasExtrato.append(f"756;{conta_corrente};;{data};{operador};{valor_imprimir};{documento};{historico};{fornecedor_cliente}\n")
    
    return linhasExtrato

def organizaExtratoItau(linhas):
    linhasExtrato = []

    data = datetime.datetime.strptime("01/01/1900", "%d/%m/%Y").date()
    data = data.strftime("%d/%m/%Y")
    documento = ""
    valor = 0
    operador = ""
    fornecedor_cliente = ""
    historico = ""
    ano_extrato = 0
    conta_corrente = ""

    for num_row, row in enumerate(linhas):

        row = str(row)
        row = funcoesUteis.trataCampoTexto(row)

        posicao_conta_corrente = row.upper().find("AGENCIA/CONTA")
        if posicao_conta_corrente > 0:
            conta_corrente = row[posicao_conta_corrente+14:]
            conta_corrente = conta_corrente.split('/')
            conta_corrente = funcoesUteis.trataCampoTexto(conta_corrente[1])

        if row[0:10] == "EXTRATO DE":
            ano_extrato = row[10:21].strip()
            ano_extrato = ano_extrato.split('/')
            ano_extrato = ano_extrato[2]

        # divide as linhas em espaço pois as posições do BB variam muito, então vamos pegar os dados de acordo a posição base deles (agencia e tipo_operacao(D,C) )
        row_dividida = row.split()

        # vai servir apenas pra identificar em qual posição está a agência
        data = f"{row_dividida[0]}/{ano_extrato}" 
        data = funcoesUteis.retornaCampoComoData(data)
        data = funcoesUteis.transformaCampoDataParaFormatoBrasileiro(data)

        historico = ""
        for i in range(1,len(row_dividida)-1):
            historico = historico + " " + funcoesUteis.trataCampoTexto(row_dividida[i])
        historico = historico.strip()

        # ignora as linhas que são referente à saldos
        if historico.count("SALDO") > 0 or historico.count("SDO CT") > 0:
            continue

        valor = funcoesUteis.trataCampoTexto(row_dividida[-1])
        if valor.count('-') > 0:
            operador = "-"
        else:
            operador = "+"
        valor = funcoesUteis.trataCampoDecimal(valor)

        valor_imprimir = str(f"{valor:.2f}")
        valor_imprimir = valor_imprimir.replace('.', ',')

        if data is not None:
            linhasExtrato.append(f"341;{conta_corrente};;{data};{operador};{valor_imprimir};{documento};{historico};{fornecedor_cliente}\n")
    
    return linhasExtrato

def organizaExtratoSantander(linhas):
    linhasExtrato = []

    data = datetime.datetime.strptime("01/01/1900", "%d/%m/%Y").date()
    data = data.strftime("%d/%m/%Y")
    documento = ""
    valor = 0
    operador = ""
    fornecedor_cliente = ""
    historico = ""
    conta_corrente = ""
    posicao_conta_corrente = 0

    for num_row, row in enumerate(linhas):

        row = str(row)
        row = funcoesUteis.trataCampoTexto(row)

        posicao_conta_corrente = row.upper().find("CONTA:")
        if posicao_conta_corrente > 0:
            conta_corrente = row[posicao_conta_corrente+6:]
            conta_corrente = funcoesUteis.trataCampoTexto(conta_corrente)

        # divide as linhas em espaço pois as posições do BB variam muito, então vamos pegar os dados de acordo a posição base deles (agencia e tipo_operacao(D,C) )
        row_dividida = row.split()

        # vai servir apenas pra identificar em qual posição está a agência
        data = f"{row_dividida[0]}" 
        data = funcoesUteis.retornaCampoComoData(data)
        data = funcoesUteis.transformaCampoDataParaFormatoBrasileiro(data)

        valor = funcoesUteis.trataCampoTexto(row_dividida[-1])

        # este valor 2 tem pois muitas das vezes no extrato Santander tem duas colunas de valores, sendo uma saldo e outro do valor em si
        try:
            valor2 = funcoesUteis.trataCampoTexto(row_dividida[-2])
        except Exception:
            valor2 = '0'
        # o if abaixo avalia se a penúltima posição do arquivo é valor, caso seja, ele que é a operação
        if valor2.count(',') > 0:
            valor = valor2
            posicao_valor = len(row_dividida)-2
        else:
            valor = valor
            posicao_valor = len(row_dividida)-1

        # analisa se a operação é soma ou subtrai
        if valor.count('-') > 0:
            operador = "-"
        else:
            operador = "+"
        valor = funcoesUteis.trataCampoDecimal(valor)

        historico = ""
        for i in range(1,posicao_valor):
            historico = historico + " " + funcoesUteis.trataCampoTexto(row_dividida[i])
        historico = historico.strip()

        # ignora as linhas que são referente à saldos
        if historico.count("SALDO") > 0:
            continue

        valor_imprimir = str(f"{valor:.2f}")
        valor_imprimir = valor_imprimir.replace('.', ',')

        if data is not None:
            linhasExtrato.append(f"33;{conta_corrente};;{data};{operador};{valor_imprimir};{documento};{historico};{fornecedor_cliente}\n")
    
    return linhasExtrato

def identificaTipoMovimento():
    
    extratos = f"{caminho_base}temp\\extrato_cartao.csv"
    extratos = open(extratos, "a", encoding='utf-8')
    extratos.write("Banco;Conta Corrente;Tipo Movimento;Data;Operacao;Valor;Num. Doc.;Historico;Historico Complementar\n")

    lista_arquivos = leLinhasPDF()

    for linhas in lista_arquivos.values():

        is_sicoob = 0
        is_itau = 0
        is_santander = 0

        for num_linha, linha in enumerate(linhas):
            # SICOOB
            if linha.count('SICOOB') > 0 and linha.count('COOPERATIVA') > 0:
                is_sicoob += 1
            # ITAU
            if linha.count('ITAUEMPRESAS') > 0:
                is_itau += 1
            # SANTANDER
            if linha.count('SANTANDER') > 0 and linha.count('EMPRESARIAL') > 0:
                is_santander += 1
            if linha.count('4004-2125') > 0:
                is_santander += 1
            if linha.count('40042125') > 0:
                is_santander += 1

        # geração do extrado do SICOOB
        if is_sicoob >= 1:
            extratoSicoob = organizaExtratoSicoob(linhas)
            extratos.writelines(extratoSicoob)

        # geração do extrado do ITAÚ
        if is_itau >= 1:
            extratoItau = organizaExtratoItau(linhas)
            extratos.writelines(extratoItau)

        # geração do extrado do ITAÚ
        if is_santander >= 2:
            extratoSantander = organizaExtratoSantander(linhas)
            extratos.writelines(extratoSantander)

    extratos.close()

# chama a geração dos dados
identificaTipoMovimento()