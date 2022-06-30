import logging

from tqdm import tqdm
from pandas import DataFrame


def fix_lot_product_code(df: DataFrame, country: str) -> DataFrame:
    """
    Check if there are non-unique product code, if found, keep the most frequent one within a lot
    :param df: Main data frame
    :param country: ISO-2 country code
    :return: Main data frame
    """
    col_name = 'lot_productcode'
    na_rate = str(((df[col_name].isnull() | df[col_name].isna()).sum() * 100 / df.index.size).round(2)) + '%'
    logging.info(f"missing rate of {col_name} in {country} is {na_rate}")
    logging.info(f"FIX 3: Keeping only the first digits of "
                 f"lot_productcode...")
    df['lot_productcode'] = df['lot_productcode'].astype('str').str.slice(0, 8)
    logging.info(f"Checking if lot_productcode are unique within lot....")
    tqdm.pandas()
    df['lot_productcode_bi'] = df.groupby(['tender_id', 'lot_number'])['lot_productcode'].transform('nunique') > 1
    if df['lot_productcode_bi'].nunique() > 1:
        logging.info(f"non-unique lot_productcode are found")
        logging.info(f"processing lot_productcode...")
        df.loc[df['lot_productcode_bi'] == True,
               "lot_productcode"] = df[df['lot_productcode_bi'] == True].groupby(['tender_id',
                                                                                  'lot_number'],
                                                                                 as_index=True)['lot_productcode']. \
            progress_transform(lambda productcode: productcode.mode()[0])
        df = df.drop("lot_productcode_bi", axis=1)
    else:
        logging.info(f"NO non-unique lot_productcode are found")
        pass
    return df
