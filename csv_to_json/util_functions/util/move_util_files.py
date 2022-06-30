import logging
import shutil


def move_util_files(country: str, des_file=None) -> None:
    """
    Move Configuration files to country data folder
    :param des_file: destination folder
    :param country: ISO-2 country code
    :return: None
    """
    logging.info(f"copying utility files to ../country_codes/{country}")
    source_files = ["configuration/connection_table.py", "configuration/settings.py"]
    if des_file:
        print(f"using provided des_file {des_file}")
        pass
    else:
        des_file = f"../country_codes/{country}"
    # des_file = f"country_data_files"
    for source_file in source_files:
        shutil.copy(source_file, des_file)
    logging.info(f"copying utility files to ../country_codes/{country} done")
