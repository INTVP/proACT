import re
from csv import DictReader


def get_ind_columns(filename_csv):
    """
    Get the first row of the CSV and extract the column names for the indicators and the "tender_id" and "lot_number"
    the indicators start with a prefix of "ind_"
    :param filename_csv: CSV file to be converted to JSON
    :return: ind_columns: column names of the CSV
    """
    with open(filename_csv, 'r') as csv_file:
        csv_dict_reader = DictReader(csv_file)
        column_names = csv_dict_reader.fieldnames
        csv_file.close()

    pattern = re.compile('^ind_|^tender_id$|^lot_number$')
    ind_columns = list(filter(pattern.search, column_names))
    assert type(ind_columns) == 'list'
    return ind_columns
