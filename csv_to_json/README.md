# Standardizing and JSON files generation

This section of the code converts the CSV files in `../country_codes/XX` first to
a standardized CSV using `indicators_json`, then into a JSON using the `/reverse-flatten-tool`. The documentation of the `/reverse-flatten-tool` is included in its folder.

1. [Requirements](#Requirements)
2. [How to run](#How-to-run)
## Requirements

to install requirements using pip

```bash
pip install -r requirements.txt
```

## How to run
to convert the file CSV file to a standardized file, run the following in
the command line

```bash
export CSV_PATH=KE
python indicators_json.py CSV_PATH
```
