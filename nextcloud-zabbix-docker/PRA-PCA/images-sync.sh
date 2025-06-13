#!/bin/bash

# Configuration
DR_SERVER="backup@dr-server.domain.com"
IMAGES_DIR="/backup/docker-images"
LOG_FILE="/var/log/images-sync.log"

# Liste des images à sauvegarder
IMAGES=(
    "nextcloud:28-apache"
    "mariadb:10.11"
    "redis:7-alpine"
    "zabbix/zabbix-server-mysql:alpine-6.4-latest"
    "zabbix/zabbix-web-nginx-mysql:alpine-6.4-latest"
    "zabbix/zabbix-agent2:alpine-6.4-latest"
)

# Fonction de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

# Fonction de gestion d'erreur
handle_error() {
    log "ERREUR: $1"
    exit 1
}

# Création du répertoire de sauvegarde
mkdir -p $IMAGES_DIR || handle_error "Impossible de créer le répertoire des images"
log "Début de la sauvegarde des images Docker"

# Sauvegarde des images
for image in "${IMAGES[@]}"; do
    image_filename=$(echo $image | tr '/:' '_').tar
    log "Sauvegarde de l'image $image..."
    
    # Pull de la dernière version
    docker pull $image || log "Attention: Impossible de pull $image"
    
    # Sauvegarde de l'image
    docker save $image > "$IMAGES_DIR/$image_filename" || handle_error "Échec sauvegarde $image"
done

# Synchronisation avec le serveur DR
log "Synchronisation des images avec le serveur DR..."
rsync -avz $IMAGES_DIR/ $DR_SERVER:/srv/backups/docker-images/ || handle_error "Échec synchronisation DR"

# Nettoyage des anciennes images
find $IMAGES_DIR -type f -mtime +7 -exec rm {} \;
log "Nettoyage des images de plus de 7 jours effectué"

log "Synchronisation des images Docker terminée avec succès" 