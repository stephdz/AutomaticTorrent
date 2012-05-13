#!/bin/bash
##############################################################################################
# download_watcher.sh : Traitement post-download
# Les vidéos MP4 sont encodées pour la Freebox via arista.
# Les sous titres sont récupérés grâce à periscope.
# Paramètres :
#  - $1 : nom du dossier des téléchargements de Deluge
# Les logs sont présents dans le fichier /var/log/deluge/download_watcher.log
##############################################################################################


# Constantes
LOG_FOLDER=/var/log/deluge
LOG_FILE="$LOG_FOLDER/download_watcher.log"
WATCHER_LOCK_FILE="$LOG_FOLDER/watcher.lock"
ENCODED_FOLDER="A supprimer"
SUDO_EXEC=gksudo
SUBTITLE_EXTENSION=srt

# Récupération des paramètres
DELUGE_FOLDER=$1
TO_COMPUTE="$DELUGE_FOLDER/A traiter"
WAITING_SUBTITLES="$DELUGE_FOLDER/En attente de sous-titres"
WAITING_TRANSCODING="$DELUGE_FOLDER/A encoder"
COMPLETED_FOLDER="$DELUGE_FOLDER/Fini"

##############################################################################################
# FONCTIONS
##############################################################################################

# Fonction d'initialisation
init() {

	# Création du dossier "A traiter"
	if [ ! -e "TO_COMPUTE" ]; then
		log "Création du dossier 'A traiter' : $TO_COMPUTE"
		$SUDO_EXEC mkdir "$TO_COMPUTE"
		$SUDO_EXEC chmod 777 "$TO_COMPUTE"
	fi

	# Création du dossier "En attente de sous-titres"
	if [ ! -e "$WAITING_SUBTITLES" ]; then
		log "Création du dossier 'En attente de sous-titres' : $WAITING_SUBTITLES"
		$SUDO_EXEC mkdir "$WAITING_SUBTITLES"
		$SUDO_EXEC chmod 777 "$WAITING_SUBTITLES"
	fi

	# Création du dossier "A encoder"
	if [ ! -e "$WAITING_TRANSCODING" ]; then
		log "Création du dossier 'A encoder' : $WAITING_TRANSCODING"
		$SUDO_EXEC mkdir "$WAITING_TRANSCODING"
		$SUDO_EXEC chmod 777 "$WAITING_TRANSCODING"
	fi

	# Création du dossier "Fini"
	if [ ! -e "$COMPLETED_FOLDER" ]; then
		log "Création du dossier 'Fini' : $COMPLETED_FOLDER"
		$SUDO_EXEC mkdir "$COMPLETED_FOLDER"
		$SUDO_EXEC chmod 777 "$COMPLETED_FOLDER"
	fi

	# Fichier de lock pour qu'un seul processus ne traite les fichiers à la fois
	if [ -e $WATCHER_LOCK_FILE ]; then
		log "init" "Daemon déjà en cours d'exécution"
		exit 0
	fi
	touch $WATCHER_LOCK_FILE
}

# Fonction de nettoyage de fin de script
clean() {
	# Suppression du fichier de lock
	rm -f $WATCHER_LOCK_FILE
}

# Fonction de log
log() {
	echo "[$1] $2" >>$LOG_FILE
}

# Fonction d'encodage
transcode(){
	log "$1" "Encodage de la vidéo de $1 vers $2"
	nice -n 0 arista-transcode -q -o "$2" -d dvd "$1"
}

# Traitement des vidéos non supportées par la Freebox
convert_for_freebox(){
	# Encodage : un seul processus à la fois
	log "$computedfile" "Vidéo à réencoder pour la Freebox : $computedfile"
	basevideoname=$(basename "$computedfile" .mp4)
	videodir=$(dirname "$computedfile")
	encodedfile="$videodir/$basevideoname.avi"
	transcode "$computedfile" "$encodedfile"
	log "$computedfile" "Fichier réencodé : $encodedfile"

	# On garde une copie au cas où
	copyfile="$torrentpath/$ENCODED_FOLDER/$torrentname"
	mv "$computedfile" "$copyfile"
	log "$computedfile" "Fichier déplacé de $computedfile vers $copyfile"
}

# Traitement d'un fichier
compute_file(){
	log "$computedfile" "Traitement du fichier $TO_COMPUTE/$computedfile"
	
	# Récupération de l'extension
	extension=$(echo "$computedfile"|awk -F . '{print $NF}')
	log "$computedfile" "Extension détectée : $extension"

	# Récupération des sous titres
	log "$computedfile" "Téléchargement des sous-titres fr"
	periscope -l fr $computedfile

	# Renommage des fichiers si c'est une série
	basefilename=$(basename "$computedfile" ".$extension")
	folder=$(dirname "$computedfile")
	newfilename=$(echo "$basefilename"|sed 's/^\([A-Za-z0-9 .]*\)S\([0-9]\{1,2\}\)E\([0-9]\{1,2\}\).*$/\1S\2E\3/')
	mv "$computedfile" "$folder/$newfilename.$extension"
	computedfile="$folder/$newfilename.$extension"
	if [ -e "$folder/$basefilename.$SUBTITLE_EXTENSION" ]; then
		mv "$folder/$basefilename.$SUBTITLE_EXTENSION" "$folder/$newfilename.$extension"
	fi

	# Traitement en fonction de l'extension
	case "$extension" in 

		# Cas du MP4 : encodage pour la Freebox
		mp4)
			convert_for_freebox
			;;

		# Autre cas : pas de traitement particulier
		*)
			log "$computedfile" "Pas de traitement particulier lié à l'extension pour $computedfile"
			;;
	esac
}

##############################################################################################
# FIN DES FONCTIONS
##############################################################################################

# Initialisation
init

# Boucle de parcours des fichiers du dossier "A traiter"
for computedfile in $(ls -a -1 -p $TO_COMPUTE|grep -v /); 
do 
	compute_file
done;

# Boucle de parcours des fichiers du dossier "En attente de sous-titres"
for computedfile in $(ls -a -1 -p $WAITING_SUBTITLES|grep -v /); 
do 
	compute_subtitle
done;

# Boucle de parcours des fichiers du dossier "En attente d'encodage"
for computedfile in $(ls -a -1 -p $WAITING_TRANSCODING|grep -v /); 
do 
	compute_transcoding
done;

# Nettoyage
clean

