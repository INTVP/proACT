import logging

from pandas import DataFrame


def check_na_col_dates(df: DataFrame, col_dates: list, country: str) -> DataFrame:
    """
    Check missing rates of each available date variable
    :param df: Main data frame
    :param col_dates: date columns
    :param country: ISO-2 country code
    :return: Main data frame
    """
    for col_name in col_dates:
        try:
            na_rate = str(((df[col_name].isnull() | df[col_name].isna()).sum() * 100 / df.index.size).round(2)) + '%'
            logging.info(
                f"missing rate of {col_name} in {country} is {na_rate}")
        except KeyError:
            logging.info(
                f"column {col_name} not found")
            continue

    # variable_in_use = 'is_capital'
    # logging.info(f"FIX 4: Converting {variable_in_use} to bool")
    return df
