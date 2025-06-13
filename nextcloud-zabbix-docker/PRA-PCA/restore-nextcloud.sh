#!/bin/bash

# Configuration
BACKUP_DIR="/backup"
NEXTCLOUD_DIR="../nextcloud"
LOG_FILE="/var/log/restore.log"

# Fonction de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

# Fonction de gestion d'erreur
handle_error() {
    log "ERREUR: $1"
    exit 1
}

# Vérification des arguments
if [ -z "$1" ]; then
    echo "Usage: $0 <date_backup> (format: YYYYMMDD_HHMMSS)"
    exit 1
fi

BACKUP_PATH="$BACKUP_DIR/$1"

# Vérification de l'existence du backup
if [ ! -d "$BACKUP_PATH" ]; then
    handle_error "Backup $BACKUP_PATH non trouvé"
fi

log "Début de la restauration Nextcloud depuis $BACKUP_PATH"

# Arrêt des conteneurs
cd $NEXTCLOUD_DIR || handle_error "Impossible d'accéder au répertoire Nextcloud"
log "Arrêt des conteneurs Nextcloud..."
docker-compose down || handle_error "Échec arrêt conteneurs"

# Restauration des données
log "Restauration des données Nextcloud..."
rm -rf data/* || handle_error "Impossible de nettoyer le répertoire data"
tar xzf $BACKUP_PATH/nextcloud-data.tar.gz -C . || handle_error "Échec restauration données"

# Démarrage de la base de données
log "Démarrage de la base de données..."
docker-compose up -d nextcloud-db || handle_error "Échec démarrage base de données"
sleep 10

# Restauration de la base de données
log "Restauration de la base de données..."
docker-compose exec -T nextcloud-db mysql -u root -p${MYSQL_ROOT_PASSWORD} nextcloud < $BACKUP_PATH/nextcloud-db.sql || handle_error "Échec restauration base de données"

# Restauration de la configuration
log "Restauration de la configuration..."
cp $BACKUP_PATH/nextcloud.env .env || log "Attention: Impossible de restaurer .env"

# Démarrage des services
log "Démarrage des services Nextcloud..."
docker-compose up -d || handle_error "Échec démarrage services"

# Mise à jour de la configuration Nextcloud
log "Mise à jour de la configuration Nextcloud..."
docker-compose exec -T nextcloud php occ maintenance:mode --on || log "Attention: Impossible d'activer le mode maintenance"
docker-compose exec -T nextcloud php occ maintenance:repair || log "Attention: Échec réparation Nextcloud"
docker-compose exec -T nextcloud php occ maintenance:mode --off || log "Attention: Impossible de désactiver le mode maintenance"

log "Restauration Nextcloud terminée avec succès"
log "Interface web accessible sur http://localhost:8080" 