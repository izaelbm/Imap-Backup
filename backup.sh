#!/bin/bash

# Verifica parâmetros
if [ "$#" -ne 3 ]; then
    echo "Uso: $0 email@dominio.com senha imap.xxx.com"
    exit 1
fi

EMAIL="$1"
SENHA="$2"
USUARIO=$(echo "$EMAIL" | cut -d@ -f1)
DOMINIO=$(echo "$EMAIL" | cut -d@ -f2)
BACKUP_DIR="$HOME/backups/$USUARIO"

# Cria pasta de backup se não existir
mkdir -p "$BACKUP_DIR"

# Cria config temporária do mbsync
CONFIG_FILE="$(mktemp)"
cat > "$CONFIG_FILE" <<EOF
IMAPAccount $USUARIO
Host $3
User $EMAIL
Pass $SENHA
TLSType IMAPS

IMAPStore ${USUARIO}-remote
Account $USUARIO

MaildirStore ${USUARIO}-local
Path $BACKUP_DIR/
Inbox $BACKUP_DIR/INBOX
SubFolders Verbatim

Channel $USUARIO
Far :${USUARIO}-remote:
Near :${USUARIO}-local:
Patterns *
Create Both
Sync All
EOF

# Executa mbsync com config isolada
mbsync -c "$CONFIG_FILE" "$USUARIO"

# Remove config temporária
rm -f "$CONFIG_FILE"
