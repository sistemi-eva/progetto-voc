<?php

// Ambiente (prod, test)
putenv('ENVIRONMENT=test');

// Standardizzazione filename
$data = date("ymd");
putenv("SUBENTRO_PROD=filename.csv");
putenv("SWITCHIN_PROD=filename.csv");
putenv("VOLTURA_PROD=filename.csv");
putenv("SWITCHOUT_PROD=filename.csv");
putenv("SUBENTRO_TEST=TEST_filename.csv");
putenv("SWITCHIN_TEST=TEST_filename.csv");
putenv("VOLTURA_TEST=TEST_filename.csv");
putenv("SWITCHOUT_TEST=TEST_filename.csv");

// Percorsi delle cartelle
putenv('UPLOAD_FOLDER=/path/to/upload/foler');

// Configurazione FTP
putenv('FTP_HOST=hostname');
putenv('FTP_USERNAME=username');
putenv('FTP_PASSWORD=password');
putenv('FTP_PORT=22');
putenv('FTP_PATH=/path/to/sftp/folder');

// Link ai CSV da inviare a Payline
putenv('URL_SUBENTRO=https://url.to.csv');
putenv('URL_SWITCHIN=https://url.to.csv');
putenv('URL_VOLTURA=https://url.to.csv');
putenv('URL_SWITCHOUT=https://url.to.csv');

// Configurazioni del mailserver
putenv('FROM=mittente');
putenv('SUBJECT_WEEKLY_OK=subject');
putenv('SUBJECT_WEEKLY_ERR=subject');
putenv('SUBJECT_MONTHLY_OK=subject');
putenv('SUBJECT_MONTHLY_ERR=subject');
putenv('SMTP_SERVER=mailserver');
putenv('SMTP_PORT=25');
putenv('RECIPIENT=destinatario');

?>