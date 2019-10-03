BEGIN { 
	FS = "";
	OFS = ";";
	
	system("if exist bin\\*.txt del /q bin\\*.txt")
	system("if exist entrada\\*.ofx dir /b entrada\\*.ofx > bin\\listaofx.txt")
	system("if exist entrada\\*.ofc dir /b entrada\\*.ofc >> bin\\listaofx.txt")
	
	ArquivosCsv = "bin\\listacsv.txt";
	ArquivosOfx = "bin\\listaofx.txt";
	
	_comp_ini = int(Trim(substr(_comp_ini, 4)) "" substr(_comp_ini, 1, 2))
	_comp_fim = int(Trim(substr(_comp_fim, 4)) "" substr(_comp_fim, 1, 2))
	
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
					print num_banco, conta_corrente, tipo_mov, data_mov, operacao, valor_transacao, num_doc, historico >> "temp\\extrato_cartao.csv"
				}
			}
			
		} close(fileofx)
	} close(ArquivosOfx)
	
	FS = ";"; 
	OFS = FS;

	print "Documento;Nome Fornecedor;CNPJ Fornecedor;Emissao;Vencimento;Banco Planilha;Banco Oco. Extrato;Data Pagto;Data Oco. Extrato;Valor Pago;Valor Desconto;Valor Juros;Valor Multa;Numero Titulo;Empresa;Codigo Conta Dominio;OBS;Tipo Pagto;Categoria" >> "temp\\pagtos_agrupados.csv"
	print "Documento;Nome Cliente;CNPJ Cliente;Emissao;Vencimento;Banco Planilha;Banco Oco. Extrato;Data Pagto;Data Oco. Extrato;Valor Pago;Valor Desconto;Valor Juros;Valor Multa;Numero Titulo;Empresa;Codigo Conta Dominio;OBS;Tipo Pagto;Categoria" >> "temp\\recebtos_agrupados.csv"
	
	while ( (getline < "temp\\extrato_cartao.csv") > 0 ) {
		num_banco_extrato = $1
		conta_corrente_extrato = $2
		tipo_mov_extrato = $3

		data_mov_extrato = $4
		data_mov_int = int(substr(data_mov_extrato, 7) "" substr(data_mov_extrato, 4, 2))

		operacao_extrato = $5
		valor_transacao_extrato = $6
		num_doc_extrato = $7

		historico_extrato = $8
		
		obs = historico_extrato
		
		if( index(historico_extrato, "COBRANCA") > 0 && index(historico_extrato, "ELETRON") > 0 ){
			historico_extrato = substr(historico_extrato, index(historico_extrato, "COBRANCA") + 8 )
			historico_extrato = Trim(historico_extrato)
		}

		if( index(historico_extrato, "FORNECEDOR") > 0 && index(historico_extrato, "RECEBIMENTO") > 0 ){
			historico_extrato = substr(historico_extrato, index(historico_extrato, "FORNECEDOR") + 10 )
			historico_extrato = Trim(historico_extrato)
		}

		if( index(historico_extrato, "TRIBUTO") > 0 && index(historico_extrato, "INTERNET") > 0 ){
			historico_extrato = substr(historico_extrato, index(historico_extrato, "INTERNET") + 8 )
			historico_extrato = Trim(historico_extrato)
			gsub("-", "", historico_extrato)
		}

		historico_complementar_extrato = $9

		ExisteMov[operacao_extrato, data_mov_extrato, valor_transacao_extrato] = 1
		BancoPago[operacao_extrato, data_mov_extrato, valor_transacao_extrato] = num_banco_extrato "-" conta_corrente_extrato
		DataPagto[operacao_extrato, data_mov_extrato, valor_transacao_extrato] = data_mov_extrato
		
		ExisteMovBanco[num_banco_extrato, operacao_extrato, data_mov_extrato, valor_transacao_extrato] = 1
		BancoPagoBanco[num_banco_extrato, operacao_extrato, data_mov_extrato, valor_transacao_extrato] = num_banco_extrato "-" conta_corrente_extrato
		DataPagtoBanco[num_banco_extrato, operacao_extrato, data_mov_extrato, valor_transacao_extrato] = data_mov_extrato
		
		# QUANDO É CHEQUE GUARDA A DATA QUE O CHEQUE COMPENSOU, É ELA QUE TEM QUE SER UTILIZADA COMO DATA DA BAIXA
		if( index(historico_extrato, "CHEQ COMP") > 0 || index(historico_extrato, "CHEQUE SAC") > 0 ){
			DataCompensacaoCheque[num_doc_extrato] = data_mov_extrato
			BancoPagoCheque[num_doc_extrato] = num_banco_extrato "-" conta_corrente_extrato
		}

		forn_cli = historico_extrato
		banco_arquivo = "BRADESCO"
		baixa = data_mov_extrato
		valor_pago = valor_transacao_extrato
		valor_desconto = "0,00"
		valor_juros = "0,00"
		valor_multa = "0,00"

		# PAGOS
		if( operacao_extrato == "-" && _comp_ini <= data_mov_int && data_mov_int <= _comp_fim ){
			print nota, forn_cli, "'" cnpj_forn_cli, emissao, vencimento, banco_arquivo, banco, baixa, baixa_extrato, valor_pago, 
					valor_desconto, valor_juros, valor_multa, nota_completo_orig, codi_emp, "", obs, tipo_pagto, categoria >> "temp\\pagtos_agrupados.csv"
		}

		# RECEBIMENTOS
		if( operacao_extrato == "+" && _comp_ini <= data_mov_int && data_mov_int <= _comp_fim ){
			print nota, forn_cli, "'" cnpj_forn_cli, emissao, vencimento, banco_arquivo, banco, baixa, baixa_extrato, valor_pago, 
					valor_desconto, valor_juros, valor_multa, nota_completo_orig, codi_emp, "", obs, tipo_pagto, categoria >> "temp\\recebtos_agrupados.csv"
		}

	} close("temp\\extrato_cartao.csv")
	
	
	system("if exist bin\\*.txt del /q bin\\*.txt")
}