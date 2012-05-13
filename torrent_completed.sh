#!/bin/bash
##############################################################################################
# torrent_completed.sh : Traitement post-download via Deluge (plug-in Execute)
# Paramètres :
#  - $1 : id du torrent
#  - $2 : nom du fichier torrent
#  - $3 : dossier où est présent le résultat
# Les logs sont présents dans le fichier /var/log/deluge/torrent_completed.log
##############################################################################################


# Constantes
LOG_FOLDER=/var/log/deluge
LOG_FILE="$LOG_FOLDER/torrent_completed.log"
COMPLETED_FOLDER="A traiter"
SUDO_EXEC=gksudo
SUBTITLE_EXTENSION=srt

# Récupération des paramètres
torrentid=$1
torrentname=$2
torrentpath=$3


##############################################################################################
# FONCTIONS
##############################################################################################

# Initialisation de l'outil
init() {

	# Création du dossier de log
	if [ ! -e "$LOG_FOLDER" ]; then
		log "Création du dossier de log : $LOG_FOLDER"
		$SUDO_EXEC mkdir "$LOG_FOLDER"
		$SUDO_EXEC chmod 777 "$LOG_FOLDER"
	fi

	# Création du dossier Fini
	if [ ! -e "$torrentpath/$COMPLETED_FOLDER" ]; then
		log "Création du dossier de stockage des fichiers terminés : $torrentpath/$COMPLETED_FOLDER"
		$SUDO_EXEC mkdir "$torrentpath/$COMPLETED_FOLDER"
		$SUDO_EXEC chmod 777 "$torrentpath/$COMPLETED_FOLDER"
	fi
}

# Fonction de log
log(){
	echo "[$torrentname] $1" >>$LOG_FILE
}

##############################################################################################
# FIN DES FONCTIONS
##############################################################################################


# Initialisation
init

# Ajout de logs
log "Nouveau torrent terminé :"
log " - ID : $torrentid"
log " - Nom : $torrentname"
log " - Chemin : $torrentpath"

# Déplacement du fichier dans le dossier "A traiter"
completedfile="$torrentpath/$COMPLETED_FOLDER/$torrentname"
mv "$torrentpath/$torrentname" "$completedfile"
log "Fichier déplacé de $torrentpath/$torrentname vers $completedfile"

# Fin de traitement post-download, on supprime le torrent de la liste
deluge-console rm $torrentid
log "Fin de traitement pour le fichier : $torrentname"

# Exécution du script de traitement des fichiers téléchargés
/var/lib/deluge/download_watcher.sh "$torrentpath"

