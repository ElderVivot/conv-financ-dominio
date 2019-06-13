BEGIN { 
	FS = "";
	OFS = ";";
	
	system("if exist bin\\*.txt del /q bin\\*.txt")
	system("dir /b temp\\*.csv > bin\\listacsv.txt")
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
		
		while ((getline < fileofx) > 0) {
			
			ofx = ""
			ofx = $0
			ofx = tolower( ofx )
			ofx = Trim(ofx)
			ofx = Trim(ofx)
			
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
				print num_banco, conta_corrente, tipo_mov, data_mov, operacao, valor_transacao, num_doc, historico >> "temp\\extrato_cartao.csv"
				ExisteMov[operacao, data_mov, valor_transacao] = 1
				BancoPago[operacao, data_mov, valor_transacao] = num_banco
			}
			
		} close(fileofx)
	} close(ArquivosOfx)
	
	FS = ";"; 
	OFS = FS;
	
	print "Nota;CNPJ Fornecedor;Data Entrada;Data Vencimento;Banco;Data Pagto;Valor Pago;Valor Desconto;Valor Juros;Nome Fornecedor;Num. Titulo;Data Entrada + 1;Data Entrada - 1" >> "saida\\pagtos_agrupados.csv"
		
	while ((getline < ArquivosCsv) > 0) {
		file = "temp\\" $0
		
		while ((getline < file) > 0) {
			
			# ESTRUTURA 1 DO ARQUIVO - COMUM ENTRE A PRIMEIRA E PENÚLTIMA PLANILHA
			if( $1 == "Documento" && $3 == "Movimento" ){
				pos_for = 6
				pos_nota = 1
				pos_emissao = 3
				pos_venc = 7
				pos_baixa = 9
				pos_valor_original = 15
				pos_valor_pago = 16
			}
			
			# ESTRUTURA 2 DO ARQUIVO - COMUM ENTRE NA ÚLTIMA PLANILHA
			if( $1 == "Documento" && $4 == "Movimento" ){
				pos_for = 7
				pos_nota = 1
				pos_emissao = 4
				pos_venc = 8
				pos_baixa = 10
				pos_valor_original = 16
				pos_valor_pago = 17
			}
			
			nome_fornecedor_completo = ""
			nome_fornecedor_completo = Trim($pos_for)
			nome_fornecedor_completo = split( nome_fornecedor_completo, nome_fornecedor_v, "-" )
			
			forn_cli = ""
			forn_cli = Trim(nome_fornecedor_v[2])
			
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
			
			#cnpj_forn_cli = soNumeros($4)
				
			emissao = ""
			emissao = Trim($pos_emissao)
			emissao = FormatDate(emissao)
			emissao = isDate(emissao)
			if( emissao != "NULO" ){
				emissao_1 = SomaDias( emissao, 1 )
				emissao_2 = SomaDias( emissao, -1 )
			}
			
			venc = ""
			venc = Trim($pos_venc)
			venc = FormatDate(venc)
			venc = isDate(venc)
			
			num_titulo = ""
			num_titulo = Trim($pos_nota)
			
			baixa = ""
			baixa = Trim($pos_baixa)
			baixa = Trim(baixa)
			baixa = FormatDate(baixa)
			baixa = isDate(baixa)
			
			valor_original = ""
			valor_original = Trim( $pos_valor_original )
			valor_original = FormataCampo("double", valor_original, 12, 2)
			valor_original_int = int(soNumeros(valor_original))
			
			valor_pago = ""
			valor_pago = Trim( $pos_valor_pago )
			valor_pago = FormataCampo("double", valor_pago, 12, 2)
			valor_pago_int = int(soNumeros(valor_pago))
			
			diferenca = ""
			diferenca = valor_pago_int - valor_original_int
			
			valor_juros = "0,00"
			valor_desconto = "0,00"
			if( diferenca >= 0 ){
				valor_juros = valor_pago_int - valor_original_int
				valor_juros = TransformaPraDecimal(valor_juros)
			} else {
				valor_desconto = valor_original_int - valor_pago_int
				valor_desconto = TransformaPraDecimal(valor_desconto)
			}
			
			# VAI MOSTRAR UMA COLUNA MOSTRANDO EM QUAL BANCO FOI PAGO AQUELE VALOR NAQUELA DATA
			banco = ""
			banco = BancoPago["-", baixa, valor_pago]
			if( int(banco) == 1 )
				banco = "BB"
			else if( int(banco) == 341 )
				banco = "ITAU"
			else if( banco == "" )
				banco = "DINHEIRO"
			else
				banco = "AVALIAR NÃO FOI ENCONTRADO"
			
			# ESTAS DUAS LINHAS SERVE PRA DEIXAR REGISTRADO O QUE TEM NA PLANILHA DO CLIENTE E FOI PAGO. SERÁ UTILIZADO PARA COMPARAÇÃO COM O OFX AFIM DE AVALIAR O QUE ESTÁ NO OFX DE PAGTO E NÃO ESTÁ NESTA PLANILHA
			PagouNoBanco["-", baixa, valor_pago] = 1
			
			if( baixa != "NULO" && int(valor_pago) > 0 && int(nota) > 0 ){
				print nota, cnpj_forn_cli, emissao, venc, banco, baixa, valor_pago, valor_desconto, valor_juros, forn_cli, num_titulo, 
				      emissao_1, emissao_2 >> "saida\\pagtos_agrupados.csv"
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