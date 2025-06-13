# Infrastructure Docker Simple - Nextcloud + Zabbix avec PRA/PCA

## Structure du Projet

```
nextcloud-zabbix-docker/
├── nextcloud/
│   ├── data/                    # Données persistantes Nextcloud
│   ├── docker-compose.yml       # Stack Nextcloud
│   └── .env                     # Variables Nextcloud
├── zabbix/
│   ├── data/                    # Données persistantes Zabbix
│   ├── docker-compose.yml       # Stack Zabbix
│   └── .env                     # Variables Zabbix
├── PRA-PCA/
│   ├── backup-local.sh          # Sauvegarde locale
│   ├── sync-dr.sh               # Synchronisation DR
│   ├── restore-nextcloud.sh     # Restauration Nextcloud
│   ├── restore-zabbix.sh        # Restauration Zabbix
│   └── images-sync.sh           # Synchronisation images Docker
├── scripts/
│   ├── deploy-all.sh            # Déploiement complet
│   ├── stop-all.sh              # Arrêt de tous les services
│   └── status.sh                # Statut des services
├── prompt                       # Cahier des charges original
└── README.md                    # Documentation
```

## Nextcloud - docker-compose.yml

```yaml
version: '3.8'

services:
  nextcloud-app:
    image: nextcloud:28
    container_name: nextcloud-app
    ports:
      - "8080:80"
    environment:
      - MYSQL_HOST=nextcloud-db
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - NEXTCLOUD_ADMIN_USER=${ADMIN_USER}
      - NEXTCLOUD_ADMIN_PASSWORD=${ADMIN_PASSWORD}
      - REDIS_HOST=nextcloud-redis
      - NEXTCLOUD_TRUSTED_DOMAINS=${TRUSTED_DOMAINS}
    volumes:
      - ./data/nextcloud:/var/www/html
      - ./data/nextcloud-data:/var/www/html/data
    depends_on:
      - nextcloud-db
      - nextcloud-redis
    restart: unless-stopped

  nextcloud-db:
    image: mariadb:10.11
    container_name: nextcloud-db
    environment:
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
    volumes:
      - ./data/nextcloud-db:/var/lib/mysql
    restart: unless-stopped

  nextcloud-redis:
    image: redis:7-alpine
    container_name: nextcloud-redis
    volumes:
      - ./data/nextcloud-redis:/data
    restart: unless-stopped
```

## Nextcloud - .env

```env
# Base de données
MYSQL_ROOT_PASSWORD=rootpassword123
MYSQL_DATABASE=nextcloud
MYSQL_USER=nextcloud
MYSQL_PASSWORD=nextcloudpass123

# Admin Nextcloud
ADMIN_USER=admin
ADMIN_PASSWORD=adminpass123

# Configuration
TRUSTED_DOMAINS=localhost,192.168.1.100
```

## Zabbix - docker-compose.yml

```yaml
version: '3.8'

services:
  zabbix-server:
    image: zabbix/zabbix-server-mysql:6.4-alpine-latest
    container_name: zabbix-server
    environment:
      - DB_SERVER_HOST=zabbix-db
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
    volumes:
      - ./data/zabbix-server:/var/lib/zabbix
    depends_on:
      - zabbix-db
    restart: unless-stopped

  zabbix-web:
    image: zabbix/zabbix-web-nginx-mysql:6.4-alpine-latest
    container_name: zabbix-web
    ports:
      - "8081:8080"
    environment:
      - ZBX_SERVER_HOST=zabbix-server
      - DB_SERVER_HOST=zabbix-db
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - PHP_TZ=${TIMEZONE}
    depends_on:
      - zabbix-server
      - zabbix-db
    restart: unless-stopped

  zabbix-agent:
    image: zabbix/zabbix-agent:6.4-alpine-latest
    container_name: zabbix-agent
    environment:
      - ZBX_HOSTNAME=zabbix-server
      - ZBX_SERVER_HOST=zabbix-server
    restart: unless-stopped

  zabbix-db:
    image: mariadb:10.11
    container_name: zabbix-db
    environment:
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
    volumes:
      - ./data/zabbix-db:/var/lib/mysql
    restart: unless-stopped
```

## Zabbix - .env

```env
# Base de données
MYSQL_ROOT_PASSWORD=rootpassword123
MYSQL_DATABASE=zabbix
MYSQL_USER=zabbix
MYSQL_PASSWORD=zabbixpass123

# Configuration
TIMEZONE=Europe/Paris
```

## Scripts de Gestion

### deploy-all.sh
```bash
#!/bin/bash
echo "=== Déploiement Infrastructure Docker ==="

# Créer les dossiers de données
mkdir -p nextcloud/data/{nextcloud,nextcloud-data,nextcloud-db,nextcloud-redis}
mkdir -p zabbix/data/{zabbix-server,zabbix-db}

# Démarrer Nextcloud
echo "Démarrage Nextcloud..."
cd nextcloud && docker compose up -d
cd ..

# Attendre que la DB soit prête
sleep 30

# Démarrer Zabbix
echo "Démarrage Zabbix..."
cd zabbix && docker compose up -d
cd ..

echo "=== Déploiement terminé ==="
echo "Nextcloud: http://localhost:8080"
echo "Zabbix: http://localhost:8081 (admin/zabbix)"
```

### status.sh
```bash
#!/bin/bash
echo "=== Statut des Services ==="
echo
echo "--- Nextcloud ---"
cd nextcloud && docker compose ps
echo
echo "--- Zabbix ---"
cd ../zabbix && docker compose ps
cd ..
```

## PRA/PCA - Scripts de Sauvegarde

### backup-local.sh
```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backup/$DATE"
PROJECT_DIR="/opt/nextcloud-zabbix-docker"

echo "=== Sauvegarde locale - $DATE ==="
mkdir -p $BACKUP_DIR/{nextcloud,zabbix}

cd $PROJECT_DIR

# Sauvegarde Nextcloud
echo "Sauvegarde Nextcloud..."
cd nextcloud
docker compose exec -T nextcloud-db mysqldump -u root -p"$MYSQL_ROOT_PASSWORD" nextcloud > $BACKUP_DIR/nextcloud/database.sql
tar czf $BACKUP_DIR/nextcloud/data.tar.gz data/
cp docker-compose.yml .env $BACKUP_DIR/nextcloud/

# Sauvegarde Zabbix
echo "Sauvegarde Zabbix..."
cd ../zabbix
docker compose exec -T zabbix-db mysqldump -u root -p"$MYSQL_ROOT_PASSWORD" zabbix > $BACKUP_DIR/zabbix/database.sql
tar czf $BACKUP_DIR/zabbix/data.tar.gz data/
cp docker-compose.yml .env $BACKUP_DIR/zabbix/

echo "Sauvegarde terminée: $BACKUP_DIR"

# Nettoyage (garder 7 jours)
find /backup -type d -mtime +7 -exec rm -rf {} \;
```

### sync-dr.sh
```bash
#!/bin/bash
DR_SERVER="backup@dr-server.domain.com"
DR_PATH="/srv/backups"
LOCAL_BACKUP="/backup"

echo "=== Synchronisation DR ==="

# Sync des sauvegardes
echo "Synchronisation des données..."
rsync -avz --delete $LOCAL_BACKUP/ $DR_SERVER:$DR_PATH/data/

# Sync des images Docker
echo "Synchronisation des images Docker..."
./images-sync.sh

echo "Synchronisation DR terminée"
```

### images-sync.sh
```bash
#!/bin/bash
DR_SERVER="backup@dr-server.domain.com"
DR_PATH="/srv/backups/images"

IMAGES=(
    "nextcloud:28"
    "mariadb:10.11"
    "redis:7-alpine"
    "zabbix/zabbix-server-mysql:6.4-alpine-latest"
    "zabbix/zabbix-web-nginx-mysql:6.4-alpine-latest"
    "zabbix/zabbix-agent:6.4-alpine-latest"
)

echo "=== Synchronisation Images Docker ==="

for IMAGE in "${IMAGES[@]}"; do
    echo "Export: $IMAGE"
    IMAGE_FILE=$(echo $IMAGE | sed 's/[\/:]/_/g').tar.gz
    docker save $IMAGE | gzip | ssh $DR_SERVER "cat > $DR_PATH/$IMAGE_FILE"
done

echo "Images synchronisées"
```

### restore-nextcloud.sh
```bash
#!/bin/bash
BACKUP_DATE=$1
BACKUP_DIR="/srv/backups/data/$BACKUP_DATE"

if [ -z "$BACKUP_DATE" ]; then
    echo "Usage: ./restore-nextcloud.sh YYYYMMDD_HHMMSS"
    exit 1
fi

echo "=== Restauration Nextcloud - $BACKUP_DATE ==="

# Arrêt des services
cd /opt/nextcloud-zabbix-docker/nextcloud
docker compose down

# Restauration des fichiers
rm -rf data/
tar xzf $BACKUP_DIR/nextcloud/data.tar.gz

# Restauration de la config
cp $BACKUP_DIR/nextcloud/docker-compose.yml .
cp $BACKUP_DIR/nextcloud/.env .

# Redémarrage
docker compose up -d

# Attendre que la DB soit prête
sleep 30

# Restauration de la base
docker compose exec -T nextcloud-db mysql -u root -p"$MYSQL_ROOT_PASSWORD" nextcloud < $BACKUP_DIR/nextcloud/database.sql

echo "Restauration Nextcloud terminée"
```

### restore-zabbix.sh
```bash
#!/bin/bash
BACKUP_DATE=$1
BACKUP_DIR="/srv/backups/data/$BACKUP_DATE"

if [ -z "$BACKUP_DATE" ]; then
    echo "Usage: ./restore-zabbix.sh YYYYMMDD_HHMMSS"
    exit 1
fi

echo "=== Restauration Zabbix - $BACKUP_DATE ==="

# Arrêt des services
cd /opt/nextcloud-zabbix-docker/zabbix
docker compose down

# Restauration des fichiers
rm -rf data/
tar xzf $BACKUP_DIR/zabbix/data.tar.gz

# Restauration de la config
cp $BACKUP_DIR/zabbix/docker-compose.yml .
cp $BACKUP_DIR/zabbix/.env .

# Redémarrage
docker compose up -d

# Attendre que la DB soit prête
sleep 30

# Restauration de la base
docker compose exec -T zabbix-db mysql -u root -p"$MYSQL_ROOT_PASSWORD" zabbix < $BACKUP_DIR/zabbix/database.sql

echo "Restauration Zabbix terminée"
```

## Cron Jobs

Ajouter dans crontab (`crontab -e`) :

```bash
# Sauvegarde quotidienne à 2h
0 2 * * * /opt/nextcloud-zabbix-docker/PRA-PCA/backup-local.sh

# Synchronisation DR à 4h
0 4 * * * /opt/nextcloud-zabbix-docker/PRA-PCA/sync-dr.sh

# Nettoyage hebdomadaire
0 1 * * 0 find /backup -type d -mtime +7 -exec rm -rf {} \;
```

## Déploiement Rapide

```bash
# 1. Cloner/créer la structure
mkdir -p /opt/nextcloud-zabbix-docker
cd /opt/nextcloud-zabbix-docker

# 2. Créer tous les fichiers selon la structure

# 3. Rendre les scripts exécutables
chmod +x scripts/*.sh
chmod +x PRA-PCA/*.sh

# 4. Déployer
./scripts/deploy-all.sh

# 5. Vérifier
./scripts/status.sh
```

## Accès aux Services

- **Nextcloud**: http://localhost:8080
- **Zabbix**: http://localhost:8081 (admin/zabbix)

## Plan de Reprise (PRA)

### RTO/RPO
- **RTO**: 15 minutes (restauration manuelle)
- **RPO**: 24h (sauvegarde quotidienne)

### Procédure de reprise
1. Restaurer les images Docker sur le serveur DR
2. Exécuter les scripts de restauration
3. Vérifier les services
4. Rediriger le DNS

## Avantages

✅ **Simple**: Pas d'Ansible, juste Docker  
✅ **Séparé**: Services indépendants  
✅ **Complet**: PRA/PCA inclus  
✅ **Rapide**: Déploiement en une commande  
✅ **Flexible**: Restauration granulaire possible