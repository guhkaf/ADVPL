//Bibliotecas
#Include "TOTVS.ch"
#Include "TopConn.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} FSWIPAD2.PRW
@description Fonte Avaliação TOTVS IP - 02/04 - Importar TXT 
@type User Function
@author Gustavo Ricci
@Date 24/10/2023

Premissas:

2. Desenvolver rotina para exportar 1 arquivo, em formato DBF/CTREE, com informações do cabeçalho e dos itens de pedidos de vendas.
Requisitos:

Grupo de Perguntas (Pedido De... Pedido Até).
DBF deve conter as seguintes colunas:
Número do pedido
Nome do cliente
Data de emissão
Quantidade total de itens
Valor total dos itens (soma dos Itens)
Preço médio unitário dos itens
Quantidades de volumes dos produtos
Não utilizar SQL.
/*/
//-------------------------------------------------------------------

User Function FSWIPAD2()
	Local aArea     := GetArea()
	Private cArqOri := ""

	//Mostra o Prompt para selecionar arquivos
	cArqOri := tFileDialog( "Arquivo TXT (*.txt) ", 'Seleção de Arquivos', , , .F., )
	//Se tiver o arquivo de origem
	If ! Empty(cArqOri)
		//Somente se existir o arquivo e for com a extensão TXT
		If File(cArqOri) .And. Upper(SubStr(cArqOri, RAt('.', cArqOri) + 1, 3)) == 'TXT'
			Processa({|| ZImportar(cArqOri) }, "Importando...")
		Else
			MsgStop("Arquivo e/ou extensão inválida!", "Atenção")
		EndIf
	EndIf
	RestArea(aArea)
Return

