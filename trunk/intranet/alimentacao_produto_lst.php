<?php
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	*																	     *
	*	@author Prefeitura Municipal de Itaja�								 *
	*	@updated 29/03/2007													 *
	*   Pacote: i-PLB Software P�blico Livre e Brasileiro					 *
	*																		 *
	*	Copyright (C) 2006	PMI - Prefeitura Municipal de Itaja�			 *
	*						ctima@itajai.sc.gov.br					    	 *
	*																		 *
	*	Este  programa  �  software livre, voc� pode redistribu�-lo e/ou	 *
	*	modific�-lo sob os termos da Licen�a P�blica Geral GNU, conforme	 *
	*	publicada pela Free  Software  Foundation,  tanto  a vers�o 2 da	 *
	*	Licen�a   como  (a  seu  crit�rio)  qualquer  vers�o  mais  nova.	 *
	*																		 *
	*	Este programa  � distribu�do na expectativa de ser �til, mas SEM	 *
	*	QUALQUER GARANTIA. Sem mesmo a garantia impl�cita de COMERCIALI-	 *
	*	ZA��O  ou  de ADEQUA��O A QUALQUER PROP�SITO EM PARTICULAR. Con-	 *
	*	sulte  a  Licen�a  P�blica  Geral  GNU para obter mais detalhes.	 *
	*																		 *
	*	Voc�  deve  ter  recebido uma c�pia da Licen�a P�blica Geral GNU	 *
	*	junto  com  este  programa. Se n�o, escreva para a Free Software	 *
	*	Foundation,  Inc.,  59  Temple  Place,  Suite  330,  Boston,  MA	 *
	*	02111-1307, USA.													 *
	*																		 *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
require_once ("include/clsBase.inc.php");
require_once ("include/clsListagem.inc.php");
require_once ("include/clsBanco.inc.php");
require_once( "include/pmieducar/geral.inc.php" );
require_once( "include/alimentacao/geral.inc.php" );

class clsIndexBase extends clsBase
{
	function Formular()
	{
		$this->SetTitulo( "{$this->_instituicao} i-Educar - Produto " );
		$this->processoAp = "10002";
	}
}

class indice extends clsListagem
{
	/**
	 * Referencia pega da session para o idpes do usuario atual
	 *
	 * @var int
	 */
	var $pessoa_logada;

	/**
	 * Titulo no topo da pagina
	 *
	 * @var int
	 */
	var $titulo;

	/**
	 * Quantidade de registros a ser apresentada em cada pagina
	 *
	 * @var int
	 */
	var $limite;

	/**
	 * Inicio dos registros a serem exibidos (limit)
	 *
	 * @var int
	 */
	var $offset;
	
	var $ref_produto_grupo;
	var $nm_produto;

	function Gerar()
	{
		@session_start();
		$this->pessoa_logada = $_SESSION['id_pessoa'];
		session_write_close();

		$this->titulo = "Produto - Listagem";

		foreach( $_GET AS $var => $val ) // passa todos os valores obtidos no GET para atributos do objeto
			$this->$var = ( $val === "" ) ? null: $val;

		$this->addBanner( "imagens/nvp_top_intranet.jpg", "imagens/nvp_vert_intranet.jpg", "Intranet" );

		$obj_permissao = new clsPermissoes();
		
		$lista_busca = array(
					"Produto",
					"Grupo",
					"Fator Corre��o",
					"Fator Coc��o"
		);

		$this->addCabecalhos($lista_busca);

		$opcoes = array();
		$obj_produto_grupo = new clsAlimentacaoProdutoGrupo();
		$lista = $obj_produto_grupo->lista();
		
		$opcoes["0"] = "Todos"; 
		if( is_array( $lista ) && count( $lista ) )
		{
			foreach ( $lista AS $registro )
			{
				$opcoes[$registro["idpg"]] = $registro["descricao"];
			}
			
		}
		
		$this->campoLista( "ref_produto_grupo", "Grupo", $opcoes, $this->ref_produto_grupo,"",false,"","","",false );
		
		$obj_cardapio = new clsAlimentacaoProduto();
		$filtro_grupo = null;
		if($this->ref_produto_grupo > 0)
		{
			$filtro_grupo = $this->ref_produto_grupo;
		}
		$lista = $obj_cardapio->lista($filtro_grupo,$this->nm_produto);
		
		if( is_array( $lista ) && count( $lista ) )
		{
			foreach ( $lista AS $registro )
			{
				$obj_ref_grupo = new clsAlimentacaoProdutoGrupo();
				$det_ref_grupo = $obj_ref_grupo->lista($registro["ref_produto_grupo"]);
				$nm_grupo = $det_ref_grupo[0]["descricao"];

				
				$lista_busca = array();
				$lista_busca[] = "<a href=\"alimentacao_produto_det.php?idpro={$registro["idpro"]}\">{$registro["nm_produto"]}</a>";
				$lista_busca[] = "<a href=\"alimentacao_produto_det.php?idpro={$registro["idpro"]}\">{$nm_grupo}</a>";
				$lista_busca[] = "<a href=\"alimentacao_produto_det.php?idpro={$registro["idpro"]}\">{$registro["fator_correcao"]}</a>";
				$lista_busca[] = "<a href=\"alimentacao_produto_det.php?idpro={$registro["idpro"]}\">{$registro["fator_coccao"]}</a>";
				$this->addLinhas($lista_busca);
			}
			
		}

		if( $obj_permissao->permissao_cadastra( 10002, $this->pessoa_logada, 3 ) )
		{		
			$this->acao = "go(\"alimentacao_produto_cad.php\")";
			$this->nome_acao = "Novo";
		}
		
		$this->largura = "100%";
	}
}
// cria uma extensao da classe base
$pagina = new clsIndexBase();
// cria o conteudo
$miolo = new indice();
// adiciona o conteudo na clsBase
$pagina->addForm( $miolo );
// gera o html
$pagina->MakeAll();
?>