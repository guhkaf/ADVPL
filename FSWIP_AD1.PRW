//Bibliotecas
#Include "TOTVS.ch"
#Include "TopConn.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} WSCLIENTES
@description Fonte Avaliação TOTVS IP - 01/04 - Importar TXT 
@type User Function
@author Gustavo Ricci
@Date 24/10/2023
Premissas:

Deverão ser importados apenas produtos ativos cuja data de cadastro seja posterior a junho de 2002.
Todos os produtos deverão ter como data de cadastro, no destino, a data da execução da rotina.
Os produtos incluídos via essa rotina deverão ter um flag no destino informando que foram cadastrados via importação automática.
Prever rotina de consistência com informação em tela para o usuário para um eventual ajuste no arquivo.
Produtos com o campo COR não preenchidos na origem deverão apresentar no destino o dado “N/A”.
Ao final da importação bem-sucedida, a rotina deve apresentar uma mensagem com o número de produtos importados.
Não utilizar SQL.

Campo			Tipo			Pos. Inicial	Tamanho	Tipo Preenchimento	Observação
---------------------------------------------------------------------------------------------------------------------------------------------
Código do Produto	Numérico		1		5	Espaço
Nome do Produto		Alfanumérico	6		50	Espaço
Data Cadastro		Numérico		56		8	Sem preenchimento	Formato DDMMAAAA
Inativo			Numérico		    64		1	Sem preenchimento	1-Inativo; 0-Ativo
Pesobruto		Numérico		    65		9	Zero
Comprimento		Numérico		    74		9	Zero
Espeçura		Numérico		    83		9	Zero
Largura			Numérico		    92		9	Zero
Cor			    Literal			    101		15	Espaço
Preço			Numérico		    116		12	Espaço
Tipo			Literal			    128		1	Sem preenchimento	S - Serviço; P - Produto

/*/
//-------------------------------------------------------------------

User Function FSWIP_AD1()
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
	Local nLinha := 0
	Local nTamLinha := 0
	Local nTamArq:= 0
    Local lArq := .T.
    Private aDados := {}

	//+---------------------------------------------------------------------+
	//| Abertura do arquivo texto                                           |
	//+---------------------------------------------------------------------+
	nHdl := fOpen(cArqOri)

	If nHdl == -1
		IF FERROR()== 516
			ALERT("Feche a planilha que gerou o arquivo.")
		EndIF
	EndIf

	//+---------------------------------------------------------------------+
	//| Verifica se foi possível abrir o arquivo                            |
	//+---------------------------------------------------------------------+
	If nHdl == -1
		cMsg := "O arquivo de nome "+cArqOri+" nao pode ser aberto! Verifique os parametros."
		MsgAlert(cMsg,"Atencao!")
		Return
	Endif

	//+---------------------------------------------------------------------+
	//| Posiciona no Inicio do Arquivo                                      |
	//+---------------------------------------------------------------------+
	FSEEK(nHdl,0,0)

	//+---------------------------------------------------------------------+
	//| Traz o Tamanho do Arquivo TXT                                       |
	//+---------------------------------------------------------------------+
	nTamArq:=FSEEK(nHdl,0,2)

	//+---------------------------------------------------------------------+
	//| Posicona novamemte no Inicio                                        |
	//+---------------------------------------------------------------------+
	FSEEK(nHdl,0,0)

	//+---------------------------------------------------------------------+
	//| Fecha o Arquivo                                                     |
	//+---------------------------------------------------------------------+
	fClose(nHdl)
	FT_FUse(cArqOri)  //abre o arquivo
	FT_FGOTOP()         //posiciona na primeira linha do arquivo
	nTamLinha := Len(FT_FREADLN()) //Ve o tamanho da linha
	FT_FGOTOP()

	//+---------------------------------------------------------------------+
	//| Verifica quantas linhas tem o arquivo                               |
	//+---------------------------------------------------------------------+
	nLinhas := nTamArq/nTamLinha

	ProcRegua(nLinhas)

	aDados:={}
	While !FT_FEOF() //Ler todo o arquivo enquanto não for o final dele

		IncProc('Importando Linha: ' + Alltrim(Str(nCont)) )

		clinha := FT_FREADLN()

        //Valido os dados antes da montagem do acols para inserir corretamente os produtos 100%
        IF EMPTY(SUBSTR(cLinha,1,5)) .OR. (ValType(SUBSTR(cLinha,1,5)) <> "N") //Validando Codigo de produto posicao 1 a 5.
            ALERT("Corrija o arquivo TXT , o mesmo possui erro(s) de tipo de caracter na linha" +ALLTRIM(STR(nLinhas))+" no código do produto.")
            lArq := .F.
        ENDIF

        IF lArq
		    aadd(aDados,Separa(cLinha,";",.T.))
        else
                FT_FUse()
            	fClose(nHdl)
                Aviso("Atenção","Importação não ocorreu!",{"Ok"},1)
                Return()
        Endif
		FT_FSKIP()
	EndDo

	FT_FUse()
	fClose(nHdl)

	ProcRegua(len(aDados))

	For i := 1 to len(aDados)
		alert(aDados[i,1] + " " + aDados[i,2]+ " " + aDados[i,3]+ " " + aDados[i,4]+ " " + aDados[i,5]+ " " + aDados[i,6]+ " " + aDados[i,7]+ " " + aDados[i,8])+ " " + aDados[i,9]+ " " + aDados[i,10]+ " " + aDados[i,11]
	Next

	Aviso("Atenção","Importação com exito!",{"Ok"},1)

Return
