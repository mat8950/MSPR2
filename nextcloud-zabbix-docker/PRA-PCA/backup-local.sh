#!/bin/bash

# Configuration
BACKUP_DIR="/backup/$(date +%Y%m%d_%H%M%S)"
NEXTCLOUD_DIR="../nextcloud"
ZABBIX_DIR="../zabbix"
LOG_FILE="/var/log/backup.log"

# Fonction de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

# Fonction de gestion d'erreur
handle_error() {
    log "ERREUR: $1"
    exit 1
}

# Création du répertoire de backup
mkdir -p $BACKUP_DIR || handle_error "Impossible de créer le répertoire de backup"
log "Début de la sauvegarde dans $BACKUP_DIR"

# Sauvegarde Nextcloud
log "Sauvegarde de Nextcloud..."
cd $NEXTCLOUD_DIR || handle_error "Impossible d'accéder au répertoire Nextcloud"

# Activation du mode maintenance
docker-compose exec -T nextcloud php occ maintenance:mode --on || handle_error "Impossible d'activer le mode maintenance"

# Sauvegarde de la base de données
log "Export de la base de données Nextcloud..."
docker-compose exec -T nextcloud-db mysqldump -u root -p${MYSQL_ROOT_PASSWORD} nextcloud > $BACKUP_DIR/nextcloud-db.sql || handle_error "Échec export DB Nextcloud"

# Sauvegarde des données
log "Sauvegarde des données Nextcloud..."
tar czf $BACKUP_DIR/nextcloud-data.tar.gz data/ || handle_error "Échec sauvegarde données Nextcloud"

# Désactivation du mode maintenance
docker-compose exec -T nextcloud php occ maintenance:mode --off || log "Attention: Impossible de désactiver le mode maintenance"

# Sauvegarde Zabbix
log "Sauvegarde de Zabbix..."
cd $ZABBIX_DIR || handle_error "Impossible d'accéder au répertoire Zabbix"

# Sauvegarde de la base de données
log "Export de la base de données Zabbix..."
docker-compose exec -T zabbix-db mysqldump -u root -p${MYSQL_ROOT_PASSWORD} zabbix > $BACKUP_DIR/zabbix-db.sql || handle_error "Échec export DB Zabbix"

# Sauvegarde des données
log "Sauvegarde des données Zabbix..."
tar czf $BACKUP_DIR/zabbix-data.tar.gz data/ || handle_error "Échec sauvegarde données Zabbix"

# Sauvegarde des configurations
log "Sauvegarde des configurations..."
cp $NEXTCLOUD_DIR/.env $BACKUP_DIR/nextcloud.env || log "Attention: Impossible de sauvegarder .env Nextcloud"
cp $ZABBIX_DIR/.env $BACKUP_DIR/zabbix.env || log "Attention: Impossible de sauvegarder .env Zabbix"

# Nettoyage des anciennes sauvegardes (plus de 7 jours)
find /backup -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null
log "Nettoyage des sauvegardes de plus de 7 jours effectué"

log "Sauvegarde terminée avec succès" 