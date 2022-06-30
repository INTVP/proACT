import json
import logging
from functools import reduce

import numpy as np
import pandas as pd
from pandas import DataFrame
from tqdm import tqdm


def sanctions(df: DataFrame, country: str) -> DataFrame:
    """
    Convert Indicators to a mini JSON to speed the Final JSON processing
    :param country:
    :param df:
    :return: Main data frame
    """
    try:
        print("processing sanctions CSV")
        df_sanctions = pd.read_csv(f"../debarment/output/data/{country}_sanctions.csv")
        ##################################
        logging.info(f"processing {country} sanction as UPPER CASE")
        print(f"processing {country} sanction as UPPER CASE")
        df_sanctions['bidder_name'] = df_sanctions['bidder_name'].str.upper()
        ##################################

        df_sanctions = df_sanctions.replace({'nan': np.nan})
        # df_sanctions = df_sanctions.where(pd.notnull(df_sanctions), None)
        df_sanctions['endDate'] = df_sanctions['endDate'].replace('[a-zA-Z]', np.nan, regex=True)

        logging.info(f"adding sequential IDs for bidders")
        df_sanctions['id'] = pd.factorize(df_sanctions.name)[0] + 1  # generate an ID
        df_sanctions['id'] = f'{country}_' + df_sanctions['id'].astype(str)
        df_sanctions['endDate'] = df_sanctions['endDate'].replace('[a-zA-Z]', np.nan, regex=True)

        def to_json_sanctions_col(df_filtered, columns, is_json):
            """
            takes a subset of data grouped by a variable to be converted to dict
            :param is_json: Boolean, If True, export as JSON, else do not export
            :param df_filtered: dataframe, grouped by some variable (bidder_name)
            :param columns: the selected columns to be used for converted to dict
            :return: column with indicators as a JSON object
            """
            df_filtered = df_filtered[columns].to_dict('records')[0]
            df_filtered = {k: v for k, v in df_filtered.items() if not pd.isnull(v)}
            if is_json:
                df_filtered = json.dumps(df_filtered)
                return df_filtered
            else:
                return df_filtered

        logging.info(f"Processing sanctions authority name")
        tqdm.pandas()
        cols = ['name', 'id']
        sanctions_name = df_sanctions.groupby(['bidder_name', 'n'], as_index=True).progress_apply(
            lambda df_in: to_json_sanctions_col(df_in, cols, False)).reset_index().rename(
            columns={0: 'sanctioningAuthority'})
        dfs = [sanctions_name, df_sanctions]
        df_f_out = reduce(lambda left, right: pd.merge(left, right, on=['bidder_name', 'n']), dfs)
        cols = ['startDate', 'endDate', 'sanctioningAuthority', 'legalGround']
        logging.info(f"Handling non-specified sanctions End Date")
        # missing end date
        cols = ['startDate', 'sanctioningAuthority', 'legalGround']
        df_f_out1 = df_f_out[df_f_out['endDate'].isnull()].drop(['endDate'], axis=1)
        try:
            df_f_out1 = df_f_out1.groupby(['bidder_name', 'n'], as_index=True).progress_apply(
                lambda df_in: to_json_sanctions_col(df_in, cols, False)).reset_index().rename(
                columns={0: 'sanctions_temp'})
            logging.info(f"Handling specified sanctions End Date")
        except (ValueError, IndexError) as e:
            logging.info(f"Handling specified sanctions End Date did not run")
        # non missing end date
        cols = ['startDate', 'endDate', 'sanctioningAuthority', 'legalGround']
        df_f_out2 = df_f_out[df_f_out['endDate'].notnull()]
        try:
            df_f_out2 = df_f_out2.groupby(['bidder_name', 'n'], as_index=True).progress_apply(
                lambda df_in: to_json_sanctions_col(df_in, cols, False)).reset_index().rename(
                columns={0: 'sanctions_temp'})
        except (ValueError, IndexError) as e:
            logging.info(f"Handling specified sanctions End dates did not run")

        df_f_out = df_f_out1.append(df_f_out2, ignore_index=True)
        logging.info(f"Removing extra data frames")
        del df_f_out1, df_f_out2
        logging.info(f"Processing sanctions data")
        bidders = df_f_out['bidder_name'].unique()
        sanctions_list_df = []
        bidders_df = pd.DataFrame({'bidder_name': [np.nan], 'sanctions': [np.nan]})
        for bidder in bidders:
            logging.info(f"Processing sanctions for {bidder}")
            bidder_df = df_f_out[df_f_out['bidder_name'] == bidder]
            sanctions_list = []
            if len(bidder_df) > 1:
                for each in bidder_df['sanctions_temp'].tolist():
                    sanctions_list.append(each)
            else:
                sanctions_list.append(bidder_df['sanctions_temp'].tolist()[0])
            bidder_df_final = pd.DataFrame({'bidder_name': [bidder], 'sanctions': [sanctions_list]})
            bidders_df = bidders_df.append(bidder_df_final)
        sanctions_list_df.append(sanctions_list)
        bidders_df = bidders_df.dropna()
        logging.info(f"generating sanctions JSONs...")
        dfs = [df_sanctions, bidders_df]
        df_sanctions = reduce(lambda left, right: pd.merge(left, right, on=['bidder_name']), dfs)
        df_sanctions = df_sanctions.drop(['startDate', 'endDate',
                                          'name', 'n', 'legalGround'], axis=1).drop_duplicates(subset=['bidder_name'],
                                                                                               keep='last')
        df_sanctions['sanctions'] = df_sanctions['sanctions'].apply(json.dumps)
        df_sanctions = df_sanctions.drop(['id'], axis=1)
        dfs = [df, df_sanctions]
        df_final = reduce(lambda left, right: pd.merge(left, right, how="left", on=['bidder_name']), dfs)
        logging.info(f"Setting the rest of bidders hasSanction to False")
        df_final.loc[df_final['bidder_hasSanction'].isnull(), 'bidder_hasSanction'] = False
        logging.info(
            f"Setting the rest of bidders previousSanction to False")
        df_final.loc[df_final['bidder_previousSanction'].isnull(), 'bidder_previousSanction'] = False
    except FileNotFoundError:
        logging.info(f"No sanctions data available")
        logging.info(f"Setting bidders hasSanction to False")
        df_final = df
        df_final['bidder_hasSanction'] = False
        df_final['bidder_previousSanction'] = False
    return df_final
