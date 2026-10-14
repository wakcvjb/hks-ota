#!/bin/bash
set -e
cd "$(dirname "$0")/.."
V=$(cat version.txt | tr -d '\n\r ')
if [ -f src/payload.bin ]; then cp src/payload.bin update.bin; else cp src/payload.txt update.bin; fi
SZ=$(wc -c < update.bin)
SH=$(sha512sum update.bin | awk '{print $1}')
if [ -z "$HKS_SIGN_KEY" ]; then exit 1; fi
printf '%s' "$HKS_SIGN_KEY" > scripts/sign.key
chmod 600 scripts/sign.key
openssl pkey -in scripts/sign.key -pubout -outform DER | tail -c 32 > pubkey.bin
openssl pkeyutl -sign -inkey scripts/sign.key -rawin -in update.bin -out update.sig
SG=$(xxd -p -c 256 update.sig)
PUBKEY_B64=$(base64 -w 0 pubkey.bin)
printf '{\n  "version": "%s",\n  "file": "update.bin",\n  "size": %s,\n  "sha512": "%s",\n  "sig": "%s",\n  "pubkey": "",
  "pubkey": "$PUBKEY_B64",
  "notes": "auto build %s"\n}\n' "$V" "$SZ" "$SH" "$SG" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > version.json
cat version.json
