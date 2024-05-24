<?php

require 'config.php';
require 'vendor/autoload.php';

use phpseclib3\Net\SFTP;

// Carico l'ambiente corrente
$environment = getenv('ENVIRONMENT');

// Definisco le variabili in base all'ambiente
$uploadFolder = getenv('UPLOAD_FOLDER');
$recipient = getenv('RECIPIENT');
$ftpHost = getenv('FTP_HOST');
$ftpUsername = getenv('FTP_USERNAME');
$ftpPassword = getenv('FTP_PASSWORD');
$ftpPort = getenv('FTP_PORT');
$remotePath = getenv('FTP_PATH');
$dateLog = date('Ymd_His');
$logDir = 'C:\\VOC_2.0\\logs\\';
$logFile = "$logDir\\log_monthly_$dateLog.log";

// Funzione per loggare messaggi
function logMessage($message, $logFile) {
    $timestamp = date('Y-m-d H:i:s');
    $logMessage = "[$timestamp] $message\n";
    file_put_contents($logFile, $logMessage, FILE_APPEND);
}

// Inizio il logging
logMessage("Inizio del processo di caricamento.", $logFile);

// Creo una funzione per ricercare i log più vecchi di 3 mesi
function deleteOldLogs($logDir) {
    // Imposto il limite di tempo a 3 mesi fa
    $limit = strtotime('-3 months');

    // Apro la directory
    if ($handle = opendir($logDir)) {
        while (false !== ($file = readdir($handle))) {
            $filePath = $logDir . '/' . $file;

            // Salto i file speciali '.' e '..'
            if ($file == '.' || $file == '..') {
                continue;
            }

            // Verifico se è un file e non una directory
            if (is_file($filePath)) {
                // Ottengo la data di modifica del file
                $fileModTime = filemtime($filePath);

                // Se il file è più vecchio del limite, elimino il file
                if ($fileModTime < $limit) {
                    unlink($filePath);
                    echo "Log $filePath eliminato in quanto antecedente ad un mese\n";
                }
            }
        }
        closedir($handle);
    } else {
        echo "Impossibile aprire la cartella $logDir";
    }
}

// Eseguo la cancellazione dei log più vecchi di 1 mese
deleteOldLogs($logDir);

// Elimino tutti i file nella cartella upload per evitare di caricare file errati o vecchi
$oldUploadFiles = glob("$uploadFolder\\*.*");
foreach ($oldUploadFiles as $oldUploadFile) {
    if (is_file($oldUploadFile)) {
        unlink($oldUploadFile);
        logMessage("File $oldUploadFile eliminato.", $logFile);
    }
}

// Definisco le variabili concordate con Cerved
if($environment=="prod"){
	$switchout_custom_name = getenv('SWITCHOUT_PROD');
} else {
	$switchout_custom_name = getenv('SWITCHOUT_TEST');
}

// Definisco gli URL da cui attingere ai CSV
$switchout = getenv('URL_SWITCHOUT');

// Scarico i file csv e li salvo in tmp
logMessage("Download del file degli switchout > $switchout_custom_name", $logFile);
file_put_contents("$uploadFolder\\$switchout_custom_name", file_get_contents($switchout));

// Inizializzo le variabili per il controllo del corretto caricamento dei file
$sizeCheck = 0;
$filesUploaded = 0;

// Controllo se il file esiste ed è non vuoto
$uploadFiles = glob("$uploadFolder\\*.csv");
foreach ($uploadFiles as $file) {
    if (filesize($file) == 0) {
        $sizeCheck = 1;
        break;
    }
}

if ($sizeCheck == 1) {
    logMessage("Script terminato con errori: uno dei file $file è vuoto", $logFile);
    goto invio_email;
}

logMessage("Connessione al servizio SFTP", $logFile);

$expectedFiles = implode(' ', array_map('basename', $uploadFiles));

// Avvio il ciclo di caricamento dei file in area SFTP
if ($environment == "prod"){ // || $environment == "test"){
    $sftp = new SFTP($ftpHost, $ftpPort);
    if (!$sftp->login($ftpUsername, $ftpPassword)) {
        logMessage("Autenticazione fallita per l'utente $ftpUsername", $logFile);
        die("Autenticazione fallita per l'utente $ftpUsername");
    }
    
    foreach ($uploadFiles as $file) {
        // Controllo se il file esiste
        if (!file_exists($file)) {
            logMessage("Il file $file non esiste.", $logFile);
            continue;
        }
    
        // Verifico i permessi del file
        if (!is_readable($file)) {
            logMessage("Il file $file non è leggibile.", $logFile);
            continue;
        }
    
        // Rimuovo il percorso dal nome del file
        $myFile = basename($file);
        logMessage("Caricamento del file $myFile in $remotePath in corso...", $logFile);
    
        // Invio il file in area SFTP
        if ($sftp->put("$remotePath/$myFile", $file, SFTP::SOURCE_LOCAL_FILE)) {
            logMessage("File $myFile caricato con successo.", $logFile);
        } else {
            logMessage("Errore durante il caricamento del file $myFile.", $logFile);
        }
    }
    
    logMessage("Caricamento dei file completato.", $logFile);
		
	// Verifico se i file sono stati caricati correttamente
	logMessage("Verifica dei file caricati sull'area SFTP in corso...", $logFile);
    $allFilesUploaded = true;
    foreach ($uploadFiles as $file) {
        $fileCheck = basename($file);
        $remoteFile = "$remotePath/$fileCheck";
        if (!$sftp->stat($remoteFile)) {
            logMessage("Il file $fileCheck non è stato trovato sul server SFTP.", $logFile);
            $allFilesUploaded = false;
        } else {
            logMessage("Il file $fileCheck è stato trovato sul server SFTP.", $logFile);
        }
    }

    if (!$allFilesUploaded) {
        $filesUploaded = 1;
		goto invio_email;
    }
} else {
    logMessage("Ambiente non di produzione. Non sarà effettuato il caricamento su area SFTP.", $logFile);
}

invio_email:
// Carico le configurazioni del mailserver
$from = getenv('FROM');
ini_set('SMTP', getenv('SMTP_SERVER'));
ini_set('smtp_port', getenv('SMTP_PORT'));
ini_set('sendmail_from', $from);
$headers = "From: $from\r\n";
$headers .= "MIME-Version: 1.0\r\n";
$headers .= "Content-Type: multipart/mixed; boundary=\"boundary1\"\r\n";

// Creo una funzione per allegare il log alla mail
function encodeFileToBase64($filePath) {
    $fileContent = file_get_contents($filePath);
    return chunk_split(base64_encode($fileContent));
}

// Definisco il messaggio da inviare sulla base delle condizioni raggiunte
if ($sizeCheck == 0 && $filesUploaded == 0) {
    $subject = getenv('SUBJECT_MONTHLY_OK');
	$messageBody = "Ciao,<br /><br />il caricamento dei file <b><i>&egrave avvenuto correttamente</i></b>.<br /><br />I seguenti files sono stati caricati:<br />$expectedFiles<br /><br />Il Team IT di Eva Solutions";
    logMessage("Caricamento dei file avvenuto correttamente.", $logFile);
} else {
	$subject = getenv('SUBJECT_MONTHLY_ERR');
    $messageBody = "Ciao,<br /><br />il caricamento dei file <b><i>NON &egrave avvenuto correttamente</i></b>.<br /><br />In allegato trovi il log dell'esito del caricamento.<br /><br />Il Team IT di Eva Solutions";
    logMessage("Caricamento dei file NON avvenuto correttamente.", $logFile);
}

// Codifico il file di log in base64
$logFileContent = encodeFileToBase64($logFile);
$logFileName = basename($logFile);

// Costruisco il corpo del messaggio con allegato
$message = "--boundary1\r\n";
$message .= "Content-Type: text/html; charset=ISO-8859-1\r\n";
$message .= "Content-Transfer-Encoding: 7bit\r\n\r\n";
$message .= $messageBody . "\r\n\r\n";
$message .= "--boundary1\r\n";
$message .= "Content-Type: text/plain; name=\"$logFileName\"\r\n";
$message .= "Content-Transfer-Encoding: base64\r\n";
$message .= "Content-Disposition: attachment; filename=\"$logFileName\"\r\n\r\n";
$message .= $logFileContent . "\r\n\r\n";
$message .= "--boundary1--";

// Invio l'email
mail($recipient, $subject, $message, $headers);

logMessage("Email inviata a $recipient con oggetto $subject.", $logFile);

logMessage("Script terminato.", $logFile);

?>
