#!/bin/bash
##############################################################################################
# open-subtitles.sh : Téléchargement des sous-titres sur opensubtitles.org
# Paramètres :
#  - $1 : options (-v pour plus de logs)
#  - $2 : langue (fre pour français)
#  - $3 : chemin vers la vidéo ou nom de fichier (existance non obligatoire)
##############################################################################################

# Inclusion des fonctions communes
. $(dirname $0)/functions.sh

# Exécution du Jar avec les paramètres fournis
java -jar "$OPEN_SUBTITLES_JAR" "$1" "$2" "$3"
