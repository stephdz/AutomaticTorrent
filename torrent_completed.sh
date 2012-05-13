#!/bin/bash
##############################################################################################
# torrent_completed.sh : Traitement post-download via Deluge (plug-in Execute)
# Les vidéos MP4 sont encodées pour la Freebox via arista.
# Les sous titres sont récupérés grâce à periscope.
# Paramètres :
#  - $1 : id du torrent
#  - $2 : nom du fichier torrent
#  - $3 : dossier où est présent le résultat
# Les logs sont présents dans le fichier /var/log/deluge/torrent_completed.log
##############################################################################################


# Constantes
LOG_FOLDER=/var/log/deluge
LOG_FILE="$LOG_FOLDER/torrent_completed.log"
COMPLETED_FOLDER=Fini
ENCODING_LOCK_FILE="$LOG_FOLDER/encoding.lock"
ENCODED_FOLDER="A supprimer"
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

	# Création du dossier A supprimer
	if [ ! -e "$torrentpath/$ENCODED_FOLDER" ]; then
		log "Création du dossier de stockage des vidéos converties : $torrentpath/$ENCODED_FOLDER"
		$SUDO_EXEC mkdir "$torrentpath/$ENCODED_FOLDER"
		$SUDO_EXEC chmod 777 "$torrentpath/$ENCODED_FOLDER"
	fi
}

# Fonction de log
log(){
	echo "[$torrentname] $1" >>$LOG_FILE
}

# Fonction d'attente du fichier de lock
wait_for_transcoding() {
	waited="false"
	while [ -e $ENCODING_LOCK_FILE ]
	do
		if [ $waited == "false" ]; then
			log "Mise en attente de l'encodage de la vidéo : $1"
			waited="true"
		fi
		sleep 10
	done 
}

# Fonction d'encodage
transcode(){
	log "Encodage de la vidéo de $1 vers $2"
	echo "$1" >$ENCODING_LOCK_FILE
	nice -n 0 arista-transcode -q -o "$2" -d dvd "$1"
	rm -f $ENCODING_LOCK_FILE
}

# Traitement des vidéos non supportées par la Freebox
convert_for_freebox(){
	# Encodage : un seul processus à la fois
	log "Vidéo à réencoder pour la Freebox : $completedfile"
	basevideoname=$(basename "$completedfile" .mp4)
	videodir=$(dirname "$completedfile")
	encodedfile="$videodir/$basevideoname.avi"
	wait_for_transcoding "$completedfile"
	transcode "$completedfile" "$encodedfile"
	log "Fichier réencodé : $encodedfile"

	# On garde une copie au cas où
	copyfile="$torrentpath/$ENCODED_FOLDER/$torrentname"
	mv "$completedfile" "$copyfile"
	log "Fichier déplacé de $completedfile vers $copyfile"
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

# Déplacement du fichier dans le dossier Fini
completedfile="$torrentpath/$COMPLETED_FOLDER/$torrentname"
mv "$torrentpath/$torrentname" "$completedfile"
log "Fichier déplacé de $torrentpath/$torrentname vers $completedfile"

# Récupération de l'extension
extension=$(echo "$completedfile"|awk -F . '{print $NF}')
log "Extension détectée : $extension"

# Récupération des sous titres
log "Téléchargement des sous-titres fr"
periscope -l fr $completedfile

# Renommage des fichiers si c'est une série
basefilename=$(basename "$completedfile" ".$extension")
folder=$(dirname "$completedfile")
newfilename=$(echo "$basefilename"|sed 's/^\([A-Za-z0-9 .]*\)S\([0-9]\{1,2\}\)E\([0-9]\{1,2\}\).*$/\1S\2E\3/')
mv "$completedfile" "$folder/$newfilename.$extension"
completedfile="$folder/$newfilename.$extension"
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
		log "Pas de traitement particulier lié à l'extension pour $completedfile"
		;;
esac

# Fin de traitement post-download, on supprime le torrent de la liste
deluge-console rm $torrentid
log "Fin de traitement pour le fichier : $torrentname"

