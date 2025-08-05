#!/bin/bash

# Verifica parâmetros
if [ "$#" -ne 3 ]; then
    echo "Uso: $0 email@dominio.com senha imap.xxx.com"
    exit 1
fi

EMAIL="$1"
SENHA="$2"
USUARIO=$(echo "$EMAIL" | cut -d@ -f1)
BACKUP_DIR="$HOME/backups/$USUARIO"

# Verifica se backup existe
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Backup não encontrado em $BACKUP_DIR"
    exit 2
fi

echo "[*] Enviando e-mails de $BACKUP_DIR para $EMAIL na pasta remota 'Backup'..."

# Remove arquivos UIDVALIDITY do Maildir local
find "$BACKUP_DIR" -name ".uidvalidity" -delete

# Cria pasta remota personalizada (BackupImport)
CUSTOM_REMOTE_DIR="Backup"

# Cria estrutura temporária contendo só a INBOX (ou outra desejada)
TEMP_BACKUP="$(mktemp -d)"
mkdir -p "$TEMP_BACKUP/$CUSTOM_REMOTE_DIR/cur"
mkdir -p "$TEMP_BACKUP/$CUSTOM_REMOTE_DIR/new"
mkdir -p "$TEMP_BACKUP/$CUSTOM_REMOTE_DIR/tmp"

# Copia todos os e-mails da pasta original (ex: INBOX) para a pasta customizada
cp -a "$BACKUP_DIR/INBOX/." "$TEMP_BACKUP/$CUSTOM_REMOTE_DIR/"

# Cria config temporária do mbsync
CONFIG_FILE="$(mktemp)"
cat > "$CONFIG_FILE" <<EOF
IMAPAccount $USUARIO
Host $3
User $EMAIL
Pass $SENHA
AuthMechs LOGIN
TLSType IMAPS

IMAPStore ${USUARIO}-remote
Account $USUARIO

MaildirStore ${USUARIO}-local
Path $TEMP_BACKUP/
Inbox $TEMP_BACKUP/$CUSTOM_REMOTE_DIR
SubFolders Verbatim

Channel ${USUARIO}-upload
Far :${USUARIO}-remote:
Near :${USUARIO}-local:
Patterns $CUSTOM_REMOTE_DIR
Create Both
Expunge None
Sync All
EOF

# Executa mbsync com config isolada
mbsync -c "$CONFIG_FILE" "${USUARIO}-upload"

# Remove config temporária e pasta temporária
rm -f "$CONFIG_FILE"
rm -rf "$TEMP_BACKUP"
