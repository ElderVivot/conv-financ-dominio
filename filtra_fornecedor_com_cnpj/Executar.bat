@echo off
set marcador=   ¯ 

title Ajusta Arquivo

echo.
echo    ±±±±±±±   ±±±±±±  ±±±    ±±± ±± ±±±   ±± ±±  ±±±±±± 
echo    ±±ßßßß±± ±±ßßßß±± ±±±±  ±±±± ßß ±±±±  ±± ßß ±±ßßßß±±
echo    ±±    ±± ±±    ±± ±±ß±±±±ß±± ±± ±±ß±± ±± ±± ±±    ±±
echo    ±±    ±± ±±    ±± ±± ß±±ß ±± ±± ±± ß±±±± ±± ±±    ±±
echo    ±±±±±±±ß ß±±±±±±ß ±±  ßß  ±± ±± ±±  ß±±± ±± ß±±±±±±ß
echo    ßßßßßßß   ßßßßßß  ßß      ßß ßß ßß   ßßß ßß  ßßßßßß 
echo                                        S I S T E M A S
echo. 

echo.
echo - Apagando dados da pasta saidas.
if exist saida\* del /q saida\*
if exist temp\* del /q temp\*

echo - Filtrando fornecedores validos.
bin\awk95 -f bin\funcoes.awk -f bin\engine.awk
echo.

echo - Processo finalizado. Aperte qualquer tela para sair.

pause > nul