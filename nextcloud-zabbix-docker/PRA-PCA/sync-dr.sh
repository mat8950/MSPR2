#!/bin/bash

# Configuration
DR_SERVER="backup@dr-server.domain.com"
DR_PATH="/srv/backups"
LOCAL_BACKUP="/backup"
LOG_FILE="/var/log/dr-sync.log"

# Fonction de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

# Fonction de gestion d'erreur
handle_error() {
    log "ERREUR: $1"
    exit 1
}

# Vérification de la connexion SSH
ssh -q $DR_SERVER exit
if [ $? -ne 0 ]; then
    handle_error "Impossible de se connecter au serveur DR"
fi

log "Début de la synchronisation vers le serveur DR"

# Synchronisation des sauvegardes
log "Synchronisation des sauvegardes..."
rsync -avz --delete $LOCAL_BACKUP/ $DR_SERVER:$DR_PATH/backups/ || handle_error "Échec de la synchronisation des sauvegardes"

# Synchronisation des configurations
log "Synchronisation des configurations..."
rsync -avz ../nextcloud/.env $DR_SERVER:$DR_PATH/configs/nextcloud.env || log "Attention: Échec sync config Nextcloud"
rsync -avz ../zabbix/.env $DR_SERVER:$DR_PATH/configs/zabbix.env || log "Attention: Échec sync config Zabbix"

# Synchronisation des scripts
log "Synchronisation des scripts..."
rsync -avz ../PRA-PCA/ $DR_SERVER:$DR_PATH/scripts/ || log "Attention: Échec sync scripts"

log "Synchronisation DR terminée avec succès" 