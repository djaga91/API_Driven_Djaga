# Atelier : API-Driven Infrastructure sur LocalStack

Ce projet implémente une orchestration de services AWS simulés (LocalStack) pilotée par API. L'objectif est de contrôler une instance EC2 (Démarrage, Arrêt, Supervision) via des requêtes HTTP publiques, sans passer par la console AWS, le tout exécuté dans un GitHub Codespace.

---

## 🏗️ Architecture du projet

Le projet repose sur l'interaction de trois services AWS simulés :
1.  **API Gateway :** Point d'entrée public (Exposé via le proxy GitHub Codespaces).
2.  **AWS Lambda (Python) :** Cerveau de l'opération, elle reçoit l'ordre de l'API et pilote l'infrastructure.
3.  **EC2 (Elastic Compute Cloud) :** La ressource d'infrastructure cible que l'on souhaite démarrer ou arrêter.

---

## ⚙️ Séquence 1 & 2 : Mise en place de l'environnement

Avant de lancer l'automatisation, l'environnement AWS simulé (LocalStack) a été préparé dans le conteneur GitHub Codespaces suivant cette procédure :

### 1. Démarrage de l'environnement
L'environnement s'exécute dans un **GitHub Codespace**, offrant un conteneur Linux isolé.

### 2. Installation des dépendances (LocalStack)
Les commandes suivantes ont permis d'installer le moteur AWS local :

* **Création d'un environnement virtuel Python :**
    ```bash
    sudo -i mkdir rep_localstack
    sudo -i python3 -m venv ./rep_localstack
    ```
    *Pourquoi ?* Cela permet d'isoler les librairies du projet du reste du système.

* **Installation et Configuration :**
    ```bash
    sudo -i pip install --upgrade pip && python3 -m pip install localstack
    export S3_SKIP_SIGNATURE_VALIDATION=0
    ```
    *Pourquoi ?* On installe `localstack` (le simulateur AWS) et on configure une variable d'environnement pour faciliter les échanges S3 (optionnel ici mais bonne pratique).

* **Démarrage du service :**
    ```bash
    localstack start -d
    ```
    *Pourquoi ?* L'option `-d` lance LocalStack en tâche de fond (daemon).

### 3. Exposition Publique (CRUCIAL)
Pour respecter la consigne **"Pas de dépendance au Localhost"**, le port de communication AWS a été ouvert :
* **Port :** `4566`
* **Visibilité :** Configurée sur **Public** (via l'onglet *PORTS* de VS Code).
* **Résultat :** Une URL publique en `app.github.dev` qui sert de *ENDPOINT AWS*.

---

## 🚀 Séquence 3 : Déploiement Automatisé (Infrastructure as Code)

Plutôt que de créer les ressources manuellement, j'ai développé un script d'automatisation **`setup.sh`** qui déploie l'architecture complète en une seule commande.

### Procédure de déploiement
1.  Ouvrir un terminal dans le Codespace.
2.  Exécuter le script :
    ```bash
    chmod +x setup.sh
    ./setup.sh
    ```

### Que fait le script `setup.sh` ? (Détails Techniques)
Le script orchestre la création de l'infrastructure en 5 étapes clés :

1.  **Installation des outils CLI :** Vérifie et installe `awscli-local` si manquant.
2.  **Infrastructure Cible (EC2) :** Démarre une instance EC2 et récupère son ID (ex: `i-12345...`) automatiquement.
3.  **Sécurité (IAM) :** Crée un rôle `lambda-ec2-role` pour autoriser la Lambda à piloter EC2.
4.  **Logique (Lambda) :** Génère et déploie le code Python.
    * *Note technique :* Le code utilise `LOCALSTACK_HOSTNAME` pour communiquer en interne avec Docker, garantissant l'indépendance vis-à-vis du localhost utilisateur.
5.  **Exposition (API Gateway) :** Configure le routing URL.

---

## 🎮 Séquence 4 : Utilisation (Démonstration)

Le script termine en affichant 3 URLs. Ces URLs sont accessibles publiquement via internet (pas de localhost).

### Les Endpoints de pilotage :

| Action | Route | Résultat attendu (JSON) |
| :--- | :--- | :--- |
| **Vérifier** | `.../prod/_user_request_/status` | Affiche l'état (`running` ou `stopped`) et l'ID de l'instance. |
| **Arrêter** | `.../prod/_user_request_/stop` | Envoie l'ordre d'arrêt. L'état passe à `stopping`. |
| **Démarrer** | `.../prod/_user_request_/start` | Relance l'instance. L'état passe à `pending` puis `running`. |

> **Validation :** Il suffit de cliquer sur les liens générés par le script pour voir le JSON de réponse changer d'état dans le navigateur.
