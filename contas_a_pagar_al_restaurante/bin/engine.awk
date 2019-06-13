BEGIN { 
	FS = "";
	OFS = ";";
	
	system("if exist bin\\*.txt del /q bin\\*.txt")
	system("dir /b entrada\\*.csv > bin\\listacsv.txt")
	system("if exist entrada\\*.ofx dir /b entrada\\*.ofx > bin\\listaofx.txt")
	system("if exist entrada\\*.ofc dir /b entrada\\*.ofc >> bin\\listaofx.txt")
	
	ArquivosCsv = "bin\\listacsv.txt";
	ArquivosOfx = "bin\\listaofx.txt";
	
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
					if( length(num_banco) > 3 )
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
					
					ExisteMov[operacao, data_mov, valor_transacao] = 1
					BancoPago[operacao, data_mov, valor_transacao] = num_banco "-" conta_corrente
					DataPagto[operacao, data_mov, valor_transacao] = data_mov
					
					print num_banco, conta_corrente, tipo_mov, data_mov, operacao, valor_transacao, num_doc, historico >> "temp\\extrato_cartao.csv"
				}
			
			}
			
			# ESTRUTURA SEM TAG FINAL
			else{
				if( substr(ofx, 1, 8) == "<bankid>" ){
					num_banco = upperCase( substr( ofx, 9 , length(ofx) - 8 ) )
					if( length(num_banco) > 3 )
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
					
					ExisteMov[operacao, data_mov, valor_transacao] = 1
					BancoPago[operacao, data_mov, valor_transacao] = num_banco "-" conta_corrente
					DataPagto[operacao, data_mov, valor_transacao] = data_mov
					
					print num_banco, conta_corrente, tipo_mov, data_mov, operacao, valor_transacao, num_doc, historico >> "temp\\extrato_cartao.csv"
				}
			}
			
		} close(fileofx)
	} close(ArquivosOfx)
	
	FS = ";"; 
	OFS = FS;
	
	print "Documento;CNPJ Fornecedor;Emissao;Vencimento;Banco Planilha;Banco Oco. Extrato;Data Pagto;Data Oco. Extrato;Valor Pago;Valor Desconto;Valor Juros;Valor Multa;Nome Fornecedor;Categoria;OBS" >> "temp\\pagtos_agrupados.csv"
	print "Documento;CNPJ Cliente;Emissao;Vencimento;Banco Planilha;Banco Oco. Extrato;Data Pagto;Data Oco. Extrato;Valor Pago;Valor Desconto;Valor Juros;Valor Multa;Nome Cliente;Categoria;OBS" >> "saida\\recebtos_agrupados.csv"
	
	while ((getline < ArquivosCsv) > 0) {
		file = "entrada\\" $0
		
		while ((getline < file) > 0) {
			
			if ( toupper($1) == toupper("Data de vencimento") ){
				load_columns();
				continue;
			}
			
			pos_for = $IfElse( int(NumColuna("Cliente / Fornecedor")) > 0, int(NumColuna("Cliente / Fornecedor")), 5 )
			pos_cnpj_for = $999
			pos_nota = $999
			pos_emissao = $IfElse( int(NumColuna("Data de Competencia")) > 0, int(NumColuna("Data de Competencia")), 2 )
			pos_venc = $IfElse( int(NumColuna("Data de vencimento")) > 0, int(NumColuna("Data de vencimento")), 1 )
			pos_baixa = $IfElse( int(NumColuna("Data de recebimento/pagamento")) > 0, int(NumColuna("Data de recebimento/pagamento")), 14 )
			pos_valor_original = $IfElse( int(NumColuna("Valor original")) > 0, int(NumColuna("Valor original")), 11 )
			pos_valor_pago = $IfElse( int(NumColuna("Valor pago")) > 0, int(NumColuna("Valor pago")), 7 )
			pos_valor_recebido = $IfElse( int(NumColuna("Valor recebido")) > 0, int(NumColuna("Valor recebido")), 6 )
			pos_valor_desc = $IfElse( int(NumColuna("Descontos/Taxas")) > 0, int(NumColuna("Descontos/Taxas")), 13 )
			pos_valor_juros = $IfElse( int(NumColuna("Juros/Multa")) > 0, int(NumColuna("Juros/Multa")), 12 )
			pos_valor_multa = $999
			pos_obs = $IfElse( int(NumColuna("Descricao")) > 0, int(NumColuna("Descricao")), 4 )
			pos_natureza_pagto = $999
			pos_banco_arquivo = $IfElse( int(NumColuna("Conta")) > 0, int(NumColuna("Conta")), 9 )
			pos_tipo_pagto = $999
			pos_categoria = $IfElse( int(NumColuna("Categoria")) > 0, int(NumColuna("Categoria")), 3 )
			
			vencimento = ""
			vencimento = Trim(pos_venc)
			vencimento = FormatDate(vencimento)
			vencimento = isDate(vencimento)
			
			baixa = ""
			baixa = Trim(pos_baixa)
			baixa = FormatDate(baixa)
			baixa = isDate(baixa)
			
			emissao = ""
			emissao = Trim(pos_emissao)
			emissao = FormatDate(emissao)
			emissao = isDate(emissao)
			
			forn_cli = ""
			forn_cli = Trim(pos_for)
			forn_cli = subsCharEspecial(forn_cli)
			forn_cli = upperCase(forn_cli)
			
			cnpj_forn_cli = ""
			cnpj_forn_cli = soNumeros(pos_cnpj_for)
			cnpj_forn_cli = IfElse(cnpj_forn_cli == "", "00000000000000", cnpj_forn_cli)
			
			valor_original = ""
			valor_original = Trim(pos_valor_original)
			valor_original = FormataCampo("double", valor_original, 12, 2)
			valor_original_int = int(soNumeros(valor_original))
			
			valor_pago = ""
			valor_pago = Trim(pos_valor_pago)
			valor_pago = FormataCampo("double", valor_pago, 12, 2)
			valor_pago_int = int(soNumeros(valor_pago))
			
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
			valor_juros = Trim(pos_valor_juros)
			valor_juros = FormataCampo("double", valor_juros, 12, 2)
			
			valor_desconto = ""
			valor_desconto = Trim(pos_valor_desc)
			valor_desconto = FormataCampo("double", valor_desconto, 12, 2)
			
			#if( valor_juros == "0,00" && valor_pago_int > valor_original_int ){
			#	valor_juros = valor_pago_int - valor_original_int
			#	valor_juros = TransformaPraDecimal(valor_juros)
			#}
			
			#if( valor_desconto == "0,00" && valor_pago_int < valor_original_int ){
			#	valor_desconto = valor_original_int - valor_pago_int
			#	valor_desconto = TransformaPraDecimal(valor_desconto)
			#}
			
			valor_multa = ""
			valor_multa = Trim(pos_valor_multa)
			valor_multa = FormataCampo("double", valor_multa, 12, 2)
			
			obs = ""
			obs = Trim(pos_obs)
			obs = subsCharEspecial(obs)
			obs = upperCase(obs)
			
			obs_forn = obs
			
			terc_char_eh_numero = substr(obs, 3, 1)
			terc_char_eh_numero = soNumeros(terc_char_eh_numero)
			
			quarto_char_eh_numero = substr(obs, 4, 1)
			quarto_char_eh_numero = soNumeros(quarto_char_eh_numero)
			
			quinto_char_eh_numero = substr(obs, 5, 1)
			quinto_char_eh_numero = soNumeros(quinto_char_eh_numero)
			
			sexto_char_eh_numero = substr(obs, 6, 1)
			sexto_char_eh_numero = soNumeros(sexto_char_eh_numero)
			
			setimo_char_eh_numero = substr(obs, 7, 1)
			setimo_char_eh_numero = soNumeros(setimo_char_eh_numero)
			
			oitavo_char_eh_numero = substr(obs, 8, 1)
			oitavo_char_eh_numero = soNumeros(oitavo_char_eh_numero)
			
			# 3 CHAR - SÃO PARCELAS POIS VEM NO FORMATO NUM_PARCELA/QTD_PARCELA
			if( index(substr(obs, 1, 3), "/") > 0 && int(terc_char_eh_numero) > 0 && int(quarto_char_eh_numero) == 0 && int(quinto_char_eh_numero) == 0 && int(sexto_char_eh_numero) == 0 && int(setimo_char_eh_numero) == 0 && int(oitavo_char_eh_numero) == 0 ){
				obs_forn = Trim(substr(obs, 4)) 
				obs = Trim(substr(obs, 4)) " " substr(obs, 1, 3)
			}
			
			# 4 CHAR
			if( index(substr(obs, 1, 4), "/") > 0 && int(quarto_char_eh_numero) > 0 && int(quinto_char_eh_numero) == 0 && int(sexto_char_eh_numero) == 0 && int(setimo_char_eh_numero) == 0 && int(oitavo_char_eh_numero) == 0 ){
				obs_forn = Trim(substr(obs, 5)) 
				obs = Trim(substr(obs, 5)) " " substr(obs, 1, 4)
			}
			
			# 5 CHAR
			if( index(substr(obs, 1, 5), "/") > 0 && int(quinto_char_eh_numero) > 0 && int(sexto_char_eh_numero) == 0 && int(setimo_char_eh_numero) == 0 && int(oitavo_char_eh_numero) == 0 ){
				obs_forn = Trim(substr(obs, 6))
				obs = Trim(substr(obs, 6)) " " substr(obs, 1, 5)
			}
			
			# 6 CHAR
			if( index(substr(obs, 1, 6), "/") > 0 && int(sexto_char_eh_numero) > 0 && int(setimo_char_eh_numero) == 0 && int(oitavo_char_eh_numero) == 0 ){
				obs_forn = Trim(substr(obs, 7)) 
				obs = Trim(substr(obs, 7)) " " substr(obs, 1, 6)
			}
			
			# 7 CHAR
			if( index(substr(obs, 1, 7), "/") > 0 && int(setimo_char_eh_numero) > 0 && int(oitavo_char_eh_numero) == 0 ){
				obs_forn = Trim(substr(obs, 8))
				obs = Trim(substr(obs, 8)) " " substr(obs, 1, 7)
			}
			
			# 8 CHAR
			if( index(substr(obs, 1, 8), "/") > 0 && int(oitavo_char_eh_numero) > 0 ){
				obs_forn = Trim(substr(obs, 9))
				obs = Trim(substr(obs, 9)) " " substr(obs, 1, 8)
			}
			
			obs_tmp = split(obs, obs_v, " ")
			
			j = 0
			for( i in obs_v ){
				j = i
				if( obs_v[i] == "NFE" || obs_v[i] == "NF-E" )
					break
			}
			
			nota_completo = ""
			nota_completo = obs_v[i+1]
			nota_completo_orig = nota_completo
			if( index(nota_completo, "-") > 0 )
				nota_completo = split( nota_completo, nota_completo_v, "-" )
			if( index(nota_completo, "/") > 0 )
				nota_completo = split( nota_completo, nota_completo_v, "/" )
			
			nota = ""
			nota = Trim(nota_completo_v[1])
			
			if( index(nota_completo_orig, "-") == 0 && index(nota_completo_orig, "/") == 0 )
				nota = nota_completo_orig
			
			nota = int(soNumeros(nota))
			
			categoria = ""
			categoria = Trim(pos_categoria)
			categoria = subsCharEspecial(categoria)
			categoria = upperCase(categoria)
			
			if( forn_cli == "" )
				forn_cli = obs_forn
			
			banco_arquivo = ""
			banco_arquivo = Trim(pos_banco_arquivo)
			banco_arquivo = subsCharEspecial(banco_arquivo)
			banco_arquivo = upperCase(banco_arquivo)
			
			# AL = CAIXA
			if(banco_arquivo == "AL")
				banco_arquivo = "CAIXA"
			if( index(banco_arquivo, "SANTANDER") > 0 )
				banco_arquivo = "SANTANDER"
			if( index(banco_arquivo, "BRASIL") > 0 )
				banco_arquivo = "BB"
			if( index(banco_arquivo, "DINHE") > 0 )
				banco_arquivo = "DINHEIRO"
			
			# TEM PAGAMENTOS QUE O CLIENTE LANÇA NA PLANILHA COM DATA ERRADA DA BAIXA, PORTANTO ESTAS LINHAS ABAIXO VAI VERIFICAR ISTO E O LIMITE É 3 DIAS A MAIS OU 3 DIAS A MENOS
			baixa_extrato = ""
			baixa_2 = ""
			baixa_3 = ""
			baixa_4 = ""
			baixa_5 = ""
			baixa_6 = ""
			baixa_7 = ""
			banco_extrato = ""
			if( baixa != "NULO" ){
				baixa_2 = SomaDias(baixa, 1)
				baixa_3 = SomaDias(baixa, 2)
				baixa_4 = SomaDias(baixa, -1)
				baixa_5 = SomaDias(baixa, -2)
				baixa_6 = SomaDias(baixa, 3)
				baixa_7 = SomaDias(baixa, -3)
				
				if( DataPagto[operacao_arq, baixa_2, valor_considerar] != "" ){
					baixa_extrato = DataPagto[operacao_arq, baixa_2, valor_considerar]
					banco_extrato = BancoPago[operacao_arq, baixa_2, valor_considerar]
				} 
				if( DataPagto[operacao_arq, baixa_3, valor_considerar] != "" ){
					baixa_extrato = DataPagto[operacao_arq, baixa_3, valor_considerar]
					banco_extrato = BancoPago[operacao_arq, baixa_3, valor_considerar]
				} 
				if( DataPagto[operacao_arq, baixa_4, valor_considerar] != "" ){
					baixa_extrato = DataPagto[operacao_arq, baixa_4, valor_considerar]
					banco_extrato = BancoPago[operacao_arq, baixa_4, valor_considerar]
				}
				if( DataPagto[operacao_arq, baixa_5, valor_considerar] != "" ){
					baixa_extrato = DataPagto[operacao_arq, baixa_5, valor_considerar]
					banco_extrato = BancoPago[operacao_arq, baixa_5, valor_considerar]
				}
				if( DataPagto[operacao_arq, baixa_6, valor_considerar] != "" ){
					baixa_extrato = DataPagto[operacao_arq, baixa_6, valor_considerar]
					banco_extrato = BancoPago[operacao_arq, baixa_6, valor_considerar]
				}
				if( DataPagto[operacao_arq, baixa_7, valor_considerar] != "" ){
					baixa_extrato = DataPagto[operacao_arq, baixa_7, valor_considerar]
					banco_extrato = BancoPago[operacao_arq, baixa_7, valor_considerar]
				}
			}
			
			banco_extrato = split(banco_extrato, banco_extrato_v, "-")
			banco_extrato = banco_extrato_v[1]
			
			banco_extrato_2 = ""
			banco_extrato_2 = banco_extrato_v[2]
			
			banco = BancoPago[operacao_arq, baixa, valor_considerar]
			banco = split(banco, banco_v, "-")
			banco = banco_v[1]
			
			banco_2 = ""
			banco_2 = banco_v[2]
			banco_2 = IfElse(banco_2 == "", banco_extrato_2, banco_2)
			
			existe_mov_dia = DataPagto[operacao_arq, baixa, valor_considerar]
			
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
			else if( banco == "" )
				banco = "NAO ENCONTROU NO OFX"
			else
				banco = "AVALIAR NAO FOI ENCONTRADO" "-" banco_2
			
			# CASO A DATA DO PAGTO ESTEJA CORRETA COM O EXTRATO ENTÃO COLOCA A DATA OCORRÊNCIA SENDO A PRÓPRIA DATA DA BAIXA
			if( baixa_extrato == "" && banco != "NAO ENCONTROU NO OFX" )
				baixa_extrato = baixa
			
			# ESTAS LINHA SERVE PRA DEIXAR REGISTRADO O QUE TEM NA PLANILHA DO CLIENTE E FOI PAGO. SERÁ UTILIZADO PARA COMPARAÇÃO COM O OFX AFIM DE AVALIAR O QUE ESTÁ NO OFX DE PAGTO E NÃO ESTÁ NESTA PLANILHA
			PagouNoBanco[operacao_arq, baixa_extrato, valor_considerar] = 1
			
			# PAGOS
			if( baixa != "NULO" && int(valor_pago) > 0 ){
				print nota, "'" cnpj_forn_cli, emissao, vencimento, banco_arquivo, banco, baixa, baixa_extrato, valor_pago, 
      				  valor_desconto, valor_juros, valor_multa, forn_cli, categoria, obs >> "temp\\pagtos_agrupados.csv"
			}
			
			# RECEBIMENTOS
			if( baixa != "NULO" && int(valor_recebido) > 0 ){
				print nota, "'" cnpj_forn_cli, emissao, vencimento, banco_arquivo, banco, baixa, baixa_extrato, valor_recebido, 
      				  "0,00", "0,00", "0,00", forn_cli, categoria, obs >> "saida\\recebtos_agrupados.csv"
			}
				
		} close(file)
	} close(ArquivosCsv)
	
	print "Banco;Conta Corrente;Tipo Movimento;Data;Operacao;Valor;Num. Doc.;Historico" >> "saida\\movtos_feitos_no_cartao_nao_estao_na_planilha.csv"
	
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
		
		if( operacao_3 == "-" && pagou_no_banco != 1 )
			print $0 >> "saida\\movtos_feitos_no_cartao_nao_estao_na_planilha.csv"
		
	} close("temp\\extrato_cartao.csv")
	
	system("if exist bin\\*.txt del /q bin\\*.txt")
}