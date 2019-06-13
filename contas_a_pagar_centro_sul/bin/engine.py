import sqlanydb
import pyodbc
import csv

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

#entrada = 'Y:\\18 - DEPARTAMENTO DE PROJETOS\\Elder\\Importador\\Conjunto de Dados\\Layouts\\Contas Pagas\\Prontas\\Grupo Centro Sul\\lanc_contabil_contas_a_pagar_centro_sul\\temp\\pagtos_agrupados.csv'
#saida = open('Y:\\18 - DEPARTAMENTO DE PROJETOS\\Elder\\Importador\\Conjunto de Dados\\Layouts\\Contas Pagas\\Prontas\\Grupo Centro Sul\\lanc_contabil_contas_a_pagar_centro_sul\\saida\\pagtos_agrupados.csv', 'w')
entrada = 'temp\\pagtos_agrupados.csv'
saida = open('saida\\pagtos_agrupados.csv', 'w')
_codi_emp = int(input('Digite o código da empresa na Domínio: '))
with open(entrada, 'rt') as csvfile:
    csvreader = csv.reader(csvfile, delimiter=';')
    for row in csvreader:
        if str(row[11]) == 'Nome Fornecedor':
            saida.write('Nota;CNPJ Fornecedor;Data Emissao;Data Vencimento;Banco Planilha;Banco Oco. Extrato;Data Pagto;Data Oco. Extrato;Valor Pago;Valor Desconto;Valor Juros;Nome Fornecedor;Num. Titulo;Data Emissao + 1;Data Emissao - 1;Data Emissao + 2;Data Emissao - 2;Obs\n')
        else:
            _nome_for = str(row[11]).replace('  ', ' ')
            _nome_for = _nome_for[0:14]

            _cnpj_for = str(cnpj_for(_codi_emp, _nome_for))
            _cnpj_for = _cnpj_for.replace(' ', '').replace('(', '').replace(')', '').replace(',', '').replace('None', "'")

            result = (f"{row[0]};{_cnpj_for};{row[2]};{row[3]};{row[4]};{row[5]};{row[6]};{row[7]};{row[8]}"
                      f";{row[9]};{str(row[10])};{row[11]};{row[12]};{row[13]};{row[14]};{row[15]};{row[16]};{row[17]}\n")
            saida.write(result)

saida.close()
