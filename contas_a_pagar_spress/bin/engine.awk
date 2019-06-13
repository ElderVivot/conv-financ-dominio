BEGIN { 
	FS = "";
	OFS = ";";
	
	system("if exist bin\\*.txt del /q bin\\*.txt")
	system("dir /b entrada\\*.html > bin\\listacsv.txt")
	system("dir /b entrada\\*.ofx > bin\\listaofx.txt")
	
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
					historico = upperCase( subsCharEspecial( selecionaTAG( ofx, "<memo>", "</memo>" ) ) )
				
				if( substr(ofx, 1, 10) == "</stmttrn>" ){
					
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
	
	# PRIMEIRO WHILE VAI GUARDAR ALGUNS VALORES PARA SER PEGOS NO SEGUNDO WHILE
	while ((getline < ArquivosCsv) > 0) {
		file = "entrada\\" $0
		
		linha = 0
		
		while ((getline < file) > 0) {
			
			linha++
			
			# CNPJ composto apenas de 12 digitos, não tem os dois últimos
			CNPJ[linha] = ""
			CNPJ[linha] = substr($0, 3, 12)
			CNPJ[linha] = soNumeros(CNPJ[linha])
			
			BancoArq[linha] = ""
			BancoArq[linha] = substr($0, 25, 20)
			BancoArq[linha] = Trim(BancoArq[linha])
			
			# Guarda valor desconto
			if( upperCase( substr( $0, 1, 8) ) == "DESCONTO" ){
				nota_ = ""
				nota_ = substr($0, 25, 18)
				
				ValorDesc[nota_] = ""
				ValorDesc[nota_] = Trim( substr($0, 119, 13) )
			}
			
			# Guarda valor juros
			if( upperCase( substr( $0, 1, 5) ) == "JUROS" ){
				nota_ = ""
				nota_ = substr($0, 25, 18)
				
				ValorJuros[nota_] = ""
				ValorJuros[nota_] = Trim( substr($0, 119, 13) )
			}
			
			# Guarda valor multa
			if( upperCase( substr( $0, 1, 5) ) == "MULTA" ){
				nota_ = ""
				nota_ = substr($0, 25, 18)
				
				ValorMulta[nota_] = ""
				ValorMulta[nota_] = Trim( substr($0, 119, 13) )
			}
			
		} close(file)
	} close(ArquivosCsv)
	
	print "Nota;CNPJ Fornecedor;Emissao;Vencimento;Banco Arquivo;Banco Oco. Extrato;Data Pagto;Data Oco. Extrato;Valor Pago;Valor Desconto;Valor Juros;Valor Multa;Nome Fornecedor" >> "temp\\pagtos_agrupados.csv"
		
	while ((getline < ArquivosCsv) > 0) {
		file = "entrada\\" $0
		
		linha_2 = 0
		
		while ((getline < file) > 0) {
			
			linha_2++
			
			# SOMENTE LINHAS QUE SAO BAIXAS
			if( upperCase( substr( $0, 1, 5) ) == "BAIXA" ){
				
				forn_cli = ""
				
				cnpj_forn_cli = ""
				cnpj_forn_cli = CNPJ[linha_2+1]
				
				nota = ""
				nota = Trim( substr($0, 25, 18) )
				nota_original = nota
				nota = split(nota, nota_v, "/")
				nota = nota_v[3]
				nota = int(nota)
				
				banco_arquivo = ""
				banco_arquivo = BancoArq[linha_2+1]
				banco_arquivo = split(banco_arquivo, banco_arquivo_v, "/")
				banco_arquivo = banco_arquivo_v[1]
				banco_arquivo = int(banco_arquivo)
				
				conta_corrente_arq = ""
				conta_corrente_arq = banco_arquivo_v[3]
				conta_corrente_arq = Trim(conta_corrente_arq)
				
				valor_pago = ""
				valor_pago = Trim( substr($0, 119, 13) )
				valor_pago = FormataCampo("double", valor_pago, 12, 2)
				valor_pago_int = int(soNumeros(valor_pago))
				
				valor_juros = ""
				valor_juros = ValorJuros[nota_original]
				valor_juros = FormataCampo("double", valor_juros, 12, 2)
				valor_juros = IfElse(valor_juros == "", "0,00", valor_juros)
				valor_juros_int = int(soNumeros(valor_juros))
				
				valor_desconto = ""
				valor_desconto = ValorDesc[nota_original]
				valor_desconto = FormataCampo("double", valor_desconto, 12, 2)
				valor_desconto = IfElse(valor_desconto == "", "0,00", valor_desconto)
				valor_desconto_int = int(soNumeros(valor_desconto))
				
				valor_multa = ""
				valor_multa = ValorMulta[nota_original]
				valor_multa = FormataCampo("double", valor_multa, 12, 2)
				valor_multa = IfElse(valor_multa == "", "0,00", valor_multa)
				valor_multa_int = int(soNumeros(valor_multa))
				
				valor_pago_calc = valor_pago_int - valor_desconto_int + valor_juros_int + valor_multa_int
				valor_pago = TransformaPraDecimal(valor_pago_calc)
				
				baixa = ""
				baixa = Trim( substr($0, 46, 10) )
				baixa = Trim(baixa)
				baixa = FormatDate(baixa)
				baixa = isDate(baixa)
				
				venc = ""
				venc = Trim( substr($0, 70, 10) )
				venc = Trim(venc)
				venc = FormatDate(venc)
				venc = isDate(venc)
				
				emissao = ""
				emissao = Trim( substr($0, 58, 10) )
				emissao = Trim(emissao)
				emissao = FormatDate(emissao)
				emissao = isDate(emissao)
				
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
					#if( DataPagto["-", baixa_6, valor_pago] != "" ){
					#	baixa_extrato = DataPagto["-", baixa_6, valor_pago]
					#	banco_extrato = BancoPago["-", baixa_6, valor_pago]
					#}
					#if( DataPagto["-", baixa_7, valor_pago] != "" ){
					#	baixa_extrato = DataPagto["-", baixa_7, valor_pago]
					#	banco_extrato = BancoPago["-", baixa_7, valor_pago]
					#}
				}
				
				banco_extrato = split(banco_extrato, banco_extrato_v, "-")
				banco_extrato = banco_extrato_v[1]
				
				banco_extrato_2 = ""
				banco_extrato_2 = banco_extrato_v[2]
				
				banco = BancoPago["-", baixa, valor_pago]
				banco = split(banco, banco_v, "-")
				banco = banco_v[1]
				
				banco_2 = ""
				banco_2 = banco_v[2]
				banco_2 = IfElse(banco_2 == "", banco_extrato_2, banco_2)
				
				existe_mov_dia = DataPagto["-", baixa, valor_pago]
				
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
				else if( banco == "" )
					banco = "NAO ENCONTROU NO OFX"
				else
					banco = "AVALIAR NAO FOI ENCONTRADO" "-" banco_2
				
				# CASO A DATA DO PAGTO ESTEJA CORRETA COM O EXTRATO ENTÃO COLOCA A DATA OCORRÊNCIA SENDO A PRÓPRIA DATA DA BAIXA
				if( baixa_extrato == "" && banco != "NAO ENCONTROU NO OFX" )
					baixa_extrato = baixa
				
				# ESTAS LINHA SERVE PRA DEIXAR REGISTRADO O QUE TEM NA PLANILHA DO CLIENTE E FOI PAGO. SERÁ UTILIZADO PARA COMPARAÇÃO COM O OFX AFIM DE AVALIAR O QUE ESTÁ NO OFX DE PAGTO E NÃO ESTÁ NESTA PLANILHA
				PagouNoBanco["-", baixa_extrato, valor_pago] = 1
				
				# BANCO DO ARQUIVO
				if( int(banco_arquivo) == 1 )
					banco_arquivo = "BB" "-" conta_corrente_arq
				else if( int(banco_arquivo) == 341 )
					banco_arquivo = "ITAU" "-" conta_corrente_arq
				else if( int(banco_arquivo) == 237 )
					banco_arquivo = "BRADESCO" "-" conta_corrente_arq
				else if( int(banco_arquivo) == 756 )
					banco_arquivo = "SICOOB" "-" conta_corrente_arq
				else if( int(banco_arquivo) == 0 )
					banco_arquivo = "DINHEIRO"
				else
					banco_arquivo = "AVALIAR NAO FOI ENCONTRADO" "-" conta_corrente_arq
				
				if( baixa != "NULO" && int(valor_pago) > 0 ){
					print nota, cnpj_forn_cli, emissao, venc, banco_arquivo, banco, baixa, baixa_extrato, valor_pago, valor_desconto, valor_juros, 
						  valor_multa, forn_cli >> "temp\\pagtos_agrupados.csv"
				}
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