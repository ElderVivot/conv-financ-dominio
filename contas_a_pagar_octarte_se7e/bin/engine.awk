BEGIN { 
	FS = "";
	OFS = ";";
	
	system("if exist bin\\*.txt del /q bin\\*.txt")
	#system("dir /b entrada\\*.csv > bin\\listacsv.txt")
	system("dir /b entrada\\*.ofx > bin\\listaofx.txt")
	
	ArquivosCsv = "temp\\baixas.csv";
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
	
	FS = ";"; 
	OFS = FS;
	
	pos_for = 999
	pos_cnpj_for = 999
	pos_nota = 9
	pos_emissao = 999
	pos_venc = 2
	pos_baixa = 1
	pos_valor_original = 11
	pos_valor_pago = 16
	pos_valor_desc = 999
	pos_valor_juros = 999
	pos_valor_multa = 999
	pos_obs = 4
	pos_natureza_pagto = 999
	pos_banco_arquivo = 999
	pos_tipo_pagto = 999
	
	print "Documento;CNPJ Fornecedor;Vencimento;Banco Oco. Extrato;Data Pagto;Data Oco. Extrato;Valor Pago;Valor Desconto;Valor Juros;Nome Fornecedor;Titulo;Obs" >> "temp\\pagtos_agrupados.csv"
	
	while ((getline < ArquivosCsv) > 0) {
		#file = "entrada\\" $0
		
		#while ((getline < file) > 0) {
			
			campo_1 = ""
			campo_1 = Trim($1)
			campo_1 = subsCharEspecial(campo_1)
			campo_1 = upperCase(campo_1)
			
			id_cliente = split(campo_1, campo_1_v, "-")
			id_cliente = campo_1_v[1]
			id_cliente = int(soNumeros(id_cliente))
			
			if( id_cliente > 0 && index(campo_1, "-") > 0 ){
				forn_cli = ""
				forn_cli = campo_1_v[2] " " campo_1_v[3] " " campo_1_v[4] " " campo_1_v[5]
				forn_cli = Trim(forn_cli)
			}
			
			cnpj_forn_cli = ""
			cnpj_forn_cli = soNumeros($pos_cnpj_for)
			cnpj_forn_cli = IfElse(cnpj_forn_cli == "", "00000000000000", cnpj_forn_cli)
			
			nota_completo = ""
			nota_completo = Trim($pos_nota)
			nota_completo_orig = nota_completo
			if( index(nota_completo, "-") > 0 )
				nota_completo = split( nota_completo, nota_completo_v, "-" )
			if( index(nota_completo, "/") > 0 )
				nota_completo = split( nota_completo, nota_completo_v, "/" )
			
			nota = ""
			nota = Trim(nota_completo_v[1])
			
			if( index(nota_completo_orig, "-") == 0 && index(nota_completo_orig, "/") == 0 )
				nota = nota_completo_orig
			
			valor_original = ""
			valor_original = Trim( $pos_valor_original )
			valor_original = FormataCampo("double", valor_original, 12, 2)
			valor_original_int = int(soNumeros(valor_original))
			
			valor_pago = ""
			valor_pago = Trim( $pos_valor_pago )
			valor_pago = FormataCampo("double", valor_pago, 12, 2)
			valor_pago_int = int(soNumeros(valor_pago))

			valor_considerar = valor_pago
			
			valor_juros = "0,00"
			#if( valor_original_int < valor_pago_int ){
			#	valor_juros = valor_pago_int - valor_original_int
			#	valor_juros = TransformaPraDecimal(valor_juros)
			#}
			
			valor_desconto = "0,00"
			#if( valor_original_int > valor_pago_int ){
			#	valor_desconto = valor_original_int - valor_pago_int
			#	valor_desconto = TransformaPraDecimal(valor_desconto)
			#}
			
			baixa = ""
			baixa = Trim($pos_baixa)
			baixa = Trim(baixa)
			baixa = FormatDate(baixa)
			baixa = isDate(baixa)
			
			vencimento = ""
			vencimento = Trim($pos_venc)
			vencimento = FormatDate(vencimento)
			vencimento = isDate(vencimento)
			
			obs = ""
			obs = Trim($pos_obs)
			obs = subsCharEspecial(obs)
			obs = upperCase(obs)
			
			#if( index(obs, "SALARIO") > 0 ){
			#	obs = obs " / " forn_cli
			#	forn_cli = "SALARIO E ORDENADOS"
			#}
			
			#if( index(obs, "LABORE") > 0 ){
			#	obs = obs " / " forn_cli
			#	forn_cli = "PRO-LABORE"
			#}
			
			if( index(obs, "AJUDA") > 0 && index(obs, "CUSTO") > 0 ){
				obs = obs " / " forn_cli
				forn_cli = "AJUDA DE CUSTO"
			}
			
			if( index(obs, "TARIFA") > 0 && index(obs, "SERVICO") > 0 ){
				obs = obs " / " forn_cli
				forn_cli = "TARIFA BANCO"
			}

			operacao_arq = "-"
			
			# TEM PAGAMENTOS QUE O CLIENTE LANÇA NA PLANILHA COM DATA ERRADA DA BAIXA, PORTANTO ESTAS LINHAS ABAIXO VAI VERIFICAR ISTO E O LIMITE É 3 DIAS A MAIS OU 3 DIAS A MENOS
			baixa_extrato = ""
			baixa_mais1 = ""
			baixa_mais2 = ""
			baixa_menos1 = ""
			baixa_menos2 = ""
			baixa_mais3 = ""
			baixa_menos3 = ""
			banco_extrato = ""
			if( baixa != "NULO" ){
				baixa_mais1 = SomaDias(baixa, 1)
				baixa_mais2 = SomaDias(baixa, 2)
				baixa_menos1 = SomaDias(baixa, -1)
				baixa_menos2 = SomaDias(baixa, -2)
				baixa_mais3 = SomaDias(baixa, 3)
				baixa_menos3 = SomaDias(baixa, -3)
				
				# COMEÇA PELOS MAIORES DIAS E VAI PRO MENOR, POIS SE SOBRESCREVER, SOBRESCRE COM DADOS MAIS RECENTES
				# - 3 DIAS
				if( DataPagto[operacao_arq, baixa_menos3, valor_considerar] != "" ){
					baixa_extrato = DataPagto[operacao_arq, baixa_menos3, valor_considerar]
					banco_extrato = BancoPago[operacao_arq, baixa_menos3, valor_considerar]
				}
				if( DataPagtoBanco[num_banco_arq, operacao_arq, baixa_menos3, valor_considerar] != "" ){
					baixa_extrato = DataPagtoBanco[num_banco_arq, operacao_arq, baixa_menos3, valor_considerar]
					banco_extrato = BancoPagoBanco[num_banco_arq, operacao_arq, baixa_menos3, valor_considerar]
				}
				
				# + 3 DIAS
				if( DataPagto[operacao_arq, baixa_mais3, valor_considerar] != "" ){
					baixa_extrato = DataPagto[operacao_arq, baixa_mais3, valor_considerar]
					banco_extrato = BancoPago[operacao_arq, baixa_mais3, valor_considerar]
				}
				if( DataPagtoBanco[num_banco_arq, operacao_arq, baixa_mais3, valor_considerar] != "" ){
					baixa_extrato = DataPagtoBanco[num_banco_arq, operacao_arq, baixa_mais3, valor_considerar]
					banco_extrato = BancoPagoBanco[num_banco_arq, operacao_arq, baixa_mais3, valor_considerar]
				}
				
				# - 2 DIAS
				if( DataPagto[operacao_arq, baixa_menos2, valor_considerar] != "" ){
					baixa_extrato = DataPagto[operacao_arq, baixa_menos2, valor_considerar]
					banco_extrato = BancoPago[operacao_arq, baixa_menos2, valor_considerar]
				}
				if( DataPagtoBanco[num_banco_arq, operacao_arq, baixa_menos2, valor_considerar] != "" ){
					baixa_extrato = DataPagtoBanco[num_banco_arq, operacao_arq, baixa_menos2, valor_considerar]
					banco_extrato = BancoPagoBanco[num_banco_arq, operacao_arq, baixa_menos2, valor_considerar]
				}
				
				# + 2 DIAS
				if( DataPagto[operacao_arq, baixa_mais2, valor_considerar] != "" ){
					baixa_extrato = DataPagto[operacao_arq, baixa_mais2, valor_considerar]
					banco_extrato = BancoPago[operacao_arq, baixa_mais2, valor_considerar]
				} 
				if( DataPagtoBanco[num_banco_arq, operacao_arq, baixa_mais2, valor_considerar] != "" ){
					baixa_extrato = DataPagtoBanco[num_banco_arq, operacao_arq, baixa_mais2, valor_considerar]
					banco_extrato = BancoPagoBanco[num_banco_arq, operacao_arq, baixa_mais2, valor_considerar]
				}
				
				# + 1 DIA --> ESTE O MAIS VEM PRIMEIRO POIS É MAIS FÁCIL O CARA COLOCAR QUE PAGOU NO DIA POSTERIOR QUANDO NA VERDADE FOI NO DIA ANTERIOR
				if( DataPagto[operacao_arq, baixa_mais1, valor_considerar] != "" ){
					baixa_extrato = DataPagto[operacao_arq, baixa_mais1, valor_considerar]
					banco_extrato = BancoPago[operacao_arq, baixa_mais1, valor_considerar]
				}
				if( DataPagtoBanco[num_banco_arq, operacao_arq, baixa_mais1, valor_considerar] != "" ){
					baixa_extrato = DataPagtoBanco[num_banco_arq, operacao_arq, baixa_mais1, valor_considerar]
					banco_extrato = BancoPagoBanco[num_banco_arq, operacao_arq, baixa_mais1, valor_considerar]
				}
				
				# - 1 DIA
				if( DataPagto[operacao_arq, baixa_menos1, valor_considerar] != "" ){
					baixa_extrato = DataPagto[operacao_arq, baixa_menos1, valor_considerar]
					banco_extrato = BancoPago[operacao_arq, baixa_menos1, valor_considerar]
				}
				if( DataPagtoBanco[num_banco_arq, operacao_arq, baixa_menos1, valor_considerar] != "" ){
					baixa_extrato = DataPagtoBanco[num_banco_arq, operacao_arq, baixa_menos1, valor_considerar]
					banco_extrato = BancoPagoBanco[num_banco_arq, operacao_arq, baixa_menos1, valor_considerar]
				}
			}
			
			banco_extrato = split(banco_extrato, banco_extrato_v, "-")
			banco_extrato = banco_extrato_v[1]
			
			banco_extrato_2 = ""
			banco_extrato_2 = banco_extrato_v[2]
			
			banco = BancoPago[operacao_arq, baixa, valor_considerar]
			if( BancoPagoBanco[num_banco_arq, operacao_arq, baixa, valor_considerar] != "")
				banco = BancoPagoBanco[num_banco_arq, operacao_arq, baixa, valor_considerar]
			
			banco = split(banco, banco_v, "-")
			banco = banco_v[1]
			
			banco_2 = ""
			banco_2 = banco_v[2]
			banco_2 = IfElse(banco_2 == "", banco_extrato_2, banco_2)
			
			existe_mov_dia = DataPagto[operacao_arq, baixa, valor_considerar]
			if( DataPagtoBanco[num_banco_arq, operacao_arq, baixa, valor_considerar] != "")
				existe_mov_dia = DataPagtoBanco[num_banco_arq, operacao_arq, baixa, valor_considerar]
			
			if( existe_mov_dia != "" ){
				banco_extrato = banco
				baixa_extrato = baixa 
			}
			
			if( int(banco) == 1 || int(banco_extrato) == 1 )
				banco = "BB" "-" banco_2
			else if( int(banco) == 341 || int(banco_extrato) == 341 )
				banco = "ITAU" "-" banco_2
			else if( int(banco) == 237 || int(banco_extrato) == 237 )
				banco = "BRADESCO" "-" banco_2
			else if( int(banco) == 756 || int(banco_extrato) == 756 )
				banco = "SICOOB" "-" banco_2
			else if( int(banco) == 422 || int(banco_extrato) == 422 )
				banco = "SAFRA" "-" banco_2
			else if( int(banco) == 104 || int(banco_extrato) == 104 )
				banco = "CAIXA" "-" banco_2
			else if( int(banco) == 33 || int(banco_extrato) == 33 )
				banco = "SANTANDER" "-" banco_2
			else if( int(banco) == 634 || int(banco_extrato) == 634 )
				banco = "TRI BANCO" "-" banco_2
			else if( banco == "" )
				banco = "NAO ENCONTROU NO OFX"
			else
				banco = "AVALIAR NAO FOI ENCONTRADO" "-" banco_2
			
			if( banco_arquivo == "DINHEIRO" && banco == "NAO ENCONTROU NO OFX" )
				banco = "DINHEIRO"
			
			# CASO A DATA DO PAGTO ESTEJA CORRETA COM O EXTRATO ENTÃO COLOCA A DATA OCORRÊNCIA SENDO A PRÓPRIA DATA DA BAIXA
			if( baixa_extrato == "" && banco != "NAO ENCONTROU NO OFX" )
				baixa_extrato = baixa
			
			# ESTAS LINHA SERVE PRA DEIXAR REGISTRADO O QUE TEM NA PLANILHA DO CLIENTE E FOI PAGO. SERÁ UTILIZADO PARA COMPARAÇÃO COM O OFX AFIM DE AVALIAR O QUE ESTÁ NO OFX DE PAGTO E NÃO ESTÁ NESTA PLANILHA
			PagouNoBanco[operacao_arq, baixa_extrato, valor_considerar] = 1
			
			# AS LINHAS ABAIXO SÃO UTILIZADAS PARA IMPRIMIR SOMENTE O QUE FOR DAQUELA COMPETENCIA
			baixa_temp = ""
			baixa_temp = baixa_extrato
			baixa_temp = IfElse(baixa_temp == "", baixa, baixa_temp)
			baixa_temp = int(substr(baixa_temp, 7) "" substr(baixa_temp, 4, 2))
			
			if( baixa != "NULO" && int(valor_pago) > 0 && _comp_ini <= baixa_temp && baixa_temp <= _comp_fim ){
				print nota, "'" cnpj_forn_cli, vencimento, banco, baixa, baixa_extrato, valor_pago, valor_desconto, valor_juros,
      				  forn_cli, nota_completo_orig, obs >> "temp\\pagtos_agrupados.csv"
			}
				
		#} close(file)
	} close(ArquivosCsv)
	
	print "Banco;Conta Corrente;Tipo Movimento;Data;Operacao;Valor;Num. Doc.;Historico" >> "saida\\pagtos_feitos_no_cartao_nao_estao_na_planilha.csv"
	
	# VAI VER NO OFX QUAIS DÉBITOS QUE NÃO ESTÃO NA PLANILHA DO CLIENTE, GERALMENTE SÃO CHEQUES COMPENSADOS EM MESES ANTERIORES OU TARIFAS
	while ( (getline < "temp\\extrato_cartao.csv") > 0 ) {
		num_banco_2 = $1
		
		conta_corrente_3 = $2
		
		tipo_mov_2 = $3
		data_mov_2 = $4
		operacao_3 = $5
		valor_transacao_2 = $6
		num_doc_2 = $7
		historico_2 = $8
		
		pagou_no_banco = PagouNoBanco[operacao_3, data_mov_2, valor_transacao_2]
		
		if( operacao_3 == "-" && pagou_no_banco != 1 )
			print $0 >> "saida\\pagtos_feitos_no_cartao_nao_estao_na_planilha.csv"
		
	} close("temp\\extrato_cartao.csv")
	
	system("if exist bin\\*.txt del /q bin\\*.txt")
}