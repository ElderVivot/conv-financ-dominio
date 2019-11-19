# encoding: utf-8

#import sqlanydb
import csv
import leArquivos
from operator import itemgetter
import datetime
import re
import os

pasta = "entrada" #"Y:\\18 - DEPARTAMENTO DE PROJETOS\\Elder\\Importador\\Conjunto de Dados\\Layouts\\Financeiro\\_ferramentas\\lancamentos_contabeis_sistema_fujiclick\\entrada"
coluna_para = 6

codi_emp = str(input('\n- Informe o código da empresa matriz dentro da Domínio: '))

def processaDePara():
    de_para = leArquivos.leXls_Xlsx([f"entrada\\{codi_emp}.xls", f"entrada\\{codi_emp}.xlsx"])

    for root, dirs, files in os.walk(pasta):
        for name_file in files:
            if name_file.upper().endswith('.TXT'):

                saida = "saida\\" + name_file
                saida = open(saida, "w", encoding='utf-8')

                with open( os.path.join(root,name_file) , 'rt', encoding='windows-1252') as txtfile:
                    for row in txtfile:
                        row = str(row)
                        if row[0:2] == '02':

                            try:
                                cta_debito = int(row[34:41])
                                cta_debito = int(list(filter( lambda x: x[0] == f"{cta_debito}", de_para ))[0][coluna_para])
                            except Exception:
                                cta_debito = 0
                            cta_debito = f"{cta_debito:0>7d}"
                            
                            try:
                                cta_credito = int(row[41:48])
                                cta_credito = int(list(filter( lambda x: x[0] == f"{cta_credito}", de_para ))[0][coluna_para])
                            except Exception:
                                cta_credito = 0
                            cta_credito = f"{cta_credito:0>7d}"

                            saida.write(f"{row[0:34]}{cta_debito}{cta_credito}{row[48:]}")
                        else:
                            saida.write(row)

processaDePara()

    

