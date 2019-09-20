BEGIN { 
	FS = "";
	OFS = ";";
	
	system("if exist bin\\*.txt del /q bin\\*.txt")
	system("dir /b temp\\*.csv > bin\\listacsv.txt")
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
	
	FS = ";"; 
	OFS = FS;
	
	print "Documento;Nome Fornecedor;CNPJ Fornecedor;Emissao;Vencimento;Banco Planilha;Banco Oco. Extrato;Data Pagto;Data Oco. Extrato;Valor Pago;Valor Desconto;Valor Juros;Valor Multa;Numero Titulo;Empresa;Codigo Conta Dominio;OBS;Tipo Pagto;Categoria" >> "temp\\pagtos_agrupados.csv"
	print "Documento;Nome Cliente;CNPJ Cliente;Emissao;Vencimento;Banco Planilha;Banco Oco. Extrato;Data Pagto;Data Oco. Extrato;Valor Pago;Valor Desconto;Valor Juros;Valor Multa;Numero Titulo;Empresa;Codigo Conta Dominio;OBS;Tipo Pagto;Categoria" >> "temp\\recebtos_agrupados.csv"
	
	while ((getline < ArquivosCsv) > 0) {
		
		filecsv = "temp\\" $0
		
		while ((getline < filecsv) > 0) {

			if ( Trim(toupper($1)) == toupper("Vencto.") ){
				load_columns();
				continue;
			}
			
			texto_for = "Fornecedor"
			texto_cnpj_for = "---------"
			texto_nota = "Doc/Ser."
			texto_emissao = "-------"
			texto_venc = "Vencto."
			texto_baixa = "Pagto."
			texto_valor_original = "Valor Fatura"
			texto_valor_pago = "Valor Pago"
			texto_valor_recebido = "---------"
			texto_valor_desc = "Desconto"
			texto_valor_juros = "Juros"
			texto_valor_multa = "---------"
			texto_obs = "Fatura/Emp"
			texto_categoria = "--------"
			texto_banco_arquivo = "--------"
			texto_empresa = "------"
			texto_tipo_pagto = "-------"
			texto_natureza_pagto = "-------------"
			texto_tipo_rec_ou_pag = "---------"
			texto_tarifas = "---------"
						
			pos_for = $IfElse( int(NumColuna(texto_for)) > 0, int(NumColuna(texto_for)), 9 )
			pos_cnpj_for = $IfElse( int(NumColuna(texto_cnpj_for)) > 0, int(NumColuna(texto_cnpj_for)), 999 )
			pos_nota = $IfElse( int(NumColuna(texto_nota)) > 0, int(NumColuna(texto_nota)), 12 )
			pos_emissao = $IfElse( int(NumColuna(texto_emissao)) > 0, int(NumColuna(texto_emissao)), 999 )
			pos_venc = $IfElse( int(NumColuna(texto_venc)) > 0, int(NumColuna(texto_venc)), 1 )
			pos_baixa = $IfElse( int(NumColuna(texto_baixa)) > 0, int(NumColuna(texto_baixa)), 4 )
			pos_valor_original = $IfElse( int(NumColuna(texto_valor_original)) > 0, int(NumColuna(texto_valor_original)), 5 )
			pos_valor_pago = $IfElse( int(NumColuna(texto_valor_pago)) > 0, int(NumColuna(texto_valor_pago)), 8 )
			pos_valor_recebido = $IfElse( int(NumColuna(texto_valor_recebido)) > 0, int(NumColuna(texto_valor_recebido)), 999 )
			pos_valor_desc = $IfElse( int(NumColuna(texto_valor_desc)) > 0, int(NumColuna(texto_valor_desc)), 7 )
			pos_valor_juros = $IfElse( int(NumColuna(texto_valor_juros)) > 0, int(NumColuna(texto_valor_juros)), 6 )
			pos_valor_multa = $IfElse( int(NumColuna(texto_valor_multa)) > 0, int(NumColuna(texto_valor_multa)), 999 )
			pos_obs = $IfElse( int(NumColuna(texto_obs)) > 0, int(NumColuna(texto_obs)), 2 )
			pos_natureza_pagto = $IfElse( int(NumColuna(texto_natureza_pagto)) > 0, int(NumColuna(texto_natureza_pagto)), 999 )
			pos_banco_arquivo = $IfElse( int(NumColuna(texto_banco_arquivo)) > 0, int(NumColuna(texto_banco_arquivo)), 999)
			pos_tipo_pagto = $IfElse( int(NumColuna(texto_tipo_pagto)) > 0, int(NumColuna(texto_tipo_pagto)), 999 )
			pos_categoria = $IfElse( int(NumColuna(texto_categoria)) > 0, int(NumColuna(texto_categoria)), 999 )
			pos_empresa = $IfElse( int(NumColuna(texto_empresa)) > 0, int(NumColuna(texto_empresa)), 999 )
			pos_tipo_rec_ou_pag = $IfElse( int(NumColuna(texto_tipo_rec_ou_pag)) > 0, int(NumColuna(texto_tipo_rec_ou_pag)), 999 )
			pos_valor_tarifas = $IfElse( int(NumColuna(texto_tarifas)) > 0, int(NumColuna(texto_tarifas)), 999 )
						
			campo_1 = ""
			campo_1 = Trim($1)
			campo_1 = subsCharEspecial(campo_1)
			campo_1 = upperCase(campo_1)
			
			forn_cli = ""
			forn_cli = Trim(pos_for)
			forn_cli = subsCharEspecial(forn_cli)
			forn_cli = upperCase(forn_cli)
			
			nota_completo = ""
			nota_completo = Trim(pos_nota)
			nota_completo_orig = nota_completo
			if( index(nota_completo, "-") > 0 )
				nota_completo = split( nota_completo, nota_completo_v, "-" )
			if( index(nota_completo, "/") > 0 )
				nota_completo = split( nota_completo, nota_completo_v, "/" )
			if( index(nota_completo, "|") > 0 )
				nota_completo = split( nota_completo, nota_completo_v, "|" )
			
			nota = ""
			nota = Trim(nota_completo_v[1])
			
			if( index(nota_completo_orig, "-") == 0 && index(nota_completo_orig, "/") == 0 && index(nota_completo_orig, "|") == 0 )
				nota = nota_completo_orig
				
			if(index(nota, "SEM") > 0 && index(nota, "NOTA") > 0){
				nota = ""
				nota_completo_orig = ""
			}
			
			nota = int(soNumeros(nota))
			
			vencimento = ""
			vencimento = Trim(pos_venc)
			vencimento = FormatDate(vencimento)
			vencimento = isDate(vencimento)
			vencimento = IfElse( vencimento == "NULO", "", vencimento )
			
			baixa = ""
			baixa = Trim(pos_baixa)
			baixa = FormatDate(baixa)
			baixa = isDate(baixa)
			
			emissao = ""
			emissao = Trim(pos_emissao)
			emissao = FormatDate(emissao)
			emissao = isDate(emissao)
			emissao = IfElse( emissao == "NULO", "", emissao )
			
			cnpj_forn_cli = ""
			cnpj_forn_cli = soNumeros(pos_cnpj_for)
			cnpj_forn_cli = IfElse(cnpj_forn_cli == "", "00000000000000", cnpj_forn_cli)
			
			valor_original = ""
			valor_original = Trim(pos_valor_original)
			valor_original = FormataCampo("double", valor_original, 12, 2)
			valor_original_int = int(soNumeros(valor_original))
			
			pago_recebido = ""
			pago_recebido = Trim(pos_tipo_rec_ou_pag)
			pago_recebido = subsCharEspecial(pago_recebido)
			pago_recebido = upperCase(pago_recebido)
			
			valor_pago = ""
			valor_pago = Trim(pos_valor_pago)
			valor_pago = FormataCampo("double", valor_pago, 12, 2)
			valor_pago_int = int(soNumeros(valor_pago))
			
			valor_recebido = ""
			valor_recebido = Trim(pos_valor_recebido)
			valor_recebido = FormataCampo("double", valor_recebido, 12, 2)
			valor_recebido_int = int(soNumeros(valor_recebido))
			
			valor_taxa = ""
			valor_taxa = Trim(pos_valor_tarifas)
			valor_taxa = FormataCampo("double", valor_taxa, 12, 2)
			valor_taxa_int = int(soNumeros(valor_taxa))
			
			if( valor_taxa_int > 0 && valor_pago_int == 0 ){
				valor_pago = valor_taxa
				valor_pago_int = valor_taxa_int
			}
			
			if( valor_taxa_int > 0 && valor_recebido_int == 0 ){
				valor_recebido = valor_taxa
				valor_recebido_int = valor_taxa_int
			}
			
			if( valor_pago_int > 0 ){
				operacao_arq = "-"
				valor_considerar = valor_pago
			} else {
				operacao_arq = "+"
				valor_considerar = valor_recebido_int
			}
			
			valor_juros = ""
			valor_juros = Trim(pos_valor_juros)
			valor_juros = FormataCampo("double", valor_juros, 12, 2)
			
			valor_desconto = ""
			valor_desconto = Trim(pos_valor_desc)
			valor_desconto = FormataCampo("double", valor_desconto, 12, 2)
			
			# if( valor_juros == "0,00" && valor_pago_int > valor_original_int ){
			# 	valor_juros = valor_pago_int - valor_original_int
			# 	valor_juros = TransformaPraDecimal(valor_juros)
			# }
			
			# if( valor_desconto == "0,00" && valor_pago_int < valor_original_int ){
			# 	valor_desconto = valor_original_int - valor_pago_int
			# 	valor_desconto = TransformaPraDecimal(valor_desconto)
			# }
			
			valor_multa = ""
			valor_multa = Trim(pos_valor_multa)
			valor_multa = FormataCampo("double", valor_multa, 12, 2)
			
			obs = ""
			obs = Trim(pos_obs)
			obs = subsCharEspecial(obs)
			obs = upperCase(obs)

			categoria = ""
			categoria = Trim(pos_categoria)
			categoria = subsCharEspecial(categoria)
			categoria = upperCase(categoria)
			
			tipo_pagto = ""
			tipo_pagto = Trim(pos_tipo_pagto)
			tipo_pagto = subsCharEspecial(tipo_pagto)
			tipo_pagto = upperCase(tipo_pagto)
			
			empresa = ""
			empresa = Trim(pos_empresa)
			empresa = subsCharEspecial(empresa)
			empresa = upperCase(empresa)
			
			codi_emp = ""

			banco_arquivo = ""
			banco_arquivo = Trim(pos_banco_arquivo)
			banco_arquivo = subsCharEspecial(banco_arquivo)
			banco_arquivo = upperCase(banco_arquivo)
			
			if( index(banco_arquivo, "SANTANDER") > 0 ){
				num_banco_arq = 33
				banco_arquivo = "SANTANDER"
			}else if( index(banco_arquivo, "ITAU") > 0 ){
				num_banco_arq = 341
				banco_arquivo = "ITAU"
			}else if( index(banco_arquivo, "BRADESCO") > 0 ){
				num_banco_arq = 237
				banco_arquivo = "BRADESCO"
			}else if( index(banco_arquivo, "SICOOB") > 0 ){
				num_banco_arq = 756
				banco_arquivo = "SICOOB"
			}else if( index(banco_arquivo, "SAFRA") > 0 ){
				num_banco_arq = 422
				banco_arquivo = "SAFRA"
			}else if( index(banco_arquivo, "CAIXA") > 0 ){
				if( index(tipo_pagto, "DIN") > 0 ){
					num_banco_arq = 999
					banco_arquivo = "DINHEIRO"
				} else {
					num_banco_arq = 104
					banco_arquivo = "CAIXA"
				}
			}else if( index(banco_arquivo, "BRASIL") > 0 || index(banco_arquivo, "BB") > 0 ){
				num_banco_arq = 1
				banco_arquivo = "BCO BRASIL"
			}else if( banco_arquivo == "DH" || banco_arquivo == "CX" ){
				num_banco_arq = 0
				banco_arquivo = "DINHEIRO"
			}else if( index(banco_arquivo, "TRI BANCO") > 0 ){
				num_banco_arq = 634
				banco_arquivo = "TRI BANCO"
			}else{
				num_banco_arq = 0
				banco_arquivo = banco_arquivo
			}
												
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
			
			# PAGOS
			if( baixa != "NULO" && valor_pago_int > 0 && _comp_ini <= baixa_temp && baixa_temp <= _comp_fim && forn_cli != "" ){
				print nota, forn_cli, "'" cnpj_forn_cli, emissao, vencimento, banco_arquivo, banco, baixa, baixa_extrato, valor_pago, 
      				  valor_desconto, valor_juros, valor_multa, nota_completo_orig, codi_emp, "", obs, tipo_pagto, categoria >> "temp\\pagtos_agrupados.csv"
			}
			
			# RECEBIMENTOS
			if( baixa != "NULO" && valor_recebido_int > 0 && _comp_ini <= baixa_temp && baixa_temp <= _comp_fim && forn_cli != "" ){
				print nota, forn_cli, "'" cnpj_forn_cli, emissao, vencimento, banco_arquivo, banco, baixa, baixa_extrato, valor_recebido, 
      				  "0,00", "0,00", "0,00", nota_completo_orig, codi_emp, "", obs, tipo_pagto, categoria >> "temp\\recebtos_agrupados.csv"
			}
			
		}close(filecsv)
				
	} close(ArquivosCsv)
	
	# VAI VER NO OFX QUAIS DÉBITOS QUE NÃO ESTÃO NA PLANILHA DO CLIENTE, GERALMENTE SÃO CHEQUES COMPENSADOS EM MESES ANTERIORES OU TARIFAS
	while ( (getline < "temp\\extrato_cartao.csv") > 0 ) {
		num_banco_2 = $1
		
		conta_corrente_3 = $2
		conta_corrente_3_int = int( soNumeros(conta_corrente_3) )
		
		tipo_mov_2 = $3
		data_mov_2 = $4
		operacao_3 = $5
		valor_transacao_2 = $6
		num_doc_2 = $7
		historico_2 = $8
		
		pagou_no_banco = PagouNoBanco[operacao_3, data_mov_2, valor_transacao_2]
		
		if( ( operacao_3 == "-" || operacao_3 == "Operacao") && pagou_no_banco != 1 )
		#if( pagou_no_banco != 1 )
			print $0 >> "saida\\pagtos_feitos_no_cartao_nao_estao_na_planilha.csv"
		
	} close("temp\\extrato_cartao.csv")
	
	system("if exist bin\\*.txt del /q bin\\*.txt")
}