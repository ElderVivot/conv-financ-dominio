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
if exist saida\*.* del /q saida\*.*
if exist temp\*.* del /q temp\*.*
if exist naoprocessados\*.* del /q naoprocessados\*.*

echo - Filtrando linhas validas de pagamentos.
call bin\dividePdfUmaPaginaCada.py
call bin\leArquivosSispag.py
call bin\leArquivosPagtos.py
bin\awk95 -f bin\funcoes.awk -f bin\engine.awk -v _comp_ini=%comp_ini% -v _comp_fim=%comp_fim%
echo.

REM --> mesmo arquivo do bin\engine.py, mas este n�o precisa da instala��o do python
REM bin\dist\engine\engine.exe
call bin\engine.py

echo.
echo - Processo finalizado. Aperte qualquer tela para sair.

pause > nul