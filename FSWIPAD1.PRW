//Bibliotecas
#Include "TOTVS.ch"
#Include "TopConn.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} FSWIPAD1.PRW
@description Fonte Avaliação TOTVS IP - 01/04 - Importar TXT 
@type User Function
@author Gustavo Ricci
@Date 24/10/2023

Premissas:

Deverão ser importados apenas produtos ativos cuja data de cadastro seja posterior a junho de 2002.
Todos os produtos deverão ter como data de cadastro, no destino, a data da execução da rotina.
Os produtos incluídos via essa rotina deverão ter um flag no destino informando que foram cadastrados via importação automática.
Prever rotina de consistência com informação em tela para o usuário para um eventual ajuste no arquivo.
Produtos com o campo cCor não preenchidos na origem deverão apresentar no destino o dado “N/A”.
Ao final da importação bem-sucedida, a rotina deve apresentar uma mensagem com o número de produtos importados.
Não utilizar SQL.

Campo			Tipo			Pos. Inicial	Tamanho	Tipo Preenchimento	Observação
---------------------------------------------------------------------------------------------------------------------------------------------
Código do Produto	Numérico		1			5			Espaço
Nome do Produto		Alfanumérico	6			50			Espaço
Data Cadastro		Numérico		56			8			Sem preenchimento	Formato DDMMAAAA
Inativo			Numérico			64			1			Sem preenchimento	1-Inativo; 0-Ativo
Pesobruto		Numérico			65			9			Zero
Comprimento		Numérico			74			9			Zero
Espeçura		Numérico			83			9			Zero
Largura			Numérico			92			9			Zero
Cor				Literal				101			15			Espaço
Preço			Numérico			116			12			Espaço
Tipo			Literal				128			1			Sem preenchimento	S - Serviço; P - Produto


TABELA CUSTOMIZADA CRIADA ZB1

Campos criados conforme tabela acima com respectivo tipo
ZB1_FILIAL
ZB1_COD
ZB1_NOME
ZB1_STATUS
ZB1_PBRUTO
ZB1_COMP
ZB1_DATA
ZB1_ESPEC
ZB1_LARG
ZB1_COR
ZB1_PRECO
ZB1_TIPO
/*/
//-------------------------------------------------------------------

User Function FSWIPAD1()
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

Static Function ZImportar(cArqOri)
	Local cLinha := ""
	Local nTamArq:= 0
	Local NCONT := 0
	Local nLinhaAtu := 0
	Local dDatade := CTOD("01/07/2002")
	Local dDataLin
	Local nAtivo
	Local nCodProd
	Local cNome
	Local nPesoBr
	Local nComp
	Local nEspecura
	Local nLargura
	Local cCor
	Local nPreco
	Local cTipo
	Local x,i //Contadores do laço
	Local cAviso
	Private aDados := {}
	Private aError:= {}

	//| Abertura do arquivo texto                                           
	nHdl := fOpen(cArqOri)

	//| Verifica se foi possível abrir o arquivo                            
	If nHdl == -1
		cMsg := "O arquivo de nome "+cArqOri+" nao pode ser aberto! Verifique os parametros."
		MsgAlert(cMsg,"Atencao!")
		Return
	Endif

	//| Posiciona no Inicio do Arquivo                                      
	FSEEK(nHdl,0,0)

	//| Traz o Tamanho do Arquivo TXT                                       
	nTamArq:=FSEEK(nHdl,0,2)

	//| Posicona novamemte no Inicio                                        
	FSEEK(nHdl,0,0)

	//| Fecha o Arquivo                                                     
	fClose(nHdl)
	FT_FUse(cArqOri)  //abre o arquivo
	FT_FGOTOP()         //posiciona na primeira linha do arquivo
	nLinTot := FT_FLastRec() //Pego a ultima linha para saber o total de itens
	FT_FGOTOP()
	nLinhaAtu := 1 //Inicalizar contagem de linha em que esta o arquivo.

	ProcRegua(nLinTot)

	aDados:={}
	aError := {}

	While !FT_FEOF() //Ler todo o arquivo enquanto não for o final dele

		clinha := FT_FREADLN()
		nMinTam := Len(FT_FREADLN())

		IncProc('Importando Linha: ' + cValtoCHar(nLinhaAtu) )

		IF  nMinTam == 128 //Tamanho da linha cCorreta 128 caracteres caso contrario não importará a linha!
			dDataLin := STOD(SUBSTR(cLinha,56,2) + "/" + SUBSTR(cLinha,58,2) + "/" +SUBSTR(cLinha,60,4))
			nAtivo := SUBSTR(cLinha,64,1)
			nCodProd := SUBSTR(cLinha,1,5)
			cNome 	 := SUBSTR(cLinha,6,50)
			nPesoBr := VAL(SUBSTR(cLinha,65,9))
			nComp := VAL(SUBSTR(cLinha,74,9))
			nEspecura := VAL(SUBSTR(cLinha,83,9))
			nLargura := VAL(SUBSTR(cLinha,92,9))
			cCor := SUBSTR(cLinha,101,15)
			nPreco := VAL(SUBSTR(cLinha,116,12))
			cTipo := SUBSTR(cLinha,128,1)

			IF dDataLin < dDatade .OR. nAtivo <> "1" //Data posterior a junho 2002 e ATIVO senão é desconsiderado
				aadd(aError,{nLinhaAtu,"Esta fora da data de cadastro e/ou inativo"})
			ELSE
				IF EMPTY(cCor)
					cCor := "N/A"
				ENDIF
				aadd(aDados,{nCodProd,cNome,GravaData(dDataBase,.F.,5),nAtivo,nPesoBr,nComp,nEspecura,nLargura,cCor,nPreco,cTipo})
			ENDIF
		ELSE
			aadd(aError,{nLinhaAtu,"A estrutura do TXT precisa ter 128 caracteres na linha."})
		ENDIF
		nLinhaAtu += 1 //Pulo uma linha antes do skip para contagem da barra de progresso
		FT_FSKIP()
	EndDo
	//Fechando arquivo TXT
	FT_FUse()
	fClose(nHdl)

	//Verificando itens desconsiderados na inserção
	IF LEN(aError) >= 1
		cAviso := ""
		For x := 1 To Len(aError)
			cAviso += "Linha: "+cValToChar(aError[x,1])+" ---- "+aError[x,2] +CHR(10)+CHR(13)
		Next
		MsgInfo(cAviso, "Linhas Desconsideradas / Motivos")
	ENDIF
	
	//Verificando se o programa adiciono array para percCorre-lo e inserir
	IF LEN(aDados) >= 1 
		ProcRegua(len(aDados))
		For i := 1 to len(aDados)
			DBSELECTAREA("ZB1")
			ZB1->(dbSetOrder(1))//Filial + Codigo do produto
			IF !ZB1->(DBSEEK(XFILIAL("ZB1")+aDados[i,1])) //Se nao existe , senão existir então inclui
				RECLOCK("ZB1",.T.)
				ZB1->ZB1_FILIAL 	:= XFILIAL("ZB1")
				ZB1->ZB1_COD		:= VAL(aDados[i,1])
				ZB1->ZB1_NOME		:= aDados[i,2]
				ZB1->ZB1_DATA		:= VAL(aDados[i,3])
				ZB1->ZB1_STATUS		:= aDados[i,4]
				ZB1->ZB1_PBRUTO		:= aDados[i,5]
				ZB1->ZB1_COMP		:= aDados[i,6]
				ZB1->ZB1_ESPEC		:= aDados[i,7]
				ZB1->ZB1_LARG		:= aDados[i,8]
				ZB1->ZB1_COR		:= aDados[i,9]
				ZB1->ZB1_PRECO		:= aDados[i,10]
				ZB1->ZB1_TIPO		:= aDados[i,11]
				ZB1->ZB1_ORIGEM		:= "FSWIPAD1"
				ZB1->(MsUnlock()) //Gravando
				NCONT += 1 //Contador de item inserido
			ENDIF
			//alert(aDados[i,1] + " " + aDados[i,2]+ " " + aDados[i,3]+ " " + aDados[i,4]+ " " + aDados[i,5]+ " " + aDados[i,6]+ " " + aDados[i,7]+ " " + aDados[i,8])+ " " + aDados[i,9]+ " " + aDados[i,10]+ " " + aDados[i,11]
		Next
		Aviso("Contagem","Foram inseridos "+ALLTRIM(STR(nCont))+" produtos do arquivo txt.",{"Ok"},1)
	ELSE
		Aviso("Atenção","Sem dados!",{"Ok"},1)
	ENDIF

Return

