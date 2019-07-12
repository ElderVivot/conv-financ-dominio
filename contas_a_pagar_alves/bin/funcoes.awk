BEGIN{
	FS = ";"
}

# ------------------ FUN«√O MATCH(express„o, combinaÁ„o ser encontrada) --> EXPLICA«√O -----------------------
#O match() È bastante parecida com o index(), exceto que em vez de procurar por uma substring como o index() faz, ele procura por uma express„o regular. 
#A funÁ„o match() ir· retornar a posiÁ„o inicial da combinaÁ„o, ou zero se n„o houver combinaÁ„o. AlÈm disso, o match() ir· configurar duas vari·veis 
#chamadas RSTART e RLENGTH. RSTART contÈm o valor de retorno (a localizaÁ„o da primeira combinaÁ„o), e RLENGTH ir· conter seu comprimento em caracteres 
#(ou -1 se nenhuma combinaÁ„o for encontrada). Veja um exemplo da chamada ao match():
#print match("Elder ama Amanda",/ama/), RSTART, RLENGTH
#O awk ir· escrever: 7 7 3
#O primeiro 7 È a posiÁ„o inicial da combinaÁ„o
#O segundo 7 È o local onde encontrou a primeira combinaÁ„o
#O 3 È o tamanho do "ama"

# ----------------- FUN«√O INDEX(express„o, caracter a ser encontrado) --> EXPLICA«√O -------------------------
#index("Amor", "r"): procura na string "Amor" a primeira ocorrÍncia da string "r" e retorna a posiÁ„o onde foi encontrada dentro da string "Amor" que 
#neste caso seria a quarta

# ----------------- FUN«√O SPLIT (express„o, vetor, separador) --> EXPLICA«√O ------------------------------
#A funÁ„o split() divide a string em partes separadas por campos de acordo o separador, e armazena as partes no array, que no caso È o vetor. 
#O valor do separador È uma express„o regular que descreve onde dividir a string. Se o valor do separador È omitido, o valor de FS È usado.
# Se o seu valor for a string nula (""), ent„o cada caracter torna-se um campo separador. O default È " ". 
# O Split retorna o n˙mero de elementos criados. Exemplo: 
# campo = split("Elder e Amanda", amor, "e")
# print campo, amor[1], amor[2]. Ent„o o resultado ser· 2, Elder, Amanda 

# RETORNA COLUNA
function Campo(Col) {
	
	CampoColuna = ""
	CampoColuna = $Coluna[Col]
	
	if ( CampoColuna == "(null)" || CampoColuna == "" )
		CampoColuna = "NULO"
	else
		CampoColuna = CampoColuna
	
	return CampoColuna
}

# AUMENTA A CAIXA DOS CARACTERES
function upperCase(upCampo) {
	# AUMENTA A CAIXA DOS CARACTERES NORMAIS USANDO toupper()
	upCampo = toupper(upCampo);
	
	# AUMENTA A CAIXA DOS CARACTERES ACENTUADOS
	gsub("‚", "¬", upCampo)
	gsub("‡", "¿", upCampo)
	gsub("„", "√", upCampo)
	gsub("·", "¡", upCampo)
	gsub("È", "…", upCampo)
	gsub("Í", " ", upCampo)
	gsub("Ì", "Õ", upCampo)
	gsub("Ó", "Œ", upCampo)
	gsub("Û", "”", upCampo)
	gsub("Ù", "‘", upCampo)
	gsub("ı", "’", upCampo)
	gsub("˙", "⁄", upCampo)
	gsub("˚", "€", upCampo)
	gsub("¸", "U", upCampo)
	gsub("‹", "U", upCampo)
	gsub("Á", "C", upCampo)
	
	return upCampo
}

# TIRA CARACTERES ESPECIAIS
function subsCharEspecial(tiraEsp){
	
	gsub("·", "a", tiraEsp)
	gsub("‡", "a", tiraEsp)
	gsub("‚", "a", tiraEsp)
	gsub("„", "a", tiraEsp)
	gsub("¡", "A", tiraEsp)
	gsub("¿", "A", tiraEsp)
	gsub("¬", "A", tiraEsp)
	gsub("√", "A", tiraEsp)
	gsub("&", "E", tiraEsp)
	gsub("È", "e", tiraEsp)
	gsub("Í", "e", tiraEsp)
	gsub(" ", "E", tiraEsp)
	gsub("…", "E", tiraEsp)
	gsub("Ì", "i", tiraEsp)
	gsub("Õ", "I", tiraEsp)
	gsub("Û", "o", tiraEsp)
	gsub("Ù", "o", tiraEsp)
	gsub("Ú", "o", tiraEsp)
	gsub("”", "O", tiraEsp)
	gsub("‘", "O", tiraEsp)
	gsub("“", "O", tiraEsp)
	gsub("˙", "u", tiraEsp)
	gsub("˚", "u", tiraEsp)
	gsub("⁄", "U", tiraEsp)
	gsub("€", "U", tiraEsp)
	gsub("Á", "c", tiraEsp)
	gsub("«", "C", tiraEsp)
	
	return tiraEsp
}

# SELECIONA COLUNAS QUANDO √â SEPARADO SOMENTE POR ESPA√áO
function selecionaColunas() {
	tamLinha = length($0)
	for (c=1; c<=tamLinha; c++) {
		char = substr($0,c,1)
		if (char != "") {
			if (char == " ")
				fimStr = 1
			if (fimStr == 1) {
				if (char == " ") numEspacos++
				else {
					numEspacos = 0; fimStr = 0; ini = 0;
					tc++
					FimColuna[tc] = c
					if (int(IniColuna[tc-1]) == 0) IniColuna[tc] = FimColuna[tc-1] + 1
					else IniColuna[tc] = FimColuna[tc-1]
					SelColuna[tc] = FimColuna[tc] - IniColuna[tc]
					ColunaNom = toupper(substr($0, IniColuna[tc], SelColuna[tc]))
					gsub(/[ ]*$|^[ ]*/,"",ColunaNom)
					ColunaIni[ColunaNom] = IniColuna[tc]
					ColunaSel[ColunaNom] = SelColuna[tc]
				}
			}
		}
		if (c == tamLinha) {
			tc++
			FimColuna[tc] = c + 1
			IniColuna[tc] = FimColuna[tc-1]
			SelColuna[tc] = FimColuna[tc] - IniColuna[tc]
			ColunaNom = toupper(substr($0, IniColuna[tc], SelColuna[tc]))
			gsub(/[ ]*$|^[ ]*/,"",ColunaNom)
			ColunaIni[ColunaNom] = IniColuna[tc]
			ColunaSel[ColunaNom] = SelColuna[tc]
		}
	}
}

# VAI RETORNAR A COLUNA
function retornaColuna(icoluna) {
	rcoluna = substr($0, ColunaIni[icoluna], ColunaSel[icoluna])
	gsub(/[ ]*$|^[ ]*/,"",rcoluna)
	gsub(/[;]/, ",", rcoluna)
	if (rcoluna == "<null>") 
		rcoluna = ""
	return upperCase(rcoluna)
}

# RETORNA FONE
function tFone(argTelefone){
	
	fone_function = ""
	fone_function = argTelefone
	
	if( substr(fone_function, 1, 1) == "0")
		fone_function = substr(fone_function, 2, length(fone_function) )
	else
		fone_function = fone_function
	
	if(length(fone_function) == 10)	#ddd + fone
		fone_function = substr(fone_function, 3, 8)
	else if(length(fone_function) == 11) #ddd + fone 9 digitos
		fone_function = substr(fone_function, 3, 9)
	else if(length(fone_function) == 8) #somente fone
		fone_function = substr(fone_function, 1, 8)
	else if(length(fone_function) == 9) #somente fone de 9 difigitos
		fone_function = substr(fone_function, 1, 9)
	else
		fone_function = "NULO"
	
	return fone_function
}

# RETORNA DDD FONE
function dddFone(argTelefone){
	if(length(argTelefone) >= 10)	#ddd + fone
		ddd = substr(argTelefone, 1, 2)
	else
		ddd = "NULO"
	
	return ddd
}

# RETORNA DDD + FONE
function Ddd_Fone(argDdd, argFone){
	if((argDdd == "NULO") && (argFone != "NULO"))
		dddefone = argFone
	else if(argFone == "NULO")
		dddefone = "NULO"
	else
		dddefone = "(" argDdd ")" argFone
	
	return dddefone
}

# RETORNA DDD + FONE POIS ESTE JA VEM PRE FORMATADO
function Ddd_Fone_Filiais(argDdd, argFone){
	if((argDdd == "NULO") && (argFone != "NULO"))
		dddefone = argFone
	else if(argFone == "NULO")
		dddefone = "NULO"
	else
		dddefone = argDdd argFone
	
	return dddefone
}

# TIRA ESPA«OS ANTES E NO FINAL DO TEXTO
function Trim(trimCampo){
	gsub(/[ ]*$|^[ ]*/,"",trimCampo)
	gsub("\t", "", trimCampo)
	
	return trimCampo
}

# S” N⁄MEROS
function soNumeros(soNumero){
	gsub(/[^0-9]/, "", soNumero)
	
	return soNumero
}

# TIRA UM CAMPO QUE EST¡ DENTRO DE UM OUTRO --> N√O PRECISA POIS TEM A SPLIT
#function TiraCampo(argCampo, argSeparador){
#	novoCampo = ""
#	
#	for(i = 1; i <= length(argCampo); i++){
#		c = substr(argCampo, i, 1)
#		if(c == argSeparador)
#			p = i + 1
#		novoCampo = substr(argCampo, p, length(argCampo) - p + 1)
#	}
#	
#	return novoCampo
#}

# TIRA UM CAMPO QUE EST¡ DENTRO DE UM OUTRO --> RETORNA O ORIGINAL
#function TiraCampoOriginal(argCampoOriginal, argSeparadorOriginal){
#	novoCampoOriginal = ""
#	
#	for(i = 1; i <= length(argCampoOriginal); i++){
#		c = substr(argCampoOriginal, i, 1)
#		if(c == argSeparadorOriginal)
#			p = i + 1
#		novoCampoOriginal = substr(argCampoOriginal, 1, p - 2)
#	}
#	
#	return novoCampoOriginal
#}

# FUN«√O IF ELSE --> AVALIAR PARA O QUE SERVE
function IfElse(alCondicao,auRetornoIf,auRetornoElse){
		if (alCondicao)
			{
				return auRetornoIf
			}
		else
			{
				return auRetornoElse
			}
}

# Criade em: 19/01/2001
# Recebe   : String com valor numÈrico padr„o Europeu(1.250,56)
# Retorna  : String com valor numÈrico padr„o Americano(1250.56)
# DefiniÁ„o: Usada para ajusar campo numÈrico com definiÁ„o de
#            vÌrgula como separador decimal e ponto para definiÁ„o
#            de milhar.
function Space(aiTamanho){	
	lsReturn=""
	for (liIndice=1; liIndice<=aiTamanho; liIndice++)
		{
			lsReturn=lsReturn " "
		}
	return lsReturn
}

# Criada em: 18/01/2002
# Recebe   : anValor q È o valor a ser trabalhado, aiInteiros q È a quantidade d digitos
#            ...inteiros q devera ficar em anValor e aiDecimais q È a quantidade de digitos
#            ...de decimais(apos virgula ou ponto) q deve ficar em anValor
# Retorna  : Valor de anValor formatado com aiInteiros e aiDecimais, preenchido com
#            ...cadeia de zeros ‡ esquerda.
# Definicao: Servira para retornar os campos numericos preenchidos com zeros ‡ esquerda.
#
function StrZero(anValor,aiTamInteiros,aiTamDecimais){

 		aiTamInteiros += 0
 		aiTamDecimais += 0
 		
		#// anValor = SoNumeros(anValor)
		
		liInteiros = ""
		liDecimais = ""
		
		liPos = ""
		liPos = match(anValor,"\\.")
		
		if (liPos != 0)
			{
				liInteiros = substr(anValor,1,liPos-1)
				liDecimais = substr(anValor,liPos,(length(anValor)-(length(anValor)-(liPos+1))))
			}
		else
			{
				liInteiros = anValor
			}
		
		if (length(liInteiros) > aiTamInteiros)
			{
				return 0
			}
		if (length(liDecimais) > aiTamDecimais)
			{
				return 0
			}

		gsub(/[^0-9]/,"",liInteiros)
		liInteiros = Space(aiTamInteiros-length(liInteiros)) liInteiros
		gsub(/[ ]/,"0",liInteiros)
		
		gsub(/[^0-9]/,"",liDecimais)
		liDecimais = liDecimais Space(aiTamDecimais-length(liDecimais))
		gsub(/[ ]/,"0",liDecimais)
		
		if (length(liInteiros) == 0)
			{
				return 0
			}
				
		if (length(liDecimais) > 0)
			{
				liDecimais = "." liDecimais
			}
		
		return liInteiros liDecimais
}

# SOMA OU SUBTRAI DIAS
function SomaDias(asDiaOrigem,asQuantiaSomar,asFormatoData)
	{
		### PARA DEIXAR PADRAO BR QDO ESTIVER VAZIO O FORMATO DA DATA INFORMADA.
		asFormatoData = IfElse(asFormatoData == "","BR",asFormatoData)
		
		### PARA DEIXAR PADRAO BR QDO ESTIVER COM VALOR INVALIDO.
		asFormatoData = IfElse(match("---BR---JP---US---",asFormatoData) == 0,"BR",asFormatoData)

		### SE O PADRAO FOR BRASILEIRO JA PEGA A DATA PRA TRABALHAR
		lsDiaOrigem = asDiaOrigem
		
		### SE NAO FOR BRASILEIRO O PADRAO, CONVERTE.
		if (asFormatoData == "JP")
			{

				lsSeparador =  substr(asDiaOrigem,5,1)

				if (lsSeparador == "\\")
					{
						lsSeparador = lsSeparador "\\"
					}

				if (asDiaOrigem == "")
					{
						return "    " lsSeparador "  " lsSeparador "  "
					}
			
				asQuantiaSomar += 0
	
				if (asQuantiaSomar == 0)
					{
						return "    " lsSeparador "  " lsSeparador "  "
					}
					
				lsDiaOrigem = substr(asDiaOrigem,9,2) lsSeparador substr(asDiaOrigem,6,2) lsSeparador substr(asDiaOrigem,1,4)
			}
		if (asFormatoData == "US")
			{
				lsSeparador = substr(asDiaOrigem,3,1)
				if (lsSeparador == "\\")
					{
						lsSeparador = lsSeparador "\\"
					}

				lsDiaOrigem = substr(asDiaOrigem,4,2) lsSeparador substr(asDiaOrigem,1,2) lsSeparador substr(asDiaOrigem,7,4)
			}
		if (asFormatoData == "BR")
			{
				lsSeparador = substr(asDiaOrigem,3,1)
				if (lsSeparador == "\\")
					{
						lsSeparador = lsSeparador "\\"
					}

			}
				

		if (asDiaOrigem == "")
			{
				return "  " lsSeparador "  " lsSeparador "    "
			}
			
		asQuantiaSomar += 0
		
		if (asQuantiaSomar == 0)
			{
				return "  " lsSeparador "  " lsSeparador "    "
			}
				
		lsDia = substr(lsDiaOrigem,1,2)
		lsMes = substr(lsDiaOrigem,4,2)
		lsAno = substr(lsDiaOrigem,7,4)
		
		lsDia += 0
		lsMes += 0
		lsAno += 0

		if (asQuantiaSomar > 0 )
			{
				for(liNum=1;liNum <= asQuantiaSomar;liNum++)
					{
						if (lsDia <= 27)
							{
								lsDia += 1
								continue
							}

						if (lsMes == 12)
							{
								if (lsDia == 31)
									{
										lsDia = 1
										lsMes = 1
										lsAno += 1
										continue
									}
								else
									{
										lsDia += 1
										continue
									}
							}
						
						if (lsMes == 2)
							{
								lsBisexto = lsAno
								lsBisexto %= 4
								### SE O ANO E BISEXTO E SABENDO Q SO CHEGOU...
								### AQUI PQ DIA E = 28 ENTAO E JA VAI SER NOVO MES.
								if (lsBisexto != 0)
									{
										lsMes += 1
										lsDia = 1
										continue
									}

								## SE TIVER 29 DIAS E PQ REALMENTE E ANO BISEXTO
								if (lsDia == 29)
									{
										lsDia = 1
										lsMes += 1
										continue
									}

								### SE NAO ERA BISEXTO E ERA DIA 28... AINDA NAO E FIM DO MES.. TEM Q SOMAR MAIS UM DIA E DESCER O SARRAFO
								lsDia += 1
								continue
							}
				
						lsMesAtua = lsMes
						lsMesAtua = lsMesAtua ""
						lsMesAtua = StrZero(lsMesAtua,2)

						if (match("--01--03--05--07--08--10--",lsMesAtua) != 0)
							{
								if (lsDia < 31)
									{
										lsDia++
										continue
									}
								else
									{
										lsDia = 1
										lsMes += 1
										continue
									}
							}

						
						if (match("--04--06--09--11--",lsMesAtua) != 0)
							{
								if (lsDia < 30)
									{
										lsDia += 1
										continue
									}
								else
									{
										lsDia = 1
										lsMes += 1
									}

							}
					}
			}
		else
			{
				liNum = -1
				while (liNum >= asQuantiaSomar)
					{
					
						lsMesAtua = lsMes
						lsMesAtua = lsMesAtua ""
						lsMesAtua = StrZero(lsMesAtua,2)

						if (lsDia > 1)
							{
								lsDia -= 1
								liNum -= 1
								continue
							}

						if (lsDia == 1)
							{
								if (match("01--02--04--06--08--09--11--",lsMesAtua) != 0)
									{
										if (lsMesAtua == "01")
											{
												lsDia = 31
												lsMes = 12
												lsAno -= 1
												liNum -= 1
												continue
											}
											
										lsDia = 31
										lsMes -= 1
										liNum -= 1
										continue
									}
					
								if (match("--05--07--10--12--",lsMesAtua) != 0)
									{
										lsDia = 30
										lsMes -= 1
										liNum -= 1
										continue
									}
									
								if (lsMes == 3)
									{
										lsBisexto = lsAno
										lsBisexto %= 4
										### SE O ANO E BISEXTO E SABENDO Q SO CHEGOU AQUI PQ DIA E MAIOR Q 27 ENTAO E DIA 28 E JA VAI SER NOVO MES
										if (lsBisexto != 0)
											{
												lsMes -= 1
												lsDia = 28
												liNum -= 1
												continue
											}
										else
											{ ### SE ANO BISSEXTO
												lsMes -= 1
												lsDia = 29
												liNum -= 1
												continue
											}
									}
							}

					}
			}

		### NOVA DATA EM FORMATO JAPONES - AAAA/MM/DD ###
		if (asFormatoData == "JP")
			{
				return StrZero(lsAno,4) lsSeparador StrZero(lsMes,2) lsSeparador StrZero(lsDia,2)
			}
			
		### NOVA DATA EM FORMATO AMERICANO - MM/DD/AAAA
		if (asFormatoData == "US")
			{
				return StrZero(lsMes,2) lsSeparador StrZero(lsDia,2) lsSeparador StrZero(lsAno,4)
			}
				
		return StrZero(lsDia,2) lsSeparador StrZero(lsMes,2) lsSeparador StrZero(lsAno,4)
}

function FormataCampo(FcTipo, FcCampo, FcTamanho, FcDecimais) {
	FcRetorno = ""
	gsub(/[ ]*$|^[ ]*/, "", FcCampo)
	#Pode ser utilizado para alguns sistemas
	#gsub("¯", "∫", FcCampo)
	#gsub("«", "√", FcCampo)
	#gsub("Ä", "«", FcCampo)
	#gsub("ê", "…", FcCampo)
	
	#Se o campo for vazio returna "NULO"
	if ((FcCampo == "")||(FcCampo == "<null>")) FcRetorno = "NULO"
	
	#Se n„o tiver informado o numero de decimais zera
	if (FcDecimais == "") FcDecimais == 0	
	#Se o formato for do tipo caracter
	if ((FcTipo == "char")||(FcTipo == "varchar")) {
		FcCampoTemp = FcCampo
		if (gsub(/[0]/, "", FcCampoTemp) == length(FcCampo))
			FcRtorno = "NULO"
		else
			FcRetorno = UpperCase(FcCampo)
	}
	#Se o formato for do tipo inteiro
	if ((FcTipo == "integer")||(FcTipo == "smallint")||(FcTipo == "tinyint")) {
		gsub(/[^0-9]/, "", FcCampo)
		FcRetorno = int(FcCampo)
		if (FcRetorno == 0)
			FcRetorno = "NULO"
	}
	#Se o formato for do tipo numerico (float)
	if ((FcTipo == "numeric")||(FcTipo == "double")) {
		if ( match(FcCampo ,"[,]" ) > 0 && match(FcCampo ,"[.]" ) > 0 )
			gsub("[.]", "", FcCampo)
		if ( match(FcCampo ,"[,]" ) > 0)
			gsub("[,]", ".", FcCampo)
		gsub(/[^0-9.]/, "", FcCampo)
		if ((int(soNumeros(FcCampo)) == 0)||(FcCampo == ""))
			FcRetorno = 0
		else
			FcRetorno = FcCampo
	}
	#Se o formato for do tipo data
	if (FcTipo == "date") {
		if ((FcCampo == "")||(FcCampo == "/  /"))
			FcRetorno = "NULO"
		else {
			if (isDate(FcCampo) != "NULO")
				FcRetorno = FormatDate(FcCampo)
		}
	}
	#Se tiver decimais
	if (FcDecimais > 0) {
		FcFormDec = "%." FcDecimais "f"
		FcRetorno = sprintf(FcFormDec, FcRetorno)
		gsub("[.]", ",", FcRetorno)
	}
	
	return FcRetorno
}

function TransformaPraDecimal( argValorInt ){
	
	valor_dec = ""
	valor_dec = argValorInt
	valor_dec = substr( valor_dec, 1, length( valor_dec ) - 2 ) "," substr( valor_dec, length( valor_dec ) - 1, 2 )
	
	return valor_dec
}

# RETORNA DATA INFORMADA DE ACORDO O PADR√O DESEJADO
function FormatDate(inDate, charSeparador, tpData) {
	# tpData = BR --> dd/mm/aaaa
	# tpData = US --> aaaa-mm-dd
	
	rtD = ""; 
	rtM = ""; 
	rtY = "";
	
	# SE SEPARADOR DA DATA FOR NULO
	if(charSeparador == "")
		charSeparador = "/"
	else
		charSeparador = charSeparador
	
	# SE TIPO DA DATA N√O FOR V¡LIDA
	if( (tpData == "") || ( (tpData != "BR") && (tpData != "US") ) )
		tpData = "BR"
	else
		tpData = tpData
	
	#Recebe a data atual para saber em que ano est·...
	fYear = getDate()
	split(fYear, sYear, "/")
	Year = substr(sYear[3], 1, 4)
	
	dateLength = length(inDate)
	
	# Se tiver separador
	if (match(inDate, charSeparador) > 0) {
		
		lqDate = split(inDate, qDate, charSeparador)
		
		if(tpData == "US"){
			#Se tem separador
			if (lqDate == 3) {
				rtY = qDate[1]
				rtM = qDate[2]
				rtD = qDate[3]
				#Se o ano for com dois digitos. Ex: 10
				if (length(rtY) == 2) {
					if ( rtY > (substr(Year,3) + 10))
						rtY = "19" rtY
					else
						rtY = "20" rtY
				}
			} 
			else if (lqDate == 2) {
				rtD = qDate[2]
				rtM = qDate[1]
				rtY = Year
			} 
			else
				return ""
			
			#Se o dia for maior que dois, ou seja, se tiver hor·rio tambÈm
			if( length(rtD) > 2 )
				rtD = substr(rtD, 1, 2)
			else
				rtD = rtD
		}
		else if(tpData == "BR"){
			#Se tem separador
			if (lqDate == 3) {
				rtD = qDate[1]
				rtM = qDate[2]
				rtY = qDate[3]
				#Se o ano for com dois digitos. Ex: 10
				if (length(rtY) == 2) {
					if ( rtY > (substr(Year,3) + 10))
						rtY = "19" rtY
					else
						rtY = "20" rtY
				}
			} 
			else if (lqDate == 2) {
				rtD = qDate[1]
				rtM = qDate[2]
				rtY = Year
			} 
			else
				return ""
			
			#Se o ano for maior que quatro, ou seja, se tiver hor·rio tambÈm
			if( length(rtY) > 4 )
				rtY = substr(rtY, 1, 4)
			else
				rtY = rtY
		}
		else
			return ""
	
	} 
	# Se n„o tiver separador
	else {
		if (dateLength == 4) {
			rtD = substr(inDate, 1, 2)
			rtM = substr(inDate, 3, 2)
			rtY = Year
		} else if (dateLength == 6) {
			rtD = substr(inDate, 1, 2)
			rtM = substr(inDate, 3, 2)
			rtY = "20" substr(inDate, 5, 2)
		} else if (dateLength == 8) {
			rtD = substr(inDate, 1, 2)
			rtM = substr(inDate, 3, 2)
			rtY = substr(inDate, 5, 4)
		} else
			return ""
	}
	
	#Retorna a data formatada
	return sprintf("%.2d/%.2d/%.4d", rtD, rtM, rtY)
}

# VERIFICA SE … UMA DATA V¡LIDA
function isDate(inDate) {
	iDay = 0; 
	iMonth = 0; 
	iYear = 0;
	
	iDate = FormatDate(inDate)
	
	if (iDate != "") {
		split(iDate, qDate, "/")
		iDay = qDate[1]
		iMonth = qDate[2]
		iYear = qDate[3]
		
		if ((iDay == 0)||(iDay > 31)) 
			return "NULO"
		
		if ((iMonth == 0)||(iMonth > 12)) 
			return "NULO"
		
		if (iYear == 0) 
			return "NULO"
		
		#Meses atÈ 30 -> 04, 06, 09, 11		
		if ( ( (iMonth == 4)||(iMonth == 6)||(iMonth == 9)||(iMonth == 11) ) && (iDay > 30) )
			return "NULO"
		
		#MÍs de fevereiro
		if ( (iMonth == 2) && (iDay > 29) )
			return "NULO"
		
		#Se chegou atÈ aqui a data È v·lida
		return inDate
	} 
	else 
		return "NULO"
}

# PEGA DATA ATUAL DO COMPUTADOR
function getDate() {
	"date /t" | getline tDate
	return tDate
}

# SOMA ANO
function SomaAno(asData,aiQuantiaAnos,asTipoData)

	{
		lsRetorno =""
		lsMeses30 = "01-05-07-08-10-12"
		lsAchou = 0
		lsJaRetornar = "N"
		lsDia    = ""
		lsMes    = ""
		lsAno    = ""
		lsMesAnt = ""
		asTipoData = IfElse(asTipoData == "","BR",asTipoData)
		
		if (asData == "")
			{
				return asData
			}

		if (aiQuantiaAnos == "")
			{
				return aiQuantiaAnos
			}


		if (asTipoData == "BR") ## TIPO BRASILEIRO DD/MM/AAAA - QUATRO DIGITOS NO ANO
			{
				lsDia = substr(asData,1,2)
				lsMes = substr(asData,4,2)
				lsAno = substr(asData,7,4)
			}
			
		if (asTipoData == "JP")  ## TIPO JAPONES DE DATA - AAAA/MM/DD
			{
				lsAno = substr(asData,1,4)
				lsMes = substr(asData,6,2)
				lsDia = substr(asData,9,2)
			}

		if (asTipoData == "US")  ## TIPO AMERICANO DE DATA - MM/DD/AAAA
			{
				lsMes = substr(asData,1,2)
				lsDia = substr(asData,4,2)
				lsAno = substr(asData,7,4)
			}

		lsAnoRetorno = lsAno
		lsAnoRetorno += aiQuantiaAnos
		lsAnoRetorno = lsAnoRetorno ""
		lsAnoRetorno = StrZero(lsAnoRetorno,4)

		if ((lsDia == "01") && (lsMes == "01"))
			{
				lsRetorno = "31/12/" lsAnoRetorno
				lsJaRetornar = "S"
			}
			
		if ((lsMes == "03") && (lsDia == "01"))
			{
				lsRetorno = "28/02/" lsAnoRetorno
				lsJaRetornar = "S"
			}
			
		if ((lsMes == "02") && (lsDia == "29"))
			{
				lsRetorno = "28/02/" lsAnoRetorno
				lsJaRetornar = "S"
			}
		
		if (lsJaRetornar == "N")
			{
				lsMesAnt = (lsMes-1)
				lsMesAnt = lsMesAnt ""
				lsMesAnt = StrZero(lsMesAnt,2)
				liAchou = match(lsMeses30,lsMesAnt)
			
				if (lsDia == "01")
					{
						if (liAchou == 0) ## SE FOR MES ANTERIOR FOR DE 31 DIAS
							{
								lsRetorno = "30/" lsMesAnt "/" lsAnoRetorno
							}
						else
							{
								lsMes = lsMesAnt
								lsRetorno = "31/" lsMesAnt "/" lsAnoRetorno
							}
					}
				else
					{
						lsDia -= 1
						lsDia = lsDia ""
						lsDia = StrZero(lsDia,2)
						lsRetorno = lsDia "/" lsMes "/" lsAnoRetorno
					}
			}
	
		if (asTipoData == "JP")  ## TIPO JAPONES DE DATA - AAAA/MM/DD
			{
				lsRetorno = substr(lsRetorno,7,4) "/" substr(lsRetorno,4,2) "/" substr(lsRetorno,1,2)
			}

		if (asTipoData == "US")  ## TIPO AMERICANO DE DATA - MM/DD/AAAA
			{
				lsRetorno = substr(lsRetorno,4,2) "/" substr(lsRetorno,1,2) "/" substr(lsRetorno,7,4)
			}
		return lsRetorno
}

# RETORNA TIPO DA INSCRI«√O
function tpInscricao(argInscricao){
	
	tpInscr = ""
	
	if(length(argInscricao) == 14)
		tpInscr = 1
	else if(length(argInscricao) == 11)
		tpInscr = 2
	else
		tpInscr = 3
	
	return tpInscr
}

# VERIFICA SE ANO … BISSEXTO OU N√O
function AnoBissexto(aiAno)
{
    liRetorno = ""
	
	if( ( (aiAno % 4 == 0) && (aiAno % 100 != 0) ) || (aiAno % 400 == 0) )
		liRetorno = 1
	else
		liRetorno = 0
    
	return liRetorno
}

# TRANSFORMA UMA DATA EM DIAS CONSIDERANDO OS ANOS ANTERIORES
function transformaDataEmDias(argData){
	
	qtdDias = 0
	dia_data = 0
	mes_data = 0
	ano_data = 0
	
	data_transforma = FormatDate(argData)
	split(argData, data_parametro, "/")
	
	dia_data = data_parametro[1]
	dia_data = FormataCampo("integer", dia_data, 30, 0)
	
	mes_data = data_parametro[2]
	mes_data = FormataCampo("integer", mes_data, 30, 0)
	
	ano_data = data_parametro[3]
	ano_data = FormataCampo("integer", ano_data, 30, 0)
	
	for(x = 0; x < ano_data; x++) { # pega total de dias dos ANOS ANTERIORES
		if ( AnoBissexto(x) == 1){
			qtdDias += 366 # se for bissexto incrementa 366
			continue
		}
		else{
			qtdDias += 365 # sen„o incrementa 365
			continue
		}	
	}
	
	for(x = 0; x < mes_data; x++) { # calcula dias dos MESES ANTERIORES
		
		if ( (x == 1) || (x == 3) || (x == 5) || (x == 7) || (x == 8) || (x == 10) || (x == 12) ){  # verifica se È 31
			qtdDias += 31
			continue
		}
		else if (x == 2) {

			if ( AnoBissexto(ano_data) == 1){
				qtdDias += 29 # se o ano for bissexto Fevereiro com 29 dias
				continue
			}
			else{
				qtdDias += 28 # sen„o Fevereiro com 28 dias
				continue
			}	
			continue
		} 
		else{ # se n„o for 31 Dias recebe 30
			qtdDias += 30
			continue
		}	
	}

	#adiciona os dias mensais
	qtdDias += dia_data

	return qtdDias
}

# RETORNA A DIFEREN«A EM DIAS DE DUAS DATAS INFORMADAS
function diferencaEmDiasEntreData(argData1, argData2){
	
	diferenca = 0
        
	# Quantidade de dias de uma data MENOS a quantidade de dias da outra
	diferenca = transformaDataEmDias(argData2) - transformaDataEmDias(argData1)

	if (diferenca < 0) # se deu negativo (menor - maior) multiplica por -1
		diferenca = diferenca * (-1)
	else
		diferenca = diferenca

	return diferenca
}

# TRANSFORMA HORAS EM MINUTOS
function transformaHoraEmMinuto(argHoras){
	
	minutos = 0
	minutos = argHoras
	minutos = soNumeros(minutos)
	minutos = FormataCampo("integer", minutos, 4, 0)
	minutos = ( minutos - ( minutos % 100 ) ) / 100 * 60 + ( minutos % 100 )
	
	return minutos
}

# TRANSFORMA MINUTOS EM HORAS
function transformaMinutoEmHora(argMinutos){
	
	horas = 0
	horas = argMinutos
	horas = FormataCampo("integer", horas, 15, 0)
	
	if(horas < 0)
		horas = horas * (-1)
	else
		horas = horas
	
	horas = ( horas - (horas % 60) ) / 60 * 100 + ( horas % 60 )
	
	if( length(horas) == 1)
		horas = "000" horas
	else if( length(horas) == 2)
		horas = "00" horas
	else if( length(horas) == 3 )
		horas = "0" horas
	else
		horas = horas
	
	return horas
}

# MONTA CPF/CNPJ
function MontaCPF_CNPJ(argCPF_CNPJ, argTipoInsc){
	
	cpf_cnpj_return = ""
	cpf_cnpj = argCPF_CNPJ
	
	if( argTipoInsc == "1" )
		cpf_cnpj_return = substr(cpf_cnpj, 1, 2) "." substr(cpf_cnpj, 3, 3) "." substr(cpf_cnpj, 6, 3) "/" substr(cpf_cnpj, 9, 4) "-" substr(cpf_cnpj, 13, 2)
	else if( argTipoInsc == "2" )
		cpf_cnpj_return = substr(cpf_cnpj, 1, 3) "." substr(cpf_cnpj, 3, 3) "." substr(cpf_cnpj, 6, 3) "-" substr(cpf_cnpj, 10, 2)
	else
		cpf_cnpj_return = cpf_cnpj
	
	return cpf_cnpj_return
}

# VERIFICA SE EH NULO
function isNull(argCampoNull){
	
	campo_nulo = ""
	
	if( argCampoNull == "" || argCampoNull == "." || argCampoNull == "0" || argCampoNull == "@" )
		campo_nulo = "NULO"
	else
		campo_nulo = argCampoNull
	
	return campo_nulo
}

function selecionaTAG( xml, tagini, tagfim ) {
	
	xmlcorreto = ""
	xmlcorreto = xml
	
	taginicial = ""
	taginicial = tagini
	
	tagfinal = ""
	tagfinal = tagfim
	
	TAG_INI = index( xmlcorreto, taginicial )
	TAG_TMP = substr( xmlcorreto, TAG_INI )
	TAG_FIM = index( TAG_TMP, tagfinal )
	
	return substr( xmlcorreto, TAG_INI + length(taginicial), TAG_FIM - length(tagfinal) )
}