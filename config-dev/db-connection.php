<?php
// Obtenemos el host de la variable de entorno, si no existe, usamos 'localhost'
$db_host = getenv('DB_HOST') ?: 'localhost';

return new PDO("mysql:host={$db_host};dbname=sample", "sampleuser", "samplepass", [PDO::ATTR_PERSISTENT => true]);