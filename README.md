AutomaticTorrent
================

Traitements automatisés après téléchargement de torrents de séries par Deluge sous Linux.

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
