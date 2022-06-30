import logging

import numpy as np
from pandas import DataFrame


def fix_enum(df: DataFrame, country: str) -> DataFrame:
    """
    Check if Enumerations are correct
    :param df: Main data frame
    :param country: ISO-2 country code
    :return: Main data frame
    """
    # ENUM checks
    enum_dict = 'configuration/enum_dict.txt'
    enum_cols = open(enum_dict, 'r').read()
    enum_cols = eval(enum_cols)
    for col_name, enum_list in enum_cols.items():
        try:
            na_rate = str(((df[col_name].isnull() | df[col_name].isna()).sum() * 100 / df.index.size).round(2)) + '%'
            logging.info(
                f"missing rate of {col_name} in {country} is {na_rate}")
            enum_list = sorted(list(enum_list))
            df_enum = sorted((list(df[col_name].dropna().unique().tolist())))
            if col_name == 'buyer_mainactivities':
                df.loc[df[col_name] == '[""]', col_name] = np.nan
                logging.info(f'setting [""] in {col_name} no NA')
                df_enum = df[col_name].dropna().unique().tolist()
                df_enum = [item.replace('"', '').replace("[", "").replace("]", "") for item in df_enum]

            if all(x in enum_list for x in df_enum):
                logging.info(f"Enum of {col_name} in are valid")
            else:
                logging.info(f"Enum of {col_name} in are NOT valid")
                logging.info(
                    f"{col_name} enum are {df[col_name].unique()}")

        except KeyError:
            logging.info(
                f"column {col_name} not found")
            continue
    return df
