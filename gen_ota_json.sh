#!/bin/bash

DEVICE=$1

if [ -z "$2" ] || [ "$2" != "onlyjson" ]; then
d=$(date +%Y%m%d)

if [ ! -z "$2" ]; then
d=$2
fi

FILENAME=LineageOS-Mods-18.1-"${d}"-UNOFFICIAL-"${DEVICE}".zip

oldd=$(grep filename $DEVICE.json | cut -d '-' -f 3)
md5=$(md5sum /home/jenkins/workspace/LineageOS-18.1-olives/out/target/product/$DEVICE/$FILENAME | cut -d ' ' -f 1)
oldmd5=$(grep '"id"' $DEVICE.json | cut -d':' -f 2)
utc=$(grep ro.build.date.utc /home/jenkins/workspace/LineageOS-18.1-olives/out/target/product/$DEVICE/system/build.prop | cut -d '=' -f 2)
oldutc=$(grep datetime $DEVICE.json | cut -d ':' -f 2)
size=$(wc -c /home/jenkins/workspace/LineageOS-18.1-olives/out/target/product/$DEVICE/$FILENAME | cut -d ' ' -f 1)
oldsize=$(grep size $DEVICE.json | cut -d ':' -f 2)
oldurl=$(grep url $DEVICE.json | cut -d ' ' -f 9)
oldtag=$(grep url $DEVICE.json | cut -d '/' -f 8)

#This is where the magic happens
sed -i "s!${oldmd5}! \"${md5}\",!g" $DEVICE.json
sed -i "s!${oldutc}! \"${utc}\",!g" $DEVICE.json
sed -i "s!${oldsize}! \"${size}\",!g" $DEVICE.json

d2=$(date +%Y%m%d-%H%M)

TAG=$(echo "${DEVICE}-${d2}")
url="https://github.com/JonnyRoller23/OTAUpdatesROM/releases/download/${TAG}/${FILENAME}"
sed -i "s!${oldurl}!\"${url}\",!g" $DEVICE.json

# Replace tag before date and after URL
# to do not break json
sed -i "s!${oldtag}!${TAG}!" $DEVICE.json
sed -i "s!${oldd}!${d}!" $DEVICE.json

echo "Write some release notes..."
echo -e "New update - ${TAG}\n--------------------------------\n" > ~/OTAUpdatesROM/changelog.txt
nano ~/OTAUpdatesROM/changelog.txt

echo "Creating new release..."

gh release create ${TAG} --title ${TAG} -F ~/OTAUpdatesROM/changelog.txt /home/jenkins/workspace/LineageOS-18.1-olives/out/target/product/${DEVICE}/${FILENAME}
else
echo "! onlyjson mode"
TAG="$(gh release list | grep Latest | sed 's/.*Latest.//g;s/202[0-9]\-.*//g;s/[[:space:]]//g')"
fi

git diff

echo "Pushing new JSON (${TAG})..."

read a

git add * && git commit -m "New OTA update - ${TAG}"
git push origin master

echo "Done."