BEGIN { 
	FS = "";
	OFS = ";";
	
	system("if exist bin\\*.txt del /q bin\\*.txt")
	system("dir /b entrada\\*.csv > bin\\listacsv.txt")
	system("dir /b entrada\\*.ofx > bin\\listaofx.txt")
	
	ArquivosCsv = "bin\\listacsv.txt";
	ArquivosOfx = "bin\\listaofx.txt";
	
	print "Tipo Movimento;Data;Valor;Num. Doc.;Historico" >> "temp\\extrato_cartao.csv"
	
	# LE O ARQUIVO OFX AFIM DE PODER COMPARAR O QUE FOI PAGO NO CARTAO COM A PLANILHA DE BAIXA DO CLIENTE
	while ((getline < ArquivosOfx) > 0) {
		fileofx = "entrada\\" $0
		
		while ((getline < fileofx) > 0) {
			
			ofx = tolower( Trim($0) )
			
			if( substr(ofx, 1, 9) == "<trntype>" )
				tipo_mov = upperCase( selecionaTAG( ofx, "<trntype>", "</trntype>" ) )
			
			if( substr(ofx, 1, 10) == "<dtposted>" ){
				data_mov = selecionaTAG( ofx, "<dtposted>", "</dtposted>" )
				data_mov = substr(data_mov, 1, 8)
				data_mov = substr(data_mov, 7, 2) "/" substr(data_mov, 5, 2) "/" substr(data_mov, 1, 4)
			}
			
			if( substr(ofx, 1, 8) == "<trnamt>" ){
				valor_transacao = selecionaTAG( ofx, "<trnamt>", "</trnamt>" )
				gsub("-", "", valor_transacao)
				gsub("[.]", ",", valor_transacao)
			}
			
			if( substr(ofx, 1, 7) == "<fitid>" )
				num_doc = selecionaTAG( ofx, "<fitid>", "</fitid>" )
			
			if( substr(ofx, 1, 6) == "<memo>" )
				historico = upperCase( selecionaTAG( ofx, "<memo>", "</memo>" ) )
			
			if( substr(ofx, 1, 10) == "</stmttrn>" ){
				print tipo_mov, data_mov, valor_transacao, num_doc, historico >> "temp\\extrato_cartao.csv"
				ExisteMov[tipo_mov, data_mov, valor_transacao] = 1
				
				# QUANDO É CHEQUE GUARDA A DATA QUE O CHEQUE COMPENSOU, É ELA QUE TEM QUE SER UTILIZADA COMO DATA DA BAIXA
				if( historico == "CHEQ COMP" || historico == "CHEQUE SAC" )
					DataCompensacaoCheque[num_doc] = data_mov
			}
			
		} close(fileofx)
	} close(ArquivosOfx)
	
	FS = ";"; 
	OFS = FS;
	
	print "Nota;CNPJ Fornecedor;Data Entrada;Data Vencimento;Num. Cheque;Data Compensacao Cheque;Data Pagto;Tipo Docto;Valor Pago;Valor Desconto;Valor Juros;Pago no Banco;Nome Fornecedor;OBS;Num. Titulo" >> "saida\\pagtos_agrupados.csv"
		
	while ((getline < ArquivosCsv) > 0) {
		file = "entrada\\" $0
		
		# PRIMEIRO WHILE QUE VAI LER TODOS OS ARQUIVOS E VER QUAL É A ESTRUTURA QUE ELE ESTÁ
		while ((getline < file) > 0) {
			
			# QUANDO EM ALGUMAS DAS LINHAS NA COLUNA 1 TIVER A INFORMACAO 'DOCTO :' ENTÃO O TIPO DE IMPRESSÃO É 1, QUANDO TIVER 'FORNECEDOR :' ENTÃO É 2
			tipo_impressao = ""
			tipo_impressao = Trim($1)
			tipo_impressao = tolower(tipo_impressao)
			if( tipo_impressao == "docto :" ){
				tipo_impressao_certo = ""
				tipo_impressao_certo = 1
				ArquivoTipoImpressao[file] = tipo_impressao_certo
				break
			}
			if( tipo_impressao == "fornecedor :" ){
				tipo_impressao_certo = ""
				tipo_impressao_certo = 2
				ArquivoTipoImpressao[file] = tipo_impressao_certo
				break
			}
			
		} close(file)
		
		while ((getline < file) > 0) {
			
			# LEITURA DO ARQUIVO POR DOCTO - PRIMEIRO LÊ ESTE E GUARDA OS DADOS COMO NOTA, JUROS, DESCONTO NUM VETOR
			if( ArquivoTipoImpressao[file] == 1 ){
				
				linha_doc = ""
				linha_doc = Trim($1)
				linha_doc = tolower(linha_doc)
				if( linha_doc == "docto :" ){
					nota = ""
					nota = Trim($2)
				}
				
				emissao_2 = ""
				emissao_2 = Trim($3)
				emissao_2 = FormatDate(emissao_2)
				emissao_2 = isDate(emissao_2)
				
				venc_2 = ""
				venc_2 = Trim($4)
				venc_2 = FormatDate(venc_2)
				venc_2 = isDate(venc_2)
				
				if( emissao_2 != "NULO" && venc_2 != "NULO" ){
					num_titulo_2 = ""
					num_titulo_2 = Trim($1)
					
					valor_juros = ""
					valor_juros = Trim( $12 )
					valor_juros = FormataCampo("double", valor_juros, 12, 2)
					
					valor_desconto = ""
					valor_desconto = Trim( $13 )
					valor_desconto = FormataCampo("double", valor_desconto, 12, 2)
					
					NumNota[num_titulo_2, emissao_2] = nota
					ValorJuros[num_titulo_2, emissao_2] = valor_juros
					ValorDesc[num_titulo_2, emissao_2] = valor_desconto
				}
			}
			
			# LEIUTRA DO ARQUIVO POR FORNECEDOR - EM SEGUNDO LÊ ESTE AFIM DE IMPRIMIR OS PAGTOS QUE ESTAO NA PLANILHA
			if( ArquivoTipoImpressao[file] == 2 ){
				
				linha_fornecedor = ""
				linha_fornecedor = Trim($1)
				linha_fornecedor = tolower(linha_fornecedor)
				if( linha_fornecedor == "fornecedor :" ){
					nome_fornecedor_completo = ""
					nome_fornecedor_completo = Trim($2)
					nome_fornecedor_completo = split( nome_fornecedor_completo, nome_fornecedor_v, "-" )
					
					forn_cli = Trim(nome_fornecedor_v[2])
					
					cnpj_forn_cli = soNumeros($4)
				}
				
				emissao = ""
				emissao = Trim($3)
				emissao = FormatDate(emissao)
				emissao = isDate(emissao)
				
				venc = ""
				venc = Trim($4)
				venc = FormatDate(venc)
				venc = isDate(venc)
				
				if( emissao != "NULO" && venc != "NULO" ){
					num_titulo = ""
					num_titulo = Trim($1)
					
					entrada = ""
					entrada = Trim($2)
					entrada = FormatDate(entrada)
					entrada = isDate(entrada)
					entrada = IfElse(entrada == "NULO", emissao, entrada)
					entrada_int = substr(entrada, 7, 4) "" substr(entrada, 4, 2) "" substr(entrada, 1, 2)
					
					baixa = ""
					baixa = Trim($9)
					baixa = Trim(baixa)
					baixa = FormatDate(baixa)
					baixa = isDate(baixa)
					# O CLIENTE TINHA PARADO DE FAZER AS BAIXAS, POR ISTO FOI NECESSARIO COLOCAR A DATA DE VENCIMENTO SENDO IGUAL AO DO PAGTO
					baixa = IfElse(baixa == "NULO", venc, baixa) 
					# EM ALGUNS CASOS A DATA DE PAGTO QUE ESTÁ NO ARQUIVO ESTÁ MENOR QUE A DATA DE EMISSÃO DA NOTA, ENTÃO ESTÁ ERRADO. FOI ALTERADO NESTE CASO PRA DATA DE PAGTO SER A MESMA DO VENCIMENTO
					baixa_int = substr(baixa, 7, 4) "" substr(baixa, 4, 2) "" substr(baixa, 1, 2)
					baixa = IfElse( baixa_int < entrada_int, venc, baixa )
					
					valor_inicial = ""
					valor_inicial = Trim( $6 )
					valor_inicial = FormataCampo("double", valor_inicial, 12, 2)
					
					valor_pago = ""
					valor_pago = Trim( $8 )
					valor_pago = FormataCampo("double", valor_pago, 12, 2)
					# O CLIENTE TINHA PARADO DE FAZER AS BAIXAS, POR ISTO FOI NECESSARIO COLOCAR O VALOR PAGO SENDO IGUAL AO DO PARCELA
					valor_pago = IfElse( int( soNumeros( valor_pago ) ) == 0, valor_inicial, valor_pago )
					
					num_cheque = ""
					num_cheque = Trim($11)
					
					tipo_doc_completo = ""
					tipo_doc_completo = upperCase( Trim($13) )
					tipo_doc_completo = split(tipo_doc_completo, tipo_doc_v, "-")
					
					tipo_doc = Trim(tipo_doc_v[2])
					
					obs = ""
					obs = Trim($14)
					obs = upperCase(obs)
					
					valor_desconto_obs = ""
					if( substr( obs, 1, 3 ) == "DES" ){
						valor_desconto_obs = soNumeros(obs)
						valor_desconto_obs = int(valor_desconto_obs)
						valor_desconto_obs = TransformaPraDecimal(valor_desconto_obs)
					}
					
					valor_desconto_certo = ValorDesc[num_titulo, emissao]
					valor_desconto_certo = IfElse( int(soNumeros(valor_desconto_certo)) == 0, valor_desconto_obs, valor_desconto_certo )
					valor_desconto_certo = IfElse( int(valor_desconto_certo) == 0, "0,00", valor_desconto_certo )
					
					valor_juros_certo = ValorJuros[num_titulo, emissao]
					valor_juros_certo = IfElse( int(valor_juros_certo) == 0, "0,00", valor_juros_certo )
					
					# ESTE CAMPO É ÚTIL PRA SABER SE PAGOU NO BANCO OU NO CAIXA
					pago_no_banco = ExisteMov["DEBIT", baixa, valor_pago]
					pago_no_banco = IfElse( pago_no_banco == 1, "S", "N" )
					
					# PRA QUANDO FOR PAGTO COM CHEQUE, VAI ENCONTRAR QUAL É A DATA QUE O CHEQUE COMPENSOU
					data_compensacao_cheque = DataCompensacaoCheque[num_cheque]
					
					if(num_cheque != "" || tipo_doc == "CHEQUE")
						pago_no_banco = "S"
					
					# ESTAS DUAS LINHAS SERVE PRA DEIXAR REGISTRADO O QUE TEM NA PLANILHA DO CLIENTE E FOI PAGO. SERÁ UTILIZADO PARA COMPARAÇÃO COM O OFX AFIM DE AVALIAR O QUE ESTÁ NO OFX DE PAGTO E NÃO ESTÁ NESTA PLANILHA
					PagouNoBanco["DEBIT", baixa, valor_pago] = 1
					PagouNoBancoCheque[num_cheque] = 1
					
					print NumNota[num_titulo, emissao], "'" cnpj_forn_cli, entrada, venc, num_cheque, data_compensacao_cheque, baixa, tipo_doc, valor_pago, 
					      valor_desconto_certo, valor_juros_certo, pago_no_banco, forn_cli, "'" obs, "'" num_titulo >> "saida\\pagtos_agrupados.csv"
				}
			}
		} close(file)
	} close(ArquivosCsv)
	
	print "Tipo Movimento;Data;Valor;Num. Doc.;Historico" >> "saida\\pagtos_feitos_no_cartao_nao_estao_na_planilha.csv"
	
	# VAI VER NO OFX QUAIS DÉBITOS QUE NÃO ESTÃO NA PLANILHA DO CLIENTE, GERALMENTE SÃO CHEQUES COMPENSADOS EM MESES ANTERIORES OU TARIFAS
	while ( (getline < "temp\\extrato_cartao.csv") > 0 ) {
		tipo_mov_2 = $1
		data_mov_2 = $2
		valor_transacao_2 = $3
		num_doc_2 = $4
		historico_2 = $5
		
		if( tipo_mov_2 == "DEBIT" && PagouNoBanco[tipo_mov_2, data_mov_2, valor_transacao_2] != 1 ){
			if( historico_2 == "CHEQ COMP" || historico_2 == "CHEQUE SAC" ){
				if( PagouNoBancoCheque[num_doc_2] != 1 )
					print $0 >> "saida\\pagtos_feitos_no_cartao_nao_estao_na_planilha.csv"
			} else
				print $0 >> "saida\\pagtos_feitos_no_cartao_nao_estao_na_planilha.csv"
		}
	} close("temp\\extrato_cartao.csv")
	
	system("if exist bin\\*.txt del /q bin\\*.txt")
}