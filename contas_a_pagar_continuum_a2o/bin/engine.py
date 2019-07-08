#import sqlanydb
import pyodbc
import csv
import datetime

def cnpj_for(codi_emp, nome_for):
    #connection = sqlanydb.connect(host="SRVERP", uid='EXTERNO', pwd='dominio', eng='srvcontabil', dbn='Contabil')
    connection = pyodbc.connect(DSN='Contabil',UID='EXTERNO',PWD='dominio',PORT='2638')
    cursor = connection.cursor()
    cursor.execute(f"SELECT MAX(cgce_for)"
                   f"  FROM bethadba.effornece "
                   f" WHERE codi_emp = {codi_emp} "
                   f"   AND nome_for LIKE '%{nome_for}%'")
    data = cursor.fetchone()
    cursor.close()
    connection.close()

    return data

def cnpj_for_nota(codi_emp, nume_nota, emissao_nota_ini, emissao_nota_fim):
    #connection = sqlanydb.connect(host="SRVERP", uid='EXTERNO', pwd='dominio', eng='srvcontabil', dbn='Contabil')
    connection = pyodbc.connect(DSN='Contabil',UID='EXTERNO',PWD='dominio',PORT='2638')
    cursor = connection.cursor()
    cursor.execute(f"SELECT MAX(cgce_for) "
                   f"  FROM bethadba.efentradas AS ent"
                   f"       INNER JOIN bethadba.effornece AS forn"
                   f"            ON    forn.codi_emp = ent.codi_emp"
                   f"              AND forn.codi_for = ent.codi_for"
                   f" WHERE ent.codi_emp = {codi_emp}"
                   f"   AND ent.nume_ent = {nume_nota}"
                   f"   AND ( ( ent.ddoc_ent BETWEEN DATE('{emissao_nota_ini}') AND DATE('{emissao_nota_fim}') ) "
                   f"        OR ( ent.dent_ent BETWEEN DATE('{emissao_nota_ini}') AND DATE('{emissao_nota_fim}') ) ) ")
    data = cursor.fetchone()
    cursor.close()
    connection.close()

    return data

def cnpj_for_nota_2(codi_emp, nume_nota, nome_for):
    #connection = sqlanydb.connect(host="SRVERP", uid='EXTERNO', pwd='dominio', eng='srvcontabil', dbn='Contabil')
    connection = pyodbc.connect(DSN='Contabil',UID='EXTERNO',PWD='dominio',PORT='2638')
    cursor = connection.cursor()
    cursor.execute(f"SELECT MAX(cgce_for) "
                   f"  FROM bethadba.efentradas AS ent"
                   f"       INNER JOIN bethadba.effornece AS forn"
                   f"            ON    forn.codi_emp = ent.codi_emp"
                   f"              AND forn.codi_for = ent.codi_for"
                   f" WHERE ent.codi_emp = {codi_emp}"
                   f"   AND ent.nume_ent = {nume_nota}"
                   f"   AND forn.nome_for LIKE '%{nome_for}%' ")
    data = cursor.fetchone()
    cursor.close()
    connection.close()

    return data

def codi_conta(codi_emp, cgce_for_):
    #connection = sqlanydb.connect(host="SRVERP", uid='EXTERNO', pwd='dominio', eng='srvcontabil', dbn='Contabil')
    connection = pyodbc.connect(DSN='Contabil',UID='EXTERNO',PWD='dominio',PORT='2638')
    cursor = connection.cursor()
    cursor.execute(f"SELECT MAX(codi_cta) "
                   f"  FROM bethadba.effornece "
                   f" WHERE codi_emp = {codi_emp} "
                   f"   AND cgce_for LIKE '%{cgce_for_}%'")
    data = cursor.fetchone()
    cursor.close()
    connection.close()

    return data

def codi_conta_cli(codi_emp, cgce_cli_):
    #connection = sqlanydb.connect(host="SRVERP", uid='EXTERNO', pwd='dominio', eng='srvcontabil', dbn='Contabil')
    connection = pyodbc.connect(DSN='Contabil',UID='EXTERNO',PWD='dominio',PORT='2638')
    cursor = connection.cursor()
    cursor.execute(f"SELECT MAX(codi_cta) "
                   f"  FROM bethadba.efclientes "
                   f" WHERE codi_emp = {codi_emp} "
                   f"   AND cgce_cli LIKE '%{cgce_cli_}%'")
    data = cursor.fetchone()
    cursor.close()
    connection.close()

    return data

def cnpj_emp_atual(codi_emp):
    #connection = sqlanydb.connect(host="SRVERP", uid='EXTERNO', pwd='dominio', eng='srvcontabil', dbn='Contabil')
    connection = pyodbc.connect(DSN='Contabil',UID='EXTERNO',PWD='dominio',PORT='2638')
    cursor = connection.cursor()
    cursor.execute(f"SELECT MAX(cgce_emp)"
                   f"  FROM bethadba.geempre "
                   f" WHERE codi_emp = {codi_emp}")
    data = cursor.fetchone()
    cursor.close()
    connection.close()

    return data

def codi_emp_atual(cgce_emp):
    #connection = sqlanydb.connect(host="SRVERP", uid='EXTERNO', pwd='dominio', eng='srvcontabil', dbn='Contabil')
    connection = pyodbc.connect(DSN='Contabil',UID='EXTERNO',PWD='dominio',PORT='2638')
    cursor = connection.cursor()
    cursor.execute(f"SELECT MAX(codi_emp)"
                   f"  FROM bethadba.geempre "
                   f" WHERE cgce_emp = {cgce_emp}")
    data = cursor.fetchone()
    cursor.close()
    connection.close()

    return data

#_codi_emp = int(input('Informe o código da empresa Matriz na Domínio: '))

#entrada = 'Y:\\18 - DEPARTAMENTO DE PROJETOS\\Elder\\Importador\\Conjunto de Dados\\Layouts\\Contas Pagas\\Avaliando\\Al Restaurante\\lanc_contabil_contas_a_pagar_al_restaurante\\temp\\pagtos_agrupados.csv'
#saida = open('Y:\\18 - DEPARTAMENTO DE PROJETOS\\Elder\\Importador\\Conjunto de Dados\\Layouts\\Contas Pagas\\Avaliando\\Al Restaurante\\lanc_contabil_contas_a_pagar_al_restaurante\\saida\\pagtos_agrupados.csv', 'w')
entrada = 'temp\\pagtos_agrupados.csv'
saida = open('saida\\pagtos_agrupados.csv', 'w')
with open(entrada, 'rt') as csvfile:
    csvreader = csv.reader(csvfile, delimiter=';')
    for row in csvreader:
        if str(row[0]) == 'Documento':
            saida.write('Documento;Nome Fornecedor;CNPJ Fornecedor;Emissao;Vencimento;Banco Planilha;Banco Oco. Extrato;Data Pagto;Data Oco. Extrato;Valor Pago;Valor Desconto;Valor Juros;Valor Multa;Numero Titulo;Empresa;Codigo Conta Dominio;OBS;Tipo Pagto;Categoria\n')
        else:
            _codi_emp = str(codi_emp_atual(row[19])).replace(' ', '').replace('(', '').replace(')', '')\
                .replace(',', '').replace('None', "")
            _codi_emp = int(_codi_emp)

            _banco_arquivo = str(row[5])

            if _codi_emp == 343:
                if _banco_arquivo.count("BRADESCO") > 0 and _banco_arquivo.count("SP") > 0:
                   _codi_emp = 379
                if _banco_arquivo.count("BRADESCO") > 0 and _banco_arquivo.count("DF") > 0:
                   _codi_emp = 376
                if _banco_arquivo.count("BRADESCO") > 0 and _banco_arquivo.count("RJ") > 0:
                   _codi_emp = 371

            _cnpj_for = str(row[2]).replace("'", "")

            _cnpj_emp_atual = str(cnpj_emp_atual(_codi_emp)).replace(' ', '').replace('(', '').replace(')', '')\
                .replace(',', '').replace('None', "'")

            if _cnpj_emp_atual == _cnpj_for:
                _cnpj_for = "'"

            # busca o código da conta para quando for filial
            _cnpj_filtro = _cnpj_for.replace("'", '')
            if _cnpj_filtro != "":
                _codi_cta = str(codi_conta(_codi_emp, _cnpj_filtro)).replace(' ', '').replace('(', '').replace(')','').replace(
                    ',', '').replace('None', "")
            else:
                _codi_cta = ""

            result = (f"{row[0]};{row[1]};{row[2]};{row[3]};{row[4]};{row[5]};{row[6]};{row[7]};{row[8]};{row[9]};{row[10]}"
                          f";{row[11]};{row[12]};{row[13]};{_codi_emp};{_codi_cta};{row[16]};{row[17]};{row[18]}\n")
            saida.write(result)

saida.close()

entrada_recebto = 'temp\\recebtos_agrupados.csv'
saida_recebto = open('saida\\recebtos_agrupados.csv', 'w')
with open(entrada_recebto, 'rt') as csvfile:
    csvreader = csv.reader(csvfile, delimiter=';')
    for row in csvreader:
        if str(row[0]) == 'Documento':
            saida_recebto.write('Documento;Nome Cliente;CNPJ Cliente;Emissao;Vencimento;Banco Planilha;Banco Oco. Extrato;Data Pagto;Data Oco. Extrato;Valor Pago;Valor Desconto;Valor Juros;Valor Multa;Numero Titulo;Empresa;Codigo Conta Dominio;OBS;Tipo Pagto;Categoria\n')
        else:
            _codi_emp = str(codi_emp_atual(row[19])).replace(' ', '').replace('(', '').replace(')', '')\
                .replace(',', '').replace('None', "")
            _codi_emp = int(_codi_emp)

            _banco_arquivo = str(row[5])

            if _codi_emp == 343:
                if _banco_arquivo.count("BRADESCO") > 0 and _banco_arquivo.count("SP") > 0:
                   _codi_emp = 379
                if _banco_arquivo.count("BRADESCO") > 0 and _banco_arquivo.count("DF") > 0:
                   _codi_emp = 376
                if _banco_arquivo.count("BRADESCO") > 0 and _banco_arquivo.count("RJ") > 0:
                   _codi_emp = 371

            _cnpj_cli = str(row[2]).replace("'", "")

            _cnpj_emp_atual = str(cnpj_emp_atual(_codi_emp)).replace(' ', '').replace('(', '').replace(')', '')\
                .replace(',', '').replace('None', "'")

            if _cnpj_emp_atual == _cnpj_cli:
                _cnpj_cli = "'"

            # busca o código da conta para quando for filial
            _cnpj_filtro = _cnpj_cli.replace("'", '')
            if _cnpj_filtro != "":
                _codi_cta = str(codi_conta_cli(_codi_emp, _cnpj_filtro)).replace(' ', '').replace('(', '').replace(')','').replace(
                    ',', '').replace('None', "")
            else:
                _codi_cta = ""

            result = (f"{row[0]};{row[1]};{row[2]};{row[3]};{row[4]};{row[5]};{row[6]};{row[7]};{row[8]};{row[9]};{row[10]}"
                          f";{row[11]};{row[12]};{row[13]};{row[14]};{_codi_cta};{row[16]};{row[17]};{row[18]}\n")
            saida_recebto.write(result)

saida_recebto.close()
