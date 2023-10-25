//Bibliotecas

#include 'protheus.ch'
#include 'parmtype.ch'

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

	//cGetFile("Descrição |*.extensao", "Titulo")

	IF MSGYESNO("Esta rotina tem como finalidade extrair dados do pedido de vendas e gerar um arquivo formato ctree, deseja continuar ? ","Pergunta")

	Private cArquivo:= "\system\tabela123.dtc" //Gera o nome do arquivo 
	Private cIndice	:= "\system\tabela123" //indice do arquivo
 
    CriarDTC() //função que irá criar a tabela
    
    GravarDTC('000001') //função que irá gravar algum conteudo na tabela
        
    MsgInfo( LerDTC('000001') ,'Leitura de tabela DTC')   //ler o conteudo gravado

Return

//criar tabela
Static Function CriarDTC() 
   	Local aCampos := {}   //defino a variavel do tipo array para criar os campos                        
   	
   	if !File(cArquivo)
	   	aAdd(aCampos,{"REV_FILIAL"	,"C",  02,0})  
	   	aAdd(aCampos,{"REV_COD"		,"C",  06,0})  
	   	aAdd(aCampos,{"REV_DATA"   	,"D",  08,0})   
	   	aAdd(aCampos,{"REV_CONTA"  	,"N",  09,0})   
	   	
		If SELECT("REV") > 0
			REV->(dbCloseArea())
		Endif
		
		//Criar o arquivo Ctree
		dbCreate(cArquivo,aCampos,"CTREECDX")
		dbUseArea(.T.,"CTREECDX",cArquivo,"REV",.F.,.F.)
		IndRegua( "REV", cIndice, "REV_FILIAL + REV_COD",,,"CODIGO" )
		dbClearIndex()
		dbSetIndex(cIndice + OrdBagExt() )
		MsgInfo("Tabela Criada!")
	Endif
Return

//gravar na tabela
Static Function GravarDTC(cCodigo)
	//Verifico se o alias está aberto e fecho
	If ( SELECT("REV") ) > 0
		dbSelectArea("REV")
		REV->(dbCloseArea())
	EndIf
	
	//abro a tabela
	dbUseArea( .T.,"CTREECDX", cArquivo,"REV", .T., .F. )
	dbSelectArea("REV")
	IndRegua( "REV", cIndice, "REV_FILIAL + REV_COD",,,"CODIGO" )
	dbClearIndex()
	dbSetIndex(cIndice + OrdBagExt() )
	
    dbSelectArea("REV")
	REV->(dbSetOrder(1))
	REV->(dbGoTop())
	If( REV->(!dbSeek('01' + cCodigo)) )
	    if RecLock("REV",.T.)		     
		     REV->REV_FILIAL	:= '01'			     
		     REV->REV_COD 		:= cCodigo
		     REV->REV_DATA  	:= dDatabase
		     REV->REV_CONTA 	:= 1
		     MsUnLock("REV") 
		     MsgInfo("Registro Inserido","Sucesso")
		Else
			MsgStop("Ocorreu um erro","Erro")
	    endif                            
	Else
	    if RecLock("REV",.F.)		     
		     REV->REV_DATA  	:= dDatabase
		     REV->REV_CONTA 	:= 2
		     MsUnLock("REV")                
		     MsgInfo("Registro Alterado","Sucesso")
		Else
			MsgStop("Ocorreu um erro","Erro")
	    endif                            
    Endif
Return
