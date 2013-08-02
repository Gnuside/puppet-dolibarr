#!/bin/bash +x

SITE=$1
FILE="/tmp/dolibarr_upgrade_cookies.txt"
AGENT="Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US) AppleWebKit/525.13 (KHTML, like Gecko) Chrome/0.X.Y.Z Safari/525.13."

while :
do
  INDEX_FILE=/tmp/dolibarr_upgrade_index.html
  curl -L -c "$FILE" -b "$FILE" -A "$AGENT" -s "http://$SITE/install/index.php" --output "$INDEX_FILE"
  CURRENT_VERSION=$(grep "Version last upgrade" $INDEX_FILE | sed 's/\(<br>\)/\n/g' | grep "last upgrade" | sed 's/^.*\([0-9]\+\.[0-9]\+\)\.[0-9]\+.*$/\1/')
  echo "Detected current version : $CURRENT_VERSION"

  TARGET_VERSION=$(grep "Version last upgrade" $INDEX_FILE | sed 's/\(<br>\)/\n/g' | grep "Version program" | sed 's/^.*\([0-9]\+\.[0-9]\+\)\.[0-9]\+.*$/\1/')
  echo "Targeted version is : $TARGET_VERSION"

  if [ $(expr "$CURRENT_VERSION = $TARGET_VERSION") ] ; then
    break
  fi

  REFERE="http://$SITE/install/index.php"
  RES_FILE=/tmp/dolibarr_upgrade_res_${CURRENT_VERSION}.html
  URL="http://$SITE/install/$(grep from=$CURRENT_VERSION $INDEX_FILE | sed 's/^.*href="\(.*\)">.*$/\1/' | sed 's/&amp;/\&/g')"
  echo "Using URL : $TARGET_URL"
  printf "upgrading step 1 from $CURRENT_VERSION..."
  curl --refere "$REFERE" -c "$FILE" -b "$FILE" -A "$AGENT" -s "$URL" --output "$RES_FILE"
  echo Done.


  # Step 2
  REFERE="$URL"

  URL="http://$SITE/install/$(grep "forminstall" "$RES_FILE" | sed 's/^.*action="\([^"]*\).*/\1/')"
  data1="testpost=$(grep 'input.*name="testpost"' "$RES_FILE" | sed 's/^.*value="\([^"]*\)".*/\1/')"
  data2="action=$(grep 'input.*name="action"' "$RES_FILE" | sed 's/^.*value="\([^"]*\)".*/\1/')"
  data3="selectlang=$(grep 'input.*name="selectlang"' "$RES_FILE" | sed 's/^.*value="\([^"]*\)".*/\1/')"
  #echo "Found URL : $URL"
  #echo "Found args: $data1 ; $data2 ; $data3"


  RES_FILE=/tmp/dolibarr_upgrade_res2_${CURRENT_VERSION}.html
  printf "upgrading step 2 from $CURRENT_VERSION..."
  curl --refere "$REFERE" -F "$data1" -F "$data2" -F "$data3" -c "$FILE" -b "$FILE" -A "$AGENT" -s "$URL" --output "$RES_FILE"
  echo Done.


  # Step 3
  REFERE="$URL"

  URL="http://$SITE/install/$(grep "forminstall" "$RES_FILE" | sed 's/^.*action="\([^"]*\).*/\1/')"
  data1="testpost=$(grep 'input.*name="testpost"' "$RES_FILE" | sed 's/^.*value="\([^"]*\)".*/\1/')"
  data2="action=$(grep 'input.*name="action"' "$RES_FILE" | sed 's/^.*value="\([^"]*\)".*/\1/')"
  data3="selectlang=$(grep 'input.*name="selectlang"' "$RES_FILE" | sed 's/^.*value="\([^"]*\)".*/\1/')"
  #echo "Found URL : $URL"
  #echo "Found args: $data1 ; $data2 ; $data3"


  RES_FILE=/tmp/dolibarr_upgrade_res3_${CURRENT_VERSION}.html
  printf "upgrading step 3 from $CURRENT_VERSION..."
  curl --refere "$REFERE" -F "$data1" -F "$data2" -F "$data3" -c "$FILE" -b "$FILE" -A "$AGENT" -s "$URL" --output "$RES_FILE"
  echo Done.



done
