import xlrd
import os
import pandas as pd

def buscaArquivosEmPasta(caminho="Y:\\18 - DEPARTAMENTO DE PROJETOS\\Elder\\Importador\\Conjunto de Dados\\Layouts\\Financeiro\\_ferramentas\\contas_a_pagar_lojas_duilson\\entrada", extensao=".xls"):
    arquivos = os.listdir(caminho)
    lista_arquivos = []

    for arquivo in arquivos:
        if arquivo.endswith(extensao):
            lista_arquivos.append(caminho+"\\"+arquivo)

    return lista_arquivos

def leXls_Xlsx(arquivos=buscaArquivosEmPasta(),saida="Y:\\18 - DEPARTAMENTO DE PROJETOS\\Elder\\Importador\\Conjunto de Dados\\Layouts\\Financeiro\\_ferramentas\\contas_a_pagar_lojas_duilson\\temp\\baixas.csv"):
    saida = open(saida, "w")
    lista_dados = []
    for arquivo in arquivos:
        arquivo = xlrd.open_workbook(arquivo)

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

                # ignora linhas em branco
                valor_linha = planilha.row(rowx=i)

                if valor_linha.count("") == max_column:
                    continue

                lista_dados.append(valor_linha)

                # lê as colunas
                for j in range(0, max_column):
                    # pega o valor da célula
                    cell_obj = planilha.cell_value(rowx=i, colx=j)
                    # gera o resultado num arquivo
                    resultado = "{}".format(str(cell_obj)) + ';'
                    resultado = resultado.replace('None', '')
                    saida.write(resultado)

                # faz uma quebra de linha para passar pra nova linha
                saida.write('\n')
    # fecha o arquivo
    saida.close()
    print(lista_dados)

def excelPandas(arquivos=buscaArquivosEmPasta(), saida = "Y:\\18 - DEPARTAMENTO DE PROJETOS\\Elder\\Importador\\Conjunto de Dados\\Layouts\\Financeiro\\_ferramentas\\contas_a_pagar_lojas_duilson\\temp\\baixas.csv"):
    saida = open(saida, "w")
    lista_dados = []
    for arquivo in arquivos:
        #data = pd.read_excel(arquivo)
        #data = pd.ExcelFile(arquivo)
        #data = str(data

        xl_file = pd.ExcelFile(arquivo)

        for sheet_name in xl_file.sheet_names:



        dfs = {sheet_name: xl_file.parse(sheet_name)
               for sheet_name in xl_file.sheet_names}

        print(dfs)

        #df = pd.DataFrame(data)
        #data.to_csv(saida, sep=";")
        #saida.write(data)
        #print(data)
#
#exportar = leXls_Xlsx()
excelPandas()