#!/bin/bash

# Configuration
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="/var/log/docker-services.log"

# Fonction de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

# Fonction de gestion d'erreur
handle_error() {
    log "ERREUR: $1"
    exit 1
}

log "Début de l'arrêt des services"

# Arrêt de Nextcloud
log "Arrêt de Nextcloud..."
cd "$BASE_DIR/nextcloud" || handle_error "Impossible d'accéder au répertoire Nextcloud"
docker-compose down || log "Attention: Problème lors de l'arrêt de Nextcloud"

# Arrêt de Zabbix
log "Arrêt de Zabbix..."
cd "$BASE_DIR/zabbix" || handle_error "Impossible d'accéder au répertoire Zabbix"
docker-compose down || log "Attention: Problème lors de l'arrêt de Zabbix"

# Vérification qu'aucun conteneur n'est en cours d'exécution
if docker ps | grep -q "nextcloud\|zabbix"; then
    handle_error "Certains conteneurs sont toujours en cours d'exécution"
fi

log "Tous les services ont été arrêtés avec succès" 