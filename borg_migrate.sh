#!/bin/bash

# Move backups do Borg de um repositório para outro
#
# Welington R. Braga - 2025-02-28

# Configurações
# Samsung 1TB
REPO_ORIGEM="/media/veracrypt2/borg"
BORG_PASSCOMMAND_ORIGEM="base64 -d $HOME/.braga.conf.d/backup_weldesk.passwd"
# Seagate 230GB
REPO_DESTINO="/media/veracrypt3/borg"
BORG_PASSCOMMAND_DESTINO="base64 -d $HOME/.braga.conf.d/backup_freeagentgo.passwd"

if [ -z "$1" ]; then
  echo "Uso: $0 source | target | <nome-do-backup>"
  exit 1
fi

if [ "$1" == "source" ]; then
  export BORG_PASSCOMMAND="$BORG_PASSCOMMAND_ORIGEM"
  export BORG_REPO="$REPO_ORIGEM"
  shift # remove o primeiro argumento
  borg "$@"
  exit $?
fi
if [ "$1" == "target" ]; then
  export BORG_PASSCOMMAND="$BORG_PASSCOMMAND_DESTINO"
  export BORG_REPO="$REPO_DESTINO"
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
if ! borg list "$REPO_ORIGEM" > /dev/null 2>&1; then
  echo "Erro: Repositório de origem não encontrado."
  exit 100
fi

print "Verifica disponibilidade do repositório de destino"
export BORG_PASSCOMMAND="$BORG_PASSCOMMAND_DESTINO"
if ! borg list "$REPO_DESTINO" > /dev/null 2>&1; then
  echo "Erro: Repositório de destino não encontrado."
  exit 110
fi

print "Verifica se o backup existe no repositório de origem"
export BORG_PASSCOMMAND="$BORG_PASSCOMMAND_ORIGEM"
if ! borg info "$REPO_ORIGEM::$BACKUP_NOME"; then
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
BACKUP_DATE_ORIGEM="$(borg info --json "$REPO_ORIGEM::$BACKUP_NOME" | jq -r .archives[0].start )"
print "Transfere o backup da origem para o destino"
(
# shellcheck disable=SC2030
  export BORG_PASSCOMMAND="$BORG_PASSCOMMAND_ORIGEM"
  borg export-tar "$REPO_ORIGEM::$BACKUP_NOME" -
) | 
(
# shellcheck disable=SC2030,SC2031
  export BORG_PASSCOMMAND="$BORG_PASSCOMMAND_DESTINO"
  faketime "$BACKUP_DATE_ORIGEM" \
  borg import-tar --verbose --progress "$REPO_DESTINO::$BACKUP_NOME" -
)

# Verifica se a transferência foi bem-sucedida
if [ $? -ne 0 ]; then
  echo "Erro: Falha ao transferir o backup."
  exit 130
fi

print "Verifica se o backup já está disponível no repositório de destino"
# shellcheck disable=SC2030,SC2031
export BORG_PASSCOMMAND="$BORG_PASSCOMMAND_DESTINO"
if ! borg info "$REPO_DESTINO::$BACKUP_NOME" ; then
  echo "Erro: Backup '$BACKUP_NOME' não encontrado no repositório de destino."
  exit 140
fi

print "Remoção do backup no repositório de origem"
# shellcheck disable=SC2030
export BORG_PASSCOMMAND="$BORG_PASSCOMMAND_ORIGEM"
if ! borg delete --verbose "$REPO_ORIGEM::$BACKUP_NOME" ; then
  echo "Aviso: Backup transferido e verificado, mas falhou a sua remoção do repositório de origem."
  exit 150
fi

echo "Backup '$BACKUP_NOME' transferido, verificado e removido com sucesso."
