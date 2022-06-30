import logging
from time import strftime


def set_up_logging(country: str, time_in: strftime) -> None:
    """
    Set up logging
    :param country: ISO-2 country code
    :param time_in: Current time
    :return: None
    """
    # create a file with date as a name
    log_file_path = time_in.strftime(f'logs/{country}_%Y_%m_%d_%H_%M_%S.log')
    with open(log_file_path, 'w') as fp:
        pass

    log_level = logging.INFO
    log_formatter = '%(asctime)s: %(threadName)s %(funcName)s %(levelname)s: %(message)s'
    logging.basicConfig(format=log_formatter,
                        filename=log_file_path, filemode='a', level=log_level)

    logging.debug("Logging is configured - Log Level %s , Log File: %s", str(log_level), log_file_path)
    print(f"logging set up in {log_file_path}")
