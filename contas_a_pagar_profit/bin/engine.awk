BEGIN { 
	FS = "";
	OFS = ";";
	
	system("if exist bin\\*.txt del /q bin\\*.txt")
	system("dir /b temp\\*.csv > bin\\listacsv.txt")
	system("dir /b entrada\\*.ofx > bin\\listaofx.txt")
	
	ArquivosCsv = "bin\\listacsv.txt";
	ArquivosOfx = "bin\\listaofx.txt";
	
	_comp_ini = int(substr(_comp_ini, 4) "" substr(_comp_ini, 1, 2))
	_comp_fim = int(substr(_comp_fim, 4) "" substr(_comp_fim, 1, 2))
	
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
		
	while ((getline < ArquivosCsv) > 0) {
		file = "temp\\" $0
		
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
			if( tipo_impressao == "banco :" ){
				tipo_impressao_certo = ""
				tipo_impressao_certo = 3
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
				
				baixa_doc = ""
				baixa_doc = Trim($5)
				baixa_doc = FormatDate(baixa_doc)
				baixa_doc = isDate(baixa_doc)
				
				if( baixa_doc != "NULO" ){
					num_titulo_2 = ""
					num_titulo_2 = Trim($1)
					
					valor_juros = ""
					valor_juros = Trim( $12 )
					valor_juros = FormataCampo("double", valor_juros, 12, 2)
					
					valor_desconto = ""
					valor_desconto = Trim( $13 )
					valor_desconto = FormataCampo("double", valor_desconto, 12, 2)
					
					NumNota[num_titulo_2, baixa_doc] = nota
					ValorJuros[num_titulo_2, baixa_doc] = valor_juros
					ValorDesc[num_titulo_2, baixa_doc] = valor_desconto
				}
			}
			
			# LEITURA DO ARQUIVO POR BANCO - LÊ ESTE E GUARDA OS DADOS DO BANCO QUE FOI PAGO
			if( ArquivoTipoImpressao[file] == 3 ){
				
				linha_banco = ""
				linha_banco = Trim($1)
				linha_banco = tolower(linha_banco)
				if( linha_banco == "banco :" ){
					banco_arq_banco = ""
					banco_arq_banco = Trim($2)
					if( index(banco_arq_banco, "CAIXA") > 0 || index(banco_arq_banco, "104") > 0 )
						banco_arq_banco = "CAIXA"
					if( index(banco_arq_banco, "ITAU") > 0 )
						banco_arq_banco = "ITAU"
					if( index(banco_arq_banco, "CARTEIRA") > 0 )
						banco_arq_banco = "DINHEIRO"
				}
				
				emissao_3 = ""
				emissao_3 = Trim($3)
				emissao_3 = FormatDate(emissao_3)
				emissao_3 = isDate(emissao_3)
				
				baixa_banco = ""
				baixa_banco = Trim($6)
				baixa_banco = FormatDate(baixa_banco)
				baixa_banco = isDate(baixa_banco)
				
				if( baixa_banco != "NULO" ){
					num_titulo_3 = ""
					num_titulo_3 = Trim($1)
					
					BancoArquivo[num_titulo_3, baixa_banco] = banco_arq_banco
				}
			}
			
			# LEIUTRA DO ARQUIVO POR FORNECEDOR - EM TERCEIRO LÊ ESTE AFIM DE IMPRIMIR OS PAGTOS QUE ESTAO NA PLANILHA
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
				#baixa = IfElse(baixa == "NULO", venc, baixa) 
				# EM ALGUNS CASOS A DATA DE PAGTO QUE ESTÁ NO ARQUIVO ESTÁ MENOR QUE A DATA DE EMISSÃO DA NOTA, ENTÃO ESTÁ ERRADO. FOI ALTERADO NESTE CASO PRA DATA DE PAGTO SER A MESMA DO VENCIMENTO
				baixa_int = substr(baixa, 7, 4) "" substr(baixa, 4, 2) "" substr(baixa, 1, 2)
				baixa = IfElse( baixa_int < entrada_int, venc, baixa )
				
				valor_inicial = ""
				valor_inicial = Trim( $6 )
				valor_inicial = FormataCampo("double", valor_inicial, 12, 2)
				
				valor_pago = ""
				valor_pago = Trim( $8 )
				valor_pago = FormataCampo("double", valor_pago, 12, 2)
				valor_pago_int = int(soNumeros(valor_pago))
				# O CLIENTE TINHA PARADO DE FAZER AS BAIXAS, POR ISTO FOI NECESSARIO COLOCAR O VALOR PAGO SENDO IGUAL AO DO PARCELA
				#valor_pago = IfElse( int( soNumeros( valor_pago ) ) == 0, valor_inicial, valor_pago )
				
				if( valor_pago_int > 0 ){
					operacao_arq = "-"
					valor_considerar = valor_pago
				} else {
					operacao_arq = "+"
					valor_considerar = valor_recebido_int
				}
				
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
				
				valor_desconto_certo = ValorDesc[num_titulo, baixa]
				valor_desconto_certo = IfElse( int(soNumeros(valor_desconto_certo)) == 0, valor_desconto_obs, valor_desconto_certo )
				valor_desconto_certo = IfElse( int(valor_desconto_certo) == 0, "0,00", valor_desconto_certo )
				
				valor_juros_certo = ValorJuros[num_titulo, baixa]
				valor_juros_certo = IfElse( int(valor_juros_certo) == 0, "0,00", valor_juros_certo )
				
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
					#baixa_6 = SomaDias(baixa, 3)
					#baixa_7 = SomaDias(baixa, -3)
					
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
				
				if( banco == "" )
					banco = BancoPagoCheque[num_cheque]
				
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
				
				banco_arquivo = BancoArquivo[num_titulo, baixa]
				if( ( banco_arquivo == "DINHEIRO" || banco_arquivo == "" ) && banco == "NAO ENCONTROU NO OFX"  )
					banco = "DINHEIRO"
				
				# PRA QUANDO FOR PAGTO COM CHEQUE, VAI ENCONTRAR QUAL É A DATA QUE O CHEQUE COMPENSOU
				data_compensacao_cheque = DataCompensacaoCheque[num_cheque]
				
				# VERIFICA SE A BAIXA_EXTRATO É VÁLIDA, CASO NÃO, UTILIZA A DATA_COMPENSACAO_CHEQUE
				baixa_extrato = IfElse(baixa_extrato == "", data_compensacao_cheque, baixa_extrato)
				
				# CASO A DATA DO PAGTO ESTEJA CORRETA COM O EXTRATO ENTÃO COLOCA A DATA OCORRÊNCIA SENDO A PRÓPRIA DATA DA BAIXA
				if( baixa_extrato == "" && banco != "NAO ENCONTROU NO OFX" )
					baixa_extrato = baixa
				
				# ESTAS LINHA SERVE PRA DEIXAR REGISTRADO O QUE TEM NA PLANILHA DO CLIENTE E FOI PAGO. SERÁ UTILIZADO PARA COMPARAÇÃO COM O OFX AFIM DE AVALIAR O QUE ESTÁ NO OFX DE PAGTO E NÃO ESTÁ NESTA PLANILHA
				PagouNoBanco[operacao_arq, baixa_extrato, valor_considerar] = 1
				
				PagouNoBancoCheque[num_cheque] = 1
				
				num_nota = ""
				num_nota = NumNota[num_titulo, baixa]
				num_nota = IfElse(num_nota == "", num_cheque, num_nota)
				
				if( num_cheque != "" )
					tipo_doc = "CHEQUE"
				
				# AS LINHAS ABAIXO SÃO UTILIZADAS PARA IMPRIMIR SOMENTE O QUE FOR DAQUELA COMPETENCIA
				baixa_temp = ""
				baixa_temp = baixa_extrato
				baixa_temp = IfElse(baixa_temp == "", baixa, baixa_temp)
				baixa_temp = int(substr(baixa_temp, 7) "" substr(baixa_temp, 4, 2))
				
				# PAGOS
				if( baixa != "NULO" && int(valor_pago) > 0 && _comp_ini <= baixa_temp && baixa_temp <= _comp_fim ){
					print num_nota, forn_cli, "'" cnpj_forn_cli, entrada, venc, banco_arquivo, banco, baixa, baixa_extrato, valor_pago, 
							  valor_desconto_certo, valor_juros_certo, "0,00", "'" num_titulo, codi_emp, codi_cta, obs, tipo_doc, categoria >> "temp\\pagtos_agrupados.csv"
				}
			}
		} close(file)
	} close(ArquivosCsv)
	
	#print "Banco;Conta Corrente;Tipo Movimento;Data;Operacao;Valor;Num. Doc.;Historico" >> "saida\\movtos_feitos_no_cartao_nao_estao_na_planilha.csv"
	
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
		
		#if( operacao_3 == "-" && pagou_no_banco != 1 )
		if( pagou_no_banco != 1 ){
			if( historico_2 == "CHEQ COMP" || historico_2 == "CHEQUE SAC" ){
				if( PagouNoBancoCheque[num_doc_2] != 1 )
					print $0 >> "saida\\pagtos_feitos_no_cartao_nao_estao_na_planilha.csv"
			} else
				print $0 >> "saida\\pagtos_feitos_no_cartao_nao_estao_na_planilha.csv"
		}
		
	} close("temp\\extrato_cartao.csv")
	
	system("if exist bin\\*.txt del /q bin\\*.txt")
}