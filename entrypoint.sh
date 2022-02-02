#!/bin/sh
set -eu

ssh_remote_command() {
  ssh -q -t -i "$HOME/.ssh/id_rsa" \
    -o UserKnownHostsFile=/dev/null \
    -p "$DOCKER_PORT" \
    -o StrictHostKeyChecking=no "$DOCKER_HOST" "$*"
}

if [ -z "$SSH_PUB" ]; then
  echo "SSH_PUB missing"
  exit 1
fi

if [ -z "$SSH_PRIV" ]; then
  echo "SSH_PRIV missing"
  exit 1
fi

if [ -z "$DOCKER_HOST" ]; then
  echo "SSH_PRIV missing"
  exit 1
fi

if [ -z "$DOCKER_PORT" ]; then
  DOCKER_PORT=22
fi

if [ -z "$COMPOSE_FILE_PATH" ]; then
  echo "COMPOSE_FILE_PATH missing"
  exit 1
fi

echo "Registering SSH keys..."
SSH_HOST=${DOCKER_HOST#*@}
# register the private key with the agent.
mkdir -p "$HOME/.ssh"
printf '%s\n' "$SSH_PRIV" > "$HOME/.ssh/id_rsa"
chmod 600 "$HOME/.ssh/id_rsa"
eval "$(ssh-agent)"
ssh-add "$HOME/.ssh/id_rsa"
echo "Add info to known hosts"
printf '%s %s\n' "$SSH_HOST" "$SSH_PUB" > /etc/ssh/ssh_known_hosts

ssh_remote_command "cd $COMPOSE_FILE_PATH && docker system prune -f"
ssh_remote_command "cd $COMPOSE_FILE_PATH && docker volume prune -f"
ssh_remote_command "cd $COMPOSE_FILE_PATH && docker-compose pull"
ssh_remote_command "cd $COMPOSE_FILE_PATH && docker-compose down -v"
ssh_remote_command "cd $COMPOSE_FILE_PATH && docker-compose up -d 2>&1"