#!/bin/sh
set -eu

ssh_remote_command() {
  ssh -J "$INPUT_BASTION_HOST" "$INPUT_DOCKER_HOST" -q -t -i "$HOME/.ssh/id_rsa" \
    -o UserKnownHostsFile=/dev/null \
    -p "$INPUT_DOCKER_PORT" \
    -o StrictHostKeyChecking=no "$*"
}

if [ -z "$INPUT_SSH_PUB" ]; then
  echo "ssh_pub input missing"
  exit 1
fi

if [ -z "$INPUT_SSH_PRIV" ]; then
  echo "ssh_priv input missing"
  exit 1
fi

if [ -z "$INPUT_DOCKER_HOST" ]; then
  echo "docker_host input missing"
  exit 1
fi

if [ -z "$INPUT_DOCKER_PORT" ]; then
  INPUT_DOCKER_PORT=22
fi

if [ -z "$INPUT_COMPOSE_FILE_PATH" ]; then
  echo "compose_file_path input missing"
  exit 1
fi

if [ -z "$INPUT_BASTION_HOST" ]; then
  echo "bastion_host input missing"
  exit 1
fi

echo "Registering SSH keys..."
SSH_HOST=${INPUT_DOCKER_HOST#*@}
SSH_JUMP_HOST=${INPUT_BASTION_HOST#*@}
# register the private key with the agent.
mkdir -p "$HOME/.ssh"
printf '%s\n' "$INPUT_SSH_PRIV" > "$HOME/.ssh/id_rsa"
chmod 600 "$HOME/.ssh/id_rsa"
eval "$(ssh-agent)"
ssh-add "$HOME/.ssh/id_rsa"
# echo "Add info to known hosts"
# printf '%s %s\n' "$SSH_HOST" "$SSH_PUB" > /etc/ssh/ssh_known_hosts
# printf '%s %s\n' "$SSH_JUMP_HOST" "$SSH_PUB" >> /etc/ssh/ssh_known_hosts


ssh_remote_command "cd $INPUT_COMPOSE_FILE_PATH && docker system prune -f"
ssh_remote_command "cd $INPUT_COMPOSE_FILE_PATH && docker volume prune -f"
ssh_remote_command "cd $INPUT_COMPOSE_FILE_PATH && docker-compose pull"
ssh_remote_command "cd $INPUT_COMPOSE_FILE_PATH && docker-compose down -v"
ssh_remote_command "cd $INPUT_COMPOSE_FILE_PATH && docker-compose up -d 2>&1"