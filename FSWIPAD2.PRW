//Bibliotecas
#Include "TOTVS.ch"
#Include "TopConn.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} FSWIPAD2.PRW
@description Fonte Avalia��o TOTVS IP - 02/04 - Importar TXT 
@type User Function
@author Gustavo Ricci
@Date 24/10/2023

Premissas:

2. Desenvolver rotina para exportar 1 arquivo, em formato DBF/CTREE, com informa��es do cabe�alho e dos itens de pedidos de vendas.
Requisitos:

Grupo de Perguntas (Pedido De... Pedido At�).
DBF deve conter as seguintes colunas:
N�mero do pedido
Nome do cliente
Data de emiss�o
Quantidade total de itens
Valor total dos itens (soma dos Itens)
Pre�o m�dio unit�rio dos itens
Quantidades de volumes dos produtos
N�o utilizar SQL.
/*/
//-------------------------------------------------------------------

User Function FSWIPAD2()
	Local aArea     := GetArea()
	Private cArqOri := ""

	//Mostra o Prompt para selecionar arquivos
	cArqOri := tFileDialog( "Arquivo TXT (*.txt) ", 'Sele��o de Arquivos', , , .F., )
	//Se tiver o arquivo de origem
	If ! Empty(cArqOri)
		//Somente se existir o arquivo e for com a extens�o TXT
		If File(cArqOri) .And. Upper(SubStr(cArqOri, RAt('.', cArqOri) + 1, 3)) == 'TXT'
			Processa({|| ZImportar(cArqOri) }, "Importando...")
		Else
			MsgStop("Arquivo e/ou extens�o inv�lida!", "Aten��o")
		EndIf
	EndIf
	RestArea(aArea)
Return
