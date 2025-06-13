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

log "Début du démarrage des services"

# Démarrage de Nextcloud
log "Démarrage de Nextcloud..."
cd "$BASE_DIR/nextcloud" || handle_error "Impossible d'accéder au répertoire Nextcloud"
docker-compose up -d || handle_error "Échec démarrage Nextcloud"

# Attente du démarrage de Nextcloud
log "Attente du démarrage de Nextcloud..."
sleep 20

# Démarrage de Zabbix
log "Démarrage de Zabbix..."
cd "$BASE_DIR/zabbix" || handle_error "Impossible d'accéder au répertoire Zabbix"
docker-compose up -d || handle_error "Échec démarrage Zabbix"

# Attente du démarrage de Zabbix
log "Attente du démarrage de Zabbix..."
sleep 20

# Vérification des services
log "Vérification des services..."

# Vérification Nextcloud
cd "$BASE_DIR/nextcloud"
if ! docker-compose ps | grep -q "nextcloud.*Up"; then
    handle_error "Nextcloud ne semble pas démarré correctement"
fi

# Vérification Zabbix
cd "$BASE_DIR/zabbix"
if ! docker-compose ps | grep -q "zabbix-web.*Up"; then
    handle_error "Zabbix ne semble pas démarré correctement"
fi

log "Tous les services ont été démarrés avec succès"
echo "
Services disponibles :
- Nextcloud : http://localhost:8080
- Zabbix    : http://localhost:8081

Pour vérifier l'état des services : ./scripts/status.sh
" 