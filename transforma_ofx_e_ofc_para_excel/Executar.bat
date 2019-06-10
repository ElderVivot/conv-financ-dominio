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


echo %marcador%Apagando dados da pasta saidas.
if exist saida\* del /q saida\*

echo %marcador%Filtrando linhas validas de pagamentos.
bin\awk95 -f bin\funcoes.awk -f bin\engine.awk

echo.
echo %marcador%Processo finalizado. Aperte qualquer tela para sair.

pause > nul