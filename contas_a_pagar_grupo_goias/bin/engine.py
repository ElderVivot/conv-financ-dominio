import sqlanydb
import pyodbc
import csv

def cnpj_for(codi_emp, nome_for):
    #connection = sqlanydb.connect(host="SRVERP", uid='EXTERNO', pwd='dominio', eng='srvcontabil', dbn='Contabil')
    connection = pyodbc.connect(DSN='Contabil',UID='EXTERNO',PWD='dominio')
    cursor = connection.cursor()
    cursor.execute(f"SELECT MAX(cgce_for) "
                   f"  FROM bethadba.effornece "
                   f" WHERE codi_emp = {codi_emp} "
                   f"   AND nome_for LIKE '%{nome_for}%'")
    data = cursor.fetchone()
    cursor.close()
    connection.close()

    return data

def cnpj_for_existe(codi_emp, cgce_for_):
    #connection = sqlanydb.connect(host="SRVERP", uid='EXTERNO', pwd='dominio', eng='srvcontabil', dbn='Contabil')
    connection = pyodbc.connect(DSN='Contabil',UID='EXTERNO',PWD='dominio')
    cursor = connection.cursor()
    cursor.execute(f"SELECT MAX(cgce_for) "
                   f"  FROM bethadba.effornece "
                   f" WHERE codi_emp = {codi_emp} "
                   f"   AND cgce_for = {cgce_for_}")
    data = cursor.fetchone()
    cursor.close()
    connection.close()

    return data

def cnpj_for_(codi_emp, cgce_for_):
    #connection = sqlanydb.connect(host="SRVERP", uid='EXTERNO', pwd='dominio', eng='srvcontabil', dbn='Contabil')
    connection = pyodbc.connect(DSN='Contabil',UID='EXTERNO',PWD='dominio')
    cursor = connection.cursor()
    cursor.execute(f"SELECT MAX(cgce_for) "
                   f"  FROM bethadba.effornece "
                   f" WHERE codi_emp = {codi_emp} "
                   f"   AND cgce_for LIKE '%{cgce_for_}%'")
    data = cursor.fetchone()
    cursor.close()
    connection.close()

    return data

def codi_conta(codi_emp, cgce_for_):
    #connection = sqlanydb.connect(host="SRVERP", uid='EXTERNO', pwd='dominio', eng='srvcontabil', dbn='Contabil')
    connection = pyodbc.connect(DSN='Contabil',UID='EXTERNO',PWD='dominio')
    cursor = connection.cursor()
    cursor.execute(f"SELECT MAX(codi_cta) "
                   f"  FROM bethadba.effornece "
                   f" WHERE codi_emp = {codi_emp} "
                   f"   AND cgce_for LIKE '%{cgce_for_}%'")
    data = cursor.fetchone()
    cursor.close()
    connection.close()

    return data

#entrada = 'Y:\\18 - DEPARTAMENTO DE PROJETOS\\Elder\\Importador\\Conjunto de Dados\\Layouts\\Contas Pagas\\Prontas\\Grupo Goias\\lanc_contabil_contas_a_pagar_grupos_goias\\temp\\pagtos_agrupados.csv'
#saida = open('Y:\\18 - DEPARTAMENTO DE PROJETOS\\Elder\\Importador\\Conjunto de Dados\\Layouts\\Contas Pagas\\Prontas\\Grupo Goias\\lanc_contabil_contas_a_pagar_grupos_goias\\saida\\pagtos_agrupados.csv', 'w')
entrada = 'temp\\pagtos_agrupados.csv'
saida = open('saida\\pagtos_agrupados.csv', 'w')
_codi_emp = int(input('Digite o código da empresa Matriz ou Filial na Domínio: '))
with open(entrada, 'rt') as csvfile:
    csvreader = csv.reader(csvfile, delimiter=';')
    for row in csvreader:
        if str(row[9]) == 'Nome Fornecedor':
            saida.write('Documento;CNPJ Fornecedor;Banco Arquivo;Banco Oco. Extrato;Data Pagto;Data Oco. Extrato;Valor Pago;Valor Desconto;Valor Juros;Nome Fornecedor;Natureza;Obs;Tipo Pagto;Empresa;Codigo Conta Dominio\n')
        else:
            _nome_for = str(row[9]).replace('  ', ' ')
            _nome_for = _nome_for[0:14]

            _cnpj_for = str(row[1]).replace("'", '')

            # avalia se o cnpj existe na domínio
            existe_cnpj = str(cnpj_for_existe(_codi_emp, _cnpj_for)).replace(' ', '').replace('(', '').replace(')', '').replace(',', '').replace('None', "")
            # se o cnpj não existir, então primeiramente vai buscá-lo pelo nome do fornecedor
            if existe_cnpj == "":
                _cnpj_for = str(cnpj_for(_codi_emp, _nome_for)).replace(' ', '').replace('(', '').replace(')', '').replace(',', '').replace('None', "'")
                # se mesmo pelo nome não encontrar o fornecedor, então compara pelos 12 primeiros digítos do CNPJ, pois talvez o cliente preencheu errado os dois últimos
                if _cnpj_for == "'":
                    _cnpj_for = str(row[1])[1:13]
                    _cnpj_for = str(cnpj_for_(_codi_emp, _cnpj_for)).replace(' ', '').replace('(', '').replace(')', '').replace(',', '').replace('None', "'")
                    # se mesmo assim não encontrar, então retorna o original que está no arquivo
                    if _cnpj_for == "'":
                        _cnpj_for = str(row[1])
            else:
                _cnpj_for = str(row[1])

            # busca o código da conta para quando for filial
            _cnpj_filtro = _cnpj_for.replace("'", '')
            if _cnpj_filtro != "":
                _codi_cta = str(codi_conta(_codi_emp, _cnpj_filtro)).replace(' ', '').replace('(', '').replace(')', '').replace(',', '').replace('None', "")
            else:
                _codi_cta = ""

            result = (f"{row[0]};{_cnpj_for};{row[2]};{row[3]};{row[4]};{row[5]};{row[6]};{row[7]};{row[8]}"
                      f";{row[9]};{str(row[10])};{row[11]};{row[12]};{row[13]};{_codi_cta}\n")
            saida.write(result)

saida.close()
