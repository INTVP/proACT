import logging
import os
import re
import sys
from csv import DictReader

import numpy as np
import pandas as pd


def reading_mapper(country: str, sheet_name: str):
    """
    Read in the file with renaming
    :param country: ISO-2 country code
    :param sheet_name: sheet name
    example: CSV name is "buyer_city_api": "buyer_city"

    :return: Dictionary output used for renaming the data
    """
    # https://docs.google.com/spreadsheets/d/113SvWugknA0bcvdO5wS40ei4Y2qisX4Txm-i9ipWIBY/edit#gid=0
    sheet_id = "113SvWugknA0bcvdO5wS40ei4Y2qisX4Txm-i9ipWIBY"
    url = f"https://docs.google.com/spreadsheets/d/{sheet_id}/gviz/tq?tqx=out:csv&sheet={sheet_name}"
    col_names = pd.read_csv(url)
    col_names = col_names.loc[col_names[country].notnull(), [country, 'column_name']]

    col_names = {k: v for k, v in col_names.values}
    # mapper = open(filename, 'r').read()
    # assert len(mapper) > 2, f"Renaming file is not filled"
    # mapper = eval(mapper)
    # return mapper
    return col_names


def import_data_file(filename_csv: str, country: str):
    """
    Import the main CSV and fix the product codes
    :param filename_csv: Input CSV file name
    :param country: ISO-2 country code
    :return: Main data frame
    """
    logging.info(f"Importing column names")
    with open(filename_csv, 'r') as read_obj:
        csv_dict_reader = DictReader(read_obj)
        column_names = csv_dict_reader.fieldnames
        column_names = ','.join(column_names)
        read_obj.close()
    logging.info(f"Importing lot_productCode as string")
    product_code_col = re.findall(r'lot_product[cC]ode', column_names)[0]
    logging.info(f"Loading FULL data from {filename_csv}")
    df = pd.read_csv(filename_csv, low_memory=False, encoding='utf-8', dtype={product_code_col: 'str'})
    df.loc[df['submp'].notnull(), ['submp']] = df.loc[df['submp'].notnull(), 'submp'].astype(np.int64)
    df.loc[df['decp'].notnull(), ['decp']] = df.loc[df['decp'].notnull(), 'decp'].astype(np.int64)

    # df = pd.read_csv(filename_csv, low_memory=False, encoding='utf-8', dtype={product_code_col: 'str',
    #                                                                           'submp': 'Int64',
    #                                                                           'decp': 'Int64'})
    df['is_capital'] = df['is_capital'].astype(bool)
    logging.info(f"{len(df)} rows imported")
    return df, column_names
