BEGIN { 
	FS = ";"; 
	OFS = FS;
	Arquivos = "bin\\lista";
	
	while ((getline < Arquivos) > 0) {
		file = "entrada\\" $0
		saida = "saida\\" substr( $0, 1, length($0) - 4 ) ".csv"
		saida2 = "saida\\" substr( $0, 1, length($0) - 4 ) "_nao_eh_nota" ".csv"
		
		# PRIMEIRO WHILE QUE VAI LER TODOS OS ARQUIVOS E GUARDAR A INFORMACAO DA FORMA DE PAGTO E DADOS DO BANCO QUE FOI PAGO
		while ((getline < file) > 0) {
			
			nro_lote_temp = ""
			nro_lote_temp = Trim( $1 )
			nro_lote_temp = upperCase( nro_lote_temp )
			if( substr( nro_lote_temp, 1, 8 ) == "NRO LOTE" ){
				nro_lote_temp = split( nro_lote_temp, nro_lote_v, ":" )
				
				nro_lote = ""
				nro_lote = nro_lote_v[2]
			}
			
			forma_pagto = ""
			forma_pagto = Trim( $1 )
			forma_pagto = upperCase(forma_pagto)
			
			if( forma_pagto == "DINHEIRO" ){
				FormaPagto[ file, nro_lote ] = forma_pagto
			} else if( forma_pagto == "PAGAMENTO" ){
				
				nome_banco = ""
				nome_banco = Trim( $3 )
				
				agencia = ""
				agencia = Trim( $12 )
				
				conta = ""
				conta = Trim( $14 )
				
				FormaPagto[ file, nro_lote ] = nome_banco "|" agencia "|" conta
			} else
				continue
				
		} close(file)
		
		print "Num Nota;CNPJ Fornecedor;Dt Emissao;Dt Vencimento;Num Parcela;Dt Baixa;Banco/Forma Pagto;Valor Pago;Valor Desconto;Valor Juros;Valor Multa;Valor Funrual;Nome Fornecedor" > saida
			   
		print "Num Nota;CNPJ Fornecedor;Dt Emissao;Dt Vencimento;Num Parcela;Dt Baixa;Banco/Forma Pagto;Valor Pago;Valor Desconto;Valor Juros;Valor Multa;Valor Funrual;Nome Fornecedor" > saida2
		
		while ((getline < file) > 0) {
			
			nro_lote_temp_2 = ""
			nro_lote_temp_2 = Trim( $1 )
			nro_lote_temp_2 = upperCase( nro_lote_temp_2 )
			if( substr( nro_lote_temp_2, 1, 8 ) == "NRO LOTE" ){
				nro_lote_temp_2 = split( nro_lote_temp_2, nro_lote_v_2, ":" )
				
				nro_lote_2 = ""
				nro_lote_2 = nro_lote_v_2[2]
			}
			
			baixa = ""
			baixa = Trim($8)
			baixa = Trim(baixa)
			baixa = FormatDate(baixa)
			baixa = isDate(baixa)
			
			# SOMENTE LINHAS DE NOTAS PAGAS
			if( baixa != "NULO" ){
				
				nota = ""
				nota = Trim($3)
				
				forn_cli = ""
				forn_cli = Trim($1)
				
				cnpj_forn_cli = ""
				
				num_parcela = ""
				
				emissao = ""
				emissao = Trim($5)
				emissao = FormatDate(emissao)
				emissao = isDate(emissao)
				
				venc = ""
				venc = Trim($7)
				venc = FormatDate(venc)
				venc = isDate(venc)
				
				valor_pago = ""
				valor_pago = Trim( $18 )
				valor_pago = FormataCampo("double", valor_pago, 12, 2)
				
				valor_juros = ""
				valor_juros = Trim( $13 )
				valor_juros = FormataCampo("double", valor_juros, 12, 2)
				
				valor_desconto = ""
				valor_desconto = Trim( $16 )
				valor_desconto = FormataCampo("double", valor_desconto, 12, 2)
				
				valor_multa = ""
				valor_multa = Trim( $14 )
				valor_multa = FormataCampo("double", valor_multa, 12, 2)
				
				valor_funrural = "0.00"
				
				parcela = IfElse( num_parcela != 0 && num_parcela != "", " PARC. " num_parcela, "" )
				
				historico = nota parcela " / " forn_cli
				
				banco = FormaPagto[ file, nro_lote_2 ]
				
				if( nota != "" )
					print nota, cnpj_forn_cli, emissao, venc, num_parcela, baixa, banco, valor_pago, valor_desconto, valor_juros, valor_multa, valor_funrural, forn_cli > saida
				else
					print nota, cnpj_forn_cli, emissao, venc, num_parcela, baixa, banco, valor_pago, valor_desconto, valor_juros, valor_multa, valor_funrural, forn_cli > saida2
			}
			
		} close(file)
		
		close(saida)
		close(saida2)
		
	} close(Arquivos)
}