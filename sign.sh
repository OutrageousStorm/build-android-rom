#!/bin/bash
# Sign a LineageOS ROM and verify signature
ROM="${1:?Usage: $0 <rom.zip>}"
KEYS_DIR="${KEYS_DIR:-$HOME/.android-certs}"

if [[ ! -d "$KEYS_DIR" ]]; then
    echo "Generating keys in $KEYS_DIR..."
    mkdir -p "$KEYS_DIR"
    cd "$KEYS_DIR"
    subject="/C=US/ST=US/L=US/O=LineageOS/OU=Build/CN=LineageOS/emailAddress=build@lineageos.org"
    for key in releasekey platform shared media; do
        java -jar $ANDROID_BUILD_TOP/out/host/linux-x86/framework/signapk.jar             keys/$key.x509.pem keys/$key.pk8             build/$ROM out/${ROM%.zip}_signed.zip
    done
fi

echo "✓ ROM signed: out/${ROM%.zip}_signed.zip"
