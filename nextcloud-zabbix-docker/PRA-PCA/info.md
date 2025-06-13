# Plan PCA/PRA HA - Infrastructure Docker Complète

## 🏗️ **ARCHITECTURE GÉNÉRALE**

### **Configuration Multi-Sites**
```
┌─────────────────────────────────────┐    ┌─────────────────────────────────────┐
│           SITE PRINCIPAL            │    │             SITE DR                 │
│         (192.168.1.100)             │    │          (10.0.1.100)              │
├─────────────────────────────────────┤    ├─────────────────────────────────────┤
│  ┌─────────┐ ┌─────────┐ ┌─────────┐│    │  ┌─────────┐ ┌─────────┐ ┌─────────┐│
│  │Nextcloud│ │ Zabbix  │ │Keycloak ││    │  │Nextcloud│ │ Zabbix  │ │Keycloak ││
│  │  :8080  │ │  :8081  │ │  :8082  ││    │  │  :8080  │ │  :8081  │ │  :8082  ││
│  └─────────┘ └─────────┘ └─────────┘│    │  └─────────┘ └─────────┘ └─────────┘│
│                                     │    │                                     │
│  📦 Docker Volumes                  │────┤  📦 Docker Volumes                  │
│  🗄️  Bases de données              │    │  🗄️  Bases de données              │
│  ⚙️  Configurations                 │    │  ⚙️  Configurations                 │
└─────────────────────────────────────┘    └─────────────────────────────────────┘
                    │                                        ▲
                    │                                        │
                    └── rsync différentiel (quotidien) ──────┘
```

### **Services par Site**

| Service | Port Principal | Port DR | DB | Volume Principal | Volume DR |
|---------|----------------|---------|----|--------------------|-----------|
| **Nextcloud** | 8080 | 8080 | MariaDB | nextcloud_data | nextcloud_data |
| **Zabbix** | 8081 | 8081 | MariaDB | zabbix_data | zabbix_data |
| **Keycloak** | 8082 | 8082 | PostgreSQL | keycloak_data | keycloak_data |

## 🎯 **OBJECTIFS PCA/PRA**

### **RTO/RPO Cibles**
- **RTO** (Recovery Time Objective) : **30 minutes maximum**
- **RPO** (Recovery Point Objective) : **24 heures maximum**
- **Disponibilité cible** : **99.5%** (43h d'arrêt/an)

### **Scénarios Couverts**
✅ **Panne serveur principal**  
✅ **Panne réseau site principal**  
✅ **Corruption de données**  
✅ **Erreur humaine**  
✅ **Cyber-attaque/ransomware**  
✅ **Sinistre physique site principal**  

## 📋 **STRATÉGIE DE SAUVEGARDE**

### **Sauvegarde Locale (Site Principal)**
```bash
# Planification Cron
0 2 * * * /opt/nextcloud-zabbix-docker/PRA-PCA/backup-local.sh

# Contenu sauvegardé quotidiennement :
- Export SQL des bases de données (MariaDB + PostgreSQL)
- Archives tar.gz des volumes Docker
- Configurations (.env, docker-compose.yml)
- Images Docker (export périodique)
```

### **Synchronisation Différentielle (rsync)**
```bash
# Planification Cron
0 4 * * * /opt/nextcloud-zabbix-docker/PRA-PCA/sync-dr.sh

# Méthode : rsync avec algorithme différentiel
rsync -avz --delete --stats /backup/ backup@10.0.1.100:/srv/backups/

# Avantages :
- Transfert uniquement des blocs modifiés
- Économie 80-95% de bande passante
- Compression automatique
- Reprise après interruption
```

### **Rétention des Sauvegardes**
- **Locale** : 7 jours (rotation automatique)
- **Site DR** : 30 jours
- **Archives mensuelles** : 12 mois

## 🔄 **PROCÉDURES PCA**

### **1. Détection de Panne**
```bash
# Monitoring automatique (cron 5min)
*/5 * * * * /opt/scripts/check-services-health.sh

# Vérifications :
- Statut conteneurs Docker (docker ps)
- Connectivité réseau (ping, curl)  
- Réponse services web (HTTP 200)
- Espace disque disponible
- Charge système (load average)
```

### **2. Basculement Automatique**
```bash
#!/bin/bash
# PRA-PCA/failover-to-dr.sh

echo "=== BASCULEMENT VERS SITE DR ==="

# 1. Arrêt propre site principal (si accessible)
if ping -c 1 192.168.1.100; then
    ssh admin@192.168.1.100 "cd /opt/nextcloud-zabbix-docker && ./scripts/stop-all.sh"
fi

# 2. Activation site DR
ssh admin@10.0.1.100 << 'EOF'
    cd /opt/nextcloud-zabbix-docker
    ./scripts/start-all.sh
    ./scripts/status.sh
EOF

# 3. Vérification services DR
curl -f http://10.0.1.100:8080 && echo "✅ Nextcloud DR OK"
curl -f http://10.0.1.100:8081 && echo "✅ Zabbix DR OK"  
curl -f http://10.0.1.100:8082 && echo "✅ Keycloak DR OK"

echo "=== BASCULEMENT TERMINÉ ==="
```

### **3. Notification d'Incident**
```bash
# Alertes automatiques
- Email équipe technique
- SMS administrateurs
- Webhook Slack/Teams
- Mise à jour page statut
```

## 🛠️ **PROCÉDURES PRA**

### **1. Restauration Complète Site DR**
```bash
#!/bin/bash
# PRA-PCA/restore-complete-dr.sh

BACKUP_DATE=$1  # Format: YYYYMMDD_HHMMSS

echo "=== RESTAURATION COMPLÈTE SITE DR ==="
echo "Date de sauvegarde: $BACKUP_DATE"

# 1. Charger les images Docker
./restore-docker-images.sh

# 2. Restaurer chaque service
./restore-nextcloud.sh $BACKUP_DATE
./restore-zabbix.sh $BACKUP_DATE  
./restore-keycloak.sh $BACKUP_DATE

# 3. Démarrage ordonné
./scripts/start-all.sh

# 4. Tests de validation
./scripts/validate-restoration.sh

echo "=== RESTAURATION TERMINÉE ==="
```

### **2. Restauration Granulaire par Service**

#### **Nextcloud**
```bash
#!/bin/bash
# PRA-PCA/restore-nextcloud.sh

BACKUP_DATE=$1
BACKUP_DIR="/srv/backups/$BACKUP_DATE"

# Arrêt service
cd /opt/nextcloud-zabbix-docker/nextcloud
docker compose down

# Restauration données
rm -rf data/
tar xzf $BACKUP_DIR/nextcloud/data.tar.gz

# Restauration config
cp $BACKUP_DIR/nextcloud/.env .
cp $BACKUP_DIR/nextcloud/docker-compose.yml .

# Redémarrage
docker compose up -d
sleep 30

# Restauration BDD
docker compose exec -T nextcloud-db mysql -u root -p"$MYSQL_ROOT_PASSWORD" nextcloud < $BACKUP_DIR/nextcloud/database.sql

echo "✅ Nextcloud restauré depuis $BACKUP_DATE"
```

#### **Zabbix**
```bash
#!/bin/bash  
# PRA-PCA/restore-zabbix.sh

BACKUP_DATE=$1
BACKUP_DIR="/srv/backups/$BACKUP_DATE"

# Arrêt service
cd /opt/nextcloud-zabbix-docker/zabbix
docker compose down

# Restauration données + config
rm -rf data/
tar xzf $BACKUP_DIR/zabbix/data.tar.gz
cp $BACKUP_DIR/zabbix/.env .
cp $BACKUP_DIR/zabbix/docker-compose.yml .

# Redémarrage
docker compose up -d
sleep 45

# Restauration BDD
docker compose exec -T zabbix-db mysql -u root -p"$MYSQL_ROOT_PASSWORD" zabbix < $BACKUP_DIR/zabbix/database.sql

echo "✅ Zabbix restauré depuis $BACKUP_DATE"
```

#### **Keycloak**
```bash
#!/bin/bash
# PRA-PCA/restore-keycloak.sh

BACKUP_DATE=$1
BACKUP_DIR="/srv/backups/$BACKUP_DATE"

# Arrêt service
cd /opt/nextcloud-zabbix-docker/keycloak  
docker compose down

# Restauration données + config
rm -rf data/ config/
tar xzf $BACKUP_DIR/keycloak/data.tar.gz
tar xzf $BACKUP_DIR/keycloak/config.tar.gz
cp $BACKUP_DIR/keycloak/.env .

# Configuration site DR
cp .env.site2 .env

# Redémarrage
docker compose up -d
sleep 45

# Restauration BDD PostgreSQL
docker compose exec -T keycloak-db psql -U keycloak keycloak < $BACKUP_DIR/keycloak/database.sql

echo "✅ Keycloak restauré depuis $BACKUP_DATE"
```

## 📊 **HAUTE DISPONIBILITÉ (HA)**

### **Option 1 : Docker Swarm (Recommandée)**
```yaml
# Configuration Swarm pour HA
version: '3.8'

services:
  nextcloud:
    image: nextcloud:28
    deploy:
      replicas: 2                    # 2 instances minimum
      placement:
        max_replicas_per_node: 1    # 1 par serveur max
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
    # Stockage NFS partagé requis
    volumes:
      - type: volume
        source: nextcloud_data
        target: /var/www/html
        volume:
          driver: local
          driver_opts:
            type: nfs
            o: addr=192.168.1.200,rw
            device: ":/srv/nfs/nextcloud"
```

### **Option 2 : Keepalived + VIP**
```bash
# Configuration keepalived.conf
vrrp_instance VI_1 {
    state MASTER                    # BACKUP sur serveur 2
    interface eth0
    virtual_router_id 51
    priority 100                    # 90 sur serveur 2
    advert_int 1
    
    virtual_ipaddress {
        192.168.1.50/24            # IP virtuelle
    }
    
    notify_master "/opt/scripts/start-docker-services.sh"
    notify_backup "/opt/scripts/stop-docker-services.sh"
}
```

## 🧪 **TESTS ET VALIDATION**

### **Tests Mensuels Obligatoires**
```bash
#!/bin/bash
# tests/monthly-dr-test.sh

echo "=== TEST DR MENSUEL ==="

# 1. Test restauration sur environnement isolé
./restore-complete-dr.sh $(ls /srv/backups | tail -1)

# 2. Validation fonctionnelle
curl -f http://10.0.1.100:8080/status.php    # Nextcloud
curl -f http://10.0.1.100:8081/api_jsonrpc.php # Zabbix
curl -f http://10.0.1.100:8082/health        # Keycloak

# 3. Test de performance
ab -n 100 -c 10 http://10.0.1.100:8080/      # Apache Bench

# 4. Test SSO
./test-sso-integration.sh

# 5. Rapport de test
echo "Rapport envoyé par email"
```

### **Tests de Charge**
```bash
# Test de montée en charge
docker run --rm -v /opt/tests:/tests \
  loadimpact/k6 run /tests/load-test.js

# Surveillance pendant les tests
docker stats
iostat -x 1
```

## 📈 **MONITORING ET ALERTES**

### **Métriques Surveillées**
- **Disponibilité services** : HTTP 200 response
- **Performance** : Temps de réponse < 2s
- **Stockage** : Utilisation < 80%
- **Réseau** : Latence < 100ms vers DR
- **Sauvegarde** : Success quotidien
- **Synchronisation** : Delta rsync < 24h

### **Alertes Configurées**
```bash
# Zabbix - Monitoring de l'infrastructure
- Service down > 5min → Email + SMS
- Espace disque > 85% → Email
- Load average > 4.0 → Email
- Échec sauvegarde → Email + SMS urgent
- Échec sync rsync → Email

# Seuils d'escalade
- 15min panne → Astreinte niveau 2
- 30min panne → Astreinte niveau 1
- 1h panne → Direction technique
```

## 📋 **CHECKLIST OPÉRATIONNELLE**

### **Vérifications Quotidiennes**
- [ ] Statut containers Docker
- [ ] Logs d'erreur
- [ ] Espace disque disponible
- [ ] Succès sauvegarde nocturne
- [ ] Succès synchronisation rsync

### **Vérifications Hebdomadaires**  
- [ ] Test connexion site DR
- [ ] Vérification intégrité sauvegardes
- [ ] Mise à jour images Docker
- [ ] Rotation logs
- [ ] Performance générale

### **Vérifications Mensuelles**
- [ ] Test restauration DR complet
- [ ] Test basculement HA
- [ ] Révision documentation
- [ ] Formation équipe
- [ ] Audit sécurité

## 🎯 **INDICATEURS CLÉS (KPI)**

### **Disponibilité**
- **Uptime** : > 99.5%
- **MTBF** : > 720h (30 jours)
- **MTTR** : < 30min

### **Performance**
- **RTO réel** : < 30min
- **RPO réel** : < 24h  
- **Taille sauvegarde** : Monitoring quotidien
- **Efficacité rsync** : > 80% économie bande passante

### **Coûts**
- **Stockage DR** : Monitoring mensuel
- **Bande passante** : Monitoring quotidien
- **Temps équipe** : < 2h/semaine maintenance

## 🚨 **CONTACTS ET ESCALADE**

### **Équipe Technique**
- **Administrateur Principal** : [Nom] - [Téléphone] - [Email]
- **Administrateur Backup** : [Nom] - [Téléphone] - [Email]
- **Astreinte Weekend** : [Téléphone]

### **Procédure d'Escalade**
1. **0-15min** : Équipe technique
2. **15-30min** : Chef d'équipe + Direction IT
3. **30min+** : Direction générale + Communication

### **Outils de Communication**
- **Slack** : Canal #incidents
- **Email** : it-emergency@company.com
- **SMS** : Liste diffusion astreinte
- **Téléphone** : Permanence 24/7

Cette documentation PCA/PRA HA est complète et opérationnelle ! 🎯