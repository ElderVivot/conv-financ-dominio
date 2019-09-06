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

print(cnpj_for([1543], 'JC DISTRIBUIDORA DE MEDICAMENTOS')[1])