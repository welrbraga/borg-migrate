#!/bin/bash

# Move backups do Borg de um repositório para outro
#
# Welington R. Braga - 2025-02-28

# Cria um arquivo de configuração de exemplo
create-envfile() {
  cat > "borg-migrate.env.sample" <<EOF
BORG_REPO_ORIGEM="path_to-your-first-repo"
BORG_PASSCOMMAND_ORIGEM="command-that-return-your-repo-password"

BORG_REPO_DESTINO="path_to-your-second-repo"
BORG_PASSCOMMAND_DESTINO="command-that-return-your-repo-password"
EOF
}

# Verifica se o arquivo env está disponível
if [ -f "$HOME/.borg-migrate.env" ]; then
  # shellcheck disable=SC1091
  source "$HOME/.borg-migrate.env"
elif [ -f ".borg-migrate.env" ]; then
  # shellcheck disable=SC1091
  source ".borg-migrate.env"
else
  echo "Erro: Arquivo de configuração não encontrado."
  create-envfile
  echo ""
  echo "Um arquivo de exemplo foi criado no diretório atual com o nome 'borg-migrate.env.sample'."
  echo "Altere as suas credenciais conforme necessário e o renomeie"
  echo "para '.borg-migrate.env' ou '$HOME/.borg-migrate.env'."
  exit 2
fi

if [ -z "$1" ]; then
  echo "Uso: $0 source | target | <nome-do-backup>"
  exit 1
fi

if [ "$1" == "source" ]; then
  export BORG_PASSCOMMAND="$BORG_PASSCOMMAND_ORIGEM"
  export BORG_REPO="$BORG_REPO_ORIGEM"
  shift # remove o primeiro argumento
  borg "$@"
  exit $?
fi
if [ "$1" == "target" ]; then
  export BORG_PASSCOMMAND="$BORG_PASSCOMMAND_DESTINO"
  export BORG_REPO="$BORG_REPO_DESTINO"
  shift # remove o primeiro argumento
  borg "$@"
  exit $?
fi
if [ -n "$1" ]; then
  BACKUP_NOME="$1"
fi

print() {
  echo ""
  echo "----------------------------------------"
  echo "* $1"
  echo "----------------------------------------"
}

print "Verifica disponibilidade do repositório de origem"
export BORG_PASSCOMMAND="$BORG_PASSCOMMAND_ORIGEM"
if ! borg list "$BORG_REPO_ORIGEM" > /dev/null 2>&1; then
  echo "Erro: Repositório de origem não encontrado."
  exit 100
fi

print "Verifica disponibilidade do repositório de destino"
export BORG_PASSCOMMAND="$BORG_PASSCOMMAND_DESTINO"
if ! borg list "$BORG_REPO_DESTINO" > /dev/null 2>&1; then
  echo "Erro: Repositório de destino não encontrado."
  exit 110
fi

print "Verifica se o backup existe no repositório de origem"
export BORG_PASSCOMMAND="$BORG_PASSCOMMAND_ORIGEM"
if ! borg info "$BORG_REPO_ORIGEM::$BACKUP_NOME"; then
  echo "Erro: Backup '$BACKUP_NOME' não encontrado no repositório de origem."
  exit 120
fi

# Se necessário, instala o faketime para simular o tempo do backup antigo
which faketime >/dev/null || which jq >/dev/null || {
  sudo apt install -y faketime jq
}

# Obtem a data do backup no repositório de origem
# shellcheck disable=SC2030,SC2031
export BORG_PASSCOMMAND="$BORG_PASSCOMMAND_ORIGEM"
BACKUP_DATE_ORIGEM="$(borg info --json "$BORG_REPO_ORIGEM::$BACKUP_NOME" | jq -r .archives[0].start )"
print "Transfere o backup da origem para o destino"
(
# shellcheck disable=SC2030
  export BORG_PASSCOMMAND="$BORG_PASSCOMMAND_ORIGEM"
  borg export-tar "$BORG_REPO_ORIGEM::$BACKUP_NOME" -
) | 
(
# shellcheck disable=SC2030,SC2031
  export BORG_PASSCOMMAND="$BORG_PASSCOMMAND_DESTINO"
  faketime "$BACKUP_DATE_ORIGEM" \
  borg import-tar --verbose --progress "$BORG_REPO_DESTINO::$BACKUP_NOME" -
)

# Verifica se a transferência foi bem-sucedida
if [ $? -ne 0 ]; then
  echo "Erro: Falha ao transferir o backup."
  exit 130
fi

print "Verifica se o backup já está disponível no repositório de destino"
# shellcheck disable=SC2030,SC2031
export BORG_PASSCOMMAND="$BORG_PASSCOMMAND_DESTINO"
if ! borg info "$BORG_REPO_DESTINO::$BACKUP_NOME" ; then
  echo "Erro: Backup '$BACKUP_NOME' não encontrado no repositório de destino."
  exit 140
fi

print "Remoção do backup no repositório de origem"
# shellcheck disable=SC2030
export BORG_PASSCOMMAND="$BORG_PASSCOMMAND_ORIGEM"
if ! borg delete --verbose "$BORG_REPO_ORIGEM::$BACKUP_NOME" ; then
  echo "Aviso: Backup transferido e verificado, mas falhou a sua remoção do repositório de origem."
  exit 150
fi

echo "Backup '$BACKUP_NOME' transferido, verificado e removido com sucesso."
