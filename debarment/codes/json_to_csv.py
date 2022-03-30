import os  # to set directory
from os import listdir  # to list files in a directory
from os.path import isfile, join  # addi

import pandas as pd  # for general purpose
import progressbar  # progress bar

os.chdir("debarment")
path = "input/ARCData-master/data/JSON"
only_files = [f for f in listdir(path) if isfile(join(path, f))]
files = listdir(path)
os.makedirs('input/csv', exist_ok=True)
os.makedirs('input/output', exist_ok=True)
# os.chdir(path)
output = dict()

for file in only_files:  # for each file in files
    filename = file[0:-4]  # subset the json to get a name used as ID
    file_fullpath = os.getcwd() + "/" + path + "/" + file # full file path
    df = pd.read_json(file_fullpath).T  # loading the data using pandas JSON reader
    df['index'] = filename + df.index  # making an ID using the index and the name of the file
    df_out = pd.DataFrame()  # empty data frame to hold the data
    bar = progressbar.ProgressBar(maxval=len(df["base"]) - 3, widgets=[progressbar.Bar('=', file + '[', ']'), ' ',
                                                                       progressbar.Percentage()])  # progress bar: change maxval to
    # the loop below
    bar.start()  # start progress bar
    for item in range(len(df["base"]) - 3):  # for each row in the dataset except the last three lines
        bar.update(item + 1)  # add progress to the bar
        df_temp = pd.DataFrame()  # create a temp data frame for each row
        df_temp["id"] = pd.DataFrame({"id": [df["index"].iloc[item]]})  # add the id
        df_base = pd.json_normalize(df["base"][item])  # flatten the list insde the column to a data frame
        df_base = pd.concat([df_temp.reset_index(drop=True), df_base], axis=1)  # merge it together with the ID
        df_out = df_out.append(df_base, sort=False)  # append it below the df_out
    bar.finish()  # end counting the bar
    output[file] = df_out  # add the data frame to a local dictionary
    df_out.to_csv('input/csv/' + filename + 'csv', index=False, encoding='utf-8')  # export the data frame
