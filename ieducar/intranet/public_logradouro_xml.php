<?php

header('Content-type: text/xml');

require_once 'include/clsBanco.inc.php';
require_once 'include/funcoes.inc.php';
require_once 'Portabilis/Utils/DeprecatedXmlApi.php';

Portabilis_Utils_DeprecatedXmlApi::returnEmptyQueryUnlessUserIsLoggedIn();

echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<query xmlns=\"sugestoes\">\n";
if (is_numeric($_GET['mun'])) {
    $db = new clsBanco();
    $db->Consulta(
        "
            SELECT idlog, nome
            FROM public.logradouro
            WHERE idmun = '{$_GET['mun']}'
            ORDER BY nome ASC
        "
    );

    while ($db->ProximoRegistro()) {
        list($cod, $nome) = $db->Tupla();
        echo " <logradouro idlog=\"{$cod}\">{$nome}</logradouro>\n";
    }
}
echo '</query>';
