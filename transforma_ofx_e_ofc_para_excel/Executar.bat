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

echo %marcador%Filtrando linhas validas de pagamentos.
bin\awk95 -f bin\funcoes.awk -f bin\engine.awk

echo.
echo %marcador%Processo finalizado. Aperte qualquer tela para sair.

pause > nul