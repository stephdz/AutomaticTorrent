#!/bin/bash
##############################################################################################
# open-subtitles.sh : Téléchargement des sous-titres sur opensubtitles.org
# Paramètres :
#  - $1 : options (-v pour plus de logs, -w pour avoir la progression dans un popup)
#  - $2 : langue (fre pour français)
#  - $3 : chemin vers la vidéo ou nom de fichier (existance non obligatoire)
##############################################################################################

# Inclusion des fonctions communes
. $(dirname $0)/functions.sh

# Recherche des paramètres
WINDOWED="false"
OPTIONS=""
LANG="fre"
VIDEO=""

# On commence par les options
for param in $@; do
	if [ "$param" = "-${param:1}" ]; then
		if [ "$param" = "-w" ]; then
			WINDOWED="true"
		else
			OPTIONS="$OPTIONS $param"
		fi
		shift
	else
		break
	fi
done

# La langue et le fichier à traiter
LANG=$1
VIDEO=$2

# Exécution du Jar avec les paramètres fournis
if [ "$WINDOWED" = "true" ]; then
	java -jar "$OPEN_SUBTITLES_JAR" $OPTIONS "$LANG" "$VIDEO" | sed 's/#/-/g'  | zenity --progress \
		--title="Recherche de sous-titres" \
		--text="Recherche en cours..." \
		--percentage=0 \
		--pulsate \
		--auto-close \
		--no-cancel
else
	java -jar "$OPEN_SUBTITLES_JAR" $OPTIONS "$LANG" "$VIDEO"
fi
