BEGIN { 
	FS = "";
	OFS = ";";
	
	system("if exist bin\\*.txt del /q bin\\*.txt")
	system("dir /b entrada\\*.csv > bin\\listacsv.txt")
	system("dir /b entrada\\*.ofx > bin\\listaofx.txt")
	
	ArquivosCsv = "bin\\listacsv.txt";
	ArquivosOfx = "bin\\listaofx.txt";
	
	print "Banco;Conta Corrente;Tipo Movimento;Data;Operacao;Valor;Num. Doc.;Historico" >> "temp\\extrato_cartao.csv"
	
	# LE O ARQUIVO OFX AFIM DE PODER COMPARAR O QUE FOI PAGO NO CARTAO COM A PLANILHA DE BAIXA DO CLIENTE
	while ((getline < ArquivosOfx) > 0) {
		fileofx = "entrada\\" $0
		
		while ((getline < fileofx) > 0) {
			
			ofx = ""
			ofx = $0
			ofx = tolower( ofx )
			ofx = Trim(ofx)
			ofx = Trim(ofx)
			
			if( substr(ofx, 1, 8) == "<bankid>" )
				num_banco = upperCase( substr( ofx, 9 , length(ofx) - 8 ) )
			
			if( substr(ofx, 1, 8) == "<acctid>" ){
				conta_corrente = upperCase( substr( ofx, 9 , length(ofx) - 8 ) )
				conta_corrente_int = int( soNumeros(conta_corrente) )
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
				ExisteMov[num_banco, conta_corrente_int, operacao, data_mov, valor_transacao] = 1
				ExisteMov_2[num_banco, conta_corrente_int, operacao, data_mov, num_doc] = 1
			}
			
		} close(fileofx)
	} close(ArquivosOfx)
	
	FS = ";"; 
	OFS = FS;
	
	while ((getline < ArquivosCsv) > 0) {
		file = "entrada\\" $0
		
		while ((getline < file) > 0) {
			
			conta_corrente_2 = ""
			conta_corrente_2 = int( soNumeros( $4 ) )
			
			num_doc_3 = ""
			num_doc_3 = soNumeros( $5 )
			num_doc_3 = substr( num_doc_3, length(num_doc_3) - 8 )
			num_doc_3 = int(num_doc_3)
			
			conciliacao = ""
			conciliacao = soNumeros($5)
			
			operacao_2 = ""
			operacao_2 = Trim($30)
			operacao_2 = upperCase(operacao_2)
			operacao_2 = IfElse(operacao_2 == "C", "+", "-")
			
			valor_pago = ""
			valor_pago = Trim( $27 )
			valor_pago = FormataCampo("double", valor_pago, 12, 2)
			
			valor_juros = ""
			valor_juros = Trim( $26 )
			valor_juros = FormataCampo("double", valor_juros, 12, 2)
			
			valor_desconto = ""
			valor_desconto = Trim( $21 )
			valor_desconto = FormataCampo("double", valor_desconto, 12, 2)
			
			baixa = ""
			baixa = Trim($35)
			baixa = Trim(baixa)
			baixa = FormatDate(baixa)
			baixa = isDate(baixa)
			
			emissao = ""
			emissao = Trim($12)
			emissao = Trim(emissao)
			emissao = FormatDate(emissao)
			emissao = isDate(emissao)
			
			nome_natureza = ""
			nome_natureza = Trim($9)
			nome_natureza = subsCharEspecial(nome_natureza)
			nome_natureza = upperCase(nome_natureza)
			
			existe_mov = ExisteMov["001", conta_corrente_2, operacao_2, baixa, valor_pago]
			existe_mov = IfElse(existe_mov == 1, "S", "N")
			
			existe_mov_2 = ExisteMov_2["001", conta_corrente_2, operacao_2, baixa, num_doc_3]
			existe_mov_2 = IfElse(existe_mov_2 == 1, "S", "N")
			
			PagouNoBanco["001", conta_corrente_2, operacao_2, baixa, valor_pago] = 1
			PagouNoBanco_2["001", conta_corrente_2, operacao_2, baixa, num_doc_3] = 1
			
			if( upperCase( Trim($2) ) == "BANCO" ){
				print $0, "Tem no Banco com mesmo Valor", "Tem no Banco com mesmo Doc." >> "saida\\baixa_notas_contas_a_pagar.csv"
				print $0 >> "saida\\baixa_notas_contas_a_receber.csv"
			} else{
				$5 = "'" conciliacao
				$21 = valor_desconto
				$26 = valor_juros
				$27 = valor_pago
				$12 = emissao
				$9 = nome_natureza
				
				if( operacao_2 == "-" )
					print $0, existe_mov, existe_mov_2 >> "saida\\baixa_notas_contas_a_pagar.csv"
				else
					print $0 >> "saida\\baixa_notas_contas_a_receber.csv"
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
		
		pagou_no_banco = PagouNoBanco[num_banco_2, conta_corrente_3_int, operacao_3, data_mov_2, valor_transacao_2]
		pagou_no_banco_2 = PagouNoBanco_2[num_banco_2, conta_corrente_3_int, operacao_3, data_mov_2, num_doc_2]
		
		if( operacao_3 == "-" && pagou_no_banco != 1 && pagou_no_banco_2 != 1 )
			print $0, pagou_no_banco, pagou_no_banco_2 >> "saida\\pagtos_feitos_no_cartao_nao_estao_na_planilha.csv"
		
	} close("temp\\extrato_cartao.csv")
	
	system("if exist bin\\*.txt del /q bin\\*.txt")
}