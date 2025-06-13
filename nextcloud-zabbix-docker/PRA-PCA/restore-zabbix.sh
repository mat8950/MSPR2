#!/bin/bash

# Configuration
BACKUP_DIR="/backup"
ZABBIX_DIR="../zabbix"
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

log "Début de la restauration Zabbix depuis $BACKUP_PATH"

# Arrêt des conteneurs
cd $ZABBIX_DIR || handle_error "Impossible d'accéder au répertoire Zabbix"
log "Arrêt des conteneurs Zabbix..."
docker-compose down || handle_error "Échec arrêt conteneurs"

# Restauration des données
log "Restauration des données Zabbix..."
rm -rf data/* || handle_error "Impossible de nettoyer le répertoire data"
tar xzf $BACKUP_PATH/zabbix-data.tar.gz -C . || handle_error "Échec restauration données"

# Démarrage de la base de données
log "Démarrage de la base de données..."
docker-compose up -d zabbix-db || handle_error "Échec démarrage base de données"
sleep 10

# Restauration de la base de données
log "Restauration de la base de données..."
docker-compose exec -T zabbix-db mysql -u root -p${MYSQL_ROOT_PASSWORD} zabbix < $BACKUP_PATH/zabbix-db.sql || handle_error "Échec restauration base de données"

# Restauration de la configuration
log "Restauration de la configuration..."
cp $BACKUP_PATH/zabbix.env .env || log "Attention: Impossible de restaurer .env"

# Démarrage des services
log "Démarrage des services Zabbix..."
docker-compose up -d || handle_error "Échec démarrage services"

# Vérification des services
log "Vérification des services..."
sleep 30
for service in zabbix-server zabbix-web zabbix-agent; do
    if ! docker-compose ps | grep $service | grep -q "Up"; then
        log "Attention: Le service $service ne semble pas démarré correctement"
    fi
done

log "Restauration Zabbix terminée avec succès"
log "Interface web accessible sur http://localhost:8081" 