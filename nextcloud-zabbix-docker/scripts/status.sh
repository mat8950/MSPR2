#!/bin/bash

# Configuration
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="/var/log/docker-services.log"

# Couleurs pour le formatage
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Fonction de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

# Fonction de vérification de service
check_service() {
    local service=$1
    local container=$2
    local port=$3
    
    echo -n "Vérification $service... "
    
    # Vérification du conteneur
    if docker ps | grep -q "$container.*Up"; then
        echo -e "${GREEN}En cours d'exécution${NC}"
        
        # Vérification du port
        if nc -z localhost $port 2>/dev/null; then
            echo "  └─ Port $port: ${GREEN}Accessible${NC}"
        else
            echo "  └─ Port $port: ${RED}Non accessible${NC}"
        fi
        
        # Affichage des logs récents (dernières 5 lignes)
        echo "  └─ Derniers logs:"
        docker logs --tail 5 $container 2>&1 | sed 's/^/     /'
    else
        echo -e "${RED}Arrêté${NC}"
    fi
    echo
}

echo "=== État des services ==="
echo

# Vérification Nextcloud
cd "$BASE_DIR/nextcloud" 2>/dev/null
echo "NEXTCLOUD"
echo "---------"
check_service "Nextcloud App" "nextcloud-app" "8080"
check_service "Nextcloud DB" "nextcloud-db" "3306"
check_service "Nextcloud Redis" "nextcloud-redis" "6379"

# Vérification Zabbix
cd "$BASE_DIR/zabbix" 2>/dev/null
echo "ZABBIX"
echo "------"
check_service "Zabbix Server" "zabbix-server" "10051"
check_service "Zabbix Web" "zabbix-web" "8081"
check_service "Zabbix Agent" "zabbix-agent" "10050"
check_service "Zabbix DB" "zabbix-db" "3306"

# Affichage des URLs d'accès
echo "URLs d'accès:"
echo "------------"
echo "Nextcloud : http://localhost:8080"
echo "Zabbix    : http://localhost:8081"
echo

# Vérification de l'espace disque
echo "Espace disque:"
echo "--------------"
df -h /var/lib/docker | tail -n 1

# Vérification de la mémoire des conteneurs
echo
echo "Utilisation mémoire:"
echo "------------------"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep -E "nextcloud|zabbix" 