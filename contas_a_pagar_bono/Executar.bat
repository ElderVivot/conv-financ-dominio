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

set /P comp_ini=- Competencia Inicial (MM/AAAA): 
set /P comp_fim=- Competencia Final (MM/AAAA): 

echo.
echo - Apagando dados da pasta saidas.
if exist saida\* del /q saida\*
if exist temp\* del /q temp\*

echo - Filtrando linhas validas de pagamentos.
bin\awk95 -f bin\funcoes.awk -f bin\engine.awk -v _comp_ini=%comp_ini% -v _comp_fim=%comp_fim%
echo.

REM --> mesmo arquivo do bin\engine.py, mas este n�o precisa da instala��o do python
bin\dist\engine\engine.exe
REM call bin\engine.py

echo.
echo - Processo finalizado. Aperte qualquer tela para sair.

pause > nul