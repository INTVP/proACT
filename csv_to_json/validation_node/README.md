# DATASET VALIDATOR
Dataset should be in format:
```bash
{tender_data}
{tender_data}
...
```

For validation we use `schemas/tender.schema.json`.

## Usage

### First usage
Before first launch you should install node modules. Use this command:
```bash
docker-compose run node yarn install
```

### Convert dataset to a proper format
```bash
docker-compose run node convert_json.js -i INPUT_FILE_PATH -o OUT_FILE_PATH
```
where `INPUT_FILE_PATH` is the path of the existing dataset and `OUT_FILE_PATH` the path with file name of the converted dataset.
Example:
```bash
docker-compose run node convert_json.js -i datasets/KE_portal.json -o datasets/KE_portal_multiline.json
```

### Validate dataset
```bash
docker-compose run node validate.js -f DATASET_PATH
```
where `DATASET_PATH` is the path with file name of the dataset to validate 

Example:
```bash
docker-compose run node validate.js -f datasets/KE_portal_multiline.json
```
