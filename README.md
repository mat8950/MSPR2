# Template Ansible - Debian 12 + Nextcloud + Zabbix + Conformité RGPD

Ce template Ansible permet de déployer automatiquement une plateforme cloud Nextcloud avec monitoring Zabbix et configuration respectant les exigences du RGPD.

## 🎯 Fonctionnalités

### ✅ Configuration système
- Debian 12 (Bookworm) configuré et sécurisé
- Mise à jour automatique du système
- Configuration timezone et locales françaises
- Synchronisation NTP

### ☁️ Nextcloud Cloud Platform
- **Nextcloud 28** - Plateforme cloud complète
- **Interface française** - Configuration locale par défaut
- **Stockage sécurisé** - Chiffrement côté serveur activé
- **Authentification 2FA** - Sécurité renforcée
- **Redis cache** - Performance optimisée
- **HTTPS obligatoire** - Certificats SSL auto-signés
- **Applications RGPD** - Data Request et Privacy intégrées

### 🔐 Sécurité
- Firewall UFW configuré
- Fail2ban pour la protection contre les intrusions
- Configuration SSH sécurisée
- Audit système avec auditd
- Mises à jour de sécurité automatiques
- Headers de sécurité HTTPS modernes
- Politique de mots de passe renforcée

### 📊 Monitoring Zabbix
- Zabbix Server 6.4 avec interface web
- Base de données MySQL/MariaDB
- Agent Zabbix configuré
- Interface HTTPS sécurisée
- **Monitoring spécifique Nextcloud** :
  - État du service Nextcloud
  - Nombre d'utilisateurs actifs
  - Utilisation du stockage
  - Conformité RGPD (fichiers anciens)
  - Performance de la base de données

### 🛡️ Conformité RGPD
- Rétention automatique des données (90 jours par défaut)
- Anonymisation des logs Apache et Nextcloud
- Scripts de nettoyage automatique des fichiers anciens
- Registre des traitements
- Headers de confidentialité
- **Spécifique Nextcloud** :
  - Nettoyage automatique de la corbeille
  - Suppression des versions anciennes de fichiers
  - Rotation des logs et sessions
  - Applications RGPD natives activées
  - Contact DPO configuré

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
        nextcloud-server:
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
│   ├── nextcloud/         # Installation Nextcloud
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
domain_name: "cloud.votre-domaine.com"

# Configuration RGPD
log_retention_days: 90
gdpr_contact_email: "dpo@votre-domaine.com"

# Configuration Zabbix
zabbix_version: "6.4"
zabbix_server_name: "Production Monitor"

# Configuration Nextcloud
nextcloud_version: "28"
nextcloud_admin_user: "admin"
nextcloud_domain: "cloud.votre-domaine.com"

# Sécurité et performance
nextcloud_max_file_size: "16G"
redis_cache_enabled: true
encryption_enabled: true
```

### Gestion des mots de passe
1. Éditer le fichier vault :
```bash
ansible-vault edit group_vars/all/vault.yml
```

2. Modifier les mots de passe par défaut :
```yaml
# Mots de passe MySQL
vault_mysql_root_password: "VotreMotDePasseMySQL"
vault_mysql_zabbix_password: "VotreMotDePasseZabbix"

# Mots de passe Zabbix
vault_zabbix_admin_password: "VotreMotDePasseAdmin"

# Mots de passe Nextcloud
vault_nextcloud_admin_password: "VotreMotDePasseNextcloud"
vault_nextcloud_db_password: "VotreMotDePasseNextcloudDB"
vault_redis_password: "VotreMotDePasseRedis"
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

## 🌐 Accès aux interfaces

Après déploiement :

### **Nextcloud** :
- **URL** : https://votre-ip-serveur/
- **Utilisateur Admin** : admin
- **Mot de passe** : Celui défini dans vault_nextcloud_admin_password
- **Interface** : Française par défaut
- **Fonctionnalités** : Stockage, partage, calendrier, contacts, applications

### **Zabbix** :
- **URL** : https://votre-ip-serveur/zabbix
- **Utilisateur** : Admin
- **Mot de passe** : Celui défini dans vault_zabbix_admin_password

## 📊 Monitoring configuré

### Éléments surveillés par défaut :
- **Système** : CPU, mémoire, disque, services
- **Nextcloud** :
  - État du service (disponibilité, maintenance)
  - Nombre d'utilisateurs actifs/total
  - Utilisation du stockage (fichiers, corbeille, versions)
  - Conformité RGPD (fichiers anciens à nettoyer)
  - Performance base de données et Redis
- Logs d'erreurs système et Nextcloud
- Processus critiques (Apache, PHP-FPM, Redis)

### Alertes configurées :
- Utilisation CPU > 80%
- Utilisation mémoire > 85%
- Espace disque < 10%
- Services critiques arrêtés
- **Nextcloud spécifique** :
  - Service Nextcloud indisponible
  - Mode maintenance activé
  - Fichiers anciens non nettoyés (conformité RGPD)
  - Base de données trop volumineuse
  - Erreurs dans les logs Nextcloud

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

## 🚀 **Avantages de Nextcloud vs autres solutions cloud**

- ✅ **Souveraineté des données** : Vos données restent chez vous
- ✅ **RGPD native** : Applications et fonctionnalités conformes intégrées  
- ✅ **Interface française** : Configuration locale complète
- ✅ **Extensible** : Plus de 300 applications disponibles
- ✅ **Open Source** : Code ouvert, pas de vendor lock-in
- ✅ **Monitoring intégré** : Surveillance automatique avec Zabbix
- ✅ **Sécurité renforcée** : 2FA, chiffrement, audit automatique

Votre cloud privé Nextcloud sera opérationnel en ~15 minutes ! 🎯