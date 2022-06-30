import logging

import validator_collection
from pandas import DataFrame


def check_urls(df: DataFrame, url_list: list) -> DataFrame:
    """
    check if URLs are valid
    :param df: Main data frame
    :param url_list: list of URLs in main data frame
    :return: Main data frame
    """
    for url_col in url_list:
        try:
            urls = sorted((list(df[url_col].dropna().unique().tolist())))
            if True in set(list(map(validator_collection.checkers.is_url, urls))):
                logging.info(f"URLS of {url_col} are valid")
            else:
                logging.info(f"URLS of {url_col} are NOT valid")
                logging.info(list(list(urls)))
        except KeyError:
            logging.info(
                f"column {url_col} not found")
            continue
    return df
