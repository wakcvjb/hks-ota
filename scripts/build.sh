#!/bin/bash
set -e
cd "$(dirname "$0")/.."
VERSION=$(cat version.txt | tr -d '\n\r ')
if [ -f src/payload.bin ]; then cp src/payload.bin update.bin; else cp src/payload.txt update.bin; fi
SIZE=$(wc -c < update.bin)
SHA=$(sha512sum update.bin | awk '{print $1}')
if [ -z "$HKS_SIGN_KEY" ]; then exit 1; fi
printf '%s' "$HKS_SIGN_KEY" > scripts/sign.key
chmod 600 scripts/sign.key
openssl pkey -in scripts/sign.key -pubout -outform DER | tail -c 32 > pubkey.bin
openssl pkeyutl -sign -inkey scripts/sign.key -rawin -in update.bin -out update.sig
SIG=$(xxd -p -c 256 update.sig)
PUBKEY_B64=$(base64 -w 0 pubkey.bin)
cat > version.json << JSONEOF
{
  "version": "$VERSION",
  "file": "update.bin",
  "size": $SIZE,
  "sha512": "$SHA",
  "sig": "$SIG",
  "pubkey": "$PUBKEY_B64",
  "notes": "auto build $(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
JSONEOF
cat version.json
