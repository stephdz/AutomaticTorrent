#!/bin/bash
##############################################################################################
# functions.sh : Fonctions communes aux différents scripts
##############################################################################################


# Dossier de base
DELUGE_FOLDER="/var/lib/deluge"
DELUGE_BIN_FOLDER="$DELUGE_FOLDER/bin"
LOG_FOLDER="$DELUGE_FOLDER/logs"

# Config OpenSubtitles
OPEN_SUBTITLES_FOLDER="$DELUGE_FOLDER/OpenSubtitles"
OPEN_SUBTITLES_VERSION="1.1"
OPEN_SUBTITLES_JAR="$OPEN_SUBTITLES_FOLDER/OpenSubtitles-$OPEN_SUBTITLES_VERSION.jar"
OPEN_SUBTITLES_LANG="fre"
OPEN_SUBTITLES_EXTENSION="srt"

# Dossier des différentes étapes
TODO_FOLDER=".a_traiter"
WAITING_SUBTITLES_FOLDER=".sous_titres"
WAITING_TRANSCODING_FOLDER=".a_encoder"
COMPLETED_FOLDER="Fini"
TO_BE_DELETED_FOLDER="A supprimer"
FAILED_TRANSCODING_FOLDER="Encodage échoué"

# Constantes diverses
LOCK_FILE=".lock"
VIDEO_REGEXP="(avi|divx|mp21|mp2v|mpg2|mp4|mp4v|mpe|mpeg4|mpg|mpeg|mkv|asf|ts|h264|mjpg|mov|movie|ogm|ogv|ogx|qt|qtm|rm|rmd|rts|rv|wmv|xvid)"
UNCOMPATIBLE_VIDEO_REGEXP="(mp4|mpeg4)"
TRANSCODING_EXTENSION="avi"
CRONTAB_FILE="$DELUGE_FOLDER/.crontab"
CRONTAB_PERIOD="10"
OR_REGEXP_STRING="|"

# La liste des watchers
WATCHERS=$(for watcher in $(ls -a -1 -p "$DELUGE_BIN_FOLDER"|grep -v /|grep "watcher"); do echo -n "$OR_REGEXP_STRING$watcher"; done)
WATCHERS="${WATCHERS:${#OR_REGEXP_STRING}}"

##############################################################################################
# FONCTIONS
##############################################################################################

# Initialisation de l'outil
init() {

	# Création du dossier de log
	if [ ! -e "$LOG_FOLDER" ]; then
		mkdir "$LOG_FOLDER"
		chmod 755 "$LOG_FOLDER"
		log "$LOG_FILE" "init" "Création du dossier de log : $LOG_FOLDER"
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
	if [ ! -e "$1/$TO_BE_DELETED_FOLDER" ]; then
		log "$LOG_FILE" "init" "Création du dossier de stockage des fichiers encodés : $1/$TO_BE_DELETED_FOLDER"
		mkdir "$1/$TO_BE_DELETED_FOLDER"
		chmod 755 "$1/$TO_BE_DELETED_FOLDER"
	fi
	
	# Création du dossier "Encodage échoué"
	if [ ! -e "$1/$FAILED_TRANSCODING_FOLDER" ]; then
		log "$LOG_FILE" "init" "Création du dossier de stockage des fichiers non encodés : $1/$FAILED_TRANSCODING_FOLDER"
		mkdir "$1/$FAILED_TRANSCODING_FOLDER"
		chmod 755 "$1/$FAILED_TRANSCODING_FOLDER"
	fi

	# Création du dossier "Fini"
	if [ ! -e "$1/$COMPLETED_FOLDER" ]; then
		log "$LOG_FILE" "init" "Création du dossier de stockage des fichiers terminés : $1/$COMPLETED_FOLDER"
		mkdir "$1/$COMPLETED_FOLDER"
		chmod 755 "$1/$COMPLETED_FOLDER"
	fi
	
	# Ajout des tâches cron pour les watchers
	crontab -l > "$CRONTAB_FILE"
	cat "$CRONTAB_FILE" | egrep -ivh "($WATCHERS)" > "$CRONTAB_FILE"
	IFS=$OR_REGEXP_STRING
	for watcher in $WATCHERS; do
		echo "*/$CRONTAB_PERIOD * * * * $DELUGE_BIN_FOLDER/$watcher \"$1\"" >> "$CRONTAB_FILE"
	done
	unset IFS
	crontab "$CRONTAB_FILE"
}

# Fonction d'initialisation
init_lock() {

	# Fichier de lock pour qu'un seul processus ne traite les fichiers à la fois
	if [ -e "$1/$LOCK_FILE" ]; then
		log "$LOG_FILE" "init_lock" "Daemon déjà en cours d'exécution"
		exit 0
	fi
	touch "$1/$LOCK_FILE"
}

# Fonction de nettoyage de fin de script
clean_lock() {
	# Suppression du fichier de lock
	rm -f "$1/$LOCK_FILE"
}

# Fonction de log
log() {
	context=$(get_log_context "$2")
	echo "$context $3" >>$1
}

# Fonction echo qui log
echo_log() {
	context=$(get_log_context "$2")
	echo "$context $3"
	echo "$context $3" >>$1
}

# Retourne le contexte de log
get_log_context() {
	date=$(date +"%d/%m/%Y %H:%M:%S")
	context="[$date"
	if [ "$1" = "" ]; then
		context="$context]"
	else
		context="$context - $1]"
	fi
	echo "$context"
}

# Retourne true si le fichier passé en paramètre est une vidéo
is_video() {
	# Comparaison de l'extension à l'expression régulière
	if [[ $(get_extension "$1") =~ $VIDEO_REGEXP ]]; then
		echo "true"
	else
		echo "false"
	fi
}

# Retourne l'extension d'un fichier passé en paramètre
get_extension() {
	extension=$(echo "$1"|awk -F . '{print $NF}')
	echo "$extension"
}

# Récupère les sous-titres d'un fichier. Retourne le nom du fichier si on en a trouvé, false sinon
get_subtitles() {
	open-subtitles.sh "$OPEN_SUBTITLES_LANG" "$1"
	subtitles=$(replace_extension "$1" "$OPEN_SUBTITLES_EXTENSION")
	if [ -e "$subtitles" ]; then
		echo "$subtitles"
	else
		echo "false"
	fi
}

# Retourne le nom du fichier passé en 1er paramètre en changeant son extension par celle fournie dans le 2è paramètre
replace_extension() {
	extension=$(get_extension "$1")
	basename=$(basename "$1" ".$extension")
	folder=$(dirname "$1")
	if [ "$folder" = "." ]; then
		folder=""
	else
		folder="$folder/"
	fi
	echo "$folder$basename.$2"
}

# Renomme un nom de fichier de série dans le format <nom>.S<saison>E<episode>.<extension>
# Si le nom de fichier n'est pas détecté comme une série, retourne le nom sans modification
rename_video() {
	extension=$(get_extension "$1")
	basefilename=$(basename "$1" ".$extension")
	folder=$(dirname "$1")
	if [ "$folder" = "." ]; then
		folder=""
	else
		folder="$folder/"
	fi
	newfilename=$(echo "$basefilename"|sed 's/^\([A-Za-z0-9 .]*\)S\([0-9]\{1,2\}\)E\([0-9]\{1,2\}\).*$/\1S\2E\3/')
	echo "$folder$newfilename.$extension"
}

# Retourne true si le fichier passé en paramètre est une vidéo compatible avec la Freebox HD
is_freebox_compatible() {
	# Comparaison de l'extension à l'expression régulière
	if [[ $(get_extension "$1") =~ $UNCOMPATIBLE_VIDEO_REGEXP ]]; then
		echo "false"
	else
		echo "true"
	fi
}

# Fonction d'encodage : retourne le nom du fichier encodé si tout s'est bien passé, false sinon
transcode() {
	src=$1
	dest=$(replace_extension "$src" "$TRANSCODING_EXTENSION")
	arista-transcode -q -o "$dest" -d dvd "$src"
	# TODO Traitements d'erreur plus poussé
	if [ -s "$dest" ]; then
		echo "$dest"
	else
		if [ -e "$dest" ]; then
			rm -f "$dest"
		fi
		echo "false"
	fi
}

##############################################################################################
# FIN DES FONCTIONS
##############################################################################################


# On ajoute le dossier bin au PATH pour simplifier les appels
PATH=$PATH:$DELUGE_BIN_FOLDER
export PATH
