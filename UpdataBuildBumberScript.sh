#!/bin/bash

#  UpdataBuildBumberScript.sh
#  BikeComputer
#
#  Created by Jussi Rajaniemi on 29.7.2024.
#  
# Tämä skripti on suunniteltu päivittämään BUILD_NUMBER johdonmukaisesti kaikissa kohteissa.
SRCROOT=.
PRODUCT_NAME=BikeComputer

# echo "Siirrytään hakemistoon: $SRCROOT/$PRODUCT_NAME"
#cd "$SRCROOT/$PRODUCT_NAME" || { echo "Hakemistoon siirtyminen epäonnistui"; exit 1; }

echo "Haetaan nykyinen päivämäärä"
current_date=$(date "+%Y%m%d")
echo "Nykyinen päivämäärä: $current_date"

echo "Luetaan edellinen build-numero"
previous_build_number=$(awk -F "=" '/BUILD_NUMBER/ {print $2}' Config.xcconfig | tr -d ' ')
echo "Edellinen build-numero: $previous_build_number"

previous_date="${previous_build_number:0:8}"
counter="${previous_build_number:8}"
echo "Edellinen päivämäärä: $previous_date, Laskuri: $counter"

if [ "$current_date" == "$previous_date" ]; then
    new_counter=$((counter + 1))
else
    new_counter=1
fi
echo "Uusi laskuri: $new_counter"

new_build_number="${current_date}$(printf "%02d" "$new_counter")"
echo "Uusi build-numero: $new_build_number"

sed -i '' -e "/BUILD_NUMBER =/ s/= .*/= $new_build_number/" Config.xcconfig

if grep -q "BUILD_NUMBER = $new_build_number" Config.xcconfig; then
    echo "BUILD_NUMBER päivitetty onnistuneesti: $new_build_number"
else
    echo "BUILD_NUMBER päivittäminen epäonnistui"
    exit 1
fi

xcodebuild clean
