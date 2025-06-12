# MSPR2

# Template Ansible - Debian 12 + Zabbix + Conformité RGPD

Ce template Ansible permet de déployer automatiquement une infrastructure de monitoring basée sur Zabbix avec une configuration respectant les exigences du RGPD.

## 🎯 Fonctionnalités

### ✅ Configuration système
- Debian 12 (Bookworm) configuré et sécurisé
- Mise à jour automatique du système
- Configuration timezone et locales françaises
- Synchronisation NTP

### 🔐 Sécurité
- Firewall UFW configuré
- Fail2ban pour la protection contre les intrusions
- Configuration SSH sécurisée
- Audit système avec auditd
- Mises à jour de sécurité automatiques
- Certificats SSL auto-signés

### 📊 Monitoring Zabbix
- Zabbix Server 6.4 avec interface web
- Base de données MySQL/MariaDB
- Agent Zabbix configuré
- Interface HTTPS sécurisée
- Configuration optimisée pour la production

### 🛡️ Conformité RGPD
- Rétention automatique des données (90 jours par défaut)
- Anonymisation des logs
- Scripts de nettoyage automatique
- Registre des traitements
- Headers de confidentialité
- Documentation de conformité

## 📋 Prérequis

### Sur votre machine de contrôle :
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install -y ansible python3-pip git

# CentOS/RHEL
sudo yum install -y ansible python3-pip git

# macOS
brew install ansible
```

### Sur les serveurs cibles :
- Debian 12 (Bookworm) fraîchement installé
- Accès SSH root avec clé publique
- Connexion Internet pour télécharger les paquets

## 🚀 Installation rapide

### 1. Cloner le projet
```bash
git clone <url-du-projet>
cd ansible-debian12-zabbix-gdpr
```

### 2. Configuration de l'inventaire
Éditez le fichier `inventory/hosts.yml` :
```yaml
all:
  children:
    debian_servers:
      hosts:
        zabbix-server:
          ansible_host: 192.168.1.100  # Votre IP
          ansible_user: root
```

### 3. Déploiement automatique
```bash
chmod +x deploy.sh
./deploy.sh auto
```

## 📁 Structure du projet

```
.
├── site.yml                 # Playbook principal
├── ansible.cfg             # Configuration Ansible
├── deploy.sh               # Script de déploiement
├── inventory/
│   └── hosts.yml          # Inventaire des serveurs
├── group_vars/
│   └── all/
│       └── vault.yml      # Mots de passe chiffrés
├── roles/
│   ├── common/            # Configuration système de base
│   ├── security/          # Sécurisation du système
│   ├── zabbix-server/     # Installation Zabbix
│   ├── gdpr-compliance/   # Conformité RGPD
│   └── monitoring-agents/ # Agents de monitoring
└── logs/                  # Logs d'exécution
```

## 🔧 Configuration détaillée

### Variables principales
Dans `group_vars/all/main.yml` :
```yaml
# Configuration de base
timezone: "Europe/Paris"
locale: "fr_FR.UTF-8"
domain_name: "votre-domaine.com"

# Configuration RGPD
log_retention_days: 90
gdpr_contact_email: "dpo@votre-domaine.com"

# Configuration Zabbix
zabbix_version: "6.4"
zabbix_server_name: "Production Monitor"
```

### Gestion des mots de passe
1. Éditer le fichier vault :
```bash
ansible-vault edit group_vars/all/vault.yml
```

2. Modifier les mots de passe par défaut :
```yaml
vault_mysql_root_password: "VotreMotDePasseMySQL"
vault_mysql_zabbix_password: "VotreMotDePasseZabbix"
vault_zabbix_admin_password: "VotreMotDePasseAdmin"
```

### Déploiement par étapes

#### 1. Vérification de la connectivité
```bash
ansible all -i inventory/hosts.yml -m ping
```

#### 2. Déploiement du système de base
```bash
ansible-playbook -i inventory/hosts.yml site.yml --tags "common,security"
```

#### 3. Installation de Zabbix
```bash
ansible-playbook -i inventory/hosts.yml site.yml --tags "zabbix"
```

#### 4. Configuration RGPD
```bash
ansible-playbook -i inventory/hosts.yml site.yml --tags "gdpr"
```

## 🌐 Accès à Zabbix

Après déploiement :
- **URL** : https://votre-ip-serveur/zabbix
- **Utilisateur** : Admin
- **Mot de passe** : Celui défini dans vault_zabbix_admin_password

## 📊 Monitoring configuré

### Éléments surveillés par défaut :
- CPU, mémoire, disque
- Services système critiques
- Logs d'erreurs
- Connexions réseau
- Processus Zabbix

### Alertes configurées :
- Utilisation CPU > 80%
- Utilisation mémoire > 85%
- Espace disque < 10%
- Services critiques arrêtés

## 🛡️ Fonctionnalités RGPD

### Rétention des données
- **Logs système** : 90 jours (configurable)
- **Données Zabbix** : 90 jours (configurable)
- **Logs d'audit** : 1 an

### Anonymisation
- Anonymisation automatique des adresses IP dans les logs
- Script de nettoyage quotidien
- Chiffrement des logs sensibles

### Documentation automatique
- Registre des traitements généré automatiquement
- Rapport de conformité mensuel
- Politique de confidentialité

## 🔧 Maintenance

### Commandes utiles

#### Mise à jour du système
```bash
ansible-playbook -i inventory/hosts.yml site.yml --tags "update"
```

#### Sauvegarde de la configuration Zabbix
```bash
ansible debian_servers -i inventory/hosts.yml -m shell -a "mysqldump -uzabbix -p zabbix > /tmp/zabbix_backup_$(date +%Y%m%d).sql"
```

#### Vérification de la conformité RGPD
```bash
ansible debian_servers -i inventory/hosts.yml -m shell -a "/usr/local/bin/gdpr-compliance-report.sh"
```

### Logs à surveiller
- `/var/log/ansible.log` - Logs d'exécution Ansible
- `/var/log/zabbix/zabbix_server.log` - Logs Zabbix server
- `/var/log/gdpr-cleanup.log` - Logs de nettoyage RGPD
- `/var/log/fail2ban.log` - Logs de sécurité

## 🚨 Dépannage

### Problèmes courants

#### 1. Erreur de connexion SSH
```bash
# Vérifier la connectivité
ssh root@votre-ip-serveur

# Régénérer les clés SSH si nécessaire
ssh-keygen -R votre-ip-serveur
```

#### 2. Erreur de base de données Zabbix
```bash
# Se connecter au serveur et vérifier MySQL
systemctl status mariadb
mysql -uroot -p -e "SHOW DATABASES;"
```

#### 3. Interface Zabbix inaccessible
```bash
# Vérifier Apache et les services
systemctl status apache2
systemctl status zabbix-server
```

#### 4. Problème de certificat SSL
```bash
# Régénérer le certificat
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/apache-selfsigned.key \
  -out /etc/ssl/certs/apache-selfsigned.crt
```

## 📞 Support

### Logs de débogage
Pour activer le mode debug :
```bash
ansible-playbook -i inventory/hosts.yml site.yml -vvv
```

### Ressources utiles
- [Documentation Zabbix](https://www.zabbix.com/documentation)
- [Guide RGPD](https://www.cnil.fr/fr/reglement-europeen-protection-donnees)
- [Documentation Ansible](https://docs.ansible.com/)

## 📝 Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails.

## 🤝 Contribution

Les contributions sont bienvenues ! Merci de :
1. Forker le projet
2. Créer une branche pour votre fonctionnalité
3. Commiter vos changements
4. Pousser vers la branche
5. Ouvrir une Pull Request

---

**⚠️ Important** : Ce template respecte les exigences RGPD mais une validation juridique est recommandée pour votre cas d'usage spécifique.