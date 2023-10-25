//Bibliotecas

#include 'protheus.ch'
#include 'parmtype.ch'
#Include "TopConn.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} FSWIPAD2.PRW
@description Fonte Avaliação TOTVS IP - 02/04 - Criar CTREE exportando dados da SC5 e SC6.
@type User Function
@author Gustavo Ricci
@Date 24/10/2023

Premissas:

2. Desenvolver rotina para exportar 1 arquivo, em formato DBF/CTREE, com informações do cabeçalho e dos itens de pedidos de vendas.
Requisitos:

Grupo de Perguntas (Pedido De... Pedido Até).
DBF/CTREE deve conter as seguintes colunas:
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

	Private cArquivo := ""

	IF MSGYESNO("Esta rotina tem como finalidade extrair dados do pedido de vendas e gerar um arquivo formato ctree, deseja continuar ? ","Pergunta")

		//Chamando o cGetFile para pegar um arquivo txt ou xml, mostrando o servidor
		IF !PERGUNTE("FSWIPAD2",.T.)
			RETURN()
		ENDIF

		cArquivo:= "\system\FSWIPAD2.dtc"
		cIndice	:= "\system\FSWIPAD2" //indice do arquivo

		CriarDTC() //função que irá criar a tabela

		//Percorrer a pergunta de ate e colocar o pedido direto na tabela dtc
		DBSELECTAREA("SC5")
		SC5->(DBSETORDER(1))
		WHILE SC5->(!eof()) .AND. SC5->C5_NUM <= MV_PAR01 .AND. SC5->C5_NUM >= MV_PAR02
			GravarDTC(SC5->C5_NUM) //função que irá gravar algum conteudo na tabela
			SC5->(DBSKIP())
		END
	ENDIF

Return

//criar tabela
Static Function CriarDTC()

	Local aCampos := {}   //defino a variavel do tipo array para criar os campos

	if !File(cArquivo)
		aAdd(aCampos,{"C5_FILIAL"	,"C",  02,0})
		aAdd(aCampos,{"C5_NUM"		,"C",  TAMSX3("C5_NUM")[1] ,0})
		aAdd(aCampos,{"C5_NOME"  	,"C",  TAMSX3("A1_NOME")[1] ,0})
		aAdd(aCampos,{"C5_DATA" 	,"D",  08,0})		
		aAdd(aCampos,{"C5_QTDVEN"  	,"N",  TAMSX3("C6_QTDVEN")[1],TAMSX3("C6_QTDVEN")[2]})
		aAdd(aCampos,{"C5_TOTAL"  	,"N",  TAMSX3("C6_VALOR")[1],TAMSX3("C6_VALOR")[2]})
		aAdd(aCampos,{"C5_PRMED"  	,"N",  TAMSX3("C6_VALOR")[1],TAMSX3("C6_VALOR")[2]})
		aAdd(aCampos,{"C5_QTDVOL"  	,"N",  TAMSX3("C6_QTDVEN")[1],0}) //Qtd total de itens

		If SELECT("XC5") > 0
			XC5->(dbCloseArea())
		Endif
		//Criar o arquivo Ctree
		dbCreate(cArquivo,aCampos,"CTREECDX")
		dbUseArea(.T.,"CTREECDX",cArquivo,"XC5",.F.,.F.)
		IndRegua( "XC5", cIndice, "C5_FILIAL + C5_NUM",,,"NUMERO" )
		dbClearIndex()
		dbSetIndex(cIndice + OrdBagExt() )
		MsgInfo("Tabela Criada!")
	Endif
Return

//gravar na tabela
Static Function GravarDTC(cNumPed)
	//Verifico se o alias está aberto e fecho
	If ( SELECT("XC5") ) > 0
		dbSelectArea("XC5")
		XC5->(dbCloseArea())
	EndIf

	//abro a tabela
	dbUseArea( .T.,"CTREECDX", cArquivo,"XC5", .T., .F. )
	dbSelectArea("XC5")
	IndRegua( "XC5", cIndice, "C5_FILIAL + C5_NUM",,,"NUMERO" )
	dbClearIndex()
	dbSetIndex(cIndice + OrdBagExt() )

	dbSelectArea("XC5")
	XC5->(dbSetOrder(1))
	XC5->(dbGoTop())
	If( XC5->(!dbSeek(XFILIAL("SC5") + cNumPed)) )
		if RecLock("XC5",.T.)
			XC5->C5_FILIAL	:= XFILIAL("SC5")
			XC5->C5_NUM 		:= cNumPed
			XC5->C5_NOME	:= Posicione("SA1",1,XFILIAL("SA1")+SC5->C5_CLIENTE + SC5->C5_LOJACLI,"A1_NOME")
			XC5->C5_DATA  	:= dDatabase
			nTotValor := 0
			nQtdVol := 0
			nQtdVen := 0
			DBSELECTAREA("SC6")
			SC6->(DBSETORDER(1))
			WHILE SC6->(!eof()) .AND. SC6->C6_NUM == SC5->C5_NUM
				nTotValor += SC6->C6_VALOR //usado para gravar total em valor
				nQtdVen += SC6->C6_QTDVEN
				nQtdVol += 1 
				SC6->(DBSKIP())
			END
			if nQtdVol > 0 
				nMedPrc := nTotValor / nQtdVol  //Preço médio unitário dos itens
			ELSE
				nMedPrc := 0
			ENDIF
			XC5->C5_QTDVEN  := nQtdVen //Qtd Total de itens
			XC5->C5_TOTAL  	:= nTotValor //Valor total dos itens (soma dos Itens)
			XC5->C5_PRMED  	:= nMedPrc //Preço médio unitário dos itens
			XC5->C5_QTDVOL  := nQtdVol //Qtd total de volumes no pedido
			
			MsUnLock("XC5")
			MsgInfo("Registro Inserido","Sucesso")
		Else
			MsgStop("Ocorreu um erro","Erro")
		endif
	Endif
Return
