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


echo - Apagando dados da pasta saidas.
if exist saida\* del /q saida\*
if exist temp\* del /q temp\*

echo - Filtrando linhas validas de pagamentos.
call bin\leArquivos.py
bin\awk95 -f bin\funcoes.awk -f bin\engine.awk
echo.
call bin\engine.py

echo.
echo - Processo finalizado. Aperte qualquer tela para sair.

pause > nul