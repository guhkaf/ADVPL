//Bibliotecas
#Include "TOTVS.ch"
#Include "TopConn.ch"
#INCLUDE 'FWMVCDef.ch'

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
	Local cLinha := "" //Variavel para armazenar linha full
	Local nTamArq:= 0 //Tamanho do arquivo
	Local NCONT := 0 //Contador de itens inseridos com sucesso
	Local nLinhaAtu := 0 //Linha atual txt
	Local dDatade := CTOD("01/07/2002") //Data a partir de quando pode inserir
	Local dDataLin //Data da linha do arquivo txt
	Local nAtivo //Ativo S ou N
	Local nCodProd //Codigo Produto
	Local cNome //Descrição Produto
	Local nPesoBr //Peso Bruto
	Local nComp //Comprimento
	Local nEspecura //Espessura 
	Local nLargura //Largura
	Local cCor //Cor do produto
	Local nPreco //Preço de venda
	Local cTipo //Tipo do produto P = Produto ou S = Serviço
	Local x,i //Contadores do laço
	Local cAviso // Aviso de itens desconsiderados
	Local cMessage //Mensagem para erro de inclusão
	Local lOk //Flag da inserção
	Private aDados := {} //Array com itens a inserir via txt
	Private aError:= {} //Array armazena todos itens desconsiderados para mostrar em msg
	Private oModel //Modelo MVC 
	Private oSB1Mod //Modelo MVC
	Private oSB5Mod //MOdelo MVC

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
				IF cTipo == "P"
					cTipo := "PA" //Material
				ELSE
					cTipo := "SV" //Serviço
				ENDIF
				aadd(aDados,{nCodProd,PADR( cNome, TAMSX3("B1_DESC")[1] ),GravaData(dDataBase,.F.,5),nAtivo,nPesoBr,nComp,nEspecura,nLargura,PADR( cCor, TAMSX3("B1_COLOR")[1] ),nPreco,cTipo})
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
			DBSELECTAREA("SB1")
			SB1->(DBSETORDER(1))
			IF !SB1->(DBSEEK(XFILIAL("SB1")+aDados[i,1])) //Senão existir cadastra caso contrario pule e va para o proximo

				//Pegando o modelo de dados, setando a operação de inclusão
				oModel := FWLoadModel("MATA010")
				oModel:SetOperation(3)
				oModel:Activate()

				//Pegando o model e setando os campos
				oSB1Mod := oModel:GetModel("SB1MASTER")
				oSB1Mod:SetValue("B1_COD"    , aDados[i,1]      )
				oSB1Mod:SetValue("B1_DESC"   , aDados[i,2]     )
				oSB1Mod:SetValue("B1_TIPO"   , aDados[i,11]     )
				oSB1Mod:SetValue("B1_UM"     , "UN"   )
				oSB1Mod:SetValue("B1_LOCPAD" , "01"   )
				oSB1Mod:SetValue("B1_PRV1"     , aDados[i,10]   )
				oSB1Mod:SetValue("B1_VIGENC"     , dDatabase   )
				oSB1Mod:SetValue("B1_ATIVO"     , "S"   )
				oSB1Mod:SetValue("B1_PESBRU"     , aDados[i,5]  )
				oSB1Mod:SetValue("B1_COLOR"     , aDados[i,9]  )

				//Setando o complemento do produto
				oSB5Mod := oModel:GetModel("SB5DETAIL")
				If oSB5Mod != Nil
					oSB5Mod:SetValue("B5_CEME"   , PADR( aDados[i,2] , TAMSX3("B5_CEME")[1] )     )
					oSB5Mod:SetValue("B5_DESCSER"   , "UTILIZADO ROTINA FSWIPAD1 PARA IMPORTAR PRODUTO"     )
					oSB5Mod:SetValue("B5_COMPR"   , aDados[i,6]     )
					oSB5Mod:SetValue("B5_ESPESS"   , aDados[i,7]     )
					oSB5Mod:SetValue("B5_LARG"   , aDados[i,8]     )
				EndIf
				//Se conseguir validar as informações
				If oModel:VldData()

					//Tenta realizar o Commit
					If oModel:CommitData()
						lOk := .T.
						nCont += 1

						//Se não deu certo, altera a variável para false
					Else
						lOk := .F.
					EndIf

				//Se não conseguir validar as informações, altera a variável para false
				Else
					lOk := .F.
				EndIf

				//Se não deu certo a inclusão, mostra a mensagem de erro
				If ! lOk
					//Busca o Erro do Modelo de Dados
					aErro := oModel:GetErrorMessage()

					//Monta o Texto que será mostrado na tela
					cMessage := "Id do formulário de origem:"  + ' [' + cValToChar(aErro[01]) + '], '
					cMessage += "Id do campo de origem: "      + ' [' + cValToChar(aErro[02]) + '], '
					cMessage += "Id do formulário de erro: "   + ' [' + cValToChar(aErro[03]) + '], '
					cMessage += "Id do campo de erro: "        + ' [' + cValToChar(aErro[04]) + '], '
					cMessage += "Id do erro: "                 + ' [' + cValToChar(aErro[05]) + '], '
					cMessage += "Mensagem do erro: "           + ' [' + cValToChar(aErro[06]) + '], '
					cMessage += "Mensagem da solução: "        + ' [' + cValToChar(aErro[07]) + '], '
					cMessage += "Valor atribuído: "            + ' [' + cValToChar(aErro[08]) + '], '
					cMessage += "Valor anterior: "             + ' [' + cValToChar(aErro[09]) + ']'

					//Mostra mensagem de erro
					lRet := .F.
					ALERT("Erro: " + cMessage)
				EndIf

				//Desativa o modelo de dados
				oModel:DeActivate()
			ENDIF

		Next
		Aviso("Contagem","Foram inseridos "+ALLTRIM(STR(nCont))+" produtos do arquivo txt.",{"Ok"},1)
	ELSE
		Aviso("Atenção","Sem dados!",{"Ok"},1)
	ENDIF

Return

