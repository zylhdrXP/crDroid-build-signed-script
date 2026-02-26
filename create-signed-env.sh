#!/bin/bash

# Default values
DEFAULT_COUNTRY="US"
DEFAULT_STATE="California"
DEFAULT_LOCALITY="Mountain View"
DEFAULT_ORGANIZATION="AfterlifeOS"
DEFAULT_ORG_UNIT="AfterlifeOS"
DEFAULT_COMMON_NAME="AfterlifeOS"
DEFAULT_EMAIL="android@android.com"

# Construct the subject line directly using defaults
subject="/C=${DEFAULT_COUNTRY}/ST=${DEFAULT_STATE}/L=${DEFAULT_LOCALITY}/O=${DEFAULT_ORGANIZATION}/OU=${DEFAULT_ORG_UNIT}/CN=${DEFAULT_COMMON_NAME}/emailAddress=${DEFAULT_EMAIL}"

# Print the subject line
echo ""
echo "Using Subject Line:"
echo "$subject"
echo ""

clear

# Create Key
# Using 'yes ""' to pipe empty lines (Enter key) to the make_key script to skip password creation
echo "Generating keys automatically (no password)..."
mkdir -p ~/.android-certs

for cert in bluetooth cyngn-app media networkstack nfc platform releasekey sdk_sandbox shared testcert testkey verity; do \
    yes "" | ./development/tools/make_key ~/.android-certs/$cert "$subject"; \
done

# Create APEX keys
cp ./development/tools/make_key ~/.android-certs/
sed -i 's|2048|4096|g' ~/.android-certs/make_key

for apex in com.android.adbd com.android.adservices com.android.adservices.api com.android.appsearch com.android.appsearch.apk com.android.art com.android.bluetooth com.android.bt com.android.btservices com.android.cellbroadcast com.android.compos com.android.configinfrastructure com.android.connectivity.resources com.android.conscrypt com.android.crashrecovery com.android.devicelock com.android.extservices com.android.graphics.pdf com.android.hardware.authsecret com.android.hardware.biometrics.face.virtual com.android.hardware.biometrics.fingerprint.virtual com.android.hardware.boot com.android.hardware.cas com.android.hardware.contexthub com.android.hardware.dumpstate com.android.hardware.gatekeeper.nonsecure com.android.hardware.neuralnetworks com.android.hardware.power com.android.hardware.rebootescrow com.android.hardware.thermal com.android.hardware.threadnetwork com.android.hardware.uwb com.android.hardware.vibrator com.android.hardware.wifi com.android.healthfitness com.android.hotspot2.osulogin com.android.i18n com.android.ipsec com.android.media com.android.media.swcodec com.android.mediaprovider com.android.nearby.halfsheet com.android.networkstack.tethering com.android.neuralnetworks com.android.nfcservices com.android.ondevicepersonalization com.android.os.statsd com.android.permission com.android.profiling com.android.resolv com.android.rkpd com.android.runtime com.android.safetycenter.resources com.android.scheduling com.android.sdkext com.android.support.apexer com.android.telephony com.android.telephonycore com.android.telephonymodules com.android.tethering com.android.tzdata com.android.uprobestats com.android.uwb com.android.uwb.resources com.android.virt com.android.vndk.current com.android.vndk.current.on_vendor com.android.wifi com.android.wifi.dialog com.android.wifi.resources com.google.pixel.camera.hal com.google.pixel.vibrator.hal com.qorvo.uwb; do \
    yes "" | ~/.android-certs/make_key ~/.android-certs/$apex "$subject"; \
    openssl pkcs8 -in ~/.android-certs/$apex.pk8 -inform DER -nocrypt -out ~/.android-certs/$apex.pem; \
done

## Create vendor for keys
rm ~/.android-certs/make_key
rm -rf vendor/afterlife-priv
mkdir -p vendor/afterlife-priv
mv ~/.android-certs vendor/afterlife-priv/keys

echo "PRODUCT_DEFAULT_DEV_CERTIFICATE := vendor/afterlife-priv/keys/releasekey" > vendor/afterlife-priv/keys/keys.mk

cat <<EOF > vendor/afterlife-priv/keys/BUILD.bazel
filegroup(
    name = "android_certificate_directory",
    srcs = glob([
        "*.pk8",
        "*.pem",
    ]),
    visibility = ["//visibility:public"],
)
EOF

echo ""
echo "Done! Now build as usual."
echo "If builds aren't being signed, add '-include vendor/afterlife-priv/keys/keys.mk' to your device mk file"
echo ""
echo "IMPORTANT: Make copies of your vendor/afterlife-priv folder as it contains your keys!"

sleep 3
