@echo off
set marcador=   � 

title Ajusta Arquivo

echo.
echo    �������   ������  ���    ��� �� ���   �� ��  ������ 
echo    �����߱� �����߱� ����  ���� �� ����  �� �� �����߱�
echo    ��    �� ��    �� ��߱���߱� �� ��߱� �� �� ��    ��
echo    ��    �� ��    �� �� ߱�� �� �� �� ߱��� �� ��    ��
echo    �������� ߱������ ��  ��  �� �� ��  ߱�� �� ߱������
echo    �������   ������  ��      �� �� ��   ��� ��  ������ 
echo                                        S I S T E M A S
echo. 

REM set /P comp_ini=- Competencia Inicial (MM/AAAA): 
REM set /P comp_fim=- Competencia Final (MM/AAAA): 

echo.
echo - Apagando dados da pasta saidas.
if exist saida\* del /q saida\*
if exist temp\* del /q temp\*

echo - Filtrando linhas validas de pagamentos.
REM call bin\leArquivos.py
call bin\dist\leArquivos\leArquivos.exe
REM bin\awk95 -f bin\funcoes.awk -f bin\engine.awk -v _comp_ini=%comp_ini% -v _comp_fim=%comp_fim%
REM echo.

REM --> mesmo arquivo do bin\engine.py, mas este n�o precisa da instala��o do python
REM call bin\engine.py
call bin\dist\engine\engine.exe

echo.
echo - Processo finalizado. Aperte qualquer tela para sair.

pause > nul