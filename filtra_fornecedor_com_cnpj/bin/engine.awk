BEGIN { 
	FS = ";";
	OFS = FS;
	
	system("if exist bin\\*.txt del /q bin\\*.txt")
	system("if exist entrada\\*.csv dir /b entrada\\*.csv > bin\\listacsv.txt")
	
	ArquivosCsv = "bin\\listacsv.txt";
	
	while ((getline < ArquivosCsv) > 0) {
		file = "entrada\\" $0
		saida = "saida\\" $0
		
		while ((getline < file) > 0) {
			
			if ( Trim(toupper($1)) == toupper("Documento") ){
				load_columns();
				continue;
			}
			
			cnpj = ""
			cnpj = $int(NumColuna("CNPJ Fornecedor"))
			cnpj = soNumeros(cnpj)
			if( length(cnpj) > 11 && int(cnpj) > 0 )
				print $0 > saida
			
		}close(file)
		close(saida)
		
	}close(ArquivosCsv)
}