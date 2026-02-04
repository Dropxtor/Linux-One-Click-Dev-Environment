#  One-Click Dev Environment

Pour transformer un VPS Debian/Ubuntu nu
en environnement de développement complet (Docker, Node, Go, Python, Git, etc.).

## Fonctionnalités

- Update & upgrade système automatique
- Outils de base : curl, git, build-essential, tmux, htop, ncdu, fzf, ripgrep, tree…
- Python 3 + pip3 + libs de build
- Go 1.22.3 (amd64 / arm64 auto)
- Node.js 18 + npm + Yarn (via dépôt officiel)
- Docker Engine + Docker Compose plugin (dépôt officiel Docker)
- lsof + ufw (gestion des ports & firewall)
- htop (monitoring)
- Git tuning (branche `main` par défaut)
- GitHub CLI (`gh`)
- Aliases Bash "DropXtor" (git, docker, ls, etc.)

## Prérequis

- Distribution basée Debian/Ubuntu
- Accès sudo
- User non-root (ne pas lancer le script en root directement)

## Installation

```bash
git clone https://github.com/Dropxtor/Linux-One-Click-Dev-Environment.git
cd oneclick
chmod +x li0nclick.sh
./li0nclick.sh
