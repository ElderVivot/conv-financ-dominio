BEGIN { 
	FS = "";
	OFS = ";";
	
	system("if exist bin\\*.txt del /q bin\\*.txt")
	system("dir /b entrada\\*.csv > bin\\listacsv.txt")
	system("dir /b entrada\\*.ofx > bin\\listaofx.txt")
	
	ArquivosCsv = "bin\\listacsv.txt";
	ArquivosOfx = "bin\\listaofx.txt";
	
	pos_for = 6
	pos_nota = 1
	pos_emissao = 3
	pos_venc = 7
	pos_baixa = 9
	pos_valor_original = 15
	pos_valor_pago = 16
	
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
			if( index( ofx_1, "</code>" ) > 0 ){
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
	
	print "Nota;CNPJ Fornecedor;Data Entrada;Banco;Data Pagto;Data Oco. Extrato;Valor Pago;Valor Desconto;Valor Juros;Nome Fornecedor;Tipo Docto;Data Entrada + 1;Data Entrada - 1;Data Entrada + 2;Data Entrada - 2" >> "saida\\pagtos_agrupados.csv"
		
	while ((getline < ArquivosCsv) > 0) {
		file = "entrada\\" $0
		
		while ((getline < file) > 0) {
			
			if ( toupper($4) == toupper("Pessoa") ){
				load_columns();
				continue;
			}
			
			pos_for = $IfElse( int(NumColuna("Pessoa")) > 0, int(NumColuna("Pessoa")), 4 )
			pos_cnpj_for = $999
			pos_nota =$IfElse( int(NumColuna("Nro NF")) > 0, int(NumColuna("Nro NF")), 3 )
			pos_emissao = $IfElse( int(NumColuna("Emissao")) > 0, int(NumColuna("Emissao")), 1 )
			pos_venc = $IfElse( int(NumColuna("-----")) > 0, int(NumColuna("-----")), 999 )
			pos_baixa = $IfElse( int(NumColuna("Data pagamento")) > 0, int(NumColuna("Data pagamento")), 7 )
			pos_valor_original = $IfElse( int(NumColuna("-----")) > 0, int(NumColuna("-----")), 999 )
			pos_valor_pago = $IfElse( int(NumColuna("Valor vencimento")) > 0, int(NumColuna("Valor vencimento")), 6 )
			pos_valor_recebido = $IfElse( int(NumColuna("-----")) > 0, int(NumColuna("-----")), 999 )
			pos_valor_desc = $IfElse( int(NumColuna("-----")) > 0, int(NumColuna("-----")), 999 )
			pos_valor_juros = $IfElse( int(NumColuna("-----")) > 0, int(NumColuna("-----")), 999 )
			pos_valor_multa = $999
			pos_obs = $IfElse( int(NumColuna("-----")) > 0, int(NumColuna("-----")), 999 )
			pos_tipo_docto = $IfElse( int(NumColuna("Tipo vencimento")) > 0, int(NumColuna("Tipo vencimento")), 5 )
			
			forn_cli = ""
			forn_cli = Trim(pos_for)
			forn_cli = subsCharEspecial(forn_cli)
			forn_cli = upperCase(forn_cli)
			
			cnpj_forn_cli = ""
			cnpj_forn_cli = soNumeros(pos_cnpj_for)
			
			nota_completo = ""
			nota_completo = Trim(pos_nota)
			nota_completo_orig = nota_completo
			if( index(nota_completo, "-") > 0 )
				nota_completo = split( nota_completo, nota_completo_v, "-" )
			if( index(nota_completo, "/") > 0 )
				nota_completo = split( nota_completo, nota_completo_v, "/" )
			
			nota = ""
			nota = Trim(nota_completo_v[1])
			
			if( index(nota_completo_orig, "-") == 0 && index(nota_completo_orig, "/") == 0 )
				nota = nota_completo_orig
			
			emissao = ""
			emissao = Trim(pos_emissao)
			emissao = FormatDate(emissao)
			emissao = isDate(emissao)
			
			emissao_2 = ""
			emissao_3 = ""
			emissao_4 = ""
			emissao_5 = ""
			if( emissao != "NULO" ){
				emissao_2 = SomaDias(emissao, 1)
				emissao_3 = SomaDias(emissao, -1)
				emissao_4 = SomaDias(emissao, 2)
				emissao_5 = SomaDias(emissao, -2)
			}
			
			valor_pago = ""
			valor_pago = Trim( pos_valor_pago )
			valor_pago = FormataCampo("double", valor_pago, 12, 2)
			
			baixa = ""
			baixa = Trim(pos_baixa)
			baixa = Trim(baixa)
			baixa = FormatDate(baixa)
			baixa = isDate(baixa)
			
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
				
				if( DataPagto["-", baixa_2, valor_pago] != "" ){
					baixa_extrato = DataPagto["-", baixa_2, valor_pago]
					banco_extrato = BancoPago["-", baixa_2, valor_pago]
				} 
				if( DataPagto["-", baixa_3, valor_pago] != "" ){
					baixa_extrato = DataPagto["-", baixa_3, valor_pago]
					banco_extrato = BancoPago["-", baixa_3, valor_pago]
				} 
				if( DataPagto["-", baixa_4, valor_pago] != "" ){
					baixa_extrato = DataPagto["-", baixa_4, valor_pago]
					banco_extrato = BancoPago["-", baixa_4, valor_pago]
				}
				if( DataPagto["-", baixa_5, valor_pago] != "" ){
					baixa_extrato = DataPagto["-", baixa_5, valor_pago]
					banco_extrato = BancoPago["-", baixa_5, valor_pago]
				}
				if( DataPagto["-", baixa_6, valor_pago] != "" ){
					baixa_extrato = DataPagto["-", baixa_6, valor_pago]
					banco_extrato = BancoPago["-", baixa_6, valor_pago]
				}
				if( DataPagto["-", baixa_7, valor_pago] != "" ){
					baixa_extrato = DataPagto["-", baixa_7, valor_pago]
					banco_extrato = BancoPago["-", baixa_7, valor_pago]
				}
			}
			
			banco_extrato_ori = banco_extrato
			banco_extrato = split(banco_extrato, banco_extrato_v, "-")
			banco_extrato = banco_extrato_v[1]
			
			banco_extrato_2 = ""
			banco_extrato_2 = banco_extrato_v[2]
			
			tipo_docto = ""
			tipo_docto = Trim(pos_tipo_docto)
			tipo_docto = subsCharEspecial(tipo_docto)
			tipo_docto = upperCase(tipo_docto)
			
			tipo_docto_2 = ""
			tipo_docto_2 = substr(tipo_docto, length(tipo_docto) - 7)
			
			valor_desconto = "0,00"
			valor_juros = "0,00"
			
			banco = BancoPago["-", baixa, valor_pago]
			banco_ori = banco
			banco = split(banco, banco_v, "-")
			banco = banco_v[1]
			
			banco_2 = ""
			banco_2 = banco_v[2]
			banco_2 = IfElse(banco_2 == "", banco_extrato_2, banco_2)
			
			if( int(banco) == 1 || int(banco_extrato) == 1 )
				banco = "BB" "-" banco_2
			else if( int(banco) == 341 || int(banco_extrato) == 341 )
				banco = "ITAU" "-" banco_2
			else if( int(banco) == 237 || int(banco_extrato) == 237 )
				banco = "BRADESCO" "-" banco_2
			else if( int(banco) == 756 || int(banco_extrato) == 756 )
				banco = "SICOOB" "-" banco_2
			else if( banco == "" )
				banco = "NAO ENCONTROU NO OFX"
			else
				banco = "AVALIAR NAO FOI ENCONTRADO" "-" banco_2
			
			# CASO A DATA DO PAGTO ESTEJA CORRETA COM O EXTRATO ENTÃO COLOCA A DATA OCORRÊNCIA SENDO A PRÓPRIA DATA DA BAIXA
			if( baixa_extrato == "" && banco != "NAO ENCONTROU NO OFX" )
				baixa_extrato = baixa
			
			banco = IfElse(tipo_docto_2 == "DINHEIRO" && banco == "NAO ENCONTROU NO OFX", tipo_docto_2, banco)
			
			# ESTAS LINHA SERVE PRA DEIXAR REGISTRADO O QUE TEM NA PLANILHA DO CLIENTE E FOI PAGO. SERÁ UTILIZADO PARA COMPARAÇÃO COM O OFX AFIM DE AVALIAR O QUE ESTÁ NO OFX DE PAGTO E NÃO ESTÁ NESTA PLANILHA
			PagouNoBanco["-", baixa_extrato, valor_pago] = 1
			
			if( baixa != "NULO" && int(valor_pago) > 0 ){
				print nota, "'" cnpj_forn_cli, emissao, banco, baixa, baixa_extrato, valor_pago, valor_desconto, valor_juros, forn_cli, 
				      tipo_docto, emissao_2, emissao_3, emissao_4, emissao_5 >> "saida\\pagtos_agrupados.csv"
			}
				
		} close(file)
	} close(ArquivosCsv)
	
	print "Banco;Conta Corrente;Tipo Movimento;Data;Operacao;Valor;Num. Doc.;Historico" >> "saida\\pagtos_feitos_no_cartao_nao_estao_na_planilha.csv"
	
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
			print $0 >> "saida\\pagtos_feitos_no_cartao_nao_estao_na_planilha.csv"
		
	} close("temp\\extrato_cartao.csv")
	
	system("if exist bin\\*.txt del /q bin\\*.txt")
}