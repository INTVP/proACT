import logging

from pandas import DataFrame


def clean_text_columns(df: DataFrame, col_text: list) -> DataFrame:
    """
    Clean text columns by removing conflicting characters ["[", "]", "{", "}", ";"]
    and convert to string
    :param df: Main data frame
    :param col_text: column of type text
    :return: Main data frame
    """
    for col_name in col_text:
        try:
            logging.info(f"cleaning {col_name}...")
            df[col_name] = df[col_name].str.replace('[', '')
            df[col_name] = df[col_name].str.replace(']', '')
            df[col_name] = df[col_name].str.replace('{', '')
            df[col_name] = df[col_name].str.replace('}', '')
            df[col_name] = df[col_name].str.replace(';', '|')
        except AttributeError:
            logging.info(f"cleaning {col_name} using astype('str')...")
            df[col_name] = df[col_name].astype('str').replace('[', '')
            df[col_name] = df[col_name].astype('str').replace(']', '')
            df[col_name] = df[col_name].astype('str').replace('{', '')
            df[col_name] = df[col_name].astype('str').replace('}', '')
            df[col_name] = df[col_name].astype('str').replace(';', '|')
        except KeyError:
            logging.info(
                f"column {col_name} not found")
            continue
    return df
