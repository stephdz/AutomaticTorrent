#!/bin/bash
##############################################################################################
# torrent_completed.sh : Traitement post-download via Deluge (plug-in Execute)
# Paramètres :
#  - $1 : id du torrent
#  - $2 : nom du fichier torrent
#  - $3 : dossier où est présent le résultat
# Les logs sont présents dans le fichier /var/lib/deluge/logs/torrent_completed.log
##############################################################################################

# Inclusion des fonctions communes
. $(dirname $0)/functions.sh

# Constantes
LOG_FILE="$LOG_FOLDER/torrent_completed.log"

# Récupération des paramètres et contrôles
torrentid=$1
torrentname=$2
torrentpath=$3
if [ "$1" = "" -o "$2" = "" -o "$3" = "" ]; then
	echo_log "$LOG_FILE" "$torrentname" "Paramètres invalides :"
	echo_log "$LOG_FILE" "$torrentname" " - 1 : id du torrent (=$torrentid)"
	echo_log "$LOG_FILE" "$torrentname" " - 2 : nom du fichier torrent (=$torrentname)"
	echo_log "$LOG_FILE" "$torrentname" " - 3 : dossier où est présent le résultat (=$torrentpath)"
	exit
fi
if [ ! -s "$torrentpath/$torrentname" ]; then
	echo_log "$LOG_FILE" "$torrentname" "Le fichier n'existe pas :"
	echo_log "$LOG_FILE" "$torrentname" " - ID : $torrentid"
	echo_log "$LOG_FILE" "$torrentname" " - Nom : $torrentname"
	echo_log "$LOG_FILE" "$torrentname" " - Chemin : $torrentpath"
	exit
fi

# Initialisation
init "$torrentpath"

# Ajout de logs
log "$LOG_FILE" "$torrentname" "Nouveau torrent terminé :"
log "$LOG_FILE" "$torrentname" " - ID : $torrentid"
log "$LOG_FILE" "$torrentname" " - Nom : $torrentname"
log "$LOG_FILE" "$torrentname" " - Chemin : $torrentpath"

# Déplacement du fichier dans le dossier "A traiter"
completedfile="$torrentpath/$TODO_FOLDER/$torrentname"
mv "$torrentpath/$torrentname" "$completedfile"
log "$LOG_FILE" "$torrentname" "Fichier déplacé de $torrentpath/$torrentname vers $completedfile"

# Fin de traitement post-download, on supprime le torrent de la liste
deluge-console rm $torrentid
log "$LOG_FILE" "$torrentname" "Fin de traitement pour le fichier : $torrentname"

# Exécution du script de traitement des fichiers téléchargés
todo_watcher.sh "$torrentpath"
