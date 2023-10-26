#include 'protheus.ch'
#include 'parmtype.ch'
#include 'totvs.ch'
#include 'restful.ch'
#INCLUDE 'FWMVCDef.ch'

//-------------------------------------------------------------------
/*/{Protheus.doc} WSPRODUTOS
@description Fonte Avaliação TOTVS IP - 04/04 - WebService para cadastro de produtos
@type wsrestful
@author Gustavo Ricci
Data : 25/10/2023
/*/
//-------------------------------------------------------------------
WSRESTFUL PRODUTOS DESCRIPTION "WebService para cadastro de produtos."

	WSDATA cprodid AS String

	WSMETHOD GET ConsultaProduto DESCRIPTION "Retorna o produto informado na URL" WSSYNTAX "/PRODUTOS"
	WSMETHOD POST InseriProduto DESCRIPTION "Inserir o produto informado" WSSYNTAX "/PRODUTOS"
	WSMETHOD PUT AlteraProduto DESCRIPTION "Alterar o produto informado" WSSYNTAX "/PRODUTOS"
	WSMETHOD DELETE ExcluiProduto DESCRIPTION "Exclui o produto informado" WSSYNTAX "/PRODUTOS"

END WSRESTFUL


//-------------------------------------------------------------------
/*/{Protheus.doc} GET
@description Metodo para requisicoes GET, para codigo de produto.
@type Webservice Method
Passar 1 parâmetro com cprodid como nome e seu respectivo valor
/*/
//-------------------------------------------------------------------

WSMETHOD GET ConsultaProduto WSRECEIVE cprodid WSSERVICE PRODUTOS
	local   cCodProd  := iif(valtype(self:cprodid) == "U","",self:cprodid)
	local   oProduto  := JSonObject():New()
	local   cResponse := ""

	DbSelectArea("SB1")
	SB1->( DbSetOrder(1) )
	If SB1->( !DbSeek( xFilial("SB1") + cCodProd ) )
		SetRestFault(404, EncodeUTF8("Produto não localizado."))
		return .F.
	EndIf

	DbSelectArea("SB5")
	SB5->( DbSetOrder(1) )
	If SB5->( !DbSeek( xFilial("SB5") + cCodProd ) )
		SetRestFault(404, EncodeUTF8("Complemento de Produto não localizado."))
		return .F.
	EndIf

	// Transforma SB1 em Json para resposta.
	oProduto := SB1ToJson()

	// Json to String
	cResponse := oProduto:toJson()

	// Define tipo de retorno.
	self:SetContentType('application/json')

	// Define resposta.
	self:SetResponse( EncodeUTF8( cResponse ) )

return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} 
@description Inclui produto enviado via JSON
@type Webservice Method
Exemplo do JSON usado:

{
    "codigo": "99099",
    "descricao": "TESTE WS",
    "tipo": "PA",
    "UM": "UN",
    "locpad": "01",
    "preco": 33.12,
    "data": "26/10/2023",
    "pesobruto": 10,
    "cor": "BRANCO",
    "comprimento": 223,
    "espessura": 123,
    "largura": 55
}

/*/
//-------------------------------------------------------------------
WSMETHOD POST InseriProduto WSRECEIVE WSSERVICE PRODUTOS

	local cCodProd
	local cError
	Local cJson     := Self:GetContent()
	local cAlias
	local lOk := .T.
	Local oModel
	Local oSB5Mod
	Local aErro := {}
	Local oSB1Mod //Modelo MVC
	Local oSB5Mod //MOdelo MVC

	Self:SetContentType("application/json")
	cCodProd := JsonObject():New()
	cError := cCodProd:fromJson( self:getContent() )
	lOk := .F.

	if Empty(cError)
		cAlias := Alias()
		dbselectArea("SB1")
		SB1->(DBSETORDER(1))

		if !SB1->( DbSeek( xFilial("SB1") + cCodProd["codigo"]) )
			oModel := FwLoadModel("MATA010")

			oModel:setOperation(MODEL_OPERATION_INSERT)
			oModel:Activate()

			//Pegando o model e setando os campos
			oSB1Mod := oModel:GetModel("SB1MASTER")
			oSB1Mod:SetValue("B1_COD"    , cCodProd["codigo"]     )
			oSB1Mod:SetValue("B1_DESC"   , cCodProd["descricao"]     )
			oSB1Mod:SetValue("B1_TIPO"   , cCodProd["tipo"]     )
			oSB1Mod:SetValue("B1_UM"     , "UN"   )
			oSB1Mod:SetValue("B1_LOCPAD" , "01"   )
			oSB1Mod:SetValue("B1_PRV1"     ,  cCodProd["preco"]   )
			IF VALTYPE(cCodProd["data"]) == "C"
				oSB1Mod:SetValue("B1_VIGENC"     , CTOD(cCodProd["data"])  )
			ELSEIF VALTYPE(cCodProd["data"]) == "D"
				oSB1Mod:SetValue("B1_VIGENC"     , cCodProd["data"]  )
			ELSE
				SetRestFault(400, "Campo data não esta vindo como data ou caracter")
			ENDIF
			oSB1Mod:SetValue("B1_ATIVO"     , "S"   )
			oSB1Mod:SetValue("B1_PESBRU"     , cCodProd["pesobruto"]  )
			oSB1Mod:SetValue("B1_COLOR"     , cCodProd["cor"]  )

			//Setando o complemento do produto
			oSB5Mod := oModel:GetModel("SB5DETAIL")
			If oSB5Mod != Nil
				oSB5Mod:SetValue("B5_CEME"   , PADR( cCodProd["descricao"] , TAMSX3("B5_CEME")[1] )     )
				oSB5Mod:SetValue("B5_COMPR"   , cCodProd["comprimento"]      )
				oSB5Mod:SetValue("B5_ESPESS"   , cCodProd["espessura"]     )
				oSB5Mod:SetValue("B5_LARG"   , cCodProd["largura"]     )
			EndIf

			if oModel:VldData()
				lOk := oModel:CommitData()

				cJson := '{"CODPRODUTO":"' + SB1->B1_COD + '"';
					+ ',"msg":"'  + "Sucesso"          + '"';
					+'}'

				::SetResponse(cJson)

			else
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
				//ConErr(oModel:GetErrorMessage()[MODEL_MSGERR_MESSAGE])
				SetRestFault(400,cMessage)
			endif

			oModel:Destroy()
			FreeObj(oModel)
		else
			SetRestFault(400, "Produto já cadastrado: " + SB1->B1_COD)
		endif
	else
		ConErr(cError)
		setRestFault(400)
	endif

return lOk

//-------------------------------------------------------------------
/*/{Protheus.doc} 
@description Altera produto enviado via JSON
@type Webservice Method

Exemplo do JSON utilizado:

{
    "codigo": "99099",
    "descricao": "TESTE WS ALTERADO",
    "tipo": "PA",
    "UM": "UN",
    "preco": 33.12,
    "pesobruto": 10,
    "cor": "PRETO",
    "comprimento": 223,
    "espessura": 123,
    "largura": 55
}
/*/
//-------------------------------------------------------------------
WSMETHOD PUT AlteraProduto WSRECEIVE WSSERVICE PRODUTOS

	local cCodProd
	local cError
	Local cJson     := Self:GetContent()
	local cAlias
	local lOk := .T.
	Local oModel
	Local oSB5Mod
	Local aErro := {}
	Local oSB1Mod //Modelo MVC
	Local oSB5Mod //MOdelo MVC

	Self:SetContentType("application/json")
	cCodProd := JsonObject():New()
	cError := cCodProd:fromJson( self:getContent() )
	lOk := .F.

	if Empty(cError)
		cAlias := Alias()
		dbselectArea("SB1")
		SB1->(DBSETORDER(1))

		if SB1->( DbSeek( xFilial("SB1") + cCodProd["codigo"]) )
			oModel := FwLoadModel("MATA010")

			oModel:setOperation(MODEL_OPERATION_UPDATE)
			oModel:Activate()

			//Pegando o model e setando os campos
			oSB1Mod := oModel:GetModel("SB1MASTER")
			oSB1Mod:SetValue("B1_DESC"   , cCodProd["descricao"]     )
			oSB1Mod:SetValue("B1_TIPO"   , cCodProd["tipo"]     )
			oSB1Mod:SetValue("B1_UM"     , "UN"   )
			oSB1Mod:SetValue("B1_PRV1"     ,  cCodProd["preco"]   )
			oSB1Mod:SetValue("B1_PESBRU"     , cCodProd["pesobruto"]  )
			oSB1Mod:SetValue("B1_COLOR"     , cCodProd["cor"]  )

			//Setando o complemento do produto
			oSB5Mod := oModel:GetModel("SB5DETAIL")
			If oSB5Mod != Nil
				oSB5Mod:SetValue("B5_CEME"   , PADR( cCodProd["descricao"] , TAMSX3("B5_CEME")[1] )     )
				oSB5Mod:SetValue("B5_COMPR"   , cCodProd["comprimento"]      )
				oSB5Mod:SetValue("B5_ESPESS"   , cCodProd["espessura"]     )
				oSB5Mod:SetValue("B5_LARG"   , cCodProd["largura"]     )
			EndIf

			if oModel:VldData()
				lOk := oModel:CommitData()

				cJson := '{"CODPRODUTO":"' + SB1->B1_COD + '"';
					+ ',"msg":"'  + "Alterado com Sucesso"          + '"';
					+'}'

				::SetResponse(cJson)

			else
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
				//ConErr(oModel:GetErrorMessage()[MODEL_MSGERR_MESSAGE])
				SetRestFault(400,cMessage)
			endif

			oModel:Destroy()
			FreeObj(oModel)
		else
			SetRestFault(400, "Produto não encontrado: " + SB1->B1_COD)
		endif
	else
		ConErr(cError)
		setRestFault(400)
	endif

return lOk


//-------------------------------------------------------------------
/*/{Protheus.doc} 
@description Deleta produto enviado via JSON
@type Webservice Method

Exemplo do JSON usado:
{
    "codigo": "99099"
}

/*/
//-------------------------------------------------------------------
WSMETHOD DELETE ExcluiProduto WSRECEIVE WSSERVICE PRODUTOS

	local cCodProd
	local cError
	Local cJson     := Self:GetContent()
	local cAlias
	local lOk := .T.
	Local oModel
	Local aErro := {}

	Self:SetContentType("application/json")
	cCodProd := JsonObject():New()
	cError := cCodProd:fromJson( self:getContent() )
	lOk := .F.

	if Empty(cError)
		cAlias := Alias()
		dbselectArea("SB1")
		SB1->(DBSETORDER(1))

		if SB1->( DbSeek( xFilial("SB1") + cCodProd["codigo"]) )
			oModel := FwLoadModel("MATA010")

			oModel:setOperation(MODEL_OPERATION_DELETE)
			oModel:Activate()

			If oModel:VldData()
				lOk := oModel:CommitData()

				cJson := '{"CODPRODUTO":"' + SB1->B1_COD + '"';
					+ ',"msg":"'  + "Excluido com Sucesso"          + '"';
					+'}'
				::SetResponse(cJson)
			Else
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
				//ConErr(oModel:GetErrorMessage()[MODEL_MSGERR_MESSAGE])
				SetRestFault(400,cMessage)
			EndIf

			oModel:Destroy()
			FreeObj(oModel)
		else
			SetRestFault(400, "Produto não encontrado: " + SB1->B1_COD)
		endif
	else
		ConErr(cError)
		setRestFault(400)
	endif

return lOk

//-------------------------------------------------------------------
/*/{Protheus.doc} SB1ToJson
@description Retorna objeto Json com registro SB1 posicionado.
@type static function
/*/
//-------------------------------------------------------------------
Static Function SB1ToJson()

	local   oJson   := JsonObject():New()

	oJson['codigo']      := AllTrim(SB1->B1_COD)
	oJson['descricao']   := AllTrim(SB1->B1_DESC)
	oJson['data']        := AllTrim(SB1->B1_VIGENC)
	oJson['status']      := AllTrim(SB1->B1_ATIVO)
	oJson['pesobruto']        := AllTrim(SB1->B1_PESBRU)
	oJson['comprimento']        := AllTrim(SB5->B5_COMPR)
	oJson['espessura']          := AllTrim(SB5->B5_ESPESS)
	oJson['largura']      := AllTrim(SB5->B5_LARG)
	oJson['cor']       := AllTrim(SB1->B1_COLOR)
	oJson['preco']    := AllTrim(SB1->B1_PRV1)
	oJson['tipo']      := AllTrim(SB1->B1_TIPO)

Return(oJson)
