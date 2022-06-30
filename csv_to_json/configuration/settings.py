import sys


class Settings:
    # input and output files:
    folder_arg = str(sys.argv[1])
    # Example files for ONLY modification:
    # input_json_filename = "example/example_input.json"
    # mod_csv_filename = "example/example_modification.csv"
    output_json_filename = "{0}/{1}_portal.json".format(folder_arg, folder_arg.split('/')[-1])

    input_csv_filename = "{0}/{1}_mod_ind.csv".format(folder_arg, folder_arg.split('/')[-1])
    # Example file for deleting list item:
    # input_json_filename = "example/Kenya_json_out.json"
    # mod_csv_filename = "example/Kenya_Modification_Test_del_list_item.csv"
    # output_json_filename = "example/Kenya_json_deleted_out.json"

    # Example file for deleting property:
    # input_json_filename = "example/Kenya_json_out.json"
    # mod_csv_filename = "example/Kenya_Modification_Test_del_property.csv"
    # output_json_filename = "example/Kenya_json_deleted_out.json"

    # modules:
    is_reverse_flatten_mode_active = True
    is_modification_mode_active = False
    is_export_only_mode_active = False

    # options:
    read_from_db_for_modification = False
    truncate_table_after_export = True

    # project level parameters:
    json_id_field_name = ['id']
    csv_id_field_name = ['tender_id']
    chunk_size = 1000
    db_operation_size = 1000
    log_level = "INFO"
    date_format_str = "%Y.%m.%d"
    json_reader_buffer_size = 20000000
    input_csv_delimiter = ';'
    modification_csv_delimiter = ';'
