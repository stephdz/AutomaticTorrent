#!/bin/bash
##############################################################################################
# todo_watcher.sh : Traitement post-download
# Les vidéos MP4 sont encodées pour la Freebox via arista.
# Les sous titres sont récupérés grâce à OpenSubtitles.
# Paramètres :
#  - $1 : nom du dossier des téléchargements de Deluge
# Les logs sont présents dans le fichier /var/lib/deluge/logs/todo_watcher.log
##############################################################################################


##############################################################################################
# FONCTIONS
##############################################################################################

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


# Inclusion des fonctions communes
. functions.sh

# Récupération des paramètres
DELUGE_FOLDER=$1

# Constantes
LOG_FILE="$LOG_FOLDER/todo_watcher.log"
LOCK_FILE="$DELUGE_FOLDER/$TODO_FOLDER/.lock"

# Initialisation
init "$DELUGE_FOLDER"
init_lock

# Boucle de parcours des fichiers du dossier "A traiter"
for file in $(ls -a -1 -p "$DELUGE_FOLDER/$TODO_FOLDER"|grep -v /); 
do 
	do_job "$file"
done;

# Nettoyage
clean_lock

