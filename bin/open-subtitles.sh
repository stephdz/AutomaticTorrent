#!/bin/bash
##############################################################################################
# open-subtitles.sh : Téléchargement des sous-titres sur opensubtitles.org
# Paramètres :
#  - $1 : langue (fre pour français)
#  - $2 : chemin vers la vidéo ou nom de fichier (existance non obligatoire)
# Les logs sont présents dans le fichier /var/lib/deluge/logs/todo_watcher.log
##############################################################################################

# Inclusion des fonctions communes
. $(dirname $0)/functions.sh

# Exécution du Jar avec les paramètres fournis
java -jar "$OPEN_SUBTITLES_JAR" $@
