#!/bin/bash
country=$1
echo moving file to datasets/"${country}"_portal.json
mv ../../country_codes/"${country}"/"${country}"_portal.json datasets/"${country}"_portal.json
#
docker-compose run node convert_json.js -i datasets/"${country}"_portal.json -o datasets/"${country}"_portal_multiline.json
echo "validating"
docker-compose run node validate.js -f datasets/"${country}"_portal_multiline.json
