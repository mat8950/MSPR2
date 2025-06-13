#!/bin/bash

# Configuration
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="/var/log/deploy.log"

# Fonction de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

# Fonction de gestion d'erreur
handle_error() {
    log "ERREUR: $1"
    exit 1
}

log "Début du déploiement de l'infrastructure"

# Création des répertoires de données
log "Création des répertoires de données..."
mkdir -p "$BASE_DIR/nextcloud/data" "$BASE_DIR/zabbix/data" || handle_error "Impossible de créer les répertoires de données"

# Vérification des fichiers .env
for service in nextcloud zabbix; do
    if [ ! -f "$BASE_DIR/$service/.env" ]; then
        handle_error "Fichier .env manquant pour $service"
    fi
done

# Démarrage de Nextcloud
log "Déploiement de Nextcloud..."
cd "$BASE_DIR/nextcloud" || handle_error "Impossible d'accéder au répertoire Nextcloud"
docker-compose pull || handle_error "Échec pull images Nextcloud"
docker-compose up -d || handle_error "Échec démarrage Nextcloud"

# Attente du démarrage de Nextcloud
log "Attente du démarrage de Nextcloud..."
sleep 30

# Démarrage de Zabbix
log "Déploiement de Zabbix..."
cd "$BASE_DIR/zabbix" || handle_error "Impossible d'accéder au répertoire Zabbix"
docker-compose pull || handle_error "Échec pull images Zabbix"
docker-compose up -d || handle_error "Échec démarrage Zabbix"

# Attente du démarrage de Zabbix
log "Attente du démarrage de Zabbix..."
sleep 30

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

log "Déploiement terminé avec succès"
echo "
Services disponibles :
- Nextcloud : http://localhost:8080 (admin/admin)
- Zabbix    : http://localhost:8081 (Admin/zabbix)

Pour vérifier l'état des services : ./scripts/status.sh
" 