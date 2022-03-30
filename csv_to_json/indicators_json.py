import json
import logging
import re
import sys
import warnings
from csv import DictReader
from datetime import datetime
from functools import reduce
from os import listdir
from os.path import isfile, join
from zipfile import ZipFile
import validator_collection

import numpy as np
import pandas as pd
import psutil
from tqdm import tqdm


def set_up_logging(country, time_in):
    # create a file with date as a name
    logFilePath = time_in.strftime(f'logs/{country}_%Y_%m_%d_%H_%M_%S.log')
    with open(logFilePath, 'w') as fp:
        pass

    log_level = logging.DEBUG
    log_formatter = '%(asctime)s: %(threadName)s %(funcName)s %(levelname)s: %(message)s'
    logging.basicConfig(format=log_formatter,
                        filename=logFilePath, filemode='a', level=log_level)

    logging.debug("Logging is configured - Log Level %s , Log File: %s", str(log_level), logFilePath)


def reading(filename):
    """
    Read in the file with renaming
    :param filename: text file, containing the name in the CSV and the name going to the CSV
    example: CSV name is "buyer_city_api": "buyer_city"
    :return: Dictionary output used for renaming the data
    """
    mapper = open(filename, 'r').read()
    assert len(mapper) > 2, f"Renaming file is not filled"
    filename = eval(mapper)
    return filename


def get_ind_columns(filename_csv):
    """
    Get the first row of the CSV and extract the column names for the indicators and the "tender_id" and "lot_number"
    the indicators start with a prefix of "ind_"
    :param filename_csv: CSV file to be converted to JSON
    :return: ind_columns: column names of the CSV
    """
    with open(filename_csv, 'r') as csv_file:
        csv_dict_reader = DictReader(csv_file)
        column_names = csv_dict_reader.fieldnames
        csv_file.close()

    pattern = re.compile('^ind_|^tender_id$|^lot_number$')
    ind_columns = list(filter(pattern.search, column_names))
    assert type(ind_columns) == 'list'
    return ind_columns


def generate_indicators(dataframe, sampled):
    """
    Takes in a data frame and generates indicators
    :param dataframe: a pandas dataframe
    :param sampled: a filtered data frame for a specific number of rows given at the beginning
    :return: pandas data frame with indicators
    """
    logging.debug(f"Importing column names")
    with open(dataframe, 'r') as read_obj:
        csv_dict_reader = DictReader(read_obj)
        column_names = csv_dict_reader.fieldnames
        column_names = ','.join(column_names)
        read_obj.close()
    logging.debug(f"Importing lot_productCode as string")
    product_code_col = re.findall(r'lot_product[cC]ode', column_names)[0]
    rename_mapper = reading(fileName)
    if sampled:
        logging.debug(f"Loading {nobs} obs of the data from {fileName_CSV}")
        df = pd.read_csv(dataframe, low_memory=False, nrows=nobs, encoding='utf-8', dtype={product_code_col: 'str'})
        # df = df.loc[330000:332002]  # For more specific look when we run into issues
    else:
        logging.debug(f"Loading FULL data from {fileName_CSV}")
        df = pd.read_csv(dataframe, low_memory=False, encoding='utf-8', dtype={product_code_col: 'str'})
    logging.debug(f"{len(df)} rows imported")
    # rename variables
    logging.debug(f"Renaming columns...")
    df = df.rename(columns=rename_mapper)
    col_text = ['buyer_name',
                'buyer_id',
                'buyer_masterid',
                'bidder_name',
                'bidder_id',
                'bidder_masterid',
                'lot_title']
    for col_name in col_text:
        try:
            logging.debug(f"cleaning {col_name}...")
            df[col_name] = df[col_name].str.replace('[', '')
            df[col_name] = df[col_name].str.replace(']', '')
            df[col_name] = df[col_name].str.replace('{', '')
            df[col_name] = df[col_name].str.replace('}', '')
            df[col_name] = df[col_name].str.replace(';', '|')
        except AttributeError:
            logging.debug(f"cleaning {col_name} using astype('str')...")
            df[col_name] = df[col_name].astype('str').replace('[', '')
            df[col_name] = df[col_name].astype('str').replace(']', '')
            df[col_name] = df[col_name].astype('str').replace('{', '')
            df[col_name] = df[col_name].astype('str').replace('}', '')
            df[col_name] = df[col_name].astype('str').replace(';', '|')
        except KeyError:
            logging.debug(
                f"column {col_name} not found")
            continue

    col_name = 'bidder_masterid'
    na_rate = str(((df[col_name].isnull() | df[col_name].isna()).sum() * 100 / df.index.size).round(2)) + '%'
    logging.debug(f"missing rate of {col_name} in {country} is {na_rate}")
    logging.debug(f"FIX 1: Adding {country} to {col_name}...")
    try:
        df.loc[df[col_name].notnull(), col_name] = country + '_' + df.loc[df[col_name].notnull(), col_name]
    except ValueError:
        logging.debug(f"FIX 2: Adding {country}"
                      f" to {col_name} astype('str') using ...")
        df[col_name] = df[col_name].values.astype(str)
        df.loc[df[col_name].astype('str').notnull(), col_name] = country + '_' + \
                                                                 df.loc[df[col_name].astype('str').notnull(), col_name]

    col_name = 'buyer_masterid'
    na_rate = str(((df[col_name].isnull() | df[col_name].isna()).sum() * 100 / df.index.size).round(2)) + '%'
    logging.debug(f"missing rate of {col_name} in {country} is {na_rate}")
    logging.debug(f"FIX 2: Adding {country} to {col_name}...")
    try:
        df.loc[df[col_name].notnull(), col_name] = country + '_' + df.loc[df[col_name].notnull(), col_name]
    except ValueError:
        logging.debug(f"FIX 2: Adding {country}"
                      f" to {col_name} astype('str') using ...")
        df[col_name] = df[col_name].values.astype(str)
        df.loc[df[col_name].astype('str').notnull(), col_name] = country + '_' + \
                                                                 df.loc[df[col_name].astype('str').notnull(), col_name]

    # lot_productCode
    def tqdm_pandas(t):
        from pandas.core.frame import DataFrame
        def inner(df, func, *args, **kwargs):
            t.total = groups.size // len(groups)

            def wrapper(*args, **kwargs):
                t.update(1)
                return func(*args, **kwargs)

            result = df.transform(wrapper, *args, **kwargs)
            t.close()
            return result

        DataFrame.progress_transform = inner

    col_name = 'lot_productCode'
    na_rate = str(((df[col_name].isnull() | df[col_name].isna()).sum() * 100 / df.index.size).round(2)) + '%'
    logging.debug(f"missing rate of {col_name} in {country} is {na_rate}")
    logging.debug(f"FIX 3: Keeping only the first digits of "
                  f"lot_productCode...")
    df['lot_productCode'] = df['lot_productCode'].astype('str').str.slice(0, 8)
    logging.debug(f"Checking if lot_productCode are unique within lot....")
    tqdm.pandas()
    df['lot_productCode_bi'] = df.groupby(['tender_id', 'lot_number'])['lot_productCode'].transform('nunique') > 1
    if df['lot_productCode_bi'].nunique() > 1:
        logging.debug(f"non-unique lot_productCode are found")
        logging.debug(f"processing lot_productCode...")
        df.loc[df['lot_productCode_bi'] == True,
               "lot_productCode"] = df[df['lot_productCode_bi'] == True].groupby(['tender_id',
                                                                                  'lot_number'],
                                                                                 as_index=True)['lot_productCode']. \
            progress_transform(lambda productCode: productCode.mode()[0])
        df = df.drop("lot_productCode_bi", axis=1)
    else:
        logging.debug(f"NO non-unique lot_productCode are found")
        pass
    col_dates = ['tender_awarddecisiondate',
                 'tender_contractsignaturedate',
                 'tender_publications_firstdcontractawarddate']
    for col_name in col_dates:
        try:
            na_rate = str(((df[col_name].isnull() | df[col_name].isna()).sum() * 100 / df.index.size).round(2)) + '%'
            logging.debug(
                f"missing rate of {col_name} in {country} is {na_rate}")
        except KeyError:
            logging.debug(
                f"column {col_name} not found")
            continue

    if country in ['UK', 'DE', 'ES']:
        logging.debug(f"special fix for {country}")
        logging.debug(f"current number of rows {len(df)}")
        df = df.dropna(subset=['bidder_name']).reset_index()
        logging.debug(f"dropping missing bidder_name...")
        logging.debug(f"current number of rows {len(df)}")

    # logging.debug(f'setting [""] in {col_name} no NA')
    # df.loc[df['buyer_mainactivities'] == '[""]', 'buyer_mainactivities'] = np.nan
    for col_name, enum_list in enum_cols.items():
        try:
            na_rate = str(((df[col_name].isnull() | df[col_name].isna()).sum() * 100 / df.index.size).round(2)) + '%'
            logging.debug(
                f"missing rate of {col_name} in {country} is {na_rate}")
            enum_list = sorted(list(enum_list))
            df_enum = sorted((list(df[col_name].dropna().unique().tolist())))
            if col_name == 'buyer_mainactivities':
                df.loc[df[col_name] == '[""]', col_name] = np.nan
                logging.debug(f'setting [""] in {col_name} no NA')
                df_enum = df[col_name].dropna().unique().tolist()
                df_enum = [item.replace('"', '').replace("[", "").replace("]", "") for item in df_enum]

            if all(x in enum_list for x in df_enum):
                logging.debug(f"Enum of {col_name} in are valid")
            else:
                logging.debug(f"Enum of {col_name} in are NOT valid")
                logging.debug(
                    f"{col_name} enum are {df[col_name].unique()}")

        except KeyError:
            logging.debug(
                f"column {col_name} not found")
            continue
    url_values = []
    url_list = ["tender_publications_lastcontractawardurl", "notice_url", "source"]
    for url_col in url_list:
        try:
            urls = sorted((list(df[url_col].dropna().unique().tolist())))
            if True in set(list(map(validator_collection.checkers.is_url, urls))):
                logging.debug(f"URLS of {url_col} are valid")
            else:
                logging.debug(f"URLS of {url_col} are NOT valid")
                logging.debug(list(list(urls)))
        except KeyError:
            logging.debug(
                f"column {url_col} not found")
            continue
    prices = ['bid_priceUsd']
    logging.debug(f"Finished renaming and cleaning columns")
    logging.debug(f"Generating indicators' JSONs starting...")
    # generate indicators data
    df_indicators = df.filter(regex='^ind_|^tender_id$|^lot_number$')
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
    logging.debug(f"Total iterations for indicators are {len(df_type)}"
                  f",their values are {len(df_val)}")
    logging.debug(f"Putting together the indicators' data frame")
    available_memory = psutil.virtual_memory().available * 100 / psutil.virtual_memory().total
    available_memory = round(available_memory, 2)
    logging.debug(f"Available memory {available_memory}")
    dfs = [df_type, df_val]
    df_grouped_ind = reduce(lambda left, right: pd.merge(left, right, left_index=True, right_index=True), dfs)
    logging.debug(f"Removing extra data frames")
    del df_type, df_val
    del dfs
    available_memory2 = psutil.virtual_memory().available * 100 / psutil.virtual_memory().total - available_memory
    available_memory2 = round(available_memory2, 2)
    logging.debug(f"Available memory {available_memory}. "
                  f"Freed {available_memory2}")
    logging.debug(f"Finalizing the indicators' process")
    df_grouped_ind = df_grouped_ind.rename(columns={'val': 'value'}).replace({'nan': np.nan})
    df_grouped_ind = df_grouped_ind.astype({"value": float})
    df_grouped_ind = df_grouped_ind.where(pd.notnull(df_grouped_ind), None)

    def to_json_custom(df_filtered):
        """
        Convert indicators to one is_JSON object
        :param df_filtered: dataframe, grouped by tender_id and lot number
        :return: column with indicators as a is_JSON object
        """
        df_filtered = df_filtered[['type', 'value']].to_dict('records')
        df_filtered = json.dumps(df_filtered)
        return df_filtered

    logging.debug(f"Applying changes....")
    df_grouped_ind = df_grouped_ind.groupby(['tender_id',
                                             'lot_number'], as_index=True).progress_apply(
        lambda df_in: to_json_custom(df_in)).reset_index().rename(columns={0: 'indicators'})
    logging.debug(f"Merging processed indicators back to full dataset...")

    dfs = [df, df_grouped_ind]
    df_final = reduce(lambda left, right: pd.merge(left, right, on=['tender_id', 'lot_number']), dfs)
    logging.debug(f"Removing extra data frames")
    del df, df_grouped_ind
    del dfs
    logging.debug(f"Selecting columns....")
    final_cols = list(rename_mapper.values()) + ["indicators"]
    df_final = df_final[final_cols]
    # processing sanctions output from matching in R
    logging.debug(f"Processing sanctions...")
    try:
        df_sanctions = pd.read_csv(f"../debarment/output/data/{country}_sanctions.csv")
        df_sanctions = df_sanctions.replace({'nan': np.nan})
        # df_sanctions = df_sanctions.where(pd.notnull(df_sanctions), None)
        df_sanctions['endDate'] = df_sanctions['endDate'].replace('[a-zA-Z]', np.nan, regex=True)

        logging.debug(f"adding sequential IDs for bidders")
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
            if is_json:
                df_filtered = json.dumps(df_filtered)
                return df_filtered
            else:
                return df_filtered

        logging.debug(f"Processing sanctions authority name")
        tqdm.pandas()
        cols = ['name', 'id']
        sanctions_name = df_sanctions.groupby(['bidder_name', 'n'], as_index=True).progress_apply(
            lambda df_in: to_json_sanctions_col(df_in, cols, False)).reset_index().rename(
            columns={0: 'sanctioningAuthority'})
        dfs = [sanctions_name, df_sanctions]
        df_f_out = reduce(lambda left, right: pd.merge(left, right, on=['bidder_name', 'n']), dfs)
        cols = ['startDate', 'endDate', 'sanctioningAuthority']
        logging.debug(f"Handling non-specified sanctions End Date")
        # missing end date
        cols = ['startDate', 'sanctioningAuthority']
        df_f_out1 = df_f_out[df_f_out['endDate'].isnull()].drop(['endDate'], axis=1)
        try:
            df_f_out1 = df_f_out1.groupby(['bidder_name', 'n'], as_index=True).progress_apply(
                lambda df_in: to_json_sanctions_col(df_in, cols, False)).reset_index().rename(
                columns={0: 'sanctions_temp'})
            logging.debug(f"Handling specified sanctions End Date")
        except (ValueError, IndexError) as e:
            logging.debug(f"Handling specified sanctions End Date did not run")

        # non missing end date
        cols = ['startDate', 'endDate', 'sanctioningAuthority']
        df_f_out2 = df_f_out[df_f_out['endDate'].notnull()]
        try:
            df_f_out2 = df_f_out2.groupby(['bidder_name', 'n'], as_index=True).progress_apply(
                lambda df_in: to_json_sanctions_col(df_in, cols, False)).reset_index().rename(
                columns={0: 'sanctions_temp'})
        except (ValueError, IndexError) as e:
            logging.debug(f"Handling specified sanctions End dates did not run")

        df_f_out = df_f_out1.append(df_f_out2, ignore_index=True)
        logging.debug(f"Removing extra data frames")
        del df_f_out1, df_f_out2
        logging.debug(f"Processing sanctions data")
        bidders = df_f_out['bidder_name'].unique()
        sanctions_list_df = []
        bidders_df = pd.DataFrame({'bidder_name': [np.nan], 'sanctions': [np.nan]})
        for bidder in bidders:
            logging.debug(f"Processing sanctions for {bidder}")
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
        logging.debug(f"generating sanctions JSONs...")
        dfs = [df_sanctions, bidders_df]
        df_sanctions = reduce(lambda left, right: pd.merge(left, right, on=['bidder_name']), dfs)
        df_sanctions = df_sanctions.drop(['startDate', 'endDate',
                                          'name', 'n'], axis=1).drop_duplicates(subset=['bidder_name'],
                                                                                keep='last')
        df_sanctions['sanctions'] = df_sanctions['sanctions'].apply(json.dumps)
        df_sanctions = df_sanctions.drop(['id'], axis=1)
        dfs = [df_final, df_sanctions]
        df_final = reduce(lambda left, right: pd.merge(left, right, how="left", on=['bidder_name']), dfs)
        logging.debug(f"Setting the rest of bidders hasSanction to False")
        df_final.loc[df_final['bidder_hasSanction'].isnull(), 'bidder_hasSanction'] = False
        logging.debug(
            f"Setting the rest of bidders previousSanction to False")
        df_final.loc[df_final['bidder_previousSanction'].isnull(), 'bidder_previousSanction'] = False
    except FileNotFoundError:
        logging.debug(f"No sanctions data available")
        logging.debug(f"Setting bidders hasSanction to False")
        df_final['bidder_hasSanction'] = False
        df_final['bidder_previousSanction'] = False
    outfile = fileName_CSV[:-4] + '_ind' + '.csv'
    logging.debug(f"Exporting {outfile}...")
    df_final = df_final.replace({'[""]': np.nan})  # temp
    df_final.to_csv(outfile, sep=';', index=False, encoding='utf-8'
                    # , quoting=csv.QUOTE_NONNUMERIC
                    )
    time_out_temp = datetime.now()
    logging.debug(f"Finished")
    logging.debug(f"Run Time of Processing {time_out_temp - time_in}")
    return df_final


def move_util_files():
    import shutil
    logging.debug(f"{datetime.now()} INFO [MainThread]: copying utility files to ../country_codes/{country}")
    source_files = ["configuration/connection_table.py", "configuration/settings.py"]
    des_file = f"../country_codes/{country}"
    for source_file in source_files:
        shutil.copy(source_file, des_file)


if __name__ == '__main__':
    warnings.simplefilter(action='ignore', category=FutureWarning)
    time_in = datetime.now()
    country = str(sys.argv[1]).upper()
    try:
        index = str(sys.argv[2])
        if isinstance(index, int):
            fileName_CSV = "../country_codes/{0}/{0}_mod{1}.csv".format(country, index)
        if len(sys.argv) > 1:
            if str(sys.argv[2]).lower() in ['sample', 's']:
                sample = True
                nobs = int(sys.argv[3])
                fileName_CSV = "../country_codes/{0}/{0}_mod.csv".format(country)
        else:
            sample = False
    except IndexError:
        fileName_CSV = "../country_codes/{0}/{0}_mod.csv".format(country)
        sample = False
        pass
    fileName = "../country_codes/{0}/name_mapper.txt".format(country)
    fileName_zip = "../country_codes/{0}/{0}_mod_ind.csv".format(country)
    logging.debug(f"{time_in} INFO [MainThread] indicators_json: Starting process...")
    # ENUM checks
    enum_dict = 'configuration/enum_dict.txt'
    enum_cols = open(enum_dict, 'r').read()
    enum_cols = eval(enum_cols)

    # current_path = os.getcwd() + '/' + country
    current_path = "../country_codes/{0}".format(country)
    country_files = [f for f in listdir(current_path) if isfile(join(current_path, f)) and f[-3:] == 'zip']

    if len(country_files) > 0:
        # zipped_file = current_path + '/' + country_files[0]
        zipped_file = "../country_codes/{0}/{1}".format(country, country_files[0])
        logging.debug(f"Zipped file found")
        with ZipFile(zipped_file, 'r') as zip_ref:
            logging.debug(f"Unzipping..")
            out = "../country_codes/{0}".format(country)
            zip_ref.extractall(out)
        logging.debug(f"Unzipped")

    else:
        logging.debug(f"CSV file found")
        pass
    set_up_logging(country, time_in)
    generate_indicators(fileName_CSV, sample)
    move_util_files()
