import logging
import os

import numpy as np
import pandas as pd
from pandas import DataFrame


def reading_mapper(sheet_name: str, available_indicators: list, country: [str, None] = None) -> dict:
    """
    Read in the file with renaming
    example: CSV name is "buyer_city_api": "buyer_city"
    :param available_indicators: all indicators available in the data frame.
    :param country: ISO-2 country code
    :param sheet_name: sheet name
    :return: Dictionary output used for renaming the data
    """
    # https://docs.google.com/spreadsheets/d/113SvWugknA0bcvdO5wS40ei4Y2qisX4Txm-i9ipWIBY/edit#gid=0
    sheet_id = "113SvWugknA0bcvdO5wS40ei4Y2qisX4Txm-i9ipWIBY"
    url = f"https://docs.google.com/spreadsheets/d/{sheet_id}/gviz/tq?tqx=out:csv&sheet={sheet_name}"
    col_names = pd.read_csv(url)
    if sheet_name == "columns":
        col_names = col_names.loc[col_names[country].notnull(), [country, 'column_name']]
        col_names = {k: v for k, v in col_names.values}
    if sheet_name == "indicators_names":
        x = [i for i in available_indicators if '_val' in i]
        col_names = col_names[col_names[country].isin(x)]
        col_names = col_names.loc[col_names[country].notnull(), [country, 'csv_name']]
        col_names = {k: v for k, v in col_names.values}
    # mapper = open(filename, 'r').read()
    # assert len(mapper) > 2, f"Renaming file is not filled"
    # mapper = eval(mapper)
    # return mapper
    return col_names


def get_sanctions_date_column(df: DataFrame, country: str) -> dict:
    """
    Deprecated: Select the date column required to merge the data for the sanctions
    :param df: Main data frame
    :param country: ISO-2 country code
    :return: date variable
    """
    rename_mapper = reading_mapper(country=country, sheet_name="columns")
    x = [i for i in list(rename_mapper.values()) if 'date' in i]
    percent_missing = df[x].isnull().sum() * 100 / len(df)
    percent_missing.sort_values(inplace=True)
    date_var = percent_missing.index[0]
    return date_var


def merge_sanctions(country: str, df: DataFrame) -> DataFrame:
    """
    Merging sanctions data to the CSV. Each sanction contains a column suffixed by the
    sanction number. returned columns are :
    sanction_startdate, sanction_enddate, sanction_sanctioning_authority,
     santion_bidder_hassanction, sanction_bidder_previoussanction,
     sanction_legalground
    :param country: ISO-2 country code
    :param df: Main data frame
    :return: Merged data frame with sanctions
    """
    df_sanctions = pd.read_csv(f"../debarment/output/data/{country}_sanctions.csv")
    df_sanctions['endDate'] = df_sanctions['endDate'].replace('[a-zA-Z]', np.nan, regex=True)

    print(df_sanctions)
    df_sanctions['idx'] = df_sanctions.groupby('bidder_name').cumcount()
    df_sanctions['idx'] = df_sanctions['idx'] + 1
    tmp = []
    rename_dict = {
        'startDate': 'sanction_startdate',
        'endDate': 'sanction_enddate',
        'name': 'sanction_sanctioning_authority',
        'bidder_hasSanction': 'santion_bidder_hassanction',
        'bidder_previousSanction': 'sanction_bidder_previoussanction',
        'legalGround': 'sanction_legalground'
    }
    df_sanctions = df_sanctions.rename(columns=rename_dict)
    for var in rename_dict.values():
        df_sanctions['tmp_idx'] = var + '_' + df_sanctions.idx.astype(str)
        tmp.append(df_sanctions.pivot(index='bidder_name', columns='tmp_idx', values=var))

    reshape = pd.concat(tmp, axis=1)
    reshape = reshape.reset_index()
    ###################################
    logging.info(f"processing {country} sanction as UPPER CASE")
    print(f"processing {country} sanction as UPPER CASE")
    reshape['bidder_name'] = reshape['bidder_name'].str.upper()
    ##################################
    df = pd.merge(df, reshape, on="bidder_name", how='left')
    # print(df[df.santion_bidder_hassanction_1.notnull()])
    return df


def indicators_columns(df: DataFrame, country: str) -> DataFrame:
    """
    Rename data frame indicator columns
    :param df: Main data frame
    :param country: ISO-2 country code
    :return: Renamed data frame
    """
    column_names = reading_mapper(country=country, sheet_name="indicators_names")
    df = df.rename(columns=column_names)
    return df


def csv_export(df: DataFrame, country: str) -> DataFrame:
    """
    Take the data frame and apply the required settings for the final CSV for ProACT
    :param df: Main data frame
    :param country: ISO-2 country code
    :return: Final CSV data frame for ProACT
    """
    available_indicators = list(df.columns)
    indicators_names = reading_mapper(country=country, available_indicators=available_indicators,
                                      sheet_name="indicators_names")

    column_names = reading_mapper(country=country, sheet_name="columns", available_indicators=available_indicators)
    df = df.rename(columns=indicators_names)
    cols_selected = list(column_names.values()) + list(indicators_names.values())

    cols_selected = [i for i in cols_selected if i not in ['tender_publications_notice_type',
                                                           'tender_publications_award_type']]
    df = df[cols_selected]
    if os.path.isfile(f"../debarment/output/data/{country}_sanctions.csv"):
        print("processing sanctions")
        df = merge_sanctions(country=country, df=df)
    return df
