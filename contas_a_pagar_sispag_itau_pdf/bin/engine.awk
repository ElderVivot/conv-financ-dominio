# coding: utf-8

BEGIN { 
	FS = "";
	OFS = ";";
	
	system("if exist bin\\*.txt del /q bin\\*.txt")
	system("dir /b temp\\*.txt > bin\\listacsv.txt")
	system("if exist entrada\\*.ofx dir /b entrada\\*.ofx > bin\\listaofx.txt")
	system("if exist entrada\\*.ofc dir /b entrada\\*.ofc >> bin\\listaofx.txt")
	
	ArquivosCsv = "bin\\listacsv.txt";
	ArquivosOfx = "bin\\listaofx.txt";
	
	_comp_ini = int(Trim(substr(_comp_ini, 4)) "" substr(_comp_ini, 1, 2))
	_comp_fim = int(Trim(substr(_comp_fim, 4)) "" substr(_comp_fim, 1, 2))
	
	print "Banco;Conta Corrente;Tipo Movimento;Data;Operacao;Valor;Num. Doc.;Historico" >> "temp\\extrato_cartao.csv"
	
	# LE O ARQUIVO OFX AFIM DE PODER COMPARAR O QUE FOI PAGO NO CARTAO COM A PLANILHA DE BAIXA DO CLIENTE
	while ((getline < ArquivosOfx) > 0) {
		fileofx = "entrada\\" $0
		
		# PRIMEIRO WHILE É PRA VER A ESTRUTURA DO OFX, OU SEJA, SE DE FATO É IGUAL A UM XML OU SE NÃO TEM A TAG FINAL DO XML
		while ((getline < fileofx) > 0) {
			
			ofx_1 = ""
			ofx_1 = $0
			ofx_1 = tolower( ofx_1 )
			ofx_1 = Trim(ofx_1)
			ofx_1 = Trim(ofx_1)
			
			# IGUAL AO XML
			if( index( ofx_1, "</acctid>" ) > 0 ){
				EstruturaOFX[fileofx] = 1
				break
			} 
			# NÃO TEM A TAG FINAL DO XML
			else
				EstruturaOFX[fileofx] = 2
			
		}close(fileofx)
		
		# LE O XML E PROCESSA SEUS CAMPOS
		while ((getline < fileofx) > 0) {
			
			ofx = ""
			ofx = $0
			ofx = tolower( ofx )
			ofx = Trim(ofx)
			ofx = Trim(ofx)
			
			# ESTRUTURA COM TAG FINAL
			if( EstruturaOFX[fileofx] == 1 ){
				if( substr(ofx, 1, 8) == "<bankid>" ){
					num_banco = upperCase(selecionaTAG( ofx, "<bankid>", "</bankid>" ) )
					num_banco = int(num_banco)
				}
				
				if( substr(ofx, 1, 8) == "<acctid>" ){
					conta_corrente = upperCase( selecionaTAG( ofx, "<acctid>", "</acctid>" ) )
					conta_corrente_int = int( soNumeros(conta_corrente) )
					if( int(num_banco) == 341 ){
						conta_corrente = substr(conta_corrente, 5, length(conta_corrente) - 4) "-" substr(conta_corrente, length(conta_corrente), 1)
					}
				}
				
				if( substr(ofx, 1, 9) == "<trntype>" )
					tipo_mov = upperCase( selecionaTAG( ofx, "<trntype>", "</trntype>" ) )
				
				if( substr(ofx, 1, 10) == "<dtposted>" ){
					data_mov = selecionaTAG( ofx, "<dtposted>", "</dtposted>" )
					data_mov = substr(data_mov, 1, 8)
					data_mov = substr(data_mov, 7, 2) "/" substr(data_mov, 5, 2) "/" substr(data_mov, 1, 4)
					data_mov_int = int(substr(data_mov, 7) "" substr(data_mov, 4, 2))
				}
				
				if( substr(ofx, 1, 8) == "<trnamt>" ){
					valor_transacao = selecionaTAG( ofx, "<trnamt>", "</trnamt>" )
					
					operacao = ""
					if(substr(valor_transacao, 1, 1) == "-")
						operacao = "-"
					else
						operacao = "+"
					
					gsub("-", "", valor_transacao)
					gsub("[.]", ",", valor_transacao)
				}
				
				if( substr(ofx, 1, 10) == "<checknum>" ){
					num_doc = selecionaTAG( ofx, "<checknum>", "</checknum>" )
					num_doc = int(num_doc)
				}
				
				if( substr(ofx, 1, 6) == "<memo>" )
					historico = upperCase( selecionaTAG( ofx, "<memo>", "</memo>" ) )
				
				if( substr(ofx, 1, 10) == "</stmttrn>" ){
					
					ExisteMov[operacao, data_mov, valor_transacao] = 1
					BancoPago[operacao, data_mov, valor_transacao] = num_banco "-" conta_corrente
					DataPagto[operacao, data_mov, valor_transacao] = data_mov
					
					ExisteMovBanco[num_banco, operacao, data_mov, valor_transacao] = 1
					BancoPagoBanco[num_banco, operacao, data_mov, valor_transacao] = num_banco "-" conta_corrente
					DataPagtoBanco[num_banco, operacao, data_mov, valor_transacao] = data_mov
					
					# QUANDO É CHEQUE GUARDA A DATA QUE O CHEQUE COMPENSOU, É ELA QUE TEM QUE SER UTILIZADA COMO DATA DA BAIXA
					if( historico == "CHEQ COMP" || historico == "CHEQUE SAC" ){
						DataCompensacaoCheque[num_doc] = data_mov
						BancoPagoCheque[num_doc] = num_banco "-" conta_corrente
					}
					
					if( _comp_ini <= data_mov_int && data_mov_int <= _comp_fim )
						print num_banco, conta_corrente, tipo_mov, data_mov, operacao, valor_transacao, num_doc, historico >> "temp\\extrato_cartao.csv"
				}
			
			}
			
			# ESTRUTURA SEM TAG FINAL
			else{
				if( substr(ofx, 1, 8) == "<bankid>" ){
					num_banco = upperCase( substr( ofx, 9 , length(ofx) - 8 ) )
					num_banco = int(num_banco)
				}
				
				if( substr(ofx, 1, 8) == "<acctid>" ){
					conta_corrente = upperCase( substr( ofx, 9 , length(ofx) - 8 ) )
					conta_corrente_int = int( soNumeros(conta_corrente) )
					if( int(num_banco) == 341 ){
						conta_corrente = substr(conta_corrente, 5, length(conta_corrente) - 4) "-" substr(conta_corrente, length(conta_corrente), 1)
					}
				}
				
				if( substr(ofx, 1, 9) == "<trntype>" )
					tipo_mov = upperCase( substr( ofx, 10 , length(ofx) - 9 ) )
				
				if( substr(ofx, 1, 10) == "<dtposted>" ){
					data_mov = substr( ofx, 11 , length(ofx) - 10 )
					data_mov = substr(data_mov, 1, 8)
					data_mov = substr(data_mov, 7, 2) "/" substr(data_mov, 5, 2) "/" substr(data_mov, 1, 4)
					data_mov_int = int(substr(data_mov, 7) "" substr(data_mov, 4, 2))
				}
				
				if( substr(ofx, 1, 8) == "<trnamt>" ){
					valor_transacao = substr( ofx, 9 , length(ofx) - 8 )
					
					operacao = ""
					if(substr(valor_transacao, 1, 1) == "-")
						operacao = "-"
					else
						operacao = "+"
					
					gsub("-", "", valor_transacao)
					gsub("[.]", ",", valor_transacao)
				}
				
				if( substr(ofx, 1, 10) == "<checknum>" ){
					num_doc = substr( ofx, 11 , length(ofx) - 10 )
					num_doc = int(num_doc)
				}
				
				if( substr(ofx, 1, 6) == "<memo>" )
					historico = upperCase( substr( ofx, 7 , length(ofx) - 6 ) )
				
				if( substr(ofx, 1, 10) == "</stmttrn>" ){
					
					ExisteMov[operacao, data_mov, valor_transacao] = 1
					BancoPago[operacao, data_mov, valor_transacao] = num_banco "-" conta_corrente
					DataPagto[operacao, data_mov, valor_transacao] = data_mov
					
					ExisteMovBanco[num_banco, operacao, data_mov, valor_transacao] = 1
					BancoPagoBanco[num_banco, operacao, data_mov, valor_transacao] = num_banco "-" conta_corrente
					DataPagtoBanco[num_banco, operacao, data_mov, valor_transacao] = data_mov
					
					# QUANDO É CHEQUE GUARDA A DATA QUE O CHEQUE COMPENSOU, É ELA QUE TEM QUE SER UTILIZADA COMO DATA DA BAIXA
					if( historico == "CHEQ COMP" || historico == "CHEQUE SAC" ){
						DataCompensacaoCheque[num_doc] = data_mov
						BancoPagoCheque[num_doc] = num_banco "-" conta_corrente
					}
					
					if( _comp_ini <= data_mov_int && data_mov_int <= _comp_fim )
						print num_banco, conta_corrente, tipo_mov, data_mov, operacao, valor_transacao, num_doc, historico >> "temp\\extrato_cartao.csv"
				}
			}
			
		} close(fileofx)
	} close(ArquivosOfx)
	
	print "Documento;Nome Fornecedor;CNPJ Fornecedor;Emissao;Vencimento;Banco Planilha;Banco Oco. Extrato;Data Pagto;Data Oco. Extrato;Valor Pago;Valor Desconto;Valor Juros;Valor Multa;Numero Titulo;Empresa;Codigo Conta Dominio;OBS;Tipo Pagto;Categoria" >> "temp\\pagtos_agrupados.csv"
	print "Documento;Nome Cliente;CNPJ Cliente;Emissao;Vencimento;Banco Planilha;Banco Oco. Extrato;Data Pagto;Data Oco. Extrato;Valor Pago;Valor Desconto;Valor Juros;Valor Multa;Numero Titulo;Empresa;Codigo Conta Dominio;OBS;Tipo Pagto;Categoria" >> "temp\\recebtos_agrupados.csv"
	
	while ((getline < ArquivosCsv) > 0) {
		nomeArquivo = $0
		nomeArquivoPDF = substr($0, 1, length($0) - 4) ".pdf"
		file = "temp\\" nomeArquivo

		conseguiu_processar_arquivo = 0

		numLinha = 1
		
		# PRIMEIRO WHILE QUE VAI LER TODOS OS ARQUIVOS E VER QUAL É A ESTRUTURA QUE ELE ESTÁ
		while ((getline < file) > 0) {

			# zera os campos pra ele não pegar dados errados
			if(numLinha == 1){
				forn_cli = ""
				cnpj_forn_cli = ""
				vencimento = ""
				valor_pago = "0,00"
				valor_pago_int = 0
				categoria = ""
				obs = ""
				nome_favorecido = ""
			}
			numLinha++

			split_dois_pontos = split($0, linha_v, ":")

			campo_1 = ""
			campo_1 = Trim(linha_v[1])
			campo_1 = subsCharEspecial(campo_1)
			campo_1 = upperCase(campo_1)

			campo_2 = Trim(linha_v[2])

			if(campo_1 == "NOME"){
				forn_cli = ""
				forn_cli = campo_2 "" Trim(linha_v[3]) "" Trim(linha_v[4])
				forn_cli = Trim(forn_cli)
			}

			if(campo_1 == "NOME DO FAVORECIDO"){
				forn_cli = ""
				forn_cli = campo_2 "" Trim(linha_v[3]) "" Trim(linha_v[4])
				forn_cli = Trim(forn_cli)
				nome_favorecido = forn_cli
			}

			if(index(campo_1, "GUIA DE RECOLHIMENTO") > 0){
				obs = ""
				obs = campo_1
				obs = Trim(obs)
			}

			if(campo_1 == "INFORMACOES FORNECIDAS PELO PAGADOR"){
				obs = ""
				obs = campo_2 "" Trim(linha_v[3]) "" Trim(linha_v[4])
				obs = Trim(obs)
			}
			
			if(campo_1 == "DATA DE VENCIMENTO"){
				vencimento = ""
				vencimento = Trim(campo_2)
				vencimento = FormatDate(vencimento)
				vencimento = isDate(vencimento)
				vencimento = IfElse( vencimento == "NULO", "", vencimento )
			}

			if(campo_1 == "CNPJ"){
				cnpj_forn_cli = ""
				cnpj_forn_cli = soNumeros(campo_2)
				cnpj_forn_cli = IfElse(cnpj_forn_cli == "", "00000000000000", cnpj_forn_cli)
			}

			if(campo_1 == "CPF"){
				cnpj_forn_cli = ""
				cnpj_forn_cli = soNumeros(campo_2)
				cnpj_forn_cli = IfElse(cnpj_forn_cli == "", "00000000000000", cnpj_forn_cli)
			}

			if(campo_1 == "CPF/CNPJ"){
				cnpj_forn_cli = ""
				cnpj_forn_cli = soNumeros(campo_2)
				cnpj_forn_cli = IfElse(cnpj_forn_cli == "", "00000000000000", cnpj_forn_cli)
			}

			if(campo_1 == "CPF / CNPJ"){
				cnpj_forn_cli = ""
				cnpj_forn_cli = soNumeros(campo_2)
				cnpj_forn_cli = IfElse(cnpj_forn_cli == "", "00000000000000", cnpj_forn_cli)
			}

			if(campo_1 == "CPF/CNPJ DO PAGADOR"){
				empresa = ""
				empresa = Trim(campo_2)
				empresa = subsCharEspecial(empresa)
				empresa = upperCase(empresa)

				codi_emp = empresa
			}

			if(campo_1 == "VALOR"){
				valor_pago = ""
				valor_pago = campo_2
				valor_pago = FormataCampo("double", valor_pago, 12, 2)
				valor_pago_int = int(soNumeros(valor_pago))
			}

			if(campo_1 == "VALOR RECOLHIDO"){
				valor_pago = ""
				valor_pago = campo_2
				valor_pago = FormataCampo("double", valor_pago, 12, 2)
				valor_pago_int = int(soNumeros(valor_pago))
			}

			if(campo_1 == "VALOR DA TED"){
				valor_pago = ""
				valor_pago = campo_2
				valor_pago = FormataCampo("double", valor_pago, 12, 2)
				valor_pago_int = int(soNumeros(valor_pago))
			}

			if(campo_1 == "VALOR DA TRANSFERENCIA (R$)"){
				valor_pago = ""
				valor_pago = campo_2
				valor_pago = FormataCampo("double", valor_pago, 12, 2)
				valor_pago_int = int(soNumeros(valor_pago))
			}
			
			if(campo_1 == "VALOR PAGO"){
				valor_pago = ""
				valor_pago = campo_2
				valor_pago = FormataCampo("double", valor_pago, 12, 2)
				valor_pago_int = int(soNumeros(valor_pago))
			}

			# quando é pagamento de imposto não tem o nome do fornecedor, o dados vem na informação complementar
			if( obs != "" && vencimento == "" && nome_favorecido == "" ){
				forn_cli = obs
			}
			
			# valor_original = ""
			# valor_original = Trim(substr($0,106,11))
			# valor_original = FormataCampo("double", valor_original, 12, 2)
			# valor_original_int = int(soNumeros(valor_original))
			
			# pago_recebido = ""
			# pago_recebido = Trim(pos_tipo_rec_ou_pag)
			# pago_recebido = subsCharEspecial(pago_recebido)
			# pago_recebido = upperCase(pago_recebido)

			valor_recebido = ""
			valor_recebido = Trim(pos_valor_recebido)
			valor_recebido = FormataCampo("double", valor_recebido, 12, 2)
			valor_recebido_int = int(soNumeros(valor_recebido))
			
			if( valor_pago_int > 0 ){
				operacao_arq = "-"
				valor_considerar = valor_pago
			} else {
				operacao_arq = "+"
				valor_considerar = valor_recebido_int
			}
			
			valor_juros = ""
			valor_juros = Trim(substr($0,117,11))
			valor_juros = FormataCampo("double", valor_juros, 12, 2)
			
			valor_desconto = ""
			valor_desconto = Trim(substr($0,128,11))
			valor_desconto = FormataCampo("double", valor_desconto, 12, 2)
			
			valor_multa = ""
			valor_multa = Trim(pos_valor_multa)
			valor_multa = FormataCampo("double", valor_multa, 12, 2)
			
			categoria = ""
			categoria = Trim(pos_categoria)
			categoria = subsCharEspecial(categoria)
			categoria = upperCase(categoria)
			
			tipo_pagto = ""
			tipo_pagto = Trim(pos_tipo_pagto)
			tipo_pagto = subsCharEspecial(tipo_pagto)
			tipo_pagto = upperCase(tipo_pagto)

			banco_arquivo = "ITAU"

			texto_filtro = "PAGAMENTO EFETUADO EM"
			if( substr(campo_1, 1, length(texto_filtro)) == texto_filtro ){
				baixa = ""
				baixa = Trim(substr($0, length(texto_filtro)+1 ,11))
				gsub("[.]", "/", baixa)
				# baixa = FormatDate(baixa)
				# baixa = isDate(baixa)

				# AS LINHAS ABAIXO SÃO UTILIZADAS PARA IMPRIMIR SOMENTE O QUE FOR DAQUELA COMPETENCIA
				baixa_temp = ""
				baixa_temp = baixa
				baixa_temp = int(substr(baixa_temp, 7) "" substr(baixa_temp, 4, 2))
				
				# PAGOS
				if( valor_pago_int > 0 && _comp_ini <= baixa_temp && baixa_temp <= _comp_fim ){
					print nota, forn_cli, "'" cnpj_forn_cli, emissao, vencimento, banco_arquivo, banco, baixa, baixa_extrato, valor_pago, 
						valor_desconto, valor_juros, valor_multa, nota_completo_orig, codi_emp, "", obs, tipo_pagto, categoria >> "temp\\pagtos_agrupados.csv"

					conseguiu_processar_arquivo = 1
				}
			}
			
			texto_filtro = "TRANSFERENCIA REALIZADA EM"
			if( substr(campo_1, 1, length(texto_filtro)) == texto_filtro ){
				baixa = ""
				baixa = Trim(substr($0, length(texto_filtro)+1 ,11))
				gsub("[.]", "/", baixa)
				# baixa = FormatDate(baixa)
				# baixa = isDate(baixa)

				# AS LINHAS ABAIXO SÃO UTILIZADAS PARA IMPRIMIR SOMENTE O QUE FOR DAQUELA COMPETENCIA
				baixa_temp = ""
				baixa_temp = baixa
				baixa_temp = int(substr(baixa_temp, 7) "" substr(baixa_temp, 4, 2))
				
				# PAGOS
				if( valor_pago_int > 0 && _comp_ini <= baixa_temp && baixa_temp <= _comp_fim ){
					print nota, forn_cli, "'" cnpj_forn_cli, emissao, vencimento, banco_arquivo, banco, baixa, baixa_extrato, valor_pago, 
						valor_desconto, valor_juros, valor_multa, nota_completo_orig, codi_emp, "", obs, tipo_pagto, categoria >> "temp\\pagtos_agrupados.csv"

					conseguiu_processar_arquivo = 1
				}
			}

			texto_filtro = "TRANSFERENCIA EFETUADA EM"
			if( substr(campo_1, 1, length(texto_filtro)) == texto_filtro ){
				baixa = ""
				baixa = Trim(substr($0, length(texto_filtro)+1 ,11))
				gsub("[.]", "/", baixa)
				# baixa = FormatDate(baixa)
				# baixa = isDate(baixa)

				# AS LINHAS ABAIXO SÃO UTILIZADAS PARA IMPRIMIR SOMENTE O QUE FOR DAQUELA COMPETENCIA
				baixa_temp = ""
				baixa_temp = baixa
				baixa_temp = int(substr(baixa_temp, 7) "" substr(baixa_temp, 4, 2))
				
				# PAGOS
				if( valor_pago_int > 0 && _comp_ini <= baixa_temp && baixa_temp <= _comp_fim ){
					print nota, forn_cli, "'" cnpj_forn_cli, emissao, vencimento, banco_arquivo, banco, baixa, baixa_extrato, valor_pago, 
						valor_desconto, valor_juros, valor_multa, nota_completo_orig, codi_emp, "", obs, tipo_pagto, categoria >> "temp\\pagtos_agrupados.csv"

					conseguiu_processar_arquivo = 1
				}
			}

			texto_filtro = "PAGAMENTO REALIZADO EM"
			if( substr(campo_1, 1, length(texto_filtro)) == texto_filtro ){
				baixa = ""
				baixa = Trim(substr($0, length(texto_filtro)+1 ,11))
				gsub("[.]", "/", baixa)
				# baixa = FormatDate(baixa)
				# baixa = isDate(baixa)

				# AS LINHAS ABAIXO SÃO UTILIZADAS PARA IMPRIMIR SOMENTE O QUE FOR DAQUELA COMPETENCIA
				baixa_temp = ""
				baixa_temp = baixa
				baixa_temp = int(substr(baixa_temp, 7) "" substr(baixa_temp, 4, 2))
				
				# PAGOS
				if( valor_pago_int > 0 && _comp_ini <= baixa_temp && baixa_temp <= _comp_fim ){
					print nota, forn_cli, "'" cnpj_forn_cli, emissao, vencimento, banco_arquivo, banco, baixa, baixa_extrato, valor_pago, 
						valor_desconto, valor_juros, valor_multa, nota_completo_orig, codi_emp, "", obs, tipo_pagto, categoria >> "temp\\pagtos_agrupados.csv"

					conseguiu_processar_arquivo = 1
				}
			}

			texto_filtro = "OPERACAO EFETUADA EM"
			if( substr(campo_1, 1, length(texto_filtro)) == texto_filtro ){
				baixa = ""
				baixa = Trim(substr($0, length(texto_filtro)+1 ,11))
				gsub("[.]", "/", baixa)
				# baixa = FormatDate(baixa)
				# baixa = isDate(baixa)

				# AS LINHAS ABAIXO SÃO UTILIZADAS PARA IMPRIMIR SOMENTE O QUE FOR DAQUELA COMPETENCIA
				baixa_temp = ""
				baixa_temp = baixa
				baixa_temp = int(substr(baixa_temp, 7) "" substr(baixa_temp, 4, 2))
				
				# PAGOS
				if( valor_pago_int > 0 && _comp_ini <= baixa_temp && baixa_temp <= _comp_fim ){
					print nota, forn_cli, "'" cnpj_forn_cli, emissao, vencimento, banco_arquivo, banco, baixa, baixa_extrato, valor_pago, 
						valor_desconto, valor_juros, valor_multa, nota_completo_orig, codi_emp, "", obs, tipo_pagto, categoria >> "temp\\pagtos_agrupados.csv"
					
					conseguiu_processar_arquivo = 1
				}
			}

			texto_filtro = "TED SOLICITADA EM"
			if( substr(campo_1, 1, length(texto_filtro)) == texto_filtro ){
				baixa = ""
				baixa = Trim(substr($0, length(texto_filtro)+1 ,11))
				gsub("[.]", "/", baixa)
				# baixa = FormatDate(baixa)
				# baixa = isDate(baixa)

				# AS LINHAS ABAIXO SÃO UTILIZADAS PARA IMPRIMIR SOMENTE O QUE FOR DAQUELA COMPETENCIA
				baixa_temp = ""
				baixa_temp = baixa
				baixa_temp = int(substr(baixa_temp, 7) "" substr(baixa_temp, 4, 2))
				
				# PAGOS
				if( valor_pago_int > 0 && _comp_ini <= baixa_temp && baixa_temp <= _comp_fim ){
					print nota, forn_cli, "'" cnpj_forn_cli, emissao, vencimento, banco_arquivo, banco, baixa, baixa_extrato, valor_pago, 
						valor_desconto, valor_juros, valor_multa, nota_completo_orig, codi_emp, "", obs, tipo_pagto, categoria >> "temp\\pagtos_agrupados.csv"
					
					conseguiu_processar_arquivo = 1
				}
			}
			
		} close(file)

		if(conseguiu_processar_arquivo == 0){
			system("copy temp\\\"" nomeArquivoPDF "\" naoprocessados\\\"" nomeArquivoPDF "\" > nul")
			print("      - Arquivo \"" nomeArquivoPDF "\" nao foi possivel processar.")
		}
	} close(ArquivosCsv)
	
	#print "Banco;Conta Corrente;Tipo Movimento;Data;Operacao;Valor;Num. Doc.;Historico" >> "saida\\movtos_feitos_no_cartao_nao_estao_na_planilha.csv"
	
	FS = ";"
	
	# VAI VER NO OFX QUAIS DÉBITOS QUE NÃO ESTÃO NA PLANILHA DO CLIENTE, GERALMENTE SÃO CHEQUES COMPENSADOS EM MESES ANTERIORES OU TARIFAS
	# while ( (getline < "temp\\extrato_cartao.csv") > 0 ) {
	# 	num_banco_2 = $1
		
	# 	conta_corrente_3 = $2
	# 	conta_corrente_3_int = int( soNumeros(conta_corrente_3) )
		
	# 	tipo_mov_2 = $3
	# 	data_mov_2 = $4
	# 	operacao_3 = $5
	# 	valor_transacao_2 = $6
	# 	num_doc_2 = $7
	# 	historico_2 = $8
		
	# 	pagou_no_banco = PagouNoBanco[operacao_3, data_mov_2, valor_transacao_2]
		
	# 	if( ( operacao_3 == "-" || operacao_3 == "Operacao") && pagou_no_banco != 1 )
	# 	#if( pagou_no_banco != 1 )
	# 		print $0 >> "saida\\pagtos_feitos_no_cartao_nao_estao_na_planilha.csv"
		
	# } close("temp\\extrato_cartao.csv")
	
	system("if exist bin\\*.txt del /q bin\\*.txt")
}