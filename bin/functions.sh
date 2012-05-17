#!/bin/bash
##############################################################################################
# functions.sh : Fonctions communes aux différents scripts
##############################################################################################

# Constantes
LOG_FOLDER=/var/lib/deluge/logs
TODO_FOLDER=".a_traiter"
WAITING_SUBTITLES_FOLDER=".sous_titres"
WAITING_TRANSCODING_FOLDER=".a_encoder"
COMPLETED_FOLDER="Fini"
ENCODED_FOLDER="A supprimer"
SUBTITLE_EXTENSION=srt


##############################################################################################
# FONCTIONS
##############################################################################################

# Initialisation de l'outil
init() {

	# Création du dossier de log
	if [ ! -e "$LOG_FOLDER" ]; then
		log "$LOG_FILE" "init" "Création du dossier de log : $LOG_FOLDER"
		mkdir "$LOG_FOLDER"
		chmod 755 "$LOG_FOLDER"
	fi

	# Création du dossier A traiter
	if [ ! -e "$1/$TODO_FOLDER" ]; then
		log "$LOG_FILE" "init" "Création du dossier de stockage des fichiers à traiter : $1/$TODO_FOLDER"
		mkdir "$1/$TODO_FOLDER"
		chmod 755 "$1/$TODO_FOLDER"
	fi

	# Création du dossier "En attente de sous-titres"
	if [ ! -e "$1/$WAITING_SUBTITLES_FOLDER" ]; then
		log "$LOG_FILE" "init" "Création du dossier de stockage des fichiers en attente de sous-titres : $1/$WAITING_SUBTITLES_FOLDER"
		mkdir "$1/$WAITING_SUBTITLES_FOLDER"
		chmod 755 "$1/$WAITING_SUBTITLES_FOLDER"
	fi

	# Création du dossier "A encoder"
	if [ ! -e "$1/$WAITING_TRANSCODING_FOLDER" ]; then
		log "$LOG_FILE" "init" "Création du dossier de stockage des fichiers à encoder : $1/$WAITING_TRANSCODING_FOLDER"
		mkdir "$1/$WAITING_TRANSCODING_FOLDER"
		chmod 755 "$1/$WAITING_TRANSCODING_FOLDER"
	fi

	# Création du dossier "A supprimer"
	if [ ! -e "$1/$ENCODED_FOLDER" ]; then
		log "$LOG_FILE" "init" "Création du dossier de stockage des fichiers encodés : $1/$ENCODED_FOLDER"
		mkdir "$1/$ENCODED_FOLDERR"
		chmod 755 "$1/$ENCODED_FOLDER"
	fi

	# Création du dossier "Fini"
	if [ ! -e "$1/$COMPLETED_FOLDER" ]; then
		log "$LOG_FILE" "init" "Création du dossier de stockage des fichiers terminés : $1/$COMPLETED_FOLDER"
		mkdir "$1/$COMPLETED_FOLDER"
		chmod 755 "$1/$COMPLETED_FOLDER"
	fi
}

# Fonction d'initialisation
init_lock() {

	# Fichier de lock pour qu'un seul processus ne traite les fichiers à la fois
	if [ -e $LOCK_FILE ]; then
		log "init" "Daemon déjà en cours d'exécution"
		exit 0
	fi
	touch $LOCK_FILE
}

# Fonction de nettoyage de fin de script
clean_lock() {
	# Suppression du fichier de lock
	rm -f $LOCK_FILE
}

# Fonction de log
log(){
	echo "[$1] $2" >>$0
}

# Fonction d'encodage
transcode(){
	log "$1" "Encodage de la vidéo de $1 vers $2"
	arista-transcode -q -o "$2" -d dvd "$1"
}

##############################################################################################
# FIN DES FONCTIONS
##############################################################################################


