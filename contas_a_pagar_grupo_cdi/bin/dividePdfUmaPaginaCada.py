import PyPDF2
import os
import funcoesUteis

caminho_pasta = "" #"Y:\\18 - DEPARTAMENTO DE PROJETOS\\Elder\\Importador\\Conjunto de Dados\\Layouts\\Financeiro\\_ferramentas\\contas_a_pagar_sispag_itau_pdf\\"

def dividePDFUmaPaginaCada(caminho=f"{caminho_pasta}entrada"):
    for root, dirs, files in os.walk(caminho):
        for file in files:
            caminho_pdf = os.path.join(root, file)
            name_file = funcoesUteis.trataCampoTexto(str(file[0:len(file)-4]))
            if str(file).upper().endswith('.PDF'):
                with open(caminho_pdf, 'rb') as arquivo_pdf:
                    leitor = PyPDF2.PdfFileReader(arquivo_pdf)
                    num_paginas = leitor.getNumPages()

                    for num_pagina in range(num_paginas):
                        escritor = PyPDF2.PdfFileWriter()
                        pagina_atual = leitor.getPage(num_pagina)
                        escritor.addPage(pagina_atual)

                        with open(f'{caminho_pasta}temp\\{name_file}-PAGINA {num_pagina+1}.pdf', 'wb') as novo_pdf:
                            escritor.write(novo_pdf)

dividePDFUmaPaginaCada()