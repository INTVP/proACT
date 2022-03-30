import sys
from csv import DictReader

fileName = str(sys.argv[1])
if not fileName:
    print('Please add path to csv file as argument. Example: python3 modification-table-creator.py "MX/MX_mini.csv"')
else:
    with open(fileName, 'r') as read_obj:
        csv_dict_reader = DictReader(read_obj)
        modification_table = [['persistent_id']]
        column_name_list = []
        column_names = csv_dict_reader.fieldnames
        for column_name in column_names:
            inner_list = [column_name]
            column_name_list.append(inner_list)
        modification_table.append(column_name_list)
        print(modification_table)
