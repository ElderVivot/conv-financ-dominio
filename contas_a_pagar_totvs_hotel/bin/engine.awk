BEGIN { 
	FS = ";"; 
	OFS = FS;
	Arquivos = "bin\\lista";
	
	while ((getline < Arquivos) > 0) {
		file = "entrada\\" $0
		saida = "saida\\" substr( $0, 1, length($0) - 4 ) ".txt"
		saida2 = "saida\\" substr( $0, 1, length($0) - 4 ) "_nao_eh_nota" ".csv"
		
		while ((getline < file) > 0) {
			
			tipo_linha = ""
			tipo_linha = Trim( $1 )
			tipo_linha = subsCharEspecial( tipo_linha )
			tipo_linha = upperCase(tipo_linha)
			
			# LINHAS QUE NAO TEM A PRIMEIRA COLUNA SAO IGNORADAS
			if( tipo_linha == "" )
				continue
			
			if( substr(tipo_linha, 1, 7 ) == "DATA DE" ){
				baixa = ""
				baixa = Trim($6)
				baixa = Trim(baixa)
				baixa = FormatDate(baixa)
				baixa = isDate(baixa)
			}
			
			valor_pago_temp = ""
			valor_pago_temp = Trim( $17 )
			valor_pago_temp = FormataCampo("double", valor_pago_temp, 12, 2)
			
			# SOMENTE LINHAS DE NOTAS PAGAS
			if( int( valor_pago_temp ) > 0 && valor_pago_temp != "0.00" ){
				
				nota_completo = ""
				nota_completo = Trim($7)
				
				nota = split( nota_completo, nota_v, "/" )
				
				nota_1 = soNumeros( nota_v[1] )
				
				forn_cli = ""
				forn_cli = Trim($1)
				forn_cli = subsCharEspecial( forn_cli )
				forn_cli = upperCase( forn_cli )
				
				cnpj_forn_cli = ""
				cnpj_forn_cli = soNumeros($5)
				
				num_cheque = ""
				num_cheque = Trim($9)
				
				emissao = ""
				
				venc = ""
				
				valor_pago = ""
				valor_pago = int( soNumeros( $17 ) )
				
				valor_bruto = ""
				valor_bruto = int( soNumeros( $13 ) )
				
				valor_alterador = ""
				valor_alterador = int( soNumeros( $14 ) )
				
				if( valor_pago < valor_bruto ){
					valor_desconto = valor_alterador
					valor_juros = "000"
				} else if( valor_pago > valor_bruto ){
					valor_desconto = "000"
					valor_juros = valor_alterador
				} else {
					valor_desconto = "000"
					valor_juros = "000"
				}
				
				valor_pago = TransformaPraDecimal(valor_pago)
				
				valor_desconto = TransformaPraDecimal(valor_desconto)
				
				valor_juros = TransformaPraDecimal(valor_juros)
				
				valor_bruto = TransformaPraDecimal(valor_bruto)
				
				forma_pagto_completo = ""
				forma_pagto_completo = Trim( $20 )
				forma_pagto_completo = subsCharEspecial( forma_pagto_completo )
				forma_pagto_completo = upperCase( forma_pagto_completo )
				
				forma_pagto = split( forma_pagto_completo, forma_pagto_v, "-" )
				
				forma_pagto_1 = Trim( forma_pagto_v[1] )
				
				forma_pagto_2 = Trim( forma_pagto_v[2] )
				forma_pagto_2 = subsCharEspecial(forma_pagto_2)
				#forma_pagto_2 = substr( forma_pagto_2,  )
				
				if( num_cheque != num_cheque_ant && num_cheque != "" && forma_pagto_2 == "CHEQUE" )
					print "I", baixa, num_cheque > saida
				
				if( forma_pagto_2 == "DEBITO EM C/C" || forma_pagto_2 == "DÉBITO EM C/C" )
					print "I", baixa, num_cheque > saida
				
				print "L", nota_completo, cnpj_forn_cli, num_cheque, nota_1, baixa, forma_pagto_completo, valor_bruto, valor_pago, valor_desconto, valor_juros, forn_cli > saida
				
				num_cheque_ant = num_cheque
			}
			
		} close(file)
		
		close(saida)
		close(saida2)
		
	} close(Arquivos)
}