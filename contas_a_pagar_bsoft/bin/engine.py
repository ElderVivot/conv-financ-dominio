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

_codi_emp = int(input('Informe o código da empresa Matriz ou Filial na Domínio: '))

#entrada = 'Y:\\18 - DEPARTAMENTO DE PROJETOS\\Elder\\Importador\\Conjunto de Dados\\Layouts\\Contas Pagas\\Avaliando\\100 Limits\\lanc_contabil_contas_a_pagar_100limits\\temp\\pagtos_agrupados.csv'
#saida = open('Y:\\18 - DEPARTAMENTO DE PROJETOS\\Elder\\Importador\\Conjunto de Dados\\Layouts\\Contas Pagas\\Avaliando\\100 Limits\\lanc_contabil_contas_a_pagar_100limits\\saida\\pagtos_agrupados.csv', 'w')
entrada = 'temp\\pagtos_agrupados.csv'
saida = open('saida\\pagtos_agrupados.csv', 'w')
with open(entrada, 'rt') as csvfile:
    csvreader = csv.reader(csvfile, delimiter=';')
    for row in csvreader:
        if str(row[12]) == 'Nome Fornecedor':
            saida.write('Documento;CNPJ Fornecedor;Emissao;Vencimento;Banco Planilha;Banco Oco. Extrato;Data Pagto;'
                        'Data Oco. Extrato;Valor Pago;Valor Desconto;Valor Juros;Valor Multa;Nome Fornecedor;Tipo Pagto;'
                        'Centro de Custo;OBS;Codigo Empresa Dominio;Codigo Conta Dominio\n')
        else:
            _cnpj_for = str(row[1])
            _cnpj_for = _cnpj_for.replace("'", "")

            _codi_cta = str(codi_conta(_codi_emp, _cnpj_for))
            _codi_cta = _codi_cta.replace(' ', '').replace('(', '').replace(')', '').replace(',', '').replace('None', "")

            result = (f"{row[0]};{row[1]};{row[2]};{row[3]};{row[4]};{row[5]};{row[6]};{row[7]};{row[8]}"
                      f";{row[9]};{str(row[10])};{row[11]};{row[12]};{row[13]};{row[14]};{row[15]};{_codi_emp};{_codi_cta}\n")
            saida.write(result)

saida.close()
