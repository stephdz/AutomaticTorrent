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
. functions.sh

# Constantes
LOG_FILE="$LOG_FOLDER/torrent_completed.log"

# Récupération des paramètres
torrentid=$1
torrentname=$2
torrentpath=$3

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

