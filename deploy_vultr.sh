#!/bin/sh

download_base=https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/
plan_type=vc2-1c-1gb
plan_location=yto

report() {
  if [ "$1" == "start" ]; then
    printf "\033[33m[ PENDING ]\033[0m $current_step         "
  elif [ "$1" == "end" ]; then
    echo -e "\r\033[32m[ OK ]\033[0m $current_step         "
  else
    echo -e "\r\033[31m[ ERROR ]\033[0m $current_step          "
    echo -e "\n$2"
    exit 1
  fi
}

result_call() {
  result_output=$(eval "$1" 2>&1)
  if [ "$curr_errno" -ne "0" ]; then
    report "error" "$result_output"
  fi
}

echo -n "Enter Vultr API Key: "
read vultr_api_key
echo ""

cd ./preseeder
rm -rf ./in
mkdir -p ./in

current_step="Retrieving name of latest debian netinst iso"
report "start"
result_call "curl $download_base"

debian_iso_name=$(echo $result_output | grep -o 'debian[0-Z.-]*iso' | head -n 1)
if [ -z "$debian_iso_name" ]; then
  report "error" "Could not find iso name"
fi
report "end"

current_step="Downloading latest debian iso: $debian_iso_name"
report "start"
result_call "wget $download_base$debian_iso_name -O ./in/debian.iso"
report "end"

current_step="Preseeding debian iso"
report "start"
result_call "./docker_preseed.sh ./in/debian.iso"
report "end"

current_step="Uploading preseeded debian iso to 0x0"
report "start"
result_call "./upload_iso.sh"
preseeded_iso=$(echo $result_output | grep -o 'https://.*iso')
report "end"

current_step="Creating ISO in Vultr"
report "start"
result_call "curl --location --request POST 'https://api.vultr.com/v2/iso' \
--header 'Authorization: Bearer $vultr_api_key' --header 'Content-Type: application/json' \
--data-raw '{\"url\":\"$preseeded_iso\"}'"
if [ -z "$(echo $result_output | grep '\"iso\"')" ]; then
  report "error" "$result_output"
fi
iso_id=$(echo $result_output | grep -o '"id":"[0-Z.-]*"' | cut -d':' -f2 | cut -d'"' -f2)
if [ -z "$iso_id" ]; then
  report "error" "No ISO id"
fi
report "end"

current_step="Waiting for ISO to finish downloading in Vultr"
report "start"
while true; do
  result_call "curl --location --request GET https://api.vultr.com/v2/iso/$iso_id \
--header 'Authorization: Bearer $vultr_api_key'"
  if [ -z "$(echo $result_output | grep '\"iso\"')" ]; then
    report "error" "No ISO"
  fi
  if [ -n "$(echo $result_output | grep '"status":"complete"')" ]; then
    break
  fi
  sleep 5
done
report "end"

current_step="Create VPS instance"
report "start"
vps_payload="{\"region\":\"$plan_location\",\"plan_id\":\"$plan_type\",\"iso_id\":\"$iso_id\", \
\"label\":\"freemaker\"}"

result_call "curl --location --request POST 'https://api.vultr.com/v2/instances' \
--header 'Authorization: Bearer $vultr_api_key' --header 'Content-Type: application/json' \
--data-raw '$vps_payload'"
report "end"
