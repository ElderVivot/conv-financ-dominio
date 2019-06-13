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
			
			if( substr(ofx, 1, 8) == "<bankid>" ){
				num_banco = upperCase( substr( ofx, 9 , length(ofx) - 8 ) )
				num_banco = int(num_banco)
			}
			
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
				BancoPago[operacao, num_banco, data_mov, valor_transacao] = num_banco
				BancoPago_2[operacao, data_mov, valor_transacao] = num_banco
			}
			
		} close(fileofx)
	} close(ArquivosOfx)
	
	FS = ";"; 
	OFS = FS;
	
	print "Duplicata;Loja;Parcela;Doc;Vencimento;Emissao;Atraso;Nota;Banco Emissor;Fornecedor;CNPJ/CPF;Razao Social;Juros Devido;Outros Despesas;Valor Parcela;Juros pagos;Valor Pago;Data;Banco Pagador;Conta Corrente;Conta;Descricao;N Cheque;Plano Contas;Descricao;Banco Comparacao OFX" >> "saida\\pagtos_agrupados.csv"
	
	while ((getline < ArquivosCsv) > 0) {
		file = "entrada\\" $0
		
		while ((getline < file) > 0) {
			
			valor_pago = ""
			valor_pago = Trim( $17 )
			valor_pago = FormataCampo("double", valor_pago, 12, 2)
			
			baixa = ""
			baixa = Trim($18)
			baixa = Trim(baixa)
			baixa = FormatDate(baixa)
			baixa = isDate(baixa)
			
			banco = ""
			banco = int( soNumeros($19) )
			
			banco_1 = BancoPago["-", banco, baixa, valor_pago]
			
			banco_2 = BancoPago["-", baixa, valor_pago]
			
			banco_1 = IfElse(banco_1 == "", banco_2, banco_1)
			
			$26 = banco_1
			
			cheque = ""
			cheque = int( soNumeros($23) )
			
			if (banco_1 == "" && cheque > 0)
				$26 = "237"
			
			if (banco_1 == "" && cheque == 0)
				$26 = "NAO ENCONTROU NO OFX"
			
			if( baixa != "NULO" && int( soNumeros( valor_pago ) ) > 0 )
				print $0 >> "saida\\pagtos_agrupados.csv"
			
			# ESTAS LINHA SERVE PRA DEIXAR REGISTRADO O QUE TEM NA PLANILHA DO CLIENTE E FOI PAGO. SERÁ UTILIZADO PARA COMPARAÇÃO COM O OFX AFIM DE AVALIAR O QUE ESTÁ NO OFX DE PAGTO E NÃO ESTÁ NESTA PLANILHA
			PagouNoBanco["-", banco_1, baixa, valor_pago] = 1
			
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
		
		pagou_no_banco = PagouNoBanco[operacao_3, num_banco_2, data_mov_2, valor_transacao_2]
		
		if( operacao_3 == "-" && pagou_no_banco != 1 )
			print $0, pagou_no_banco, pagou_no_banco_2 >> "saida\\pagtos_feitos_no_cartao_nao_estao_na_planilha.csv"
		
	} close("temp\\extrato_cartao.csv")
	
	system("if exist bin\\*.txt del /q bin\\*.txt")
}