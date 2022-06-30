#!/bin/bash

TARGET=country_data_files/
dir=$(pwd)
cd reverse-flatten-tool
sudo docker-compose up -d
echo "$dir"
cd "${dir}"
inotifywait -m -e create -e moved_to --format "%f" $TARGET \
        | while read FILENAME
                do
                        COUNTRY="$(cut -d'_' -f1 <<< "${FILENAME}")"
                        echo Detected "${FILENAME}", running the tool for "${COUNTRY}"
                        python3 indicators_json.py country_data_files/"${COUNTRY}"
                        cd reverse-flatten-tool
                        python3 reverse_flatten.py ../../country_codes/"${COUNTRY}"
                        cd "${dir}"
                        cd validation_node
                        echo "$dir"

                        sudo bash json_validate.sh "${COUNTRY}"

                        cd "${dir}"
                        echo "$dir"
                done