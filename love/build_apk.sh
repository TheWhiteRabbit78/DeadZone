#!/bin/bash
# Build DeadZone.apk from the repo: game.love + LÖVE 11.5 Android APK (embed mode).
# Needs in the working dir: love_dec/ (apktool-decoded love-11.5-android.apk, with the
# DEAD ZONE icons), apktool.jar and uber-apk-signer as signer.jar. Desktop test: love <stage dir>
set -e
REPO=${1:-/home/claude/DeadZone}
VER=$(grep -o 'N.VERSION = "v[0-9.]*"' $REPO/dz/patchnotes.lua | grep -o 'v[0-9.]*' | tr -d v)
cd /home/claude/apk
rm -rf stage && mkdir -p stage/dz
cp $REPO/love/main.lua $REPO/love/conf.lua $REPO/deadzone.lua stage/
cp $REPO/dz/*.lua stage/dz/
rm -f game.love && (cd stage && zip -q -9 -r ../game.love .)
rm -rf work && cp -r love_dec work
mkdir -p work/assets && cp game.love work/assets/game.love
sed -i 's#<bool name="embed">false</bool>#<bool name="embed">true</bool>#' work/res/values/bools.xml
python3 - "$VER" <<'PY'
import re, sys
ver = sys.argv[1]
p = 'work/AndroidManifest.xml'
s = open(p, encoding='utf-8').read()
s = s.replace('LÖVE for Android', 'DEAD ZONE').replace('LÖVE Loader', 'DEAD ZONE')
s = s.replace('org.love2d.android.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION', 'com.patrik.deadzone.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION')
s = s.replace('org.love2d.android.androidx-startup', 'com.patrik.deadzone.androidx-startup')
for perm in ('RECORD_AUDIO', 'BLUETOOTH', 'INTERNET'):
    s = re.sub(r'\s*<uses-permission android:name="android.permission.%s"/>' % perm, '', s)
# GameActivity: keep only the launcher intent; drop ".love opener" filters + the download activity
act = re.search(r'(<activity[^>]*org.love2d.android.GameActivity".*?</activity>)', s, re.S).group(1)
launch = re.search(r'<intent-filter>\s*<action android:name="android.intent.action.MAIN"/>.*?</intent-filter>', act, re.S).group(0)
head = act[:act.index('>') + 1]
s = s.replace(act, head + '\n            ' + launch + '\n        </activity>')
s = re.sub(r'\s*<activity[^>]*DownloadActivity".*?</activity>', '', s, flags=re.S)
open(p, 'w', encoding='utf-8').write(s)
y = 'work/apktool.yml'
t = open(y).read()
t = t.replace('renameManifestPackage: null', 'renameManifestPackage: com.patrik.deadzone')
t = re.sub(r'versionCode: \d+', 'versionCode: %d' % int(ver.replace('.', '')), t)
t = re.sub(r'versionName: .*', 'versionName: %s' % ver, t)
open(y, 'w').write(t)
PY
java -jar apktool.jar b -q -o unsigned.apk work 2>&1 | grep -v JAVA_TOOL || true
rm -rf signed && java -jar signer.jar -a unsigned.apk -o signed 2>&1 | grep -E "SUCCESS|ERROR|FAIL" || true
cp signed/*.apk DeadZone-$VER.apk
ls -la DeadZone-$VER.apk
