# ☁️ API-Driven Infrastructure (LocalStack Edition)

> **Projet :** Pilotage dynamique d'une infrastructure AWS simulée via API REST.
> **Concept :** "Zero Console" - Tout est contrôlé par le code et les requêtes HTTP.

Ce projet démontre comment orchestrer des ressources Cloud (EC2) sans jamais toucher à une console graphique. L'architecture repose sur **API Gateway** et **Lambda** pour piloter une instance **EC2** au sein d'un environnement **LocalStack** (émulateur AWS).

---

## 🏗️ Architecture Technique

Le flux de données est le suivant :

graph LR
    User["👤 Utilisateur"] -- HTTP GET --> APIG["🌐 API Gateway"]
    APIG -- Trigger --> Lambda["⚡ AWS Lambda (Python)"]
    Lambda -- Boto3 SDK --> EC2["💻 Instance EC2 (LocalStack)"]
    EC2 -- État --> Lambda
    Lambda -- JSON Reponse --> User

* **API Gateway** : Expose les endpoints publics (`/start`, `/stop`, `/status`).
* **AWS Lambda** : "Cerveau" du projet. Reçoit l'ordre, interagit avec l'EC2 et renvoie une réponse JSON formatée (UTF-8).
* **EC2** : La ressource d'infrastructure cible (Machine Virtuelle simulée).

---

## 🚀 Installation & Démarrage (Automatisé)

Ce projet utilise un **Makefile** pour automatiser l'installation des dépendances, le démarrage du moteur Cloud et le déploiement de l'infra.

### Pré-requis

* GitHub Codespaces (Recommandé) ou Linux avec Python 3.

### 1. Installation & Démarrage

Lancez les commandes suivantes pour préparer l'environnement :

```bash
make install   # Crée le venv et installe LocalStack/AWS CLI
make start     # Démarre le moteur AWS en arrière-plan

```

### ⚠️ ÉTAPE CRITIQUE : Exposition du Port

Avant de continuer, vous **devez** rendre l'API accessible :

1. Allez dans l'onglet **[PORTS]** de VS Code.
2. Repérez le port **4566**.
3. Faites **Clic-droit > Visibilité du port > Public**.

> *Sans cette action, les URLs générées ne seront pas accessibles depuis votre navigateur.*

### 2. Déploiement de l'Infrastructure

Une fois le port ouvert, lancez le script de déploiement "Ultimate" :

```bash
make deploy

```

Ce script va automatiquement :

* Detecter votre URL Codespace.
* Lancer une instance EC2.
* Configurer la sécurité (IAM).
* Déployer le code Lambda et l'API Gateway.
* **Vous afficher les liens de contrôle cliquables.**

---

## 🎮 Utilisation de l'API

L'API répond en JSON formaté avec des émojis pour indiquer l'état visuellement.

| Méthode | Endpoint | Action | Réponse attendue (Exemple) |
| --- | --- | --- | --- |
| **GET** | `/status` | Vérifie l'état de la VM | `{"etat_actuel": "running", "message_info": "🔍 Vérification..."}` |
| **GET** | `/stop` | Éteint la VM | `{"etat_actuel": "stopped", "message_info": "🛑 Arrêt demandé..."}` |
| **GET** | `/start` | Allume la VM | `{"etat_actuel": "pending", "message_info": "🚀 Démarrage initié..."}` |

---

## 🧪 Vérification Technique (Preuve de concept)

Comment être sûr que l'API pilote vraiment l'infrastructure ? Faites ce test :

1. Cliquez sur le lien **STOP** dans votre navigateur.
2. Ouvrez votre terminal et demandez directement à AWS l'état de la machine :

```bash
awslocal ec2 describe-instances --query 'Reservations[0].Instances[0].State.Name' --output text

```

**Résultat :** Le terminal affichera `stopped`.
Cela prouve que votre action Web a eu un impact réel sur le Backend ("Back-end driven by Front-end request").

---

## 🛠️ Commandes Utiles (Makefile)

* `make install` : Installe tout.
* `make start` : Lance LocalStack.
* `make deploy` : Déploie l'infra (setup.sh).
* `make clean` : **Nettoyage complet** (Supprime venv, fichiers temporaires et données LocalStack). Utile pour repartir de zéro.
* `make stop` : Arrête les services.

---

*Réalisé dans le cadre du TP API-Driven Infrastructure.*

```

### Comment mettre à jour sur GitHub

Comme d'habitude, une fois le fichier sauvegardé :

```bash
git add README.md
git commit -m "Update: Documentation finale avec Architecture et Procédure complète"
git push

`