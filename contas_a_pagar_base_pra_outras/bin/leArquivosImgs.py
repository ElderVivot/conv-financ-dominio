import os
import unicodedata
import re
import time
import sys
import csv
#import openpyxl
#import pandas as pd
import datetime
import funcoesUteis
import pytesseract as ocr
import funcoesUteis
from PIL import Image

caminho_base = "" #"Y:\\18 - DEPARTAMENTO DE PROJETOS\\Elder\\Importador\\Conjunto de Dados\\Layouts\\Financeiro\\_ferramentas\\contas_a_pagar_base_pra_outras\\"

def ImageToJPG(arquivos=funcoesUteis.buscaArquivosEmPasta(caminho=f"{caminho_base}entrada",extensao=(".BMP", ".PNG", ".GIF"))):
    for arquivo in arquivos:
        nome_arquivo = os.path.basename(arquivo)
        saida = f"{caminho_base}temp\\" + str(nome_arquivo[0:len(nome_arquivo)-4]) + ".jpg"
        try:

           # chama o comando pra transformação do PDF
            comando = f"convert \"{arquivo}[0]\" -size 1920x1080 \"{saida}\""
            os.system(comando)
        except Exception as ex:
            print(f"Nao foi possivel transformar o arquivo \"{saida}\". O erro é: {str(ex)}")

# chama a geração da transformação pra PDF
ImageToJPG()

def imageToText(arquivos=funcoesUteis.buscaArquivosEmPasta(caminho=f"{caminho_base}temp", extensao=(".JPG"))):
    # print(arquivos)
    for arquivo in arquivos:
        nome_arquivo = os.path.basename(arquivo)
        saida = f"{caminho_base}temp\\" + str(nome_arquivo[0:len(nome_arquivo)-4]) + ".txt"
        saida = open(saida, "w", encoding='utf-8')
        phrase = ocr.image_to_string(Image.open(arquivo), lang='por')
        saida.write(phrase)
        saida.close()

imageToText()

def processText(arquivos=funcoesUteis.buscaArquivosEmPasta(caminho=f"{caminho_base}temp", extensao=(".JPG")),separadorCampos=' '):
    for arquivo in arquivos:
        with open(arquivo, 'rt') as csvfile:
            csvreader = csv.reader(csvfile, delimiter=separadorCampos)
            for row in csvreader:
                numCampoNota = -1

                # primeiro lê os campos da linha pra identificar onde está a nota
                for key, campo in enumerate(row):
                    try:
                        nota = int(campo)
                    except Exception:
                        nota = 0

                    tracoProximoCampo = row[key+1]
                    if(tracoProximoCampo[0] == "-"):
                        tracoProximoCampo = True
                    else:
                        tracoProximoCampo = False
                    
                    if nota > 0 and tracoProximoCampo is True:
                        numCampoNota = key
                        break

                nomeFornecedor = row[1:numCampoNota]

                nota = row[numCampoNota]

                

        