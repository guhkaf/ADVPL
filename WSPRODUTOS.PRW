#include 'protheus.ch'
#include 'parmtype.ch'
#include 'totvs.ch'
#include 'restful.ch'

//-------------------------------------------------------------------
/*/{Protheus.doc} WSPRODUTOS
@description WebService para cadastro de produtos
@type wsrestful
@author Gustavo Ricci

4. Desenvolver web service em ADVPL (protocolo SOAP ou REST) para manipulação CRUD do cadastro de produtos (SB1). A estrutura do XML ou JSON deve conter tipo de operação e os campos abaixo.
Informações adicionais:

Tipos de Operação

Inclusão de produto
Consulta pelo código do produto
Alteração pelo código do produto
Exclusão pelo código do produto
Campos do cadastro de produtos

Código do Produto
Nome do Produto
Data Cadastro
Inativo
Peso bruto
Comprimento
Espessura
Largura
Cor
Preço
Tipo
/*/
//-------------------------------------------------------------------
WSRESTFUL PRODUTOS DESCRIPTION "WebService para cadastro de produtos."

	WSDATA cprodid AS String
	WSDATA codigo AS String
	WSDATA descricao AS String
	WSDATA data as DATE
	WSDATA status as String
	WSDATA pesobruto as float
	WSDATA locpad as String
	WSDATA tipo as String
	WSDATA preco as float
	WSDATA cor as String
	WSDATA comprimento as float
	WSDATA espessura as float
	WSDATA largura as float

	WSMETHOD GET DESCRIPTION "Retorna o produto informado na URL" WSSYNTAX "/PRODUTOS"
	WSMETHOD POST DESCRIPTION "Inserir o produto informado" WSSYNTAX "/PRODUTOS"

END WSRESTFUL


//-------------------------------------------------------------------
/*/{Protheus.doc} GET
@description Metodo para requisicoes GET, para codigo de produto.
@type wsmethod
@author Gustavo Ricci
/*/
//-------------------------------------------------------------------

WSMETHOD GET WSRECEIVE cprodid WSSERVICE PRODUTOS
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
WSMETHOD POST WSRECEIVE nullparam WSSERVICE PRODUTOS

	local cCodProd
	local cError 
	local cJson
	local cAlias 
	local lOk := .T.
	local aAreaSB1 := {}
	local aAreaSB5 := {}

	Self:SetContentType("application/json")
	cCodProd := JsonObject():New()
	cError := cCodProd:fromJson( self:getContent() )
	lOk := .F.

	if Empty(cError)
		cAlias := Alias()
		aAreaSB1 := SB1->( GetArea() )
		aAreaSB5 := SB5->( GetArea() )

		if !SB1->( DbSeek( xFilial("SB1") + cCodProd["codigo"]) )
			oModel := FwLoadModel("MATA010")

			oModel:setOperation(MODEL_OPERATION_INSERT)
			oModel:Activate()

			oModel:setValue("SB1MASTER", "B1_COD", cCodProd["codigo"])
			oModel:setValue("SB1MASTER", "B1_DESC", cCodProd["descricao"])
			oModel:setValue("SB1MASTER", "B1_VIGENC", cCodProd["data"])
			oModel:setValue("SB1MASTER", "B1_ATIVO", cCodProd["status"])
			oModel:setValue("SB1MASTER", "B1_PESBRU", cCodProd["pesobruto"])
			oModel:setValue("SB1MASTER", "B1_LOCPAD", cCodProd["locpad"])
			oModel:setValue("SB1MASTER", "B1_TIPO", cCodProd["tipo"])
			oModel:setValue("SB1MASTER", "B1_PRV1", cCodProd["preco"])
			oModel:setValue("SB1MASTER", "B1_COLOR", cCodProd["cor"])

			//Setando o complemento do produto
			oSB5Mod := oModel:GetModel("SB5DETAIL")
			If oSB5Mod != Nil
				oSB5Mod:SetValue("B5_CEME"   , cCodProd["descricao"]     )
				oSB5Mod:SetValue("B5_COMPR"   , cCodProd["comprimento"]     )
				oSB5Mod:SetValue("B5_ESPESS"   , cCodProd["espessura"]    )
				oSB5Mod:SetValue("B5_LARG"   , cCodProd["largura"]     )
			EndIf

			if oModel:VldData()
				lOk := oModel:CommitData()

				cJson := '{"CODPRODUTO":"' + SB1->B1_COD + '"';
					+ ',"msg":"'  + "Sucesso"          + '"';
					+'}'

				::SetResponse(cJson)

			else
				ConErr(oModel:GetErrorMessage()[MODEL_MSGERR_MESSAGE])
				SetRestFault(400)
			endif

			oModel:Destroy()
			FreeObj(oModel)
		else
			SetRestFault(400, "Produto já cadastrado: " + SB1->B1_COD)
		endif

		RestAlias(aAreaSB1)
		RestAlias(aAreaSB5)

		if !Empty(cAlias)
			DBSelectArea(cAlias)
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
@author Julian de Almeida Santos
@since 14/07/2021
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
