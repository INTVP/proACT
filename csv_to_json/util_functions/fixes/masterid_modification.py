import logging

from pandas import DataFrame


def masterid_modification(df: DataFrame, country: str) -> DataFrame:
    """
    Prefix IDs with the ISO-2 country code except for WB and IDB, we add WB and IDB
    :param df: Main data frame
    :param country: ISO-2 country code
    :return: Main data frame
    """
    col_name = 'bidder_masterid'
    # assert not df[col_name].isnull().values.any(), f"There are missing {col_name}"
    na_rate = str(((df[col_name].isnull() | df[col_name].isna()).sum() * 100 / df.index.size).round(2)) + '%'
    logging.info(f"missing rate of {col_name} in {country} is {na_rate}")
    logging.info(f"FIX 1: Adding {country} to {col_name}...")
    try:
        df.loc[df[col_name].notnull(), col_name] = country + '_' + df.loc[df[col_name].notnull(), col_name]
    except ValueError:
        logging.info(f"FIX 2: Adding {country}"
                     f" to {col_name} astype('str') using ...")
        df[col_name] = df[col_name].values.astype(str)
        df.loc[df[col_name].astype('str').notnull(), col_name] = country + '_' + \
                                                                 df.loc[df[col_name].astype('str').notnull(), col_name]

    col_name = 'buyer_masterid'
    # assert not df[col_name].isnull().values.any(), f"There are missing {col_name}"
    na_rate = str(((df[col_name].isnull() | df[col_name].isna()).sum() * 100 / df.index.size).round(2)) + '%'
    logging.info(f"missing rate of {col_name} in {country} is {na_rate}")
    logging.info(f"FIX 2: Adding {country} to {col_name}...")
    try:
        df.loc[df[col_name].notnull(), col_name] = country + '_' + df.loc[df[col_name].notnull(), col_name]
    except ValueError:
        logging.info(f"FIX 2: Adding {country}"
                     f" to {col_name} astype('str') using ...")
        df[col_name] = df[col_name].values.astype(str)
        df.loc[df[col_name].astype('str').notnull(), col_name] = country + '_' + \
                                                                 df.loc[df[col_name].astype('str').notnull(), col_name]

    return df
