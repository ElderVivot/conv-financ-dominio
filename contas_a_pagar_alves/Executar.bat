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


echo %marcador%Apagando dados da pasta saidas.
if exist saida\* del /q saida\*
if exist temp\* del /q temp\*

echo %marcador%Filtrando linhas validas de pagamentos.
call bin\leArquivos.py
bin\awk95 -f bin\funcoes.awk -f bin\engine.awk

echo.
echo %marcador%Processo finalizado. Aperte qualquer tela para sair.

pause > nul