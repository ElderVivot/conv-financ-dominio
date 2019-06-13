import sqlanydb
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
            _nome_for = str(row[1]).replace('  ', ' ').replace("'", "")
            _nome_for_ori = _nome_for
            _nome_for = _nome_for[0:14]

            _nome_for_2 = _nome_for_ori.split()
            if len(_nome_for_2[0]) > 10:
                _nome_for = _nome_for_ori[0:20]

            _nume_nota = int(row[0])

            _emissao_nota = str(row[3])
            _emissao_nota = datetime.datetime.strptime(_emissao_nota, "%d/%m/%Y").date()

            # emissão + 3 dias
            _emissao_nota_soma_3 = _emissao_nota + datetime.timedelta(days=3)
            _emissao_nota_soma_3 = _emissao_nota_soma_3.strftime('%Y-%m-%d')

            # emissão - 3 dias
            _emissao_nota_subt_3 = _emissao_nota + datetime.timedelta(days=-3)
            _emissao_nota_subt_3 = _emissao_nota_subt_3.strftime('%Y-%m-%d')

            # CNPJ pelo nome do fornecedor
            _cnpj_for = str(cnpj_for(_codi_emp, _nome_for)).replace(' ', '').replace('(', '').replace(')', '').replace(',', '').replace('None', "'")
            if len(_nome_for_ori) < 10:
                _cnpj_for = "'"

            # CNPJ pela nota fiscal
            _cnpj_for_2 = str(cnpj_for_nota(_codi_emp, _nume_nota, _emissao_nota_subt_3, _emissao_nota_soma_3)).replace(' ', '') \
                .replace('(', '').replace(')', '').replace(',', '').replace('None', "'")

            # Primeiro busca pela nota, se não encontrar busca pelo nome
            if _cnpj_for_2 != "'":
                _cnpj_for = _cnpj_for_2
            else:
                _cnpj_for = _cnpj_for

            # busca o código da conta para quando for filial
            _cnpj_filtro = _cnpj_for.replace("'", '')
            if _cnpj_filtro != "":
                _codi_cta = str(codi_conta(_codi_emp, _cnpj_filtro)).replace(' ', '').replace('(', '').replace(')','').replace(
                    ',', '').replace('None', "")
            else:
                _codi_cta = ""

            _empresa = int(row[14])

            if _codi_emp == _empresa:
                result = (f"{row[0]};{row[1]};{row[2]};{row[3]};{row[4]};{row[5]};{row[6]};{row[7]};{row[8]};{row[9]};{row[10]}"
                          f";{row[11]};{row[12]};{row[13]};{_codi_emp};{_codi_cta};{row[16]};{row[17]};{row[18]}\n")
                saida.write(result)

saida.close()
