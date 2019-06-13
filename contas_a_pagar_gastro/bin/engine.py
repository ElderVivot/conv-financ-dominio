import sqlanydb
import csv
import pyodbc

def cnpj_for(codi_emp, nome_for):
    #connection = sqlanydb.connect(host="SRVERP", uid='EXTERNO', pwd='dominio', eng='srvcontabil', dbn='Contabil')
    connection = pyodbc.connect(DSN='Contabil', UID='EXTERNO', PWD='dominio', PORT='2638')
    cursor = connection.cursor()
    cursor.execute(f"SELECT MAX(cgce_for) "
                   f"  FROM bethadba.effornece "
                   f" WHERE codi_emp = {codi_emp} "
                   f"   AND nome_for LIKE '%{nome_for}%'")
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

_codi_emp = int(input('Informe o código da Empresa Matriz ou Filial na Domínio: '))
if _codi_emp == 203:
    empresa = "GASTRO_HOSPITAL"
elif _codi_emp == 194:
    empresa = "GASTRO_CLINICA"
elif _codi_emp == 446:
    empresa = "UNOGASTRO"
else:
    empresa = "0"

# arquivo de pagamentos
entrada = 'temp\\pagtos_agrupados.csv'
saida = open('saida\\pagtos_agrupados.csv', 'w')
with open(entrada, 'rt') as csvfile:
    csvreader = csv.reader(csvfile, delimiter=';')
    for row in csvreader:
        if str(row[10]) == 'Nome Fornecedor':
            saida.write('Documento;CNPJ Fornecedor;Vencimento;Banco Arquivo;Banco Oco. Extrato;Data Pagto;Data Oco. Extrato;Valor Pago;Valor Desconto;Valor Juros;Nome Fornecedor;Boleto/Cheque;Tipo Pagto;Obs;Categoria;Empresa;Codigo Conta Dominio\n')
        else:
            _nome_for = str(row[10]).replace('  ', ' ')
            _nome_for = _nome_for[0:11]

            _cnpj_for = str(cnpj_for(_codi_emp, _nome_for))
            _cnpj_for = _cnpj_for.replace(' ', '').replace('(', '').replace(')', '').replace(',', '').replace('None', "'")

            _empresa = row[15]

            # busca o código da conta para quando for filial
            _cnpj_filtro = _cnpj_for.replace("'", '')
            if _cnpj_filtro != "":
                _codi_cta = str(codi_conta(_codi_emp, _cnpj_filtro)).replace(' ', '').replace('(', '').replace(')','').replace(',', '').replace('None', "")
            else:
                _codi_cta = ""

            if empresa == _empresa:
                result = (f"{row[0]};{_cnpj_for};{row[2]};{row[3]};{row[4]};{row[5]};{row[6]};{row[7]};{row[8]}"
                          f";{row[9]};{str(row[10])};{row[11]};{row[12]};{row[13]};{row[14]};{_codi_emp};{_codi_cta}\n")
                saida.write(result)
saida.close()

# arquivo de recebimento
entrada_rec = 'temp\\recebtos_agrupados.csv'
saida_rec = open('saida\\recebtos_agrupados.csv', 'w')
with open(entrada_rec, 'rt') as csvfile:
    csvreader = csv.reader(csvfile, delimiter=';')
    for row in csvreader:
        if str(row[10]) == 'Nome Cliente':
            saida_rec.write('Documento;CNPJ Cliente;Vencimento;Banco Arquivo;Banco Oco. Extrato;Data Pagto;Data Oco. Extrato;Valor Recebido;Valor Desconto;Valor Juros;Nome Cliente;Boleto/Cheque;Tipo Pagto;Obs;Categoria;Empresa\n')
        else:
            _empresa = row[15]

            if empresa == _empresa:
                result = (f"{row[0]};{row[1]};{row[2]};{row[3]};{row[4]};{row[5]};{row[6]};{row[7]};{row[8]}"
                          f";{row[9]};{str(row[10])};{row[11]};{row[12]};{row[13]};{row[14]};{_codi_emp}\n")
                saida_rec.write(result)
saida_rec.close()