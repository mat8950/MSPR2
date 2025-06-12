#!/bin/bash

# Script de déploiement automatisé Debian 12 + Zabbix + RGPD
# Auteur: Votre nom
# Version: 1.0

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INVENTORY_FILE="inventory/hosts.yml"
VAULT_FILE="group_vars/all/vault.yml"
LOG_DIR="logs"

# Fonctions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Vérifications préliminaires
check_requirements() {
    log "Vérification des prérequis..."
    
    # Vérifier Ansible
    if ! command -v ansible-playbook &> /dev/null; then
        error "Ansible n'est pas installé. Veuillez l'installer d'abord."
    fi
    
    # Vérifier Python
    if ! command -v python3 &> /dev/null; then
        error "Python 3 n'est pas installé."
    fi
    
    # Vérifier la structure des dossiers
    if [ ! -f "$INVENTORY_FILE" ]; then
        error "Fichier d'inventaire non trouvé: $INVENTORY_FILE"
    fi
    
    info "Tous les prérequis sont satisfaits."
}

# Création de la structure des dossiers
create_directories() {
    log "Création de la structure des dossiers..."
    
    mkdir -p logs
    mkdir -p group_vars/all
    mkdir -p host_vars
    mkdir -p roles/{common,security,zabbix-server,gdpr-compliance,monitoring-agents}/{tasks,templates,files,handlers,vars,defaults}
    
    info "Structure des dossiers créée."
}

# Configuration du vault Ansible
setup_vault() {
    log "Configuration du coffre-fort Ansible..."
    
    if [ ! -f "$VAULT_FILE" ]; then
        cat > "$VAULT_FILE" << 'EOF'
---
# Fichier de mots de passe chiffrés Ansible Vault
# Pour chiffrer: ansible-vault encrypt group_vars/all/vault.yml
# Pour éditer: ansible-vault edit group_vars/all/vault.yml

vault_mysql_root_password: "ChangeMe_MySQL_Root_123!"
vault_mysql_zabbix_password: "ChangeMe_MySQL_Zabbix_456!"
vault_zabbix_admin_password: "ChangeMe_Zabbix_Admin_789!"
vault_ssl_passphrase: "ChangeMe_SSL_Pass_000!"
EOF
        
        warn "Fichier vault créé avec des mots de passe par défaut."
        warn "IMPORTANT: Changez les mots de passe dans $VAULT_FILE puis chiffrez-le avec:"
        warn "ansible-vault encrypt $VAULT_FILE"
    fi
}

# Test de connectivité
test_connectivity() {
    log "Test de connectivité vers les serveurs..."
    
    if ! ansible all -i "$INVENTORY_FILE" -m ping; then
        error "Impossible de se connecter aux serveurs. Vérifiez votre inventaire et vos clés SSH."
    fi
    
    info "Connectivité OK."
}

# Déploiement principal
deploy() {
    log "Début du déploiement..."
    
    # Vérifier si le vault est chiffré
    if grep -q "ChangeMe" "$VAULT_FILE" 2>/dev/null; then
        warn "Le fichier vault contient encore les mots de passe par défaut!"
        read -p "Voulez-vous continuer quand même? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Lancer le playbook
    local extra_args=""
    if ansible-vault view "$VAULT_FILE" &>/dev/null; then
        extra_args="--ask-vault-pass"
        info "Vault détecté comme chiffré, demande du mot de passe vault."
    fi
    
    ansible-playbook -i "$INVENTORY_FILE" site.yml $extra_args \
        --extra-vars "@$VAULT_FILE" \
        --diff \
        -v
    
    if [ $? -eq 0 ]; then
        log "Déploiement terminé avec succès!"
        info "Accédez à Zabbix via: https://YOUR_SERVER_IP/zabbix"
        info "Utilisateur: Admin"
        info "Consultez les logs dans: $LOG_DIR/"
    else
        error "Le déploiement a échoué. Consultez les logs pour plus d'informations."
    fi
}

# Installation des collections Ansible requises
install_collections() {
    log "Installation des collections Ansible..."
    
    cat > requirements.yml << 'EOF'
---
collections:
  - name: community.general
    version: ">=3.0.0"
  - name: community.mysql
    version: ">=2.0.0"
  - name: community.crypto
    version: ">=1.0.0"
  - name: ansible.posix
    version: ">=1.0.0"
EOF
    
    ansible-galaxy collection install -r requirements.yml
    
    info "Collections installées."
}

# Menu principal
show_menu() {
    echo
    echo "=== Déploiement Debian 12 + Zabbix + RGPD ==="
    echo "1. Installation complète (recommandé)"
    echo "2. Vérification seulement"
    echo "3. Test de connectivité"
    echo "4. Configuration du vault"
    echo "5. Déploiement seulement"
    echo "6. Quitter"
    echo
}

# Main
main() {
    cd "$SCRIPT_DIR"
    
    if [ "$1" = "auto" ]; then
        check_requirements
        create_directories
        install_collections
        setup_vault
        test_connectivity
        deploy
        exit 0
    fi
    
    while true; do
        show_menu
        read -p "Choisissez une option [1-6]: " choice
        
        case $choice in
            1)
                check_requirements
                create_directories
                install_collections
                setup_vault
                test_connectivity
                deploy
                ;;
            2)
                check_requirements
                ;;
            3)
                test_connectivity
                ;;
            4)
                setup_vault
                ;;
            5)
                deploy
                ;;
            6)
                log "Au revoir!"
                exit 0
                ;;
            *)
                warn "Option invalide. Veuillez choisir entre 1 et 6."
                ;;
        esac
        
        echo
        read -p "Appuyez sur Entrée pour continuer..."
    done
}

# Gestion des arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [auto|--help]"
        echo "  auto    : Déploiement automatique complet"
        echo "  --help  : Affiche cette aide"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac