# Makefile pour API-Driven Infrastructure
# Automatisation des Séquences 1, 2 et 3

# --- CONFIGURATION UTF-8 & SHELL ---
SHELL := /bin/bash
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# Variables
VENV_DIR = rep_localstack
ACTIVATE = . $(VENV_DIR)/bin/activate

# Couleurs pour le terminal
YELLOW = \033[1;33m
CYAN = \033[0;36m
GREEN = \033[0;32m
BLUE = \033[0;34m
RED = \033[0;31m
RESET = \033[0m

# --- CIBLES ---

install:
	@echo -e "$(BLUE)📦 [Sequence 2] Création de l'environnement virtuel...$(RESET)"
	python3 -m venv $(VENV_DIR)
	@echo -e "$(BLUE)⬇️  Installation des dépendances (LocalStack & AWS CLI)...$(RESET)"
	$(ACTIVATE) && pip install --upgrade pip > /dev/null
	$(ACTIVATE) && pip install localstack awscli-local > /dev/null
	@echo -e "$(GREEN)✅ Installation terminée.$(RESET)"

start:
	@echo -e "$(BLUE)🚀 [Sequence 2] Démarrage de LocalStack...$(RESET)"
	$(ACTIVATE) && export S3_SKIP_SIGNATURE_VALIDATION=0 && localstack start -d
	@echo -e "⏳ Attente de la disponibilité des services AWS..."
	@sleep 10
	$(ACTIVATE) && localstack status services
	@echo ""
	@echo -e "$(YELLOW)============================================================$(RESET)"
	@echo -e "$(YELLOW)⚠️  ACTION REQUISE : RÉCUPÉRATION DE L'API AWS LOCALSTACK ⚠️$(RESET)"
	@echo -e "$(YELLOW)============================================================$(RESET)"
	@echo "Votre environnement AWS (LocalStack) est prêt."
	@echo -e "1. Cliquez sur l'onglet $(CYAN)[PORTS]$(RESET) dans votre Codespace."
	@echo -e "2. Rendez $(CYAN)public$(RESET) votre port $(CYAN)4566$(RESET) (Visibilité du port)."
	@echo -e "3. L'URL sera automatiquement détectée par le script !"
	@echo ""
	@echo -e "💡 $(CYAN)Note :$(RESET) Il n'y a rien dans votre navigateur et c'est normal"
	@echo "   car il s'agit d'une API AWS (Pas un développement Web type UX)."
	@echo -e "$(YELLOW)============================================================$(RESET)"

deploy:
	@echo -e "$(BLUE)🏗️  [Sequence 3] Déploiement de l'infrastructure...$(RESET)"
	chmod +x setup.sh
	$(ACTIVATE) && ./setup.sh

stop:
	@echo -e "$(CYAN)🛑 Arrêt des services...$(RESET)"
	$(ACTIVATE) && localstack stop
	@echo -e "$(GREEN)✅ Services arrêtés.$(RESET)"

clean:
	rm -rf $(VENV_DIR)
	rm -f function.zip lambda_function.py
	@echo -e "$(GREEN)🧹 Nettoyage effectué.$(RESET)"

all: install start