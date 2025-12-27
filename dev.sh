#!/usr/bin/env bash
# Development and deployment helper script
# Usage: ./dev.sh [command ...]

set -o pipefail

# Determine if running on GitHub Actions
GITHUB_ACTIONS_RUN="false"
if [ -n "${GITHUB_ACTIONS:-}" ]; then
  GITHUB_ACTIONS_RUN="true"
fi

load_env() {
  if [ "$GITHUB_ACTIONS_RUN" = "true" ]; then
    echo "Running on GitHub Actions. Executing CI-specific commands."
    echo "Loading .env files from GitHub Secrets..."
  else
    echo "Not running on GitHub Actions. Executing local commands."
    if [ ! -f .env ]; then
      echo "✘ .env file not found! Please create a .env file with ./dev.sh new"
      exit 1
    else
      echo "✔ .env file found."
      # Export variables from .env so subsequent commands can use them
      set -a
      # shellcheck disable=SC1091
      . ./.env
      set +a
    fi
  fi
}

cmd_env() {
  load_env
}

cmd_login() {
  load_env
  cmd_docker
  cmd_ec2
}

cmd_docker() {
  load_env
  echo "Authenticating Docker Hub credentials..."
  echo "${DOCKER_PAT}" | docker login -u "${DOCKER_USERNAME}" --password-stdin > /dev/null 2>&1 || {
    echo "✘ Docker Hub authentication failed."
    exit 1
  }
  echo "✔ Docker Hub authentication successful."
}

cmd_ssh() {
  load_env
  ssh -i "${HOME}/.ssh/${EC2_KEY_NAME}" "ubuntu@${EC2_DEPLOY_HOST}"
}

cmd_ec2() {
  load_env
  echo "Validating EC2 connection..."
  chmod 400 "${HOME}/.ssh/${EC2_KEY_NAME}"
  ssh -o StrictHostKeyChecking=no -i "${HOME}/.ssh/${EC2_KEY_NAME}" "ubuntu@${EC2_DEPLOY_HOST}" 'echo "EC2 connection successful."' > /dev/null 2>&1 || {
    echo "✘ EC2 connection failed."
    exit 1
  }
  echo "✔ EC2 connection successful."
  echo "Checking other environment variables..."
  if [ -z "${APP_VERSION:-}" ] || [ -z "${APP_NAME:-}" ] || [ -z "${EC2_DEPLOY_DIR:-}" ]; then
    echo "✘ APP_VERSION, APP_NAME, and EC2_DEPLOY_DIR must be set in .env file."
    exit 1
  else
    echo "APP_NAME: ${APP_NAME}"
    echo "APP_VERSION: ${APP_VERSION}"
    echo "EC2_DEPLOY_DIR: ${EC2_DEPLOY_DIR}"
    echo "✔ All required environment variables are set."
  fi
}

cmd_init() {
  load_env
  echo "Initializing production setup..."
  sed -e "s|__DOCKER_USERNAME__|${DOCKER_USERNAME}|g" \
      -e "s|__APP_VERSION__|${APP_VERSION}|g" \
      -e "s|__APP_NAME__|${APP_NAME}|g" \
      docker-compose-template.yml > docker-compose.yml
  echo "Generated docker-compose.yml from template."
}

cmd_up() {
  load_env
  docker compose up --build
}

cmd_down() {
  load_env
  docker compose down
}

cmd_build() {
  load_env
  docker compose build --no-cache
}

cmd_push() {
  load_env
  docker compose push
}

cmd_deploy() {
  load_env
  echo "Deploying to EC2 instance at ${EC2_DEPLOY_HOST}..."
  ssh -i "${HOME}/.ssh/${EC2_KEY_NAME}" "ubuntu@${EC2_DEPLOY_HOST}" "mkdir -p ${EC2_DEPLOY_DIR}"
  scp -i "${HOME}/.ssh/${EC2_KEY_NAME}" docker-compose.yml "ubuntu@${EC2_DEPLOY_HOST}:${EC2_DEPLOY_DIR}/docker-compose.yml"
  ssh -i "${HOME}/.ssh/${EC2_KEY_NAME}" "ubuntu@${EC2_DEPLOY_HOST}" "cd ${EC2_DEPLOY_DIR} && docker compose pull && docker compose up -d --remove-orphans"
  echo "Deployment complete. Access your application at:"
  echo "http://${EC2_DEPLOY_HOST}"
}

cmd_logs() {
  load_env
  ssh -i "${HOME}/.ssh/${EC2_KEY_NAME}" "ubuntu@${EC2_DEPLOY_HOST}" "cd ${EC2_DEPLOY_DIR} && docker compose logs -f"
}

cmd_web() {
  load_env
  echo "http://${EC2_DEPLOY_HOST}"
}

cmd_clean() {
  rm -rf ./data/
  (cd app && npm run clean)
}

cmd_nuke() {
  echo "⚠️  NUKE WARNING: This will remove ALL configuration and Docker resources!"
  echo ""
  echo "This command will:"
  echo "  • Remove .env file"
  echo "  • Remove docker-compose.yml"
  echo "  • Remove ec2-ssh.sh"
  echo "  • Stop and remove all Docker containers, images, volumes"
  echo "  • Delete local data directory"
  echo ""
  echo "Type 'nuke' to confirm (or anything else to cancel):"
  read -r confirmation
  if [ "$confirmation" != "nuke" ]; then
    echo "✔ Nuke cancelled."
    return 0
  fi

  echo ""
  echo "🔥 Nuking everything..."

  # Stop and remove Docker resources
  docker compose down --rmi all --volumes --remove-orphans 2>/dev/null || true

  # Remove generated files
  rm -f .env
  rm -f docker-compose.yml
  rm -f ec2-ssh.sh

  # Remove data
  rm -rf ./data/

  # Clean app directory
  (cd app && npm run clean 2>/dev/null || true)

  echo "✔ Nuke complete. Everything removed."
  echo ""
  echo "To start fresh, run: ./dev.sh new"
}

cmd_help() {
  echo "Configure commands:"
  echo "  env [e]     - Verify and load .env (CI prints info only)"
  echo "  new [n]     - Create a new .env file interactively"
  echo "  init [i]    - Generate docker-compose.yml from template"
  echo "  login [l]   - Run both: docker + ec2 checks"

  echo "Development commands:"
  echo "  up [u]      - Build images and start services"
  echo "  down [d]    - Stop services"
  echo "  build [b]   - Build Docker images without cache"

  echo "EC2 commands:"
  echo "  web [w]     - Print EC2 web address"
  echo "  ssh [s]     - SSH into the EC2 instance"
  echo "  logs [lg]   - Tail service logs on EC2"
  echo "  ec2 [ec]    - Verify EC2 SSH connectivity and env vars"
  echo "  deploy [y]  - Upload compose and start services on EC2"

  echo "Docker Hub commands:"
  echo "  docker [dk] - Authenticate Docker Hub credentials"
  echo "  push [p]    - Push Docker images to registry"

  echo "Maintenance commands:"
  echo "  clean [c]   - Remove containers, images, volumes; purge local data"
  echo "  nuke [x]    - DESTROY everything: .env, compose, Docker, data"
  echo "  help [h]    - Show this help message"
  echo "  default     - No args runs 'up'"
}

cmd_new() {
  if [ -f .env ]; then
    echo "✘ .env file already exists! Aborting to prevent overwrite."
    exit 1
  fi
  echo "This will create a new .env file for your application."
  APP_NAME=$(echo "${PWD##*/}" | tr ' ' '-')
  APP_VERSION="latest"
  echo "Do you have a Docker Hub account and Personal Access Token (PAT)? (y/n  default: n)"
  read -r has_docker_account
  if [ "$has_docker_account" != "n" ] && [ "$has_docker_account" != "N" ] && [ "$has_docker_account" != "" ]; then
    echo "What is your Docker Hub username?"
    read -r docker_username
    DOCKER_USERNAME=$docker_username
    echo "Enter Docker Hub Personal Access Token: "
    read -r docker_pat
    DOCKER_PAT=$docker_pat
  else
    DOCKER_USERNAME="changeme"
    DOCKER_PAT="changeme"
  fi
  echo "Are you deploying to an AWS EC2 instance? (y/n  default: n)"
  read -r has_ec2
  if [ "$has_ec2" != "n" ] && [ "$has_ec2" != "N" ] && [ "$has_ec2" != "" ]; then
      echo "What is the EC2 deploy host (ec2-xx-xxx-xx-xx.us-west-2.compute.amazonaws.com)?"
      read -r ec2_deploy_host
      EC2_DEPLOY_HOST=$ec2_deploy_host
      echo "Your EC2 SSH key must be located in the $HOME/.ssh directory or validation will fail."
      echo "What is the name of your EC2 SSH key (e.g., cs123-shanepanter-sshkey.pem)?"
      read -r ec2_key_name
      EC2_KEY_NAME=$ec2_key_name
      echo "Check for AWS SSH key..."
      if [ ! -f "$HOME/.ssh/${EC2_KEY_NAME}" ]; then
        echo "✘ SSH key $HOME/.ssh/${EC2_KEY_NAME} not found! Please place your EC2 SSH key in the .ssh directory."
        exit 1
      else
        echo "✔ SSH key found."
        chmod 600 "$HOME/.ssh/${EC2_KEY_NAME}"
  fi
  else
      EC2_DEPLOY_HOST="changeme"
      EC2_KEY_NAME="changeme.pem"
  fi

  EC2_DEPLOY_DIR="/home/ubuntu/${APP_NAME}"
  {
    echo "APP_NAME=${APP_NAME}"
    echo "APP_VERSION=${APP_VERSION}"
    echo "EC2_DEPLOY_HOST=${EC2_DEPLOY_HOST}"
    echo "EC2_DEPLOY_DIR=${EC2_DEPLOY_DIR}"
    echo "EC2_KEY_NAME=${EC2_KEY_NAME}"
    echo "DOCKER_USERNAME=${DOCKER_USERNAME}"
    echo "DOCKER_PAT=${DOCKER_PAT}"
  } > .env
  echo "✔ .env file created."
  echo "Initializing new development environment..."
  load_env
  cmd_init
  echo "New dev environment setup complete."

  # Auto-install bash completion
  echo ""
  echo "Would you like to enable bash completion for dev.sh? (y/n  default: y)"
  read -r enable_completion
  if [ "$enable_completion" != "n" ] && [ "$enable_completion" != "N" ]; then
    install_completion
  fi

  echo "If you are using EC2 deployment, run './dev.sh login' to verify connectivity."
  echo "Run './dev.sh up' to start the application."
}

install_completion() {
  local shell_rc
  local shell_name

  # Detect shell type
  if [[ "$SHELL" == *"zsh"* ]]; then
    shell_rc="$HOME/.zshrc"
    shell_name="zsh"
  else
    shell_rc="$HOME/.bashrc"
    shell_name="bash"
  fi

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local completion_path="$script_dir/dev.sh.completion"

  # Check if already installed
  if grep -q "source.*dev.sh.completion" "$shell_rc" 2>/dev/null; then
    echo "✔ Bash completion already installed in $shell_rc"
    return 0
  fi

  # Add completion to shell config
  {
    echo ""
    echo "# Enable bash completion for dev.sh"
    echo "[ -f \"$completion_path\" ] && source \"$completion_path\""
  } >> "$shell_rc"

  echo "✔ Bash completion installed in $shell_rc"
  echo "Run 'source $shell_rc' or restart your shell to enable it."
}

# Dispatch
main() {
  if [ $# -eq 0 ]; then
    # Default target is up
    cmd_up
    exit 0
  fi

  for cmd in "$@"; do
    case "$cmd" in
      new|n) cmd_new ;;
      env|e) cmd_env ;;
      login|l) cmd_login ;;
      ssh|s) cmd_ssh ;;
      init|i) cmd_init ;;
      up|u) cmd_up ;;
      down|d) cmd_down ;;
      build|b) cmd_build ;;
      push|p) cmd_push ;;
      docker|dk) cmd_docker ;;
      ec2|ec) cmd_ec2 ;;
      deploy|y) cmd_deploy ;;
      logs|lg) cmd_logs ;;
      web|w) cmd_web ;;
      clean|c) cmd_clean ;;
      nuke|x) cmd_nuke ;;
      help|h) cmd_help ;;
      *)
        echo "Unknown command: $cmd"
        cmd_help
        exit 1
        ;;
    esac
  done
}

main "$@"
