BEGIN { 
	FS = ";";
	OFS = ";";

    ArquivoPagtos = "temp\\pagtos_agrupados2.csv";
	ArquivoRecebtos = "temp\\recebtos_agrupados2.csv";

    linha = 0
    linha2 = 0

    print "Identificador;Documento;Nome Fornecedor;CNPJ Fornecedor;Emissao;Vencimento;Banco Planilha;Banco Oco. Extrato;Data Pagto;Data Oco. Extrato;Valor Total Lote;Valor Pago;Valor Desconto;Valor Juros;Valor Multa;Numero Titulo;Eh uma NF?;Empresa;Codigo Conta Dominio;OBS;Tipo Pagto;Categoria" >> "saida\\pagtos_agrupados.csv"

    # primeira leitura é pra identificar as linhas que são cabeçalho, pois na segunda impressão ela não será impressa mais
    while ((getline < ArquivoPagtos) > 0) {
        linha++

        if($1 == "INICIO"){
            NumLinhaPagtos[linha] = 1
        }
    } close(ArquivoPagtos)

    # segunda leitura é onde vai retirar os cabeçalhos
    while ((getline < ArquivoPagtos) > 0) {
        linha2++

        if($1 == "INICIO"){
            valor_pago_total = $3
        }

        if($4 == "LANC"){
            if(NumLinhaPagtos[linha2-1] == 1){
                $4 = ""
                print "INICIO", $1, $2, $3, $4, $5, $6, $7, $8, $9, valor_pago_total, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21 >> "saida\\pagtos_agrupados.csv"
            } else {
                $4 = ""
                print "LANCAMENTO", $1, $2, $3, $4, $5, $6, $7, $8, $9, valor_pago_total, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21 >> "saida\\pagtos_agrupados.csv"
            }
        }
    } close(ArquivoPagtos)

    print "Identificador;Documento;Nome Cliente;CNPJ Cliente;Emissao;Vencimento;Banco Planilha;Banco Oco. Extrato;Data Pagto;Data Oco. Extrato;Valor Pago;Valor Desconto;Valor Juros;Valor Multa;Numero Titulo;Empresa;Codigo Conta Dominio;OBS;Tipo Pagto;Categoria" >> "saida\\recebtos_agrupados.csv"

    # --------------- RECEBIMENTOS -----------------
    linha = 0
    linha2 = 0

    # primeira leitura é pra identificar as linhas que são cabeçalho, pois na segunda impressão ela não será impressa mais
    while ((getline < ArquivoRecebtos) > 0) {
        linha++

        if($1 == "INICIO"){
            NumLinhaRecebtos[linha] = 1
        }
    } close(ArquivoRecebtos)

    # segunda leitura é onde vai retirar os cabeçalhos
    while ((getline < ArquivoRecebtos) > 0) {
        linha2++

        if($1 == "INICIO"){
            valor_pago_total = $3
        }

        if($4 == "LANC"){
            if(NumLinhaRecebtos[linha2-1] == 1){
                $4 = ""
                print "INICIO", $1, $2, $3, $4, $5, $6, $7, $8, $9, valor_pago_total, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20 >> "saida\\recebtos_agrupados.csv"
            } else {
                $4 = ""
                print "LANCAMENTO", $1, $2, $3, $4, $5, $6, $7, $8, $9, valor_pago_total, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20 >> "saida\\recebtos_agrupados.csv"
            }
        }
    } close(ArquivoRecebtos)

}