#!/bin/bash +x

SITE=$1
FILE="/tmp/dolibarr_upgrade_cookies.txt"
AGENT="Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US) AppleWebKit/525.13 (KHTML, like Gecko) Chrome/0.X.Y.Z Safari/525.13."

INDEX_FILE=/tmp/dolibarr_upgrade_index.html

curl -L -c "$FILE" -b "$FILE" -A "$AGENT" -s "http://$SITE/install/index.php" --output "$INDEX_FILE"

CURRENT_VERSION=$(grep "Version last upgrade" $INDEX_FILE | sed 's/\(<br>\)/\n/g' | grep "last upgrade" | sed 's/^.*\([0-9]\+\.[0-9]\+\)\.[0-9]\+.*$/\1/')

echo "Detected current version : $CURRENT_VERSION"

TARGET_VERSION=$(grep "Version last upgrade" $INDEX_FILE | sed 's/\(<br>\)/\n/g' | grep "Version program" | sed 's/^.*\([0-9]\+\.[0-9]\+\)\.[0-9]\+.*$/\1/')

echo "Targeted version is : $TARGET_VERSION"

while :
do
  REFERE="http://$SITE/install/index.php"
  FILE=/tmp/dolibarr_upgrade_res_${CURRENT_VERSION}.html
  URL="http://$SITE/install/$(grep from=$CURRENT_VERSION $INDEX_FILE | sed 's/^.*href="\(.*\)">.*$/\1/' | sed 's/&amp;/\&/g')"
  echo "Using URL : $TARGET_URL"
  printf "upgrading step 1 from $CURRENT_VERSION..."
  curl --refere "$REFERE" -c "$FILE" -b "$FILE" -A "$AGENT" -s "$URL" --output "$FILE"
  echo Done.


  # Step 2
  REFERE="$URL"
  DATA="$(grep -A2 "forminstall" "$FILE" | sed 's/^.*action="\([^"]*\).*/\1/' | sed 's/^.*name="\([^"]*\)" value="\([^"]*\)".*/\1=\2/')"

  echo "DATA = '$DATA'"
  URL="http://$SITE/install/$(cut -f 1 -d ' ' < <(echo $DATA))"
  data1=$(cut -f 2 -d ' ' < <(echo $DATA))
  data2=$(cut -f 3 -d ' ' < <(echo $DATA))
  echo "Found URL : $URL"
  echo "Found args: $data1 ; $data2"


  FILE=/tmp/dolibarr_upgrade_res2_${CURRENT_VERSION}.html
  printf "upgrading step 2 from $CURRENT_VERSION..."
  curl --refere "$REFERE" -F "$data1;$data2" -c "$FILE" -b "$FILE" -A "$AGENT" -s "$URL" --output "$FILE"
  echo Done.


  # Step 3
  REFERE="$URL"
  DATA="$(grep -A2 "forminstall" "$FILE" | sed 's/^.*action="\([^"]*\).*/\1/' | sed 's/^.*name="\([^"]*\)" value="\([^"]*\)".*/\1=\2/')"

  echo "DATA = '$DATA'"
  URL="http://$SITE/install/$(cut -f 1 -d ' ' < <(echo $DATA))"
  data1=$(cut -f 2 -d ' ' < <(echo $DATA))
  data2=$(cut -f 3 -d ' ' < <(echo $DATA))
  echo "Found URL : $URL"
  echo "Found args: $data1 ; $data2"


  FILE=/tmp/dolibarr_upgrade_res3_${CURRENT_VERSION}.html
  printf "upgrading step 3 from $CURRENT_VERSION..."
  curl --refere "$REFERE" -F "$data1;$data2" -c "$FILE" -b "$FILE" -A "$AGENT" -s "$URL" --output "$FILE"
  echo Done.
  break
done
