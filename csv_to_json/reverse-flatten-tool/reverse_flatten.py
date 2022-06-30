import csv
import os
import subprocess

import psycopg2
import datetime
import json
import logging
import sys
import types
import uuid
import importlib.machinery
from hone import hone
from json_buffered_reader import read_json_records

folder_arg = str(sys.argv[1])
system_settings_loader = importlib.machinery.SourceFileLoader('SystemSettings', "system_settings.py")
system_settings_mod = types.ModuleType(system_settings_loader.name)
system_settings_loader.exec_module(system_settings_mod)

settings_loader = importlib.machinery.SourceFileLoader('Settings', folder_arg + "/settings.py")
settings_mod = types.ModuleType(settings_loader.name)
settings_loader.exec_module(settings_mod)

connection_table_loader = importlib.machinery.SourceFileLoader('ConnectionTable', folder_arg + "/connection_table.py")
connection_table_mod = types.ModuleType(connection_table_loader.name)
connection_table_loader.exec_module(connection_table_mod)

global start_time
global connection_table
global hone_instance
global input_csv_reader
global mod_csv_reader
global csv_header
global mod_csv_header
global project_name
global settings
global system_settings
global db_id_field_name
global db_schema_name
global db_name
global input_id_field_index
global mod_id_field_index
global duplicated_ids


def get_log_level_value(level_name):
    return {
        'ERROR': 40,
        'WARNING': 30,
        'INFO': 20,
        'DEBUG': 10
    }[level_name]


def initialize_globals_and_files():
    globals()['system_settings'] = system_settings_mod.SystemSettings
    globals()['settings'] = settings_mod.Settings
    globals()['connection_table'] = connection_table_mod.ConnectionTable(settings)
    globals()['csv_header'] = -1
    globals()['mod_csv_header'] = -1
    globals()['hone_instance'] = hone.Hone(connection_table.connection_table, settings)
    globals()['db_id_field_name'] = "id"
    globals()['db_schema_name'] = "digiwhist_sch"
    globals()['db_name'] = "digiwhist_rf"
    globals()['duplicated_ids'] = set()

    if not hasattr(settings, 'input_csv_delimiter') or not hasattr(settings, 'modification_csv_delimiter'):
        logger.error("Error: CSV limiter must be set in settings!")
        exit(255)

    if len(folder_arg) > 1:
        if folder_arg.find('/') > 1:
            globals()['project_name'] = folder_arg.split('/')[-1]
        else:
            globals()['project_name'] = folder_arg
    else:
        globals()['table_name'] = "digi_demo"
    globals()["logger"] = logging.getLogger('reverse_flatten')
    if settings.log_level:
        logger.setLevel(get_log_level_value(settings.log_level))
    else:
        logger.setLevel(logging.DEBUG)
    logging.basicConfig(level=settings.log_level,
                        format='%(asctime)s.%(msecs)03d %(levelname)s [%(threadName)s] %(module)s: %(message)s',
                        datefmt='%Y-%m-%d %H:%M:%S')

    if settings.is_reverse_flatten_mode_active:
        init_input_csv_reader()
        connection_table.init_connection_table(csv_header)
    if settings.is_modification_mode_active:
        init_mod_csv_reader()
        connection_table.init_connection_table(mod_csv_header)
    create_table_if_not_exists()


def create_table_if_not_exists():
    db_connection = open_db_connection()
    cursor = db_connection.cursor()
    cursor.execute("SELECT 1 FROM pg_catalog.pg_database WHERE datname = '" + db_name + "';")
    exists = cursor.fetchone()
    if not exists:
        cursor.execute("CREATE DATABASE " + db_name)
    sql_schema = "CREATE SCHEMA IF NOT EXISTS digiwhist_sch;"
    sql_table = "CREATE TABLE IF NOT EXISTS " + db_schema_name + "." + project_name + " (id text not null constraint " + project_name \
                + "_pkey primary key, json_rec jsonb not null, created timestamp not null, updated  timestamp);"
    try:
        cursor.execute(sql_schema)
        cursor.execute(sql_table, project_name)
    except (Exception, psycopg2.Error) as error:
        logger.debug("Could not create table " + str(error))
    finally:
        db_connection.commit()
        db_connection.close()
        cursor.close()


def init_input_csv_reader():
    globals()['input_csv_reader'] = csv.reader(open(settings.input_csv_filename, "rt", encoding='utf-8'),
                                               delimiter=settings.input_csv_delimiter)
    globals()['csv_header'] = next(input_csv_reader)
    set_id_field_index()
    return input_csv_reader


def init_mod_csv_reader():
    globals()['mod_csv_reader'] = csv.reader(open(settings.mod_csv_filename, "rt", encoding='utf-8'),
                                             delimiter=settings.modification_csv_delimiter)
    globals()['mod_csv_header'] = next(mod_csv_reader)
    set_id_field_index()
    return mod_csv_reader


def process_scanned_record_list():
    if settings.is_reverse_flatten_mode_active:
        process_csv(input_csv_reader, 'reverse')
        logger.debug('Reverse flatten finished: ' + str(datetime.datetime.now() - start_time))
    if settings.is_modification_mode_active:
        mod_process_json_and_csv()
        logger.debug('Modification process finished: ' + str(datetime.datetime.now() - start_time))


def set_id_field_index():
    if settings.is_reverse_flatten_mode_active:
        globals()['input_id_field_index'] = get_id_field_indices_from_header(csv_header, settings.csv_id_field_name)
    if settings.is_modification_mode_active:
        globals()['mod_id_field_index'] = get_id_field_indices_from_header(mod_csv_header, settings.csv_id_field_name)


def get_id_field_indices_from_header(csv_header_row, id_fields):
    indices = []
    for id_field in id_fields:
        indices.append(csv_header_row.index(id_field))
    return indices


def mod_process_json_and_csv():
    if not settings.read_from_db_for_modification:
        db_connection = open_db_connection()
        cursor = db_connection.cursor()
        truncate_table(db_connection, cursor)
        read_and_process_json_for_modification()
    process_csv(mod_csv_reader, 'modification')


def read_and_process_json_for_modification():
    search_for_duplicated_ids()
    logger.info("Saving json records into db...")
    data = []
    json_record_counter = 0
    json_records_list = read_json_records(settings)
    last_position = 0
    while json_records_list:
        for json_record in json_records_list:
            last_position = json_record[1]
            record_id = get_record_id(json_record[0])
            if record_id in duplicated_ids:
                record_id += str(uuid.uuid4())
            data.append((record_id, json.dumps(json_record[0]),
                         datetime.datetime.now(), None))
            json_record_counter += 1
            if json_record_counter % 10000 == 0:
                logger.info("Saved " + str(json_record_counter) + " json records into db.")
            if len(data) == settings.chunk_size:
                save_record_into_db(data)
                data = []
        if len(data) > 0:
            save_record_into_db(data)
            data = []
        json_records_list = read_json_records(settings, last_position)
    logger.info("Number of json records saved into db: " + str(json_record_counter)
                 + " Elapsed time: " + str(datetime.datetime.now() - start_time))


def search_for_duplicated_ids():
    logger.info("Searching for duplicated ids...")
    json_record_counter = 0
    duplication_number = 0
    json_records_list = read_json_records(settings)
    last_position = 0
    ids = set()
    while json_records_list:
        for json_record in json_records_list:
            json_record_counter += 1
            last_position = json_record[1]
            record_id = get_record_id(json_record[0])
            if record_id in ids:
                duplication_number += 1
                globals()['duplicated_ids'].add(record_id)
            else:
                ids.add(record_id)
            if json_record_counter % 10000 == 0:
                logger.info("Scanned " + str(json_record_counter) + " json records.")
        json_records_list = read_json_records(settings, last_position)
    logger.info("Found " + str(duplication_number) + " duplication in " + str(json_record_counter)
                + " json records. Elapsed time: " + str(datetime.datetime.now() - start_time))


def get_record_id(json_record):
    result = ""
    if len(json_record) > 0:
        for id_field_index in settings.json_id_field_name:
            result += str(json_record[id_field_index])
    return result


def save_record_into_db(json_record_list):
    db_connection = open_db_connection()
    cursor = db_connection.cursor()
    try:
        arg_str = ','.join(['%s'] * len(json_record_list))
        sql = "INSERT INTO " + db_schema_name + "." + project_name + " (id, json_rec, created, updated) VALUES {}".format(
            arg_str)
        cursor.mogrify(sql, json_record_list)
        cursor.execute(sql, json_record_list)
        logger.debug("Successfully inserted data into " + project_name)
    except (Exception, psycopg2.Error) as error:
        logger.error("Failed to insert record into table; " + str(error))
    finally:
        if db_connection:
            db_connection.commit()
            cursor.close()
            db_connection.close()
            logger.debug("PostgreSQL connection is closed")


def process_csv(csv_reader, mode):
    logger.info("Starting csv processing.")
    modified_json_records_list = list()
    id_field_indices = []
    header = []
    if mode == 'modification':
        id_field_indices = mod_id_field_index
        header = mod_csv_header
    else:
        id_field_indices = input_id_field_index
        header = csv_header
    processed_csv_lines = 0
    for scanned_lines in scan_csv_list(settings.chunk_size, csv_reader):
        processed_csv_lines += len(scanned_lines)
        for index in range(0, len(scanned_lines)):
            record_id = get_concatenated_id_from_cvs_line(scanned_lines[index], id_field_indices)
            if record_id not in duplicated_ids:
                json_record_to_be_modified = find_json_record_in_db(record_id)
                is_new_record = False
                if not json_record_to_be_modified and mode == 'reverse':
                    json_record_to_be_modified = {}
                    is_new_record = True
                mod_dict = dict(zip(header, scanned_lines[index]))
                modified_json_record = hone_instance.modify_nested_json(mod_dict,
                                                                        json_record_to_be_modified,
                                                                        connection_table, mode)
                if is_new_record:
                    modified_json_records_list.append(
                        (record_id, json.dumps(modified_json_record), datetime.datetime.now(),None))
                    save_record_into_db(modified_json_records_list)
                else:
                    modified_json_records_list.append(
                        (json.dumps(modified_json_record), datetime.datetime.now(),
                         get_record_id(modified_json_record)))
                    update_db_records(modified_json_records_list)
                modified_json_records_list = []
        logger.info("Processed csv rows: " + str(processed_csv_lines))
    logger.info("Csv processing finished. Processed " + str(processed_csv_lines) + " modification csv rows.")


def get_concatenated_id_from_cvs_line(csv_line, id_field_index_list):
    concatenated_id = ''
    for column_index in id_field_index_list:
        concatenated_id += str(csv_line[column_index])
    return concatenated_id


def scan_csv_list(json_list_size, csv_reader):
    if json_list_size <= 0:
        logger.error("Error: Chunk size has to be greater than 0.")
        exit(255)
    scanned_csv_rows = []
    for index, line in enumerate(csv_reader):
        scanned_csv_rows.append(line)
        if len(scanned_csv_rows) % json_list_size == 0 and index > 0:
            yield scanned_csv_rows
            del scanned_csv_rows[:]
    yield scanned_csv_rows


def update_db_records(new_json_records_list):
    db_connection = open_db_connection()
    cursor = db_connection.cursor()
    try:
        sql = ("UPDATE " + db_schema_name + "." + project_name + " SET json_rec = %s, updated = %s WHERE "
               + db_id_field_name + " = %s;")
        for record in new_json_records_list:
            cursor.execute(sql, (record[0], record[1], record[2]))
        logger.debug("Successfully updated " + project_name)
    except (Exception, psycopg2.Error) as error:
        if db_connection:
            logger.error("Failed to update record into table " + str(error))
    finally:
        if db_connection:
            db_connection.commit()
            cursor.close()
            db_connection.close()
            logger.debug("PostgreSQL connection is closed")


def find_json_record_in_db(csv_line_id):
    db_connection = open_db_connection()
    cursor = db_connection.cursor()
    sql = "SELECT * FROM " + db_schema_name + "." + project_name + " WHERE " + db_id_field_name + f" = \'{csv_line_id}\';"
    cursor.execute(sql, (db_id_field_name, csv_line_id))
    json_record = cursor.fetchone()
    cursor.close()
    if json_record:
        return json_record[1]
    return {}


def send_all_db_records_for_modification(mod_scanned_line):
    modified_json_records_list = list()
    db_connection = open_db_connection()
    cursor = db_connection.cursor()
    cursor.itersize = settings.chunk_size  # chunk size
    sql = "SELECT * FROM " + db_schema_name + "." + project_name + ";"
    cursor.execute(sql)
    for record in cursor:
        mod_dict = dict(zip(csv_header, mod_scanned_line))
        modified_json_record = hone_instance.modify_nested_json(mod_dict, record[1], connection_table)
        modified_json_records_list.append((json.dumps(modified_json_record), datetime.datetime.now(),
                                           get_record_id(modified_json_record)))
        if len(modified_json_records_list) == settings.chunk_size:
            update_db_records(modified_json_records_list)
            modified_json_records_list = []
    if len(modified_json_records_list) > 0:
        update_db_records(modified_json_records_list)


def delete_last_char():
    with open(settings.output_json_filename, "rb+") as output_json_file:
        output_json_file.seek(-1, os.SEEK_END)
        output_json_file.truncate()
        output_json_file.close()


def add_finishing_bracket_to_file():
    with open(settings.output_json_filename, "a") as output_json_file:
        output_json_file.write("]")
        output_json_file.close()


def export_db_content_to_json():
    logger.info("Export records to json file...")
    exported_lines_counter = 0
    db_connection = open_db_connection()
    cursor = db_connection.cursor()
    try:
        overwrite_json_with_empty()
        add_starter_bracket_to_file()
        cursor.itersize = settings.chunk_size  # chunk size
        sql = "SELECT * FROM " + db_schema_name + "." + project_name + " ORDER BY %s;" % db_id_field_name
        cursor.execute(sql)
        for row in cursor:
            append_json_file(json.dumps(row[1]))
            exported_lines_counter += 1
            delete_last_char()
            with open(settings.output_json_filename, "a") as output_json_file:
                output_json_file.write("},")
        delete_last_char()
        add_finishing_bracket_to_file()
        if settings.truncate_table_after_export:
            truncate_table(db_connection, cursor)
        cursor.close()
        logger.debug("Number of exported lines: " + str(exported_lines_counter))
    except Exception as error:
        logger.error("Failed to write json to file. " + str(error))
    finally:
        if db_connection:
            db_connection.commit()
            cursor.close()
            db_connection.close()


def overwrite_json_with_empty():
    with open(settings.output_json_filename, "w"):
        pass


def add_starter_bracket_to_file():
    with open(settings.output_json_filename, "a") as output_json_file:
        output_json_file.write("[")
        output_json_file.close()


def truncate_table(db_connection, cursor):
    try:
        sql = "TRUNCATE TABLE " + db_schema_name + "." + project_name + ";"
        cursor.execute(sql)
        db_connection.commit()
    except(Exception, psycopg2.Error) as error:
        logger.error("Failed to truncate table " + project_name + str(error))
    finally:
        if db_connection:
            cursor.close()
            logger.debug("Successfully truncated " + project_name + " table")


def append_json_file(list_item):
    with open(settings.output_json_filename, "a") as output_json_file:
        output_json_file.write(str(list_item))
        output_json_file.close()
    delete_last_char()
    with open(settings.output_json_filename, "a") as output_json_file:
        output_json_file.write(",")


def open_db_connection():
    db_connection = psycopg2.connect(user='digiwhist',
                                     password='digiwhist',
                                     port=system_settings.db_port,
                                     host='localhost',
                                     database='digiwhist_rf')
    return db_connection


def main():
    globals()['start_time'] = datetime.datetime.now()
    initialize_globals_and_files()
    logger.debug("Started")

    if not settings.is_export_only_mode_active:
        process_scanned_record_list()
        export_db_content_to_json()
    else:
        export_db_content_to_json()

    logger.info('Finished: ' + str(datetime.datetime.now() - start_time))


logger = logging.getLogger('reverse_flatten')

if __name__ == '__main__':
    main()
