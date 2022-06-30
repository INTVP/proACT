#!/bin/bash
Help()
{
   # Display Help
   echo "Run the pipeline of data standardization and JSON creation"
   echo
   echo "Syntax: run_country.sh [-c|h|x]"
   echo "options:"
   echo "c     ISO-2 country code"
   echo "x     Chunk index"
   echo "h     Print this Help."
   echo
}

# Get the options

while getopts ":c:x:" options; do


  case "${options}" in
    c)
      COUNTRY=${OPTARG}
      ;;
    x)
      chunk=${OPTARG}
      re_isanum='^[0-9]+$'
      if ! [[ $chunk =~ $re_isanum ]] ; then
        echo "Error: TIMES must be a positive, whole number."
        exit_abnormal
        exit 1
      elif [ "$chunk" -eq "0" ]; then
        echo "Error: TIMES must be greater than zero."
        exit_abnormal
      fi
      ;;
    :)
      echo "Error: -${OPTARG} requires an argument."
      exit_abnormal
      ;;
    *)
      exit_abnormal
      ;;
  esac
done

echo "${COUNTRY}"
echo running the pipeline of data standardization and JSON creation for "${COUNTRY}"
sub_dir=mod_ind_df/"${COUNTRY}"/"${COUNTRY}"_"${chunk}"/reverse-flatten-tool-"${COUNTRY,,}"-"${chunk}"
echo "${sub_dir}"

COUNTRY_PORT=$(grep "${COUNTRY}""${chunk}": configuration/dataset_ports.txt | rev | cut -d: -f1 | rev)
CURRENT_PORT=$(grep '[[:digit:]].*:' "${sub_dir}"/docker-compose.yml | rev | cut -d: -f2 | rev | sed -e 's/ *//g' | sed -e 's/-//g')
echo "CURRENT_PORT is ${CURRENT_PORT}, changing to ${COUNTRY_PORT}"
sed -e "s/${CURRENT_PORT}/${COUNTRY_PORT}/i" -i "${sub_dir}"/docker-compose.yml
sed -e "s/dw-database/dw-database-${COUNTRY,,}-${chunk}/" -i "${sub_dir}"/docker-compose.yml
sed -e "s/${CURRENT_PORT}/${COUNTRY_PORT}/" -i "${sub_dir}"/system_settings.py

