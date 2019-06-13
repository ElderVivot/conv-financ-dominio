# coding: cp1252

import sqlanydb
import pyodbc
import csv
import datetime

def cnpj_for(codi_emp, nome_for):
    #connection = sqlanydb.connect(host="SRVERP", uid='EXTERNO', pwd='dominio', eng='srvcontabil', dbn='Contabil')
    connection = pyodbc.connect(DSN='Contabil',UID='EXTERNO',PWD='dominio',PORT='2638')
    cursor = connection.cursor()
    cursor.execute(f"SELECT MAX(cgce_for) "
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

_codi_emp = int(input('Informe o código da Empresa ou Filial na Domínio: '))

#entrada = 'Y:\\18 - DEPARTAMENTO DE PROJETOS\\Elder\\Importador\\Conjunto de Dados\\Layouts\\Contas Pagas\\Avaliando\\Vbg\\lanc_contabil_contas_a_pagar_cisspoder\\temp\\pagtos_agrupados.csv'
#saida = open('Y:\\18 - DEPARTAMENTO DE PROJETOS\\Elder\\Importador\\Conjunto de Dados\\Layouts\\Contas Pagas\\Avaliando\\Vbg\\lanc_contabil_contas_a_pagar_cisspoder\\saida\\pagtos_agrupados.csv', 'w')
entrada = 'temp\\pagtos_agrupados.csv'
saida = open('saida\\pagtos_agrupados.csv', 'w')
with open(entrada, 'rt') as csvfile:
    csvreader = csv.reader(csvfile, delimiter=';')
    for row in csvreader:
        if str(row[10]) == 'Nome Fornecedor':
            saida.write('Documento;CNPJ Fornecedor;Emissao;Vencimento;Banco Oco. Extrato;Data Pagto;Data Oco. Extrato;Valor Pago;Valor Desconto;Valor Juros;Nome Fornecedor;Titulo;Categoria;Codigo Conta Dominio\n')
        else:
            _nome_for = str(row[10]).replace('  ', ' ')
            _nome_for = _nome_for[0:14]

            _nume_nota = int(row[0])

            _emissao_nota = str(row[2])
            _emissao_nota = datetime.datetime.strptime(_emissao_nota, "%d/%m/%Y").date()

            # emissão + 3 dias
            _emissao_nota_soma_3 = _emissao_nota + datetime.timedelta(days=3)
            _emissao_nota_soma_3 = _emissao_nota_soma_3.strftime('%Y-%m-%d')

            # emissão - 3 dias
            _emissao_nota_subt_3 = _emissao_nota + datetime.timedelta(days=-3)
            _emissao_nota_subt_3 = _emissao_nota_subt_3.strftime('%Y-%m-%d')

            # CNPJ pelo nome do fornecedor
            _cnpj_for = str(cnpj_for(_codi_emp, _nome_for)).replace(' ', '').replace('(', '').replace(')', '')\
                .replace(',', '').replace('None', "'")

            # CNPJ pela nota fiscal
            _cnpj_for_2 = str(cnpj_for_nota(_codi_emp, _nume_nota, _emissao_nota_subt_3, _emissao_nota_soma_3)).replace(' ', '')\
                .replace('(', '').replace(')', '').replace(',', '').replace('None', "'")

            # Primeiro busca pela nota, se não encontrar busca pelo nome
            if _cnpj_for_2 != "'":
                _cnpj_for = _cnpj_for_2
            else:
                _cnpj_for = _cnpj_for

            # busca o código da conta para quando for filial
            _cnpj_filtro = _cnpj_for.replace("'", '')
            if _cnpj_filtro != "":
                _codi_cta = str(codi_conta(_codi_emp, _cnpj_filtro)).replace(' ', '').replace('(', '').replace(')', '').replace(',', '').replace('None', "")
            else:
                _codi_cta = ""

            result = (f"{row[0]};{_cnpj_for};{row[2]};{row[3]};{row[4]};{row[5]};{row[6]};{row[7]};{row[8]}"
                      f";{row[9]};{str(row[10])};{row[11]};{row[12]};{_codi_cta}\n")
            saida.write(result)

saida.close()
