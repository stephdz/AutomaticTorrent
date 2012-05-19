#!/bin/bash
##############################################################################################
# subtitles_watcher.sh : Traitement post-download
# Téléchargement des sous-titres :
#  1 - Prend les fichiers présents dans le dossier .sous_titres
#  2 - Télécharge les sous-titres
#  3 - Renomme correctement toutes les vidéos qui ont des sous-titres 
#  4 - Déplace toutes les vidéos qui ont des sous-titres dans le dossier .a_encoder et les sous-titres dans le dossier Fini
# Paramètres :
#  - $1 : nom du dossier des téléchargements de Deluge
# Les logs sont présents dans le fichier /var/lib/deluge/logs/subtitles_watcher.log
##############################################################################################

# Inclusion des fonctions communes
. $(dirname $0)/functions.sh

# Récupération des paramètres
DELUGE_FOLDER=$1

# Constantes
LOG_FILE="$LOG_FOLDER/subtitles_watcher.log"

# Initialisation
init "$DELUGE_FOLDER"
init_lock "$DELUGE_FOLDER/$WAITING_SUBTITLES_FOLDER"

# Boucle de parcours des fichiers du dossier "En attente de sous-titres"
found="false"
for video in $(ls -a -1 -p "$DELUGE_FOLDER/$WAITING_SUBTITLES_FOLDER"|grep -v /); 
do
	# On ne traite pas les fichiers cachés (qui commencent par un point)
	# Ni les fichiers de sous-titres
	if [ ! "$video" = ".${video:1}" -a ! $(get_extension "$video") = "$OPEN_SUBTITLES_EXTENSION" ]; then
		
		# Si on est arrivé à récupérer des sous-titres, on renomme et on déplace les fichiers
		subtitles=$(get_subtitles "$DELUGE_FOLDER/$WAITING_SUBTITLES_FOLDER/$video")
		if [ ! "$subtitles" = "false" ]; then
			new_video_name=$(rename_video "$video")
			subtitles=$(basename "$subtitles")
			new_subtitles_name=$(replace_extension "$new_video_name" "$OPEN_SUBTITLES_EXTENSION")
			mv "$DELUGE_FOLDER/$WAITING_SUBTITLES_FOLDER/$video" "$DELUGE_FOLDER/$WAITING_TRANSCODING_FOLDER/$new_video_name"
			mv "$DELUGE_FOLDER/$WAITING_SUBTITLES_FOLDER/$subtitles" "$DELUGE_FOLDER/$COMPLETED_FOLDER/$new_subtitles_name"
			log "$LOG_FILE" "$video" "Transfert et renommage en $new_video_name du fichier $video dans le dossier En attente d'encodage"
			log "$LOG_FILE" "$subtitles" "Transfert et renommage en $new_subtitles_name du fichier $subtitles dans le dossier Fini"
			found="true"
		# Sinon, on ne fait rien, on aura peut-être plus de chance un peu plus tard
		else
			log "$LOG_FILE" "$video" "Impossible de trouver des sous-titres pour $video. Retentera plus tard."
		fi
	fi
done;

# Lancement de transcoding_watcher si on a trouvé des sous-titres
if [ "$found" = "true" ]; then
	transcoding_watcher.sh "$DELUGE_FOLDER"
fi

# Nettoyage
clean_lock "$DELUGE_FOLDER/$WAITING_SUBTITLES_FOLDER"

