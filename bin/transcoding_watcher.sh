#!/bin/bash
##############################################################################################
# transcoding_watcher.sh : Traitement post-download
# Encodage dans un format compatible avec la Freebox HD :
#  1 - Prend les fichiers présents dans le dossier .a_encoder
#  2 - Si le format n'est pas compatible avec la Freebox (seulement mp4 actuellement), encode le fichier et le transfère vers le dossier Fini
#  3 - Si compatible transfère la vidéo vers le dossier Fini
# Paramètres :
#  - $1 : nom du dossier des téléchargements de Deluge
# Les logs sont présents dans le fichier /var/lib/deluge/logs/transcoding_watcher.log
##############################################################################################

# Inclusion des fonctions communes
. $(dirname $0)/functions.sh

# Récupération des paramètres
DELUGE_FOLDER=$1

# Constantes
LOG_FILE="$LOG_FOLDER/transcoding_watcher.log"

# Initialisation
init "$DELUGE_FOLDER"
init_lock "$DELUGE_FOLDER/$WAITING_TRANSCODING_FOLDER"

# Boucle de parcours des fichiers du dossier "A encoder"
finished="false"
failed="false"
for video in $(ls -a -1 -p "$DELUGE_FOLDER/$WAITING_TRANSCODING_FOLDER"|grep -v /); 
do
	# On ne traite pas les fichiers cachés (qui commencent par un point)
	if [ ! "$video" = ".${video:1}" ]; then
		
		# Si le fichier est compatible, on le transfère directement dans le dossier Fini
		if [ $(is_freebox_compatible "$video") = "true" ]; then
			mv "$DELUGE_FOLDER/$WAITING_TRANSCODING_FOLDER/$video" "$DELUGE_FOLDER/$COMPLETED_FOLDER/$video"
			log "$LOG_FILE" "$video" "Transfert du fichier $video dans le dossier Fini"
			finished="true"
			
		# Sinon, on l'encode
		else
			# Si l'encodage s'est bien passé, on déplace le fichier résultat vers Fini et le fichier source vers A supprimer
			log "$LOG_FILE" "$video" "Encodage du fichier $video"
			encoded=$(transcode "$DELUGE_FOLDER/$WAITING_TRANSCODING_FOLDER/$video")
			if [ ! "$encoded" = "false" ]; then
				encoded=$(basename "$encoded")
				mv "$DELUGE_FOLDER/$WAITING_TRANSCODING_FOLDER/$encoded" "$DELUGE_FOLDER/$COMPLETED_FOLDER/$encoded"
				mv "$DELUGE_FOLDER/$WAITING_TRANSCODING_FOLDER/$video" "$DELUGE_FOLDER/$TO_BE_DELETED_FOLDER/$video"
				log "$LOG_FILE" "$video" "Transfert du fichier $video dans le dossier A supprimer"
				log "$LOG_FILE" "$video" "Transfert du fichier $encoded dans le dossier Fini"
				finished="true"
				
			# Sinon, on déplace le fichier vers le dossier Encodage échoué
			else
				mv "$DELUGE_FOLDER/$WAITING_TRANSCODING_FOLDER/$video" "$DELUGE_FOLDER/$FAILED_TRANSCODING_FOLDER/$video"
				log "$LOG_FILE" "$video" "Transfert du fichier $video dans le dossier Encodage échoué"
				failed="true"
			fi
		fi
	fi
done;

# Nettoyage
clean_lock "$DELUGE_FOLDER/$WAITING_TRANSCODING_FOLDER"

# Lancement de failed_transcoding_watcher si on a échoué des encodages
if [ "$failed" = "true" ]; then
	failed_transcoding_watcher.sh "$DELUGE_FOLDER"
fi

# Lancement de finished_watcher si on a terminé des fichiers
if [ "$finished" = "true" ]; then
	finished_watcher.sh "$DELUGE_FOLDER"
fi
