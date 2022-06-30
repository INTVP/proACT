import logging
import os
import sys
import warnings
from datetime import datetime
from os import listdir
from os.path import isfile, join

import numpy as np
import pandas as pd

from util_functions.csv_export.csv_export import csv_export
from util_functions.fixes.fix_col_dates import check_na_col_dates
from util_functions.fixes.fix_enum import fix_enum
from util_functions.fixes.fix_lot_productCode import fix_lot_product_code
from util_functions.fixes.fix_urls import check_urls
from util_functions.fixes.masterid_modification import masterid_modification
from util_functions.importing.clean_text_columns import clean_text_columns
from util_functions.importing.import_file import import_data_file, reading_mapper
from util_functions.mini_jsons.indicators import indicators_mini_json
from util_functions.mini_jsons.sanctions import sanctions
from util_functions.set_up_logging import set_up_logging
from util_functions.util.move_util_files import move_util_files


def generate_indicators(filename_csv, country, chunk_it=None, chunk_size=10):
    """
    Takes in a data frame and generates indicators
    :param chunk_size: The number of chunks to split the data to using IDs
    :param chunk_it: chunk the data
    :param filename_csv: The name of the starting CSV file
    :param country: ISO-2 country code
    :return: Main data frame with indicators
    """
    print(os.getcwd())

    df, column_names = import_data_file(filename_csv=filename_csv, country=country)
    print(f"processing {country} with {len(df)} rows")
    # rename variables
    logging.info(f"Renaming columns...")
    # rename_mapper = reading_mapper(filename=f'../country_codes/{country}/name_mapper.txt')
    rename_mapper = reading_mapper(country=country, sheet_name="columns")
    df = df.rename(columns=rename_mapper)
    # PT FIX for
    df.loc[df.tender_id == "64c85640-8297-4ab7-b0c3-866880f0bd9a", "tender_addressofimplementation_country"] = "AT"
    # FIX CO master IDs
    if country == "CO":
        df = df.loc[df.buyer_masterid.notnull()]
        df = df.loc[df.bidder_masterid.notnull()]
        print(f"processing {country} after dropping missing master IDs with {len(df)} rows")

    col_text = ['buyer_name',
                'buyer_id',
                'buyer_masterid',
                'bidder_name',
                'bidder_id',
                'bidder_masterid',
                'lot_title']

    df = clean_text_columns(df, col_text)
    df = masterid_modification(df=df, country=country)
    # lot_productCode -- > lot_productcode
    df = fix_lot_product_code(df=df, country=country)
    # col_dates
    col_dates = ['tender_awarddecisiondate',
                 'tender_contractsignaturedate',
                 'tender_publications_firstdcontractawarddate']
    df = check_na_col_dates(df=df, col_dates=col_dates, country=country)

    if country in ['UK', 'DE', 'ES']:
        logging.info(f"special fix for {country}")
        logging.info(f"current number of rows {len(df)}")
        df = df.dropna(subset=['bidder_name']).reset_index()
        logging.info(f"dropping missing bidder_name...")
        logging.info(f"current number of rows {len(df)}")

    # logging.info(f'setting [""] in {col_name} no NA')
    # df.loc[df['buyer_mainactivities'] == '[""]', 'buyer_mainactivities'] = np.nan
    df = fix_enum(df=df, country=country)
    url_values = []
    url_list = ["tender_publications_lastcontractawardurl", "notice_url", "source"]
    df = check_urls(df=df, url_list=url_list)
    prices = ['bid_priceusd']
    logging.info(f"Finished renaming and cleaning columns")
    logging.info(f"Generating indicators' JSONs starting...")
    for entity_country in ['buyer_country', 'bidder_country', 'tender_country']:
        print(f"Fixing country codes in {entity_country} that are GB to UK")
        logging.info(f"Fixing country codes in {entity_country} that are GB to UK")
        try:
            df.loc[df[entity_country] == "GB", entity_country] = "UK"
            df.loc[df[entity_country] == 'British lndian Ocean Territory', entity_country] = "IO"

        except KeyError:
            print(f"{entity_country} is not available")
            pass

    # generate CSV export
    print("generate CSV export..")
    df_csv = csv_export(df=df, country=country)
    df_csv.to_csv(f"csv_export/{country}_export.csv.gz",
                  index=False, encoding='utf-8')
    del df_csv
    print(f"generate CSV export done. File in csv_export/{country}_export.csv")
    # generate indicators data
    if chunk_it:
        print(f"Chunking data for {country} into {chunk_size} chunks")
        logging.info(f"Chunking data for {country} into {chunk_size} chunks")
        df_groups = df.groupby('tender_id').ngroups
        range_groups_df = range(df_groups + 1)
        range_groups_df = np.array_split(np.array(range_groups_df), chunk_size)
        df['id_group'] = df.groupby('tender_id').ngroup()
        df_full = pd.DataFrame()
        for index_df, range_out_df in enumerate(range_groups_df):
            df_chunk = df[df['id_group'].isin(range_out_df)]
            print(f"processing range {index_df+1}, with chunk size of {len(df_chunk)}")
            logging.info(f"processing range {index_df}, with chunk size of {len(df_chunk)}")
            df_chunk = indicators_mini_json(df=df_chunk)
            logging.info(f"Selecting columns....")
            final_cols = list(rename_mapper.values()) + ["indicators"]
            for col_to_drop in ['bidder_previousSanction',
                                'bidder_hasSanction', 'sanct_startdate',
                                'sanct_enddate', 'sanct_name',
                                'lot_bidscount']:
                try:
                    final_cols.remove(col_to_drop)
                except ValueError:
                    continue
            df_chunk = df_chunk[final_cols]
            df_full = pd.concat([df_full, df_chunk])
            df_full = df_full.replace({'[""]': np.nan})  # temp
        logging.info(f"Processing sanctions...")
        df_full = sanctions(df=df_full, country=country)
        return df_full

    else:
        df = indicators_mini_json(df=df)
        logging.info(f"Selecting columns....")
        final_cols = list(rename_mapper.values()) + ["indicators"]
        for col_to_drop in ['bidder_previousSanction',
                            'bidder_hasSanction', 'sanct_startdate',
                            'sanct_enddate', 'sanct_name',
                            'lot_bidscount']:
            try:
                final_cols.remove(col_to_drop)
            except ValueError:
                continue
        df = df[final_cols]
        df = df.replace({'[""]': np.nan})  # temp
        logging.info(f"Processing sanctions...")
        df = sanctions(df=df, country=country)
        return df

    # processing sanctions output from matching in R


if __name__ == '__main__':
    warnings.simplefilter(action='ignore', category=FutureWarning)
    time_in = datetime.now()
    logging.info("making directories")
    os.makedirs("mod_ind_df", exist_ok=True)
    os.makedirs("csv_export", exist_ok=True)
    os.makedirs("validation_node/datasets", exist_ok=True)
    os.makedirs("validation_node/logs", exist_ok=True)

    country = str(sys.argv[1].split('/')[-1]).upper()
    try:
        chunk = str(sys.argv[2].split('/')[-1])
    except IndexError:
        chunk = False
        print("processing data as whole")
        pass
    try:
        chunk_it = str(sys.argv[3].split('/')[-1])
        chunk_it = True
        chunk_size = int(sys.argv[4].split('/')[-1])
    except IndexError:
        chunk_it = False
        chunk_size = 0
        print("processing data as whole with no chunks")
        pass
    set_up_logging(sys.argv[1].split('/')[-1], time_in)
    fileName_CSV = f"../utility_data/country/{country}/{country}_mod.csv"
    logging.info(f"Starting process...")

    current_path = f"../utility_data/country/{country}/"
    country_files = [f for f in listdir(current_path) if isfile(join(current_path, f)) and f[-3:] == 'zip']

    df_final = generate_indicators(filename_csv=fileName_CSV, country=country,
                                   chunk_it=chunk_it, chunk_size=chunk_size)

    if chunk == "chunk":
        df_final_groups = df_final.groupby('tender_id').ngroups
        range_groups = range(df_final_groups + 1)
        range_groups = np.array_split(np.array(range_groups), chunk_size)
        df_final['id_group'] = df_final.groupby('tender_id').ngroup()
        os.makedirs(f"mod_ind_df/{country}", exist_ok=True)
        for index, range_out in enumerate(range_groups):
            # df_final_chunk = df_final.loc[range_out, :]
            df_final_chunk = df_final[df_final.id_group.isin(range_out)]
            os.makedirs(f"mod_ind_df/{country}/{country}_{index + 1}/{country}", exist_ok=True)
            outfile = f"mod_ind_df/{country}/{country}_{index + 1}/{country}/{country}_mod_ind.csv"
            move_util_files(country=country, des_file=f"mod_ind_df/{country}/{country}_{index + 1}/{country}")
            print(f"copying tool to {outfile} dir")
            source_file = "reverse-flatten-tool"
            des_file = f"mod_ind_df/{country}/{country}_{index + 1}/reverse-flatten-tool-{country.lower()}-{index + 1}"
            os.system(f"\cp -fr {source_file} -T {des_file}")
            # shutil.copytree(source_file, des_file,)
            os.system(f"bash run_country_chunks.sh -c {country} -x {index+1}")
            logging.info(f"Exporting {outfile}...")
            df_final_chunk.to_csv(outfile, sep=';', index=False, encoding='utf-8')
            print(f"File saved in {outfile}")
        # move_util_files(country=country, des_file=f"mod_ind_df/{country}")
    else:
        outfile = f"../country_codes/{country}/{country}_mod_ind.csv"
        logging.info(f"Exporting {outfile}...")

        df_final.to_csv(outfile, sep=';', index=False, encoding='utf-8'
                        # , quoting=csv.QUOTE_NONNUMERIC
                        )
        print(f"File saved in {outfile}")

        move_util_files(country=country)
    time_out_temp = datetime.now()
    logging.info(f"Finished")
    logging.info(f"Run Time of Processing {time_out_temp - time_in}")
    print(f"Run Time of Processing for {country} {time_out_temp - time_in}")
