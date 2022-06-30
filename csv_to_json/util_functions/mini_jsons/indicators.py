import logging
from functools import reduce

import numpy as np
import pandas as pd
import psutil
from pandas import DataFrame
from tqdm import tqdm


def indicators_mini_json(df: DataFrame) -> DataFrame:
    """
    Convert Indicators to a mini JSON to speed the Final JSON processing
    :param df: Main data frame
    :return: Main data frame
    """
    df_indicators = df.filter(regex='^ind_|^tender_id$|^lot_number$|^bid_iswinning$')
    try:
        logging.info("processing indicators for winning bids")
        df_indicators = df_indicators[df_indicators['bid_iswinning'] == True]
    except KeyError:
        print("processing indicators for all bids")
        logging.info("processing indicators for all bids")
        pass
    df_indicators_dict = df_indicators.replace(np.nan, 'nan'). \
        loc[df_indicators['ind_singleb_val'] != 9999]. \
        drop_duplicates(subset=['tender_id', 'lot_number']). \
        set_index(['tender_id', 'lot_number']).stack().reset_index()
    tqdm.pandas()
    df_indicators_dict["temp"] = df_indicators_dict["level_2"].str.split("_").progress_apply(lambda splat_list:
                                                                                             splat_list[-1])
    df_indicators_dict = df_indicators_dict.drop("level_2", axis=1)
    df_type = df_indicators_dict[df_indicators_dict['temp'] == 'type']
    df_type = df_type.melt(id_vars=["tender_id", "lot_number", "temp"], value_name='type').loc[:, ["tender_id",
                                                                                                   "lot_number",
                                                                                                   "type"]]

    df_val = df_indicators_dict[df_indicators_dict['temp'] == 'val']
    df_val = df_val.melt(id_vars=["tender_id", "lot_number", "temp"], value_name='val').loc[:, 'val']
    logging.info(f"Total iterations for indicators are {len(df_type)}"
                 f",their values are {len(df_val)}")
    logging.info(f"Putting together the indicators' data frame")
    available_memory = psutil.virtual_memory().available * 100 / psutil.virtual_memory().total
    available_memory = round(available_memory, 2)
    logging.info(f"Available memory {available_memory}")
    dfs = [df_type, df_val]
    df_grouped_ind = reduce(lambda left, right: pd.merge(left, right, left_index=True, right_index=True), dfs)
    logging.info(f"Removing extra data frames")
    del df_type, df_val
    del dfs
    available_memory2 = psutil.virtual_memory().available * 100 / psutil.virtual_memory().total - available_memory
    available_memory2 = round(available_memory2, 2)
    logging.info(f"Available memory {available_memory}. "
                 f"Freed {available_memory2}")
    logging.info(f"Finalizing the indicators' process")
    df_grouped_ind = df_grouped_ind.rename(columns={'val': 'value'}).replace({'nan': np.nan})
    df_grouped_ind = df_grouped_ind.astype({"value": float})
    df_grouped_ind = df_grouped_ind.where(pd.notnull(df_grouped_ind), None)

    def to_json_custom(df_filtered):
        """
        Convert indicators to one is_JSON object
        :param df_filtered: dataframe, grouped by tender_id and lot number
        :return: column with indicators as a is_JSON object
        """
        df_filtered = df_filtered[['type', 'value']].to_json(orient='records')
        # df_filtered = json.dumps(df_filtered)
        return df_filtered

    logging.info(f"Applying changes....")
    df_grouped_ind = df_grouped_ind.groupby(['tender_id',
                                             'lot_number'], as_index=True).progress_apply(
        lambda df_in: to_json_custom(df_in)).reset_index().rename(columns={0: 'indicators'})
    logging.info(f"Merging processed indicators back to full dataset...")

    dfs = [df, df_grouped_ind]
    df_final = reduce(lambda left, right: pd.merge(left, right, on=['tender_id', 'lot_number']), dfs)
    logging.info(f"Removing extra data frames")
    del df, df_grouped_ind
    del dfs
    return df_final
