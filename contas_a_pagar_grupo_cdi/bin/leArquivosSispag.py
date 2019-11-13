# coding: utf-8

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
import pytesseract as ocr
from PIL import Image

caminho_leitura = "" #"Y:\\18 - DEPARTAMENTO DE PROJETOS\\Elder\\Importador\\Conjunto de Dados\\Layouts\\Financeiro\\_ferramentas\\contas_a_pagar_grupo_cdi\\"

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

def ImageToText(arquivo):
    nome_arquivo = os.path.basename(arquivo)
    saida = f"{caminho_leitura}temp\\" + str(nome_arquivo[0:len(nome_arquivo)-4]) + ".tmp"
    saida = open(saida, "w", encoding='utf-8')
    phrase = ocr.image_to_string(Image.open(arquivo), lang='por')
    saida.write(phrase)
    saida.close()

def PDFImgToText(arquivo):
    nome_arquivo = os.path.basename(arquivo)
    saida = f"{caminho_leitura}temp\\" + str(nome_arquivo[0:len(nome_arquivo)-4]) + ".jpg"

    comando = f"magick -density 300 \"{arquivo}\" \"{saida}\""
    os.system(comando)

    ImageToText(saida)
    
def PDFToText(arquivos=buscaArquivosEmPasta(caminho=f"{caminho_leitura}temp",extensao=(".PDF")), mode = "simple"):
    for arquivo in arquivos:
        nome_arquivo = os.path.basename(arquivo)
        saida = f"{caminho_leitura}temp\\" + str(nome_arquivo[0:len(nome_arquivo)-4]) + ".tmp"
        try:
            # verifica se o Windows é 32 ou 64 bits
            architecture = platform.architecture()
            if architecture[0].count('32') > 0:
                pdftotext = "pdftotext32.exe"
            else:
                pdftotext = "pdftotext64.exe"
            
            # chama o comando pra transformação do PDF
            comando = f"{caminho_leitura}bin\\{pdftotext} -{mode} \"{arquivo}\" \"{saida}\""
            os.system(comando)

            # analisa se o PDF é uma imagem
            tamanho_arquivo = os.path.getsize(saida)
            if(tamanho_arquivo <= 5):
                PDFImgToText(arquivo)

        except Exception as ex:
            print(f"Nao foi possivel transformar o arquivo \"{saida}\". O erro é: {str(ex)}")

PDFToText()

def leTxt(arquivos=buscaArquivosEmPasta(caminho=f"{caminho_leitura}temp", extensao=(".TMP"))):
    lista_arquivos = {}
    lista_linha = []
    
    for arquivo in arquivos:
        nome_arquivo = os.path.basename(arquivo)
        saida = f"{caminho_leitura}temp\\" + str(nome_arquivo[0:len(nome_arquivo)-4]) + ".txt"
        saida = open(saida, "w", encoding='utf-8')

        # pra cada arquivo criar uma posição no dicionário
        lista_arquivos[arquivo] = lista_linha[:]
        
        # le o arquivo e grava num vetor
        with open(arquivo, 'rt', encoding='utf-8') as txtfile:
            for linha in txtfile:
                linha = funcoesUteis.trataCampoTexto(linha)
                if linha == "":
                    continue
                lista_linha.append(linha)
                saida.write(f'{linha}\n')
            lista_arquivos[arquivo] = lista_linha[:]
            lista_linha.clear()
        txtfile.close()

        saida.close()

    return lista_arquivos

leTxt()