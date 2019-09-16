#import sqlanydb
import pyodbc
import csv
import datetime

def cnpj_for(codi_emp, nome_for):
    connection = pyodbc.connect(DSN='Contabil',UID='EXTERNO',PWD='dominio',PORT='2638')
    cursor = connection.cursor()
    for emp in codi_emp:
        cursor.execute(f"SELECT MAX(cgce_for)"
                       f"  FROM bethadba.effornece "
                       f" WHERE codi_emp IN ({emp}) "
                       f"   AND ( nome_for LIKE '%{nome_for}%' OR nomr_for LIKE '%{nome_for}%' )")
        data = str(cursor.fetchone())
        if data.count('None') == 0:
            break
    cursor.close()
    connection.close()

    return (data, emp)

def cnpj_for_verifica_a_esquerda(codi_emp, nome_for):
    connection = pyodbc.connect(DSN='Contabil',UID='EXTERNO',PWD='dominio',PORT='2638')
    cursor = connection.cursor()
    for emp in codi_emp:
        cursor.execute(f"SELECT MAX(cgce_for)"
                       f"  FROM bethadba.effornece "
                       f" WHERE codi_emp IN ({emp}) "
                       f"   AND nome_for LIKE '{nome_for}%'")
        data = str(cursor.fetchone())
        if data.count('None') == 0:
            break
    cursor.close()
    connection.close()

    return (data, emp)

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
        data = str(cursor.fetchone())
        if data.count('None') == 0:
            break
    cursor.close()
    connection.close()

    return (data, emp)

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
        data = str(cursor.fetchone())
        if data.count('None') == 0:
            break
    cursor.close()
    connection.close()

    return (data, emp)

def codi_conta(codi_emp, cgce_for_):
    #connection = sqlanydb.connect(host="SRVERP", uid='EXTERNO', pwd='dominio', eng='srvcontabil', dbn='Contabil')
    connection = pyodbc.connect(DSN='Contabil',UID='EXTERNO',PWD='dominio',PORT='2638')
    cursor = connection.cursor()
    cursor.execute(f"SELECT MAX(codi_cta) "
                    f"  FROM bethadba.effornece "
                    f" WHERE codi_emp IN ({codi_emp})"
                    f"   AND cgce_for LIKE '%{cgce_for_}%'")
    data = str(cursor.fetchone())
    cursor.close()
    connection.close()

    return data

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

def codi_emp_por_cnpj(cnpj):
    #connection = sqlanydb.connect(host="SRVERP", uid='EXTERNO', pwd='dominio', eng='srvcontabil', dbn='Contabil')
    connection = pyodbc.connect(DSN='Contabil',UID='EXTERNO',PWD='dominio',PORT='2638')
    cursor = connection.cursor()
    cursor.execute(f"SELECT MAX(codi_emp)"
                   f"  FROM bethadba.geempre "
                   f" WHERE cgce_emp LIKE '%{cnpj}%'")
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
                saida.write('Documento;Nome Fornecedor;CNPJ Fornecedor;Texto Fixo;Vencimento;Banco Planilha;Banco Oco. Extrato;'
                            'Data Pagto;Data Oco. Extrato;Valor Pago;Valor Desconto;Valor Juros;Valor Multa;Numero Titulo;'
                            'É uma NF?;Empresa;Codigo Conta Dominio;OBS;Tipo Pagto;Categoria\n')
            elif str(row[0]) == 'INICIO':
                saida.write(f'{row[0]};{row[1]};{row[2]};{row[3]};{row[4]};{row[5]}\n')
            else:
                
                _codi_emp_arquivo = int(row[14])
                if _codi_emp != _codi_emp_arquivo:
                    continue

                _lista_filiais = str(lista_filiais(_codi_emp))

                _codi_emp_v = []
                for empresa in _lista_filiais.split(","):
                    empresa = apenas_valor_campo_dominio(empresa).replace("'", "")
                    if empresa != "":
                        _codi_emp_v.append(int(empresa))

                _codi_emp_v = sorted(_codi_emp_v)

                _nome_for_ori = str(row[1])

                _nome_for_75porcento = _nome_for_ori[0 : int(len(_nome_for_ori)*0.75)]

                if len(_nome_for_ori) < 10:
                    consulta_cnpj_verifica_a_esquerda = cnpj_for_verifica_a_esquerda(_codi_emp_v, _nome_for_ori)

                    _cnpj_for_nome_75porcento_ou_menor_que_10_letras = apenas_valor_campo_dominio(str(consulta_cnpj_verifica_a_esquerda[0]))
                    _codi_emp_75porcento_ou_menor_que_10_letras = apenas_valor_campo_dominio(str(consulta_cnpj_verifica_a_esquerda[1]))
                else:
                    consulta_cnpj = cnpj_for(_codi_emp_v, _nome_for_75porcento)

                    _cnpj_for_nome_75porcento_ou_menor_que_10_letras = apenas_valor_campo_dominio(str(consulta_cnpj[0]))
                    _codi_emp_75porcento_ou_menor_que_10_letras = apenas_valor_campo_dominio(str(consulta_cnpj[1]))

                _nome_for_dividido = _nome_for_ori.split()
                if len(_nome_for_dividido) > 2:
                    _nome_for_2palavras_a_menos_vetor = _nome_for_dividido[0 : len(_nome_for_dividido) - 2]

                    _nome_for_2palavras_a_menos = ' '.join(_nome_for_2palavras_a_menos_vetor)

                    consulta_cnpj_2palavras_a_menor = cnpj_for(_codi_emp_v, _nome_for_2palavras_a_menos)

                    _cnpj_for_nome_2palavras_a_menos = apenas_valor_campo_dominio(str(consulta_cnpj_2palavras_a_menor[0]))
                    _codi_emp_nome_2palavras_a_menos = apenas_valor_campo_dominio(str(consulta_cnpj_2palavras_a_menor[1]))

                    # se for nome muito curto pra evitar que retorne errado
                    if len(_nome_for_2palavras_a_menos.split()) == 1 and len(_nome_for_2palavras_a_menos) < 7:
                        _cnpj_for_nome_2palavras_a_menos = ""
                else:
                     _nome_for_2palavras_a_menos_vetor = []
                     _nome_for_2palavras_a_menos = ''
                     _cnpj_for_nome_2palavras_a_menos = ''
                     _codi_emp_nome_2palavras_a_menos = ''

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

                consulta_cnpj_nota = cnpj_for_nota(_codi_emp_v, _nume_nota, _emissao_nota_subt_3, _emissao_nota_soma_3)

                _cnpj_for_nota = apenas_valor_campo_dominio(str(consulta_cnpj_nota[0]))
                _codi_emp_nota = apenas_valor_campo_dominio(str(consulta_cnpj_nota[1]))

                _nome_for_30porcento = _nome_for_ori[0 : int(len(_nome_for_ori)*0.3)]

                consulta_cnpj_nota_pelo_nome = cnpj_for_nota_2(_codi_emp_v, _nume_nota, _nome_for_30porcento)

                _cnpj_for_nota_pelo_nome = apenas_valor_campo_dominio(str(consulta_cnpj_nota_pelo_nome[0]))
                _codi_emp_nota_pelo_nome = apenas_valor_campo_dominio(str(consulta_cnpj_nota_pelo_nome[1]))

                _cnpj_for = ""
                codi_emp = 0
                nota_existe = 'NAO'
                # Primeiro busca pela nota, se não encontrar busca pelo nome
                if _cnpj_for_nota != "'" and _cnpj_for_nota_pelo_nome == "'":
                    _cnpj_for = _cnpj_for_nota
                    codi_emp = _codi_emp_nota
                    nota_existe = 'SIM'
                elif _cnpj_for_nota_pelo_nome != "'":
                    _cnpj_for = _cnpj_for_nota_pelo_nome
                    codi_emp = _codi_emp_nota_pelo_nome
                    nota_existe = 'SIM'
                elif len(_nome_for_2palavras_a_menos) >= 3 and _cnpj_for_nome_2palavras_a_menos != "'" and _cnpj_for_nome_2palavras_a_menos != "":
                    _cnpj_for = _cnpj_for_nome_2palavras_a_menos
                    codi_emp = _codi_emp_nome_2palavras_a_menos
                else:
                    _cnpj_for = _cnpj_for_nome_75porcento_ou_menor_que_10_letras
                    codi_emp = _codi_emp_75porcento_ou_menor_que_10_letras

                if _cnpj_for == "'":
                    codi_emp = _codi_emp

                if _cnpj_for == "'" and str(row[2]) != "'00000000000000":
                    _cnpj_for = row[2]

                #print(f"{_nome_for_ori};{_cnpj_for_nota};{_cnpj_for_nota_pelo_nome};{_cnpj_for_nome_2palavras_a_menos};{_cnpj_for_nome_75porcento_ou_menor_que_10_letras}")

                # busca o código da conta para quando for filial
                _cnpj_filtro = _cnpj_for.replace("'", '')
                if _cnpj_filtro != "":
                    _codi_cta = apenas_valor_campo_dominio(str(codi_conta(codi_emp, _cnpj_filtro)))
                else:
                    _codi_cta = ""
                _codi_cta = _codi_cta.replace("'", '')

                result = (f"{row[0]};{row[1]};{_cnpj_for};LANC;{row[4]};{row[5]};{row[6]};{row[7]};{row[8]};{row[9]};{row[10]}"
                            f";{row[11]};{row[12]};{row[13]};{nota_existe};{codi_emp};{_codi_cta};{row[16]};{row[17]};{row[18]}\n")
                saida.write(result)

saida.close()

try:
    entrada = 'temp\\recebtos_agrupados.csv'
    saida = open('saida\\recebtos_agrupados.csv', 'w')

    with open(entrada, 'rt') as csvfile:
        csvreader = csv.reader(csvfile, delimiter=';')
        for row in csvreader:
            if str(row[0]) == 'Documento':
                saida.write('Documento;Nome Cliente;CNPJ Cliente;Emissao;Vencimento;Banco Planilha;Banco Oco. Extrato;Data Pagto;Data Oco. Extrato;Valor Pago;Valor Desconto;Valor Juros;Valor Multa;Numero Titulo;Empresa;Codigo Conta Dominio;OBS;Tipo Pagto;Categoria\n')
            elif str(row[0]) == 'INICIO':
                saida.write(f'{row[0]};{row[1]};{row[2]};{row[3]};{row[4]};{row[5]}\n')
            else:
                #_codi_emp = str(row[14])
                #_codi_emp = apenas_valor_campo_dominio(str(codi_emp_por_cnpj(_codi_emp)))

                result = (f"{row[0]};{row[1]};{row[2]};{row[3]};{row[4]};{row[5]};{row[6]};{row[7]};{row[8]};{row[9]};{row[10]}"
                            f";{row[11]};{row[12]};{row[13]};{_codi_emp};{row[15]};{row[16]};{row[17]};{row[18]}\n")
                saida.write(result)

    saida.close()
except Exception:
    ""
