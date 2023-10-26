//Bibliotecas

#include 'protheus.ch'
#include 'parmtype.ch'
#Include "TopConn.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} FSWIPAD3.PRW
@description Fonte Avaliação TOTVS IP - 03/04 - Criar 3 CTREE exportando dados da SC7 - Pedidos de Compras
@type User Function
@author Gustavo Ricci
@Date 24/10/2023
/*/
//-------------------------------------------------------------------

User Function FSWIPAD3()

	Private cArquivo := ""
	Private X
    Private CQUERY

	IF MSGYESNO("Esta rotina tem como finalidade extrair dados do pedido de compras e gerar 3 arquivos formato ctree, deseja continuar ? ","Pergunta")

		//Chamando o cGetFile para pegar um arquivo txt ou xml, mostrando o servidor
		IF !PERGUNTE("FSWIPAD3",.T.)
			RETURN()
		ENDIF

		FOR X:=1 to 3
			cArquivo:= "\system\EXEC03"+ALLTRIM(STR(X))+".dtc"
			cIndice	:= "\system\EXEC03"+ALLTRIM(STR(X)) //indice do arquivo
			CriarDTC(x) //função que irá criar a tabela
		NEXT X
	ENDIF

Return

//criar tabela
Static Function CriarDTC(x) //X significa qual estrutura sera usada

	Local aCampos := {}   //defino a variavel do tipo array para criar os campos
	IF X = 1
		if !File(cArquivo)
			aAdd(aCampos,{"C7_FILIAL"	,"C",  02,0})
			aAdd(aCampos,{"C7_NUM"		,"C",  TAMSX3("C7_NUM")[1] ,0})
			aAdd(aCampos,{"C7_EMISSAO" 	,"D",  08,0})
			aAdd(aCampos,{"C7_TOTAL"  	,"N",  TAMSX3("C7_TOTAL")[1],TAMSX3("C7_TOTAL")[2]})
			//Criar o arquivo Ctree
			dbCreate(cArquivo,aCampos,"CTREECDX")
		Endif

		nTotal := 0

		CQUERY := "SELECT SUM(C7_TOTAL) C7_TOTAL,C7_FILIAL,C7_NUM,C7_EMISSAO  FROM "+RETSQLNAME("SC7")+" WHERE D_E_L_E_T_ = '' AND C7_NUM BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' GROUP BY C7_FILIAL,C7_NUM,C7_EMISSAO  "

		TcQuery CQUERY Alias "TMP" New

		TcSetField("TMP","C7_EMISSAO","D")

		TMP->(DBGOTOP())

		WHILE !TMP->(EOF())

			If ( SELECT("XC7") ) > 0
				dbSelectArea("XC7")
				XC7->(dbCloseArea())
			EndIf

			dbUseArea( .T.,"CTREECDX", cArquivo,"XC7", .T., .F. )
			IndRegua( "XC7", cIndice, "C7_FILIAL + C7_NUM",,,"NUMERO" )
			dbClearIndex()
			dbSetIndex(cIndice + OrdBagExt() )
			If( XC7->(!dbSeek(XFILIAL("XC7") + TMP->C7_NUM )) )
				RecLock("XC7",.T.)
				XC7->C7_FILIAL := TMP->C7_FILIAL
				XC7->C7_NUM := TMP->C7_NUM
				XC7->C7_EMISSAO := TMP->C7_EMISSAO
				XC7->C7_TOTAL := TMP->C7_TOTAL
				XC7->(MSUNLOCK())
			ENDIF
			TMP->(DBSKIP())
		END
	ELSEIF X = 2
		if !File(cArquivo)
			aAdd(aCampos,{"C7_PRODUTO"	,"C",  TAMSX3("C7_PRODUTO")[1] ,0})
			aAdd(aCampos,{"C7_ITEM" 	,"C",  TAMSX3("C7_ITEM")[1],0})
			aAdd(aCampos,{"C7_QUANT"  	,"N",  TAMSX3("C7_QUANT")[1],TAMSX3("C7_QUANT")[2]})
			aAdd(aCampos,{"C7_PRECO"  	,"N",  TAMSX3("C7_PRECO")[1],TAMSX3("C7_PRECO")[2]})
			aAdd(aCampos,{"C7_TOTAL"  	,"N",  TAMSX3("C7_TOTAL")[1],TAMSX3("C7_TOTAL")[2]})
			//Criar o arquivo Ctree
			dbCreate(cArquivo,aCampos,"CTREECDX")
		Endif

		CQUERY := " SELECT C7_PRODUTO,C7_ITEM,C7_PRECO,C7_QUANT,C7_TOTAL FROM "+RETSQLNAME("SC7")+" WHERE D_E_L_E_T_ = '' AND C7_NUM BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' "

		If ( SELECT("TMP") ) > 0
			dbSelectArea("TMP")
			TMP->(dbCloseArea())
		EndIf

		TcQuery CQUERY Alias "TMP" New

		TMP->(DBGOTOP())

		WHILE TMP->(!EOF())
			If ( SELECT("XC7") ) > 0
				dbSelectArea("XC7")
				XC7->(dbCloseArea())
			EndIf
			dbUseArea( .T.,"CTREECDX", cArquivo,"XC7", .T., .F. )
			IndRegua( "XC7", cIndice, "C7_ITEM+C7_PRODUTO",,,"ITEM+PRODUTO" )
			dbClearIndex()
			dbSetIndex(cIndice + OrdBagExt() )
			If( XC7->(!dbSeek(XFILIAL("XC7") + TMP->C7_ITEM+TMP->C7_PRODUTO )) )
				RecLock("XC7",.T.)
				XC7->C7_PRODUTO := TMP->C7_PRODUTO
				XC7->C7_ITEM := TMP->C7_ITEM
				XC7->C7_QUANT := TMP->C7_QUANT
				XC7->C7_PRECO := TMP->C7_PRECO
				XC7->C7_TOTAL := TMP->C7_TOTAL
				XC7->(MSUNLOCK())
			ENDIF
			TMP->(DBSKIP())
		END
	ELSEIF X = 3
		if !File(cArquivo)
			aAdd(aCampos,{"C7_PRODUTO"	,"C",  TAMSX3("C7_PRODUTO")[1] ,0})
			aAdd(aCampos,{"C7_DESC" 	,"C",  TAMSX3("B1_DESC")[1],0})
			aAdd(aCampos,{"C7_PRECO"  	,"N",  TAMSX3("C7_PRECO")[1],TAMSX3("C7_PRECO")[2]})
			//Criar o arquivo Ctree
			dbCreate(cArquivo,aCampos,"CTREECDX")
		Endif

		CQUERY := " SELECT C7_PRODUTO,C7_PRECO,B1_DESC  FROM "+RETSQLNAME("SC7")+" AS C7 "
		CQUERY += " INNER JOIN "+RETSQLNAME("SB1")+" AS B1 "
		CQUERY += " ON B1_COD = C7_PRODUTO "
		CQUERY += " AND B1.D_E_L_E_T_ = '' "
		CQUERY += " WHERE C7.D_E_L_E_T_ = '' AND C7_NUM BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' "

		If ( SELECT("TMP") ) > 0
			dbSelectArea("TMP")
			TMP->(dbCloseArea())
		EndIf

		TcQuery CQUERY Alias "TMP" New

		TMP->(DBGOTOP())

		WHILE TMP->(!EOF())
			If ( SELECT("XC7") ) > 0
				dbSelectArea("XC7")
				XC7->(dbCloseArea())
			EndIf
			dbUseArea( .T.,"CTREECDX", cArquivo,"XC7", .T., .F. )
			IndRegua( "XC7", cIndice, "C7_PRODUTO",,,"PRODUTO" )
			dbClearIndex()
			dbSetIndex(cIndice + OrdBagExt() )
			If( XC7->(!dbSeek(XFILIAL("XC7") + TMP->C7_PRODUTO )) )
				RecLock("XC7",.T.)
				XC7->C7_PRODUTO := TMP->C7_PRODUTO
				XC7->C7_DESC := TMP->B1_DESC
				XC7->C7_PRECO := TMP->C7_PRECO
				XC7->(MSUNLOCK())
			ENDIF
			TMP->(DBSKIP())
		END
	ENDIF
Return
