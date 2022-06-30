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
the command line. The command below is for Malta (ISO-2 code **MT**)

This code also exports the standard CSV files to [csv_export][csv_export]
with the file name `MT_export.csv.gz`
```shell
python3 indicators_json.py MT
```
It is also possible to chunk the data if it is big but that requires 
running the docker-compose for each created chunk separately. 

For example if we are going to run the data for a big into 10 chunks.
we can run:

```shell
python3 indicators_json.py MT chunk True 10
```
All chunks along with the tool and the `docker-compose.yml` ports
will be moved to [mod_ind_df][mod_ind_df]. 
Inside that folder there will the following tree
as an example for chunk 1 (reduced to necessary files)

```shell
├── [4.0K]  MT
│   ├── [4.0K]  MT_1
│   │   ├── [4.0K]  MT
│   │   │   ├── [ 11K]  connection_table.py
│   │   │   ├── [539K]  MT_mod_ind.csv
│   │   │   └── [1.4K]  settings.py
│   │   └── [4.0K]  reverse-flatten-tool-mt-1
│   │       ├── [ 369]  docker-compose.yml
│   │       ├── [ 17K]  reverse_flatten.py
│   │       ├── [  41]  system_settings.py

``` 

Creating the JSON files can be done after that by navigating inside `MT`
```shell
cd MT_1/reverse-flatten-tool-mt-1 && docker-compose up -d && read -t 5 -r || python3 reverse_flatten.py ../MT
```
The command above should be done for each chunk. 
To collect the chunks together you must install `qj` on you Linux machine
and run the following command

```shell
jq flatten */*/*.json > MT_portal.json
```

[csv_export]: /csv_to_json/csv_export
[mod_ind_df]: /csv_to_json/mod_ind_df