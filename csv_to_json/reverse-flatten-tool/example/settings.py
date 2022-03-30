class Settings:
    # input and output files:

    # Example files for ONLY modification:
    input_json_filename = "example/example_input.json"
    mod_csv_filename = "example/example_modification.csv"
    output_json_filename = "example/example_json_out.json"

    input_csv_filename = "example/Kenya_Modification_Test_input.csv"
    # Example file for deleting list item:
    # input_json_filename = "example/Kenya_json_out.json"
    # mod_csv_filename = "example/Kenya_Modification_Test_del_list_item.csv"
    # output_json_filename = "example/Kenya_json_deleted_out.json"

    # Example file for deleting property:
    # input_json_filename = "example/Kenya_json_out.json"
    # mod_csv_filename = "example/Kenya_Modification_Test_del_property.csv"
    # output_json_filename = "example/Kenya_json_deleted_out.json"

    # modules:
    is_reverse_flatten_mode_active = False
    is_modification_mode_active = True
    is_export_only_mode_active = False

    # options:
    read_from_db_for_modification = False
    truncate_table_after_export = True

    # project level parameters:
    json_id_field_name = ['persistentId']
    csv_id_field_name = ['persistent_id']
    chunk_size = 500
    db_operation_size = 500
    log_level = "INFO"
    date_format_str = "%Y.%m.%d"
    json_reader_buffer_size = 20000000
    input_csv_delimiter = ','
    modification_csv_delimiter = ';'
