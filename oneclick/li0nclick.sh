#!/bin/bash

###############################################################################
#  LINUX DEV ENVIRONMENT ONE-CLICK INSTALLER
#  Built by DropXtor
###############################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Banner
echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║   ██████╗ ██████╗  ██████╗ ██████╗ ██╗  ██╗████████╗ ██████╗ ██████╗      ║
║   ██╔══██╗██╔══██╗██╔═══██╗██╔══██╗╚██╗██╔╝╚══██╔══╝██╔═══██╗██╔══██╗     ║
║   ██║  ██║██████╔╝██║   ██║██████╔╝ ╚███╔╝    ██║   ██║   ██║██████╔╝     ║
║   ██║  ██║██╔══██╗██║   ██║██╔═══╝  ██╔██╗    ██║   ██║   ██║██╔══██╗     ║
║   ██████╔╝██║  ██║╚██████╔╝██║     ██╔╝ ██╗   ██║   ╚██████╔╝██║  ██║     ║
║   ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝     ║
║                                                                           ║
║              🔥 LINUX DEV ENVIRONMENT - ONE CLICK INSTALLER 🔥            ║
║                           [ Built by DropXtor ]                           ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
log_error()   { echo -e "${RED}[✗]${NC} $1"; }

# Ne pas lancer en root
if [[ $EUID -eq 0 ]]; then
   log_error "Ne lance pas ce script en root (utilise un user sudo)."
   exit 1
fi

# Sudo warm‑up
log_info "Demande des droits sudo..."
sudo -v

# Keep sudo alive
while true; do
  sudo -n true 2>/dev/null || exit 0
  sleep 60
  kill -0 "$$" 2>/dev/null || exit 0
done &

###############################################################################
# UPDATE SYSTEM
###############################################################################
log_info "Update & upgrade du système..."
sudo apt-get update && sudo apt-get upgrade -y
log_success "Système à jour."

###############################################################################
# SECTION 1: MAIN PACKAGES
###############################################################################
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║            INSTALLATION DES PACKAGES DE BASE                   ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

PACKAGES="curl screen iptables build-essential git wget lz4 jq make gcc nano \
automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev \
libleveldb-dev tar clang bsdmainutils ncdu unzip ca-certificates \
fzf ripgrep tree"

log_info "Installation des paquets principaux..."
sudo apt install -y $PACKAGES
log_success "Packages de base installés."

###############################################################################
# SECTION 2: PYTHON3 & PIP
###############################################################################
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║            INSTALLATION DE PYTHON3 & PIP                       ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

log_info "Installation de python3-pip et deps build..."
sudo apt install -y python3-pip
sudo apt install -y build-essential libssl-dev libffi-dev python3-dev
python3 --version || true
pip3 --version || true
log_success "Python3 + pip3 OK."

###############################################################################
# SECTION 3: GO 1.22.3
###############################################################################
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║            INSTALLATION DE GO (GOLANG) 1.22.3                  ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

log_info "Suppression éventuelle d’une ancienne version de Go..."
sudo rm -rf /usr/local/go

ARCH=$(uname -m)
GO_ARCH="linux-amd64"
if [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
  GO_ARCH="linux-arm64"
fi

log_info "Installation de Go 1.22.3 pour ${GO_ARCH}..."
curl -L "https://go.dev/dl/go1.22.3.${GO_ARCH}.tar.gz" | sudo tar -xzf - -C /usr/local

# PATH Go
if ! grep -q "/usr/local/go/bin" "$HOME/.bash_profile" 2>/dev/null; then
  echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> "$HOME/.bash_profile"
fi
if ! grep -q "/usr/local/go/bin" "$HOME/.bashrc" 2>/dev/null; then
  echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> "$HOME/.bashrc"
fi

# shellcheck source=/dev/null
if [ -f "$HOME/.bash_profile" ]; then
  source "$HOME/.bash_profile"
elif [ -f "$HOME/.bashrc" ]; then
  source "$HOME/.bashrc"
fi

export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
go version || true
log_success "Go installé."

###############################################################################
# SECTION 4: NODEJS 18, NPM & YARN
###############################################################################
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║            INSTALLATION DE NODE 23, NPM & YARN                 ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

CURRENT_NODE=$(node --version 2>/dev/null || echo "")

if [[ "$CURRENT_NODE" == v23* ]]; then
  log_warn "Node.js 23 déjà présent ($CURRENT_NODE), skip."
else
  log_info "Nettoyage éventuel d’une vieille version de Node..."
  sudo apt-get remove -y nodejs 2>/dev/null || true
  sudo apt-get purge -y nodejs 2>/dev/null || true
  sudo apt-get autoremove -y 2>/dev/null || true
  sudo rm -f /etc/apt/keyrings/nodesource.gpg 2>/dev/null || true
  sudo rm -f /etc/apt/sources.list.d/nodesource.list 2>/dev/null || true

  log_info "Setup du dépôt NodeSource pour Node 23..."
  curl -fsSL https://deb.nodesource.com/setup_23.x | sudo -E bash -
  sudo apt install -y nodejs

  log_success "Node.js 23 installé.[web:62]"
fi

node -v || true
npm -v || true

log_info "Installation de Yarn (via keyring dédié)..."
sudo mkdir -p /usr/share/keyrings
curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | \
  sudo gpg --yes --dearmor -o /usr/share/keyrings/yarnkey.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | \
  sudo tee /etc/apt/sources.list.d/yarn.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y yarn
yarn --version || true
log_success "Yarn installé sans warnings de clé GPG expirée.[web:63][web:60]"

###############################################################################
# SECTION 5: DOCKER & DOCKER COMPOSE
###############################################################################
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║            INSTALLATION DE DOCKER & DOCKER COMPOSE             ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

log_info "Suppression d’anciens Docker..."
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
  sudo apt-get remove -y "$pkg" 2>/dev/null || true
done

log_info "Installation des prérequis Docker..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Ajout user au groupe docker
sudo usermod -aG docker "$USER"

log_info "Test rapide Docker (hello-world)..."
sudo docker run --rm hello-world || log_warn "Test hello-world échoué (réseau ou DNS), vérifie manuellement."
log_success "Docker OK via dépôt officiel Docker pour Ubuntu/Debian.[web:13][web:8]"

###############################################################################
# SECTION 6: LSOF & UFW
###############################################################################
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║            INSTALLATION DE LSOF & UFW                          ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

log_info "Installation de lsof..."
sudo apt install -y lsof

log_info "Installation de ufw..."
sudo apt install -y ufw

log_info "Rappels commandes utiles :"
echo -e "${YELLOW}  # Ports en écoute   :${NC} lsof -i -P -n | grep LISTEN"
echo -e "${YELLOW}  # Process sur 80    :${NC} lsof -i :80"
echo -e "${YELLOW}  # Ouvrir port 3000  :${NC} sudo ufw allow 3000"
log_success "lsof + ufw installés."

###############################################################################
# SECTION 7: HTOP
###############################################################################
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║            INSTALLATION DE HTOP                                ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

log_info "Installation de htop..."
sudo apt install -y htop
log_success "htop installé (commande: htop)."

###############################################################################
# SECTION 8: GIT TUNING + GITHUB CLI
###############################################################################
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║            CONFIG GIT & GITHUB CLI                             ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

log_info "Configuration minimale Git (branche par défaut main)..."
git config --global init.defaultBranch main || true
git config --global pull.rebase false || true

log_info "Installation de GitHub CLI (gh)..."
sudo apt-get install -y ca-certificates curl gnupg
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
  sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
  sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update -y
sudo apt install -y gh
log_success "GitHub CLI installé (commande: gh)."

###############################################################################
# SECTION 9: ALIASES & TUNING SHELL
###############################################################################
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║            ALIASES DROPXTOR & QUALITÉ DE VIE                   ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

ALIASES_FILE="$HOME/.bash_aliases"
if ! grep -q "### DropXtor aliases" "$ALIASES_FILE" 2>/dev/null; then
  log_info "Ajout d’un set d’aliases dans ~/.bash_aliases..."
  cat >> "$ALIASES_FILE" << 'EOF'

### DropXtor aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Git
alias gs='git status'
alias ga='git add .'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'

# Docker
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dpsa='docker ps -a'
alias dlogs='docker logs -f'
alias dstopall='docker stop $(docker ps -q)'
alias drmiall='docker rm -f $(docker ps -aq)'
alias dpruneall='docker system prune -af'

# Sys
alias c='clear'
alias dn='du -sh * | sort -h'
EOF
  log_success "Aliases ajoutés."
else
  log_warn "~/.bash_aliases contient déjà le bloc DropXtor, skip."
fi

###############################################################################
# FINAL
###############################################################################
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    INSTALLATION TERMINÉE                       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

log_success "Tout est installé."

echo ""
echo -e "${CYAN}Versions détectées:${NC}"
echo -e "  • $(go version 2>/dev/null || echo 'Go: non installé')"
echo -e "  • Node.js : $(node --version 2>/dev/null || echo 'Non installé')"
echo -e "  • npm     : $(npm --version 2>/dev/null || echo 'Non installé')"
echo -e "  • Yarn    : $(yarn --version 2>/dev/null || echo 'Non installé')"
echo -e "  • Docker  : $(docker --version 2>/dev/null || echo 'Non installé')"
echo -e "  • Python  : $(python3 --version 2>/dev/null || echo 'Non installé')"
echo -e "  • pip3    : $(pip3 --version 2>/dev/null | awk '{print $2}' || echo 'Non installé')"

echo ""
echo -e "${YELLOW}Note:${NC} déconnecte‑toi / reconnecte‑toi pour que le groupe 'docker' soit pris en compte."
echo ""
echo -e "${CYAN}Built by DropXtor | Stay cool .${NC}"
