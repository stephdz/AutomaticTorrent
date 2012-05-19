#!/bin/bash
##############################################################################################
# todo_watcher.sh : Traitement post-download
# Préparation au traitement :
#  1 - Prend les fichiers présents dans le dossier .a_traiter
#  2 - Place les vidéos dans le dossier .sous_titres pour l'étape suivante
#  3 - Place les autres fichiers dans le dossier Fini
#  4 - S'il y a eu des vidéos de traitées, lance subtitles_watcher.sh
# Paramètres :
#  - $1 : nom du dossier des téléchargements de Deluge
# Les logs sont présents dans le fichier /var/lib/deluge/logs/todo_watcher.log
##############################################################################################

# Inclusion des fonctions communes
. $(dirname $0)/functions.sh

# Récupération des paramètres
DELUGE_FOLDER=$1

# Constantes
LOG_FILE="$LOG_FOLDER/todo_watcher.log"

# Initialisation
init "$DELUGE_FOLDER"
init_lock "$DELUGE_FOLDER/$TODO_FOLDER"

# Boucle de parcours des fichiers du dossier "A traiter"
video="false"
finished="false"
for file in $(ls -a -1 -p "$DELUGE_FOLDER/$TODO_FOLDER"|grep -v /); 
do
	# On ne traite pas les fichiers cachés (qui commencent par un point)
	if [ ! "$file" = ".${file:1}" ]; then
		
		# Si c'est une vidéo, on la met dans le dossier en attente de sous-titres
		if [ $(is_video "$file") = "true" ]; then
			mv "$DELUGE_FOLDER/$TODO_FOLDER/$file" "$DELUGE_FOLDER/$WAITING_SUBTITLES_FOLDER/$file"
			log "$LOG_FILE" "$file" "Transfert du fichier $file dans le dossier En attente de sous-titres"
			video="true"
		# Sinon, dans le dossier fini
		else
			mv "$DELUGE_FOLDER/$TODO_FOLDER/$file" "$DELUGE_FOLDER/$COMPLETED_FOLDER/$file"
			log "$LOG_FILE" "$file" "Transfert du fichier $file dans le dossier Fini"
			finished="true"
		fi
	fi
done;

# Nettoyage
clean_lock "$DELUGE_FOLDER/$TODO_FOLDER"

# Lancement de finished_watcher si on a trouvé terminé des fichiers
if [ "$finished" = "true" ]; then
	finished_watcher.sh "$DELUGE_FOLDER"
fi

# Lancement de subtitles_watcher
if [ "$video" = "true" ]; then
	subtitles_watcher.sh "$DELUGE_FOLDER"
fi
