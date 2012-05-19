#!/bin/bash
##############################################################################################
# finished_watcher.sh : Traitement post-download
# Traitement des fichiers dont les traitements sont terminés
#  1 - Rien pour l'instant
# TODO : Rangement des vidéos (séries et films) et copie sur la Freebox selon certains critères
# Paramètres :
#  - $1 : nom du dossier des téléchargements de Deluge
# Les logs sont présents dans le fichier /var/lib/deluge/logs/finished_watcher.log
##############################################################################################

# Inclusion des fonctions communes
. $(dirname $0)/functions.sh

# Récupération des paramètres
DELUGE_FOLDER=$1

# Constantes
LOG_FILE="$LOG_FOLDER/finished_watcher.log"

# Initialisation
init "$DELUGE_FOLDER"
init_lock "$DELUGE_FOLDER/$COMPLETED_FOLDER"

# Boucle de parcours des fichiers du dossier "Fini"
for video in $(ls -a -1 -p "$DELUGE_FOLDER/$COMPLETED_FOLDER"|grep -v /); 
do
	# On ne traite pas les fichiers cachés (qui commencent par un point)
	if [ ! "$video" = ".${video:1}" ]; then
		echo "Rangement des vidéos (séries et films) et copie sur la Freebox selon certains critères"
	fi
done;

# Nettoyage
clean_lock "$DELUGE_FOLDER/$COMPLETED_FOLDER"

