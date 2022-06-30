#!/bin/bash

dir=$(pwd)
TARGET=/shared/gti_files/ProACT/
DES=country_data_files/

inotifywait -m -e create -e moved_to --format "%f" $TARGET \
        | while read FILENAME
                do
                        echo Detected "${FILENAME}", moving to  "${DES}"
                        cp "${TARGET}"/"${FILENAME}" "${DES}"
                done