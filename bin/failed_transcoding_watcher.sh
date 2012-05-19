#!/bin/bash
##############################################################################################
# failed_transcoding_watcher.sh : Traitement post-download
# Traitement des encodages qui ont échoué :
#  1 - Rien pour l'instant
# TODO : Envoi d'un email et changement de dossier
# Paramètres :
#  - $1 : nom du dossier des téléchargements de Deluge
# Les logs sont présents dans le fichier /var/lib/deluge/logs/failed_transcoding_watcher.log
##############################################################################################

# Inclusion des fonctions communes
. $(dirname $0)/functions.sh

# Récupération des paramètres
DELUGE_FOLDER=$1

# Constantes
LOG_FILE="$LOG_FOLDER/failed_transcoding_watcher.log"

# Initialisation
init "$DELUGE_FOLDER"
init_lock "$DELUGE_FOLDER/$FAILED_TRANSCODING_FOLDER"

# Boucle de parcours des fichiers du dossier "Encodage échoué"
for video in $(ls -a -1 -p "$DELUGE_FOLDER/$FAILED_TRANSCODING_FOLDER"|grep -v /); 
do
	# On ne traite pas les fichiers cachés (qui commencent par un point)
	if [ ! "$video" = ".${video:1}" ]; then
		echo "Envoi d'un email et changement de dossier"
	fi
done;

# Nettoyage
clean_lock "$DELUGE_FOLDER/$FAILED_TRANSCODING_FOLDER"

