Reverse flatten tool - Documentation
------------------------------------

How it works:
------------------
Reverse flatten tool is made for converting csv files into json records and modifying existing json records. At the end of each process the produced json records are exported into a json file from the database.
The tool executes the modules set to true in settings.py, which determines how the tool will process the input files. The folder containing the files to be processed should be put into the reverse flatten tool's directory, so the projects under the tool look like this:

- reverse-flatten-tool
	- Project1
	- Project2

The reverse flatten tool must contain the following files and directories to work:

- conversions.py
- docker-compose.yml
- utils.py
- json_buffered_reader.py
- make_connection_table_tool.py
- reverse_flatten.py
- hone folder (modification and structure builder logic module)
- project_folder (any number of project folders can exist in the tool's directory)

	- connection_table.py
	- settings.py
	- input csv and json files (the files which will be processed and their output)

Running the reverse flatten tool:
---------------------------------
All commands must be executed in the reverse flatten tool's directory on the command line.

- First, execute the following command to start the database:

        docker-compose up -d

- Second, run this command with the project folder name instead of "project_folder_name":

        python3 reverse_flatten.py project_folder_name

- If the project is in a different folder, you can add the folder name there

        python3 reverse_flatten.py ../some/path/project_folder_name
- Example on Windows
```git
docker-compose up -d
python reverse_flatten.py ../../country_codes/KE
```
- Example on Linux
```git
docker-compose up -d
python3 reverse_flatten.py ../../country_codes/KE
```



system_settings.py:
-------------------
All settings and parameters must be set by the user of the reverse flatten tool

- db_port: the port number of the PostgreSQL server. Check the docker-compose.yml file for the proper port number. Default is 5432.


settings.py:
------------
All settings and parameters must be set by the user of the reverse flatten tool if no instruction says otherwise.

- Types of settings:

	Input and output files:
	-----------------------
	An example file is provided in the project folder for each file type in the 'example' folder. There are four modification operations: item modification, branch appending, list item deletion, single property deletion.
	Possible input files for the tool (depending on whether it is used for creating or modifying a json file):

	- input_csv_filename:
		Input csv file provided for the reverse flatten tool's reverse flatten module to convert it to json records. Read line by line and converted to json records which are saved into database, then exported into a json file. Keep in mind that the records in the file **have to be ordered by id**.
	- input_json_filename:
		Input json file provided for the reverse flatten tool's modification module. The file is parsed for individual json records which are persisted, then modified according to the data given in mod_csv_filename and the operations provided in the modification_table in connection_table.py.
	- mod_csv_filename:
		Input csv file provided for the reverse flatten tool's modification module. Read line by line and for each line the corresponding json record is modified using the data read from the csv line.
	- output_json_filename:
		Name of the output json file produced after running the reverse flatten tool with any module being active.

	IMPORTANT! In csv files MUST use "true" or "false" as boolean value! Nothing else will work, like 't' or 'T', etc.

	Modules:
	--------
	- is_reverse_flatten_mode_active:
		If set to true, the tool will read the input csv file given in settings.py and convert them to json records which are persisted and then exported to an output json file.
	- is_modification_mode_active:
		Depending on read_from_db_for_modification option being true or false, either the json records are loaded directly from the database or the input json file is parsed for individual json records which are persisted. The json records are then modified according to the data given in mod_csv_filename and the operations provided in the modification_table in connection_table.py. These modifications can be: value update, new value insertion or value deletion.
	- is_export_only_mode_active:
		If this mode is active, all other modules are ignored and the only process being executed is the exporting of json records currently stored in the database into an output json file.

	Options:
	--------
	- read_from_db_for_modification:
		If this option is set to true, the input json file will not be parsed for json records, the json records needed for the process will be loaded directly from the database.
	- truncate_table_after_export:
		If this option is set to true, the table containing the produced json records will be emptied after it's content is exported into an output json file. If both reverse flatten module and modification module are active with read_from_db_for_modification set to true, then this parameter should not be set to true, as the table would be truncated at the end of the first module, and the second module could not read from records from the emptied table.

	Project level parameters:
	-------------------------
	- json_id_field_name:
		It's a list. It contains the names of the id keys in the json records to be constructed. (Example: "persistentId", "id")
	- csv_id_field_name:
		It's a list. It contains the names of the columns containing the ids of the records in the input csv file. (Example: "persistent_id", "tender_id")
	- chunk_size:
		The number of records to be loaded and processed at once. Should be set to an amount which the memory can still hold with no problem considering the average size of an individual record.
	- db_operation_size:
		The number of records persisted at once.
	- log_level:
		The level set for logging information while running the tool, only the logs on and above the set level will be shown. Log levels (lowest->highest): DEBUG, INFO, ERROR.
	- date_format_str:
		Date format of the dates in the input csv files. %Y, %m and %d refer to year, month and day.
		For example:
		- Date in csv file: 2020,07,17	date_format_str: "%Y,%m,%d"
		- Date in csv file: 17/July/2020	date_format_str: "%d/%m/%Y"
	- json_reader_buffer_size:
		Buffer size provided for json_buffered_reader.py. This number of bytes will be read into the buffer and parsed for individual json records. Should not be smaller than the size of the biggest record. This number can and should be set to a multiple of the size of an average json record, in this case multiple json records will be read and processed. The default 20 MB works fine, but it can be set to higher values.
	- input_csv_delimiter:
	    The delimiter for input csv file. Example: ','
    - modification_csv_delimiter:
        The delimiter for input csv file. Example: ',' or ';'

connection_table.py:
--------------------
- connection_table:
	The main connection table describing the relations of the columns in the csv input file and the corresponding json keys. This table is used to build the json record's structure.
	An example connection table:

		connection_table = [['id', 'id'],
		                    ['salary[].month', 'month'],
		                    ['salary[].amount[].net', 'net', ['str_to_int_or_float'],
		                    ['salary[].amount[].currency', 'currency'],
		                    ['salary[].work[]', 'work'],
		                    ['date', 'date', 'date_conversion'],
		                    ['activeWorker', 'activeWorker', ['str_to_bool']

	The connection table has at least 2 columns and a third optional column. The first column contains the fields path to the field in the json structure to be created (eg.: 'salary[].amount[].net'), the second column contains the name of the column in the input csv file (eg.: 'net'). After the 2 mandatory columns were given, the third column is optional, it can contain a list of conversion names which specify what conversions should be applied to the field's value.

	IMPORTANT! It's possible to use pre-defined json array in the csv file as a value for an array in the json structure. For example the user can define the whole indicators array as a json array in the csv file. In this case the array symbol "[]" has to be removed from the json path. Example: ['indicators', 'tender_indicators'] instead of ['indicators[]', 'tender_indicators']

	For non-object type arrays (like string or number array), the user HAVE TO define json array in the csv file.  

- id_fields:
    It's a list that contains id field names (column names) from the csv file header.

- conversion_table:
	Initialized by the software for internal use, should be left empty.

- modification_table and reverse_flatten_table:

	From v1.0.10 reverse_flatten_table is MANDATORY for reverse flatten operation, so please update your connection_table, and create the reverse_flatten_table.

	The tool creates/modifies the json structure following the order of this list. So unique field should be define first (this can be the filter for the other fields), than the others. For example in the case of indicators the 'type' field must be add to this list first, than the the others ('value', 'status'). The 'type' field will be the filter for 'status' and 'value'. For more information please see the '5. Handling indicators' chapter.

	FILTERS: The order of the filters is IMPORTANT! The order of the filters must follow the json structure. The first filter is the one that is the closest to the json root level. Example: If there are filters for lot level, bid level and bidder level, the order must be:
	1. lot level filter (this is the closest to the root (tender) level)
	2. bid level filter
	3. bidder level filter

	It is not possible to use field from "deeper" structure as a filter. For example: for filtering bidders the user can't use the id field from bodyIds, because this id field is one level deeper in the json structure.

	Only fields with UNIQUE VALUE can be filters. The user should define the filter field BEFORE the other field of the json object in the modification_table or reverse_flatten_table.

	The way the user should define the modification_table's and modification csv's content changes with the type of modification.
	4 types of modification can be executed:
	- List item modification with or without filter parameters
	- Appending the record with a list of values/json branch with or without filter parameters
	- List item deletion
	- Property deletion

	Modification table structure

	I. For modification or reverse-flatten operation

	    modification_table = [['persistent_id','tender_id'], [['lot_indicator_type', ['lot_number']],
                                        ['lot_indicator_value', ['lot_number', 'lot_indicator_type']],
                                        ['lot_indicator_status', ['lot_number', 'lot_indicator_type']],
                                        ['tender_indicators']
                                        ]
                          ]

    - 1st item: list of the names of the fields (from modification csv header) that contain IDs (example: persistent_id, tender_id). At least one ID is mandatory.
    - 2nd item: it's a list of field names and optional filters. Names come from the header of the modification csv file. (In the example above 'lot_indicator_value' has 2 filters, but 'tender_indicator_type' doesn't have one.) The order of the filter items is follow the json structure (from root to leaf). For example for 'lot_indicator_value' first we filter at lot level by 'lot_number', than we filter for the specific indicator by 'lot_indicator_type'. So the order of the filters is IMPORTANT!   

	II. For deletion

	    modification_table = ['persistent_id', 'bidder_name', 'DELETE_LIST_ITEM']

	- 1st item: the name of the field (from modification csv header) that contains the ID
	- 2nd item: the name of the field you want to delete
	- 3rd item: it contains a flag which shows what do you want to delete. (DELETE_LIST_ITEM or DELETE_PROPERTY)

1. List item modification with or without filter parameters:

	2 columns are defined in the modification table. The first one is for ID. The 2nd one also contains 2 columns: 1 mandatory for field name and 1 optional for filters. The filtering fields are keys in the json tree which have a unique value and help locate the field to be modified. The filter column only needs to be given, if the path to the field to be modified in the json tree is ambiguous (there are more than one fields with the same key in one json record, maybe with different paths as well).
	In the modification csv we provide the values for the modification table: the id of the record to be modified, the new value of the field to be modified and the values of the filter parameters. Multiple filter values can be given in the third column.
	For example:
	If the field to be modified is a main level field like "date":

		"id": "2",
		"date": "2020-08-24",
		"lots": [
			{
				"bids": [
					{
						"bidders": [
							{
								"bidder_name": "name1"
								"address": {
									"rawAddress": "addr1"
								}
							},
							{
								"bidder_name": "name2"
								"address": {
									"rawAddress": "addr2"
								}
							}
						]
					}
				]
			}
		]
	Then there is no need for filtering and the row in modification_table (in connection_table.py) for changing "date" field's value is:

		modification_table = ['id', ['date']]
	And the modification csv row is:

		"2","2020-07-24"

	In this case we don't need to specify the path to the field in the tree.

	The example record after modification:

		"id": "2",
		"date": "2020-07-24",
		"lots": [
			{
				"bids": [
					{
						"bidders": [
							{
								"bidder_name": "name1"
								"address": {
									"rawAddress": "addr1"
								}
							},
							{
								"bidder_name": "name2"
								"address": {
									"rawAddress": "addr2"
								}
							}
						]
					}
				]
			}

	If we want to change a field which is in a nested list like "rawAddress", then we have to specify the path, as there can be fields with the same key, but with different paths. In this case, we will use the field above "rawAddress" named "bidderName", because it is in the same nested list in the tree and has a rather specific value.

	In this case, the connection table row is:

		['id', ['rawAddress', ["bidder_name"]]]

	and the modification csv row is:

		"2","new address value","name1"

	The example record after modification:

		"id": "2",
		"date": "2020-08-24",
		"lots": [
			{
				"bids": [
					{
						"bidders": [
							{
								"bidder_name": "name1"
								"address": {
									"rawAddress": "new address value"
								}
							},
							{
								"bidder_name": "name2"
								"address": {
									"rawAddress": "addr2"
								}
							}
						]
					}
				]
			}

2. Appending the record with a list of values/json branch with or without filter parameters:

	In this case, the only difference in the modification table is that the name of the key given in the second column refers to a json key which has its own specific branch built by the tool with the help of the connection table.
	For example:
	If we want to add a new branch with a "lots" containing a "bids" containing a "bidders" containing an "address", like above, then we only have to give the innermost property's name which is "address". It is already specified in the connection table how to build an "address":

		['lots[].bids[].bidders[].address', 'address']
	So the modification table row for adding the above branch is:

		['id', ['address']]
	And the modification csv row is:

		"2","new adress value"

	The example record after modification:

		"id": "2",
		"date": "2020-08-24",
		"lots": [
			{
				"bids": [
					{
						"bidders": [
							{
								"bidder_name": "name1"
								"address": {
									"rawAddress": "new adress value"
								}
							},
							{
								"bidder_name": "name2"
								"address": {
									"rawAddress": "addr2"
								}
							}
						]
					}
				]
			}
		]

	In both appending types of modification:
	- if the id of the record to be modified is not given in the modification csv, then every record containing the field with the specified path will be modified.
	- if no filter parameters are given but there are more then one record with the given key name, then every value will be changed in the record with the given id.
	- if no id AND no filter parameters were given, then every field with the given name in every record will be modified.
	- if a value is not found in the record, then it will be inserted to its place in the tree.

3. List item deletion:

	When deleting a list item, in the modification table the first column defines the id of the record which has the list item to be deleted, the second column defines the name of the list item to be deleted and the third column defines the type of deletion to be executed, in this case: 'DELETE_LIST_ITEM'. All occurrences of the given list item will be deleted in the given record.
	For example:
	If we want to delete "bidder_name" from the example above, the modification table line will be:

		['id', 'bidder_name', 'DELELTE_LIST_ITEM']
	and the modification csv row will be:

		"2","name1"

	The example record after deletion:

		"id": "2",
		"date": "2020-08-24",
		"lots": [
			{
				"bids": [
					{
						"bidders": [
							{
								"bidder_name": "name2"
								"address": {
									"rawAddress": "addr2"
								}
							}
						]
					}
				]
			}
		]

4. Property deletion:

	In this case the whole property (key-value pair) will be deleted. The only difference is in the modification table: we have to change the third column to 'DELETE_PROPERTY':

		['id', 'bidder_name', 'DELETE_PROPERTY']
	The example record after deletion:

		"id": "2",
		"date": "2020-08-24",
		"lots": [
			{
				"bids": [
					{
						"bidders": [
							{
								"address": {
									"rawAddress": "addr1"
								}
							},
							{
								"address": {
									"rawAddress": "addr2"
								}
							}
						]
					}
				]
			}
		]

    If we want to execute a deletion on all existing records, then the modification table should be defined with the first column's value not provided, or with empty value provided as id in the modification csv:

    modification table line:

	    ['', 'bidder_name', 'DELETE_PROPERTY']

    or

    modification csv:

    	"id"
    	""

    Only one deletion should be executed at once.

5. Handling indicators

    In this example we add or modify indicators at tender and lot level.

    It is possible to add or modify a single indicator property (using modification_table items: indicator_type, indicator_value, indicator_status) or we can define the whole indicators array (using tender_indicators or lot_indicators). In this case the tool will remove all array items from the given indicator, and replace them with the predefined one from the modification csv file.   

    IMPORTANT: If we want to modify a single indicator property/value, we must first define indicator TYPE field in the modification_table. The algorithm process the fields the same order as they are in the modification table.

    In the example we first define lot level indicator, and we use lot number as a filter. The first field is the type. The modification algorithm check if the specified (in modification csv) type name is already exist or not. If not it will create it. Later the value and/or status will be modified for this indicator. That's why the type field is included in the value/status filter list.

    We also use the replace method for tender level indicators (tender_indicators in the modification_table). To use this, we have to add a new element to connection table: ['indicators', 'tender_indicators'] Please notice that we use 'indicators' and not 'indicators[]'!  

    Example modification table in connection_table.py file:

        modification_table = [['persistent_id','tender_id'], [['lot_indicator_type', ['lot_number']],
                                        ['lot_indicator_value', ['lot_number', 'lot_indicator_type']],
                                        ['lot_indicator_status', ['lot_number', 'lot_indicator_type']],
                                        ['tender_indicators']
                                        ]
                          ]

    Example modification csv file (delimiter is CHANGED to ';'):

        "persistent_id";"lot_indicator_type";"lot_indicator_value";"lot_indicator_status";"lot_number";"tender_indicators";"lot_updatedprice";"lot_updateddurationdays";"net_amount";"currency"
        KE_000308a71bea345a00673a0ac2ab7c43ca43bf32cf8791dd727d51d4c50c4f96_1;MY_NEW_INDICATOR;77777;CALCULATED;2;;2222;22;;
        KE_000308a71bea345a00673a0ac2ab7c43ca43bf32cf8791dd727d51d4c50c4f96_1;;;;;[{"type": "MY_NEW_TENDER_INDICATOR", "value": "100", "status": "CALCULATED"}, {"type": "MY_NEW_TENDER_INDICATOR2","value": "1","status": "CALCULATED"}];;;;


- mapping_table:
	Initialized by the software for internal use, should be left empty.

- reverse_mapping_table:
	Initialized by the software for internal use, should be left empty.

conversions.py:
------------
- date_conversion:
	Converts dates to the digiwhist date format.
- str_to_int_or_float:
	Converts strings to integer or float numbers (useful if some data were extracted in string format but are numbers).
- str_to_bool:
	Converts strings to boolean values (Extract True and False values from strings).
conversions.py can be extend with more methods with the same syntax in the future.

modification-table-creator.py:
------------

   This tool helps you to create a modification_table. It will collect all the column names from the csv file header, and create a base list for modification_table. The result will be printed on the terminal.

   When you start this tool, you have to specify the path for the input or modification csv file like this:

    python3  modification-table-creator.py 'MX/MX_input.csv'

   You have to check the order of the fields, because unique fields must precede the other fields. For example for indicators 'type' field must precede 'status' and 'value'.

   Also you have to add the filters to the elements. In the case of indicators the 'type' field will be the filter for 'status' and 'value'.
