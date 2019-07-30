#import sqlanydb
import pyodbc
import csv
import datetime

def cnpj_for(codi_emp, nome_for):
    #connection = sqlanydb.connect(host="SRVERP", uid='EXTERNO', pwd='dominio', eng='srvcontabil', dbn='Contabil')
    connection = pyodbc.connect(DSN='Contabil',UID='EXTERNO',PWD='dominio',PORT='2638')
    cursor = connection.cursor()
    for emp in codi_emp:
        cursor.execute(f"SELECT MAX(cgce_for)"
                       f"  FROM bethadba.effornece "
                       f" WHERE codi_emp IN ({emp}) "
                       f"   AND nome_for LIKE '%{nome_for}%'")
        data = cursor.fetchone()
        if data != '(None, )':
            break
    cursor.close()
    connection.close()

    return data

def cnpj_for_nota(codi_emp, nume_nota, emissao_nota_ini, emissao_nota_fim):
    #connection = sqlanydb.connect(host="SRVERP", uid='EXTERNO', pwd='dominio', eng='srvcontabil', dbn='Contabil')
    connection = pyodbc.connect(DSN='Contabil',UID='EXTERNO',PWD='dominio',PORT='2638')
    cursor = connection.cursor()
    for emp in codi_emp:
        cursor.execute(f"SELECT MAX(cgce_for) "
                       f"  FROM bethadba.efentradas AS ent"
                       f"       INNER JOIN bethadba.effornece AS forn"
                       f"            ON    forn.codi_emp = ent.codi_emp"
                       f"              AND forn.codi_for = ent.codi_for"
                       f" WHERE ent.codi_emp IN ({emp})"
                       f"   AND ent.nume_ent = {nume_nota}"
                       f"   AND ( ( ent.ddoc_ent BETWEEN DATE('{emissao_nota_ini}') AND DATE('{emissao_nota_fim}') ) "
                       f"        OR ( ent.dent_ent BETWEEN DATE('{emissao_nota_ini}') AND DATE('{emissao_nota_fim}') ) ) ")
        data = cursor.fetchone()
        if data != '(None, )':
            break
    cursor.close()
    connection.close()

    return data

def cnpj_for_nota_2(codi_emp, nume_nota, nome_for):
    #connection = sqlanydb.connect(host="SRVERP", uid='EXTERNO', pwd='dominio', eng='srvcontabil', dbn='Contabil')
    connection = pyodbc.connect(DSN='Contabil',UID='EXTERNO',PWD='dominio',PORT='2638')
    cursor = connection.cursor()
    for emp in codi_emp:
        cursor.execute(f"SELECT MAX(cgce_for) "
                       f"  FROM bethadba.efentradas AS ent"
                       f"       INNER JOIN bethadba.effornece AS forn"
                       f"            ON    forn.codi_emp = ent.codi_emp"
                       f"              AND forn.codi_for = ent.codi_for"
                       f" WHERE ent.codi_emp IN ({emp})"
                       f"   AND ent.nume_ent = {nume_nota}"
                       f"   AND forn.nome_for LIKE '%{nome_for}%' ")
        data = cursor.fetchone()
        if data != '(None, )':
            break
    cursor.close()
    connection.close()

    return data

def codi_conta(codi_emp, cgce_for_):
    #connection = sqlanydb.connect(host="SRVERP", uid='EXTERNO', pwd='dominio', eng='srvcontabil', dbn='Contabil')
    connection = pyodbc.connect(DSN='Contabil',UID='EXTERNO',PWD='dominio',PORT='2638')
    cursor = connection.cursor()
    for emp in codi_emp:
        cursor.execute(f"SELECT MAX(codi_cta) "
                       f"  FROM bethadba.effornece "
                       f" WHERE codi_emp IN ({emp})"
                       f"   AND cgce_for LIKE '%{cgce_for_}%'")
        data = cursor.fetchone()
        if data != '(None, )':
            break
    cursor.close()
    connection.close()

    return data, "-", emp

def cnpj_emp_atual(codi_emp):
    #connection = sqlanydb.connect(host="SRVERP", uid='EXTERNO', pwd='dominio', eng='srvcontabil', dbn='Contabil')
    connection = pyodbc.connect(DSN='Contabil',UID='EXTERNO',PWD='dominio',PORT='2638')
    cursor = connection.cursor()
    cursor.execute(f"SELECT MAX(cgce_emp)"
                   f"  FROM bethadba.geempre "
                   f" WHERE codi_emp IN ({codi_emp})")
    data = cursor.fetchone()
    cursor.close()
    connection.close()

    return data

def lista_filiais(codi_emp):
    #connection = sqlanydb.connect(host="SRVERP", uid='EXTERNO', pwd='dominio', eng='srvcontabil', dbn='Contabil')
    connection = pyodbc.connect(DSN='Contabil',UID='EXTERNO',PWD='dominio',PORT='2638')
    cursor = connection.cursor()
    cursor.execute(f"SELECT ( SELECT LIST(emp2.codi_emp)"
                   f"           FROM bethadba.geempre AS emp2"
                   f"          WHERE SUBSTR(emp2.cgce_emp, 1, 8) = SUBSTR(emp.cgce_emp, 1, 8)"
                   f"       /*ORDER BY emp2.codi_emp*/ ) AS lista"
                   f"  FROM bethadba.geempre AS emp"
                   f" WHERE emp.codi_emp = {codi_emp}")
    data = cursor.fetchone()
    cursor.close()
    connection.close()

    return data


def apenas_valor_campo_dominio(campo):
    return campo.replace(' ', '').replace('(', '').replace(')', '').replace(',', '').replace('None', "'")

_codi_emp = int(input('- Informe o código da empresa Matriz ou Filial na Domínio: '))

#entrada = 'Y:\\18 - DEPARTAMENTO DE PROJETOS\\Elder\\Importador\\Conjunto de Dados\\Layouts\\Financeiro\\_ferramentas\\contas_a_pagar_grupo_positiva\\temp\\pagtos_agrupados.csv'
#saida = open('Y:\\18 - DEPARTAMENTO DE PROJETOS\\Elder\\Importador\\Conjunto de Dados\\Layouts\\Financeiro\\_ferramentas\\contas_a_pagar_grupo_positiva\\saida\\pagtos_agrupados.csv', 'w')
entrada = 'temp\\pagtos_agrupados.csv'
saida = open('saida\\pagtos_agrupados.csv', 'w')
with open(entrada, 'rt') as csvfile:
        csvreader = csv.reader(csvfile, delimiter=';')
        for row in csvreader:
            if str(row[0]) == 'Documento':
                saida.write('Documento;Nome Fornecedor;CNPJ Fornecedor;Emissao;Vencimento;Banco Planilha;Banco Oco. Extrato;'
                            'Data Pagto;Data Oco. Extrato;Valor Pago;Valor Desconto;Valor Juros;Valor Multa;Numero Titulo;'
                            'Empresa;Codigo Conta Dominio;OBS;Tipo Pagto;Categoria\n')
            else:
                #_codi_emp = int(row[14])

                _lista_filiais = str(lista_filiais(_codi_emp))

                _codi_emp_v = []
                for empresa in _lista_filiais.split(","):
                    empresa = apenas_valor_campo_dominio(empresa).replace("'", "")
                    if empresa != "":
                        _codi_emp_v.append(int(empresa))

                _nome_for_ori = str(row[1])

                _nome_for_75porcento = _nome_for_ori[0 : int(len(_nome_for_ori)*0.75)]

                _cnpj_for_nome_75porcento = apenas_valor_campo_dominio(str(cnpj_for(_codi_emp_v, _nome_for_75porcento)))

                _nome_for_dividido = _nome_for_ori.split()
                if len(_nome_for_dividido) > 2:
                    _nome_for_2palavras_a_menos_vetor = _nome_for_dividido[0 : len(_nome_for_dividido) - 2]
                else:
                    _nome_for_2palavras_a_menos_vetor = []

                _nome_for_2palavras_a_menos = ' '.join(_nome_for_2palavras_a_menos_vetor)

                _cnpj_for_nome_2palavras_a_menos = apenas_valor_campo_dominio(str(cnpj_for(_codi_emp_v, _nome_for_2palavras_a_menos)))

                try:
                    _nume_nota = int(row[0])
                except:
                    _nume_nota = 0

                _emissao_nota = str(row[3])
                try:
                    _emissao_nota = datetime.datetime.strptime(_emissao_nota, "%d/%m/%Y").date()
                except:
                    _emissao_nota = datetime.datetime.strptime("01/01/1900", "%d/%m/%Y").date()

                _emissao_nota_soma_3 = _emissao_nota + datetime.timedelta(days=3)
                _emissao_nota_soma_3 = _emissao_nota_soma_3.strftime('%Y-%m-%d')

                _emissao_nota_subt_3 = _emissao_nota + datetime.timedelta(days=-3)
                _emissao_nota_subt_3 = _emissao_nota_subt_3.strftime('%Y-%m-%d')

                _cnpj_for_nota = apenas_valor_campo_dominio(str(cnpj_for_nota(_codi_emp_v, _nume_nota, _emissao_nota_subt_3, _emissao_nota_soma_3)))

                _nome_for_30porcento = _nome_for_ori[0 : int(len(_nome_for_ori)*0.3)]
                _cnpj_for_nota_pelo_nome = apenas_valor_campo_dominio(str(cnpj_for_nota_2(_codi_emp_v, _nume_nota, _nome_for_30porcento)))

                _cnpj_for = ""
                # Primeiro busca pela nota, se não encontrar busca pelo nome
                if _cnpj_for_nota != "'" and _cnpj_for_nota_pelo_nome == "'":
                    _cnpj_for = _cnpj_for_nota
                elif _cnpj_for_nota_pelo_nome != "'":
                    _cnpj_for = _cnpj_for_nota_pelo_nome
                elif len(_nome_for_2palavras_a_menos) >= 3:
                    _cnpj_for = _cnpj_for_nome_2palavras_a_menos
                else:
                    _cnpj_for = _cnpj_for_nome_75porcento

                if _cnpj_for == "'":
                    _cnpj_for = row[2]

                # busca o código da conta para quando for filial
                _cnpj_filtro = _cnpj_for.replace("'", '')
                if _cnpj_filtro != "":
                    _codi_cta_e_codi_emp = apenas_valor_campo_dominio(str(codi_conta(_codi_emp_v, _cnpj_filtro)))
                    _codi_cta_e_codi_emp = _codi_cta_e_codi_emp.split("'-'")

                    _codi_cta = _codi_cta_e_codi_emp[0]
                    codi_emp = _codi_cta_e_codi_emp[1]
                else:
                    _codi_cta = ""
                    codi_emp = _codi_emp

                result = (f"{row[0]};{row[1]};{_cnpj_for};{row[3]};{row[4]};{row[5]};{row[6]};{row[7]};{row[8]};{row[9]};{row[10]}"
                            f";{row[11]};{row[12]};{row[13]};{codi_emp};{_codi_cta};{row[16]};{row[17]};{row[18]}\n")
                saida.write(result)

saida.close()

entrada = 'temp\\recebtos_agrupados.csv'
saida = open('saida\\recebtos_agrupados.csv', 'w')

with open(entrada, 'rt') as csvfile:
    csvreader = csv.reader(csvfile, delimiter=';')
    for row in csvreader:
        if str(row[0]) == 'Documento':
            saida.write('Documento;Nome Cliente;CNPJ Cliente;Emissao;Vencimento;Banco Planilha;Banco Oco. Extrato;Data Pagto;Data Oco. Extrato;Valor Pago;Valor Desconto;Valor Juros;Valor Multa;Numero Titulo;Empresa;Codigo Conta Dominio;OBS;Tipo Pagto;Categoria\n')
        else:
            _codi_emp = int(row[14])

            result = (f"{row[0]};{row[1]};{row[2]};{row[3]};{row[4]};{row[5]};{row[6]};{row[7]};{row[8]};{row[9]};{row[10]}"
                          f";{row[11]};{row[12]};{row[13]};{_codi_emp};{row[15]};{row[16]};{row[17]};{row[18]}\n")
            saida.write(result)

saida.close()
