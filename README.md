AutomaticTorrent
================

Traitements automatisés après téléchargement de torrents de séries par Deluge sous Linux.

v2.0 :
======

 - un script torrent_completed à utiliser avec le plugin Execute de Deluge
 - des watchers qui scrutent chacun un dossier avec un workflow complet entre les différents dossiers permettant de :
	* rester en attente des sous-titres si jamais la vidéo a été téléchargée avant que des sous-titres aient été publiés
	* réencoder les fichiers non compatibles avec la Freebox (1 seul à la fois pour ne pas surcharger le PC)
	* alerter en cas d'encodage échoué
	* ranger les fichiers terminés reconnus
 - nécessite :
    * Arista pour encoder les vidéos pour la Freebox
 - OpenSubtitles v1.0 est inclus pour le téléchargement des fichiers de sous-titres depuis opensubtitles.org
 - problèmes connus : 
    * risques d'état instable en cas d'arrêt du PC pendant le travail d'un watcher
		=> à étudier et à gérer en v2.1

 
v1.0 :
======

 - un script torrent_completed à utiliser avec le plugin Execute de Deluge
 - nécessite :
    * Arista pour encoder les vidéos pour la Freebox
    * periscope pour récupérer les sous-titres
 - problèmes connus : 
    * les sous-titres ne se récupèrent pas forcément 
        => coder un utilitaire pour les télécharger depuis OpenSubtitles
    * les fichiers ne sont pas rangés de manière efficace
        => essayer de détecter par expressions régulières la série, la saison et l'épisode pour tout ranger et renommer automatiquement
    * le script devient compliqué
        => découper le code et traiter les vidéos avec un dossier par étape et une tâche cron ou un daemon qui scrute ces dossiers
