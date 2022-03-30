import conversions
import logging
import json

logger = logging.getLogger('hone')
logger.setLevel(logging.DEBUG)


class Hone:
    DEFAULT_DELIMITERS = [",", "_", " "]

    def __init__(self, connection_list, settings, delimiters=DEFAULT_DELIMITERS):
        self.delimiters = delimiters
        self.schema = self.nest_dict(connection_list)
        self.settings = settings
        logging.basicConfig(level=self.settings.log_level,
                            format='%(asctime)s.%(msecs)03d %(levelname)s [%(threadName)s] %(module)s: %(message)s',
                            datefmt='%Y-%m-%d %H:%M:%S')
        self.conversions_instance = conversions.Conversion(self.settings)

    def nest_dict(self, connection_list):
        result = {}
        for i in range(len(connection_list)):
            key = connection_list[i][0]
            value = connection_list[i][1]

            # for each key call method split_rec which
            # will split keys to form recursively
            # nested dictionary
            self.split_rec(key, value, result)

        return result

    def split_rec(self, key, value, out):
        # splitting keys in dict
        # calling recursively to break items on '.'
        key, *rest = key.split('.', 1)

        if rest:
            if isinstance(out, list):
                out = out[0]
            if key[-2:] != "[]":
                self.split_rec(rest[0], value, out.setdefault(key, {}))
            else:
                self.split_rec(rest[0], value, out.setdefault(key, [{}]))
        else:
            if isinstance(out, dict):
                out[key] = value
            elif isinstance(out, list):
                out[0][key] = value

    def _finditem(self, obj, key):
        if key in obj: return obj[key]
        for k, v in obj.items():
            if isinstance(v, dict):
                return self._finditem(v, key)  # added return statement

    def apply_conversion(self, applicable_conversions, cell):
        for conversion_str in applicable_conversions:
            method_to_execute = getattr(self.conversions_instance, conversion_str)
            cell = method_to_execute(cell)
        return cell

    def define_cell_value(self, column_name, connection_table_instance, row, column_index):
        cell = row[column_index]
        if isinstance(row[column_index], str):
            cell = self.escape_quotes(row[column_index])
        elif isinstance(row[column_index], list):
            cell = row[column_index]

        if column_name in connection_table_instance.conversion_table:
            return self.apply_conversion(connection_table_instance.conversion_table[column_name], cell)
        else:
            return cell

    def delete_json_list_element(self, mod_dict, json_record_from_db, connection_table_instance):
        do_continue = True
        modification_table_item = connection_table_instance.modification_table
        current_json_branch = json_record_from_db[-1]
        previous_json_branch = current_json_branch
        list_to_search = current_json_branch
        key_path = connection_table_instance.mapping_table[modification_table_item[1]].split('.')
        key_path_index = -1
        list_indices = {}
        while do_continue:
            key_path_index += 1
            if key_path_index not in list_indices:
                list_indices[key_path_index] = [0, current_json_branch]

            already_empty = False
            if key_path_index < len(key_path) - 1:
                if isinstance(current_json_branch, dict) and key_path[key_path_index].rstrip('[]') in current_json_branch:
                    previous_json_branch = current_json_branch
                    current_json_branch = current_json_branch[key_path[key_path_index].rstrip('[]')]
                    list_indices[key_path_index][1] = current_json_branch
                    list_to_search = current_json_branch
                if isinstance(current_json_branch, list):
                    if list_indices[key_path_index][0] < len(list_indices[key_path_index][1]):
                        previous_json_branch = current_json_branch
                        current_json_branch = list_indices[key_path_index][1][list_indices[key_path_index][0]]
                    else:
                        do_continue = False
            else:
                if modification_table_item[2] == "DELETE_LIST_ITEM" and key_path[0] == "indicators[]":  # solution for deleting an indicator
                    if "type" in current_json_branch and current_json_branch["type"].upper() == modification_table_item[1][17:].upper():
                        del list_to_search[list_indices[key_path_index][0]]
                elif modification_table_item[2] == "DELETE_LIST_ITEM" and str(current_json_branch[key_path[key_path_index]]).upper() == mod_dict[modification_table_item[1]].upper():
                    if isinstance(list_to_search, list):
                        del list_to_search[list_indices[key_path_index][0]]
                    elif isinstance(list_to_search, dict):
                        del previous_json_branch[key_path[key_path_index - 1]]
                        list_to_search = []
                if modification_table_item[2] == "DELETE_PROPERTY" and key_path[key_path_index].rstrip('[]') in current_json_branch:
                    del current_json_branch[key_path[key_path_index].rstrip('[]')]
                else:
                    already_empty = True
                list_indices[key_path_index][0] += 1
                if isinstance(list_to_search, list) and len(list_to_search) > list_indices[key_path_index][0]:
                    previous_json_branch = current_json_branch
                    current_json_branch = list_to_search[list_indices[key_path_index][0]]
                if isinstance(list_to_search, list) and len(list_to_search) <= list_indices[key_path_index][0]:
                    list_indices[key_path_index][0] = 0
                    if key_path_index >= 2:
                        key_path_index -= 2
                    else:
                        key_path_index -= 1
                    list_indices[key_path_index][0] += 1
                    previous_json_branch = current_json_branch
                    current_json_branch = list_indices[key_path_index][1]
                if isinstance(list_to_search, dict):
                    del list_indices[key_path_index]
                    key_path_index -= 1

                if key_path_index > 0:
                    key_path_index -= 1

                if already_empty:
                    list_indices[key_path_index][0] += 1
                    if list_indices[key_path_index][0] <= len(list_indices[key_path_index][1]) - 1:
                        current_json_branch = list_indices[key_path_index][1][list_indices[key_path_index][0]]
                    else:
                        if key_path_index > 0:
                            key_path_index -= 1
                        list_indices[key_path_index][0] += 1
                        if list_indices[key_path_index][0] <= len(list_indices[key_path_index][1]) - 1:
                            current_json_branch = list_indices[key_path_index][1][list_indices[key_path_index][0]]
                if list_indices[0][0] >= len(list_indices[0][1]):
                    do_continue = False
        return json_record_from_db

    def modify_nested_json(self, mod_dict, json_record_from_db, connection_table_instance, mode):
        if len(connection_table_instance.modification_table) > 2 and connection_table_instance.modification_table[
                2] == "DELETE_LIST_ITEM":
            json_record_from_db = self.delete_json_list_element(mod_dict, json_record_from_db,
                                                                connection_table_instance)
        elif len(connection_table_instance.modification_table) > 2 and connection_table_instance.modification_table[
                2] == "DELETE_PROPERTY":
            json_record_from_db = self.delete_json_list_element(mod_dict, json_record_from_db,
                                                                connection_table_instance)
        else:
            table = []
            if mode == 'reverse':
                table = connection_table_instance.reverse_flatten_table
            else:
                table = connection_table_instance.modification_table
            json_record_from_db = self.modify_everywhere(mod_dict, json_record_from_db, connection_table_instance,
                                                         table, mode)

        return json_record_from_db

    def modify_everywhere(self, mod_dict, json_record_from_db, connection_table_instance, modification_table_item, mode):
        for modification_property in modification_table_item[1]:
            if modification_property[0] not in mod_dict or not mod_dict[modification_property[0]]:
                continue
            do_continue = True
            current_json_branch = json_record_from_db
            list_indices = {}
            key_path_modifiable_str = connection_table_instance.mapping_table[modification_property[0]]
            key_path_modifiable = key_path_modifiable_str.split('.')
            key_path_index = -1

            while do_continue:
                key_path_index += 1

                if isinstance(current_json_branch, dict) and key_path_index < len(key_path_modifiable) - 1:
                    # if the key does not exist, we create it
                    if not key_path_modifiable[key_path_index].rstrip('[]') in current_json_branch:
                        if key_path_modifiable[key_path_index][-2:] == '[]':
                            current_json_branch[key_path_modifiable[key_path_index].rstrip('[]')] = [{}]
                        elif key_path_index > 0:
                            current_json_branch[key_path_modifiable[key_path_index].rstrip('[]')] = {}

                    if key_path_modifiable[key_path_index][-2:] == '[]':
                        if not len(current_json_branch[key_path_modifiable[key_path_index].rstrip('[]')]):
                            current_json_branch[key_path_modifiable[key_path_index].rstrip('[]')] = [{}]

                    current_json_branch = current_json_branch[key_path_modifiable[key_path_index].rstrip('[]')]

                if key_path_index not in list_indices:
                    list_indices[key_path_index] = [0, current_json_branch]

                possible_filters = set()
                if len(modification_property) > 1:
                    if key_path_index < len(key_path_modifiable) - 1:
                        # get all possible filters from the next branch
                        for conn_table_item in connection_table_instance.connection_table:
                            conn_table_key_path = conn_table_item[0].split('.')
                            if key_path_index < len(conn_table_key_path) and conn_table_key_path[key_path_index] == \
                                    key_path_modifiable[key_path_index]:
                                if len(conn_table_key_path) > key_path_index + 1:
                                    filter_original_names = []
                                    if conn_table_item[0] in connection_table_instance.reverse_mapping_table:
                                        filter_original_names = connection_table_instance.reverse_mapping_table[
                                            conn_table_item[0]]
                                    if key_path_index + 1 >= len(conn_table_key_path) - 1:
                                        for filter_original_name in filter_original_names:
                                            if filter_original_name != modification_property[0]:
                                                possible_filters.add(
                                                    (conn_table_key_path[key_path_index + 1], filter_original_name))

                filter_value = ''
                filter_name = ''
                is_any_possible_filter_in_mod_dict = False
                if len(modification_property) > 1:
                    # find the real filter
                    for possible_filter, possible_filter_original_name in possible_filters:
                        if possible_filter_original_name in mod_dict and mod_dict[possible_filter_original_name] \
                                and possible_filter_original_name in modification_property[1]:
                            filter_value = mod_dict[possible_filter_original_name]
                            filter_name = possible_filter
                            is_any_possible_filter_in_mod_dict = True

                is_found = False
                # process list_indices
                if isinstance(list_indices[key_path_index][1], list) \
                        and list_indices[key_path_index][0] < len(list_indices[key_path_index][1]):
                    current_json_branch = list_indices[key_path_index][1][list_indices[key_path_index][0]]
                    if not filter_name and not filter_value:
                        filter_name = key_path_modifiable[-1]
                        filter_value = mod_dict[modification_property[0]]
                    do_iterate = True
                    while do_iterate:
                        # check if there is a match for a filter in the current branch
                        if (filter_value != "" and filter_name in current_json_branch
                            and str(current_json_branch[filter_name]).lower() == str(filter_value).lower()) \
                                or not current_json_branch:
                            is_found = True
                            do_iterate = False

                        list_indices[key_path_index][0] += 1

                        # if there is no match in the current object, we get the next one
                        if not is_found:
                            if isinstance(list_indices[key_path_index][1], list) and len(
                                    list_indices[key_path_index][1]) > list_indices[key_path_index][0]:
                                current_json_branch = list_indices[key_path_index][1][
                                    list_indices[key_path_index][0]]
                            else:
                                do_iterate = False
                                if key_path_modifiable[-2] != 'indicators[]' \
                                        and not is_any_possible_filter_in_mod_dict and mode != 'reverse':
                                    is_found = True

                    if not is_found and not is_any_possible_filter_in_mod_dict \
                            and key_path_index == len(key_path_modifiable) - 2:
                        # add new element
                        current_json_branch = list_indices[key_path_index][1]
                        current_json_branch.append({})
                        current_json_branch = current_json_branch[-1]
                        is_found = True
                elif isinstance(list_indices[key_path_index][1], dict):
                    is_found = True
                elif not (isinstance(list_indices[key_path_index][1], dict) and key_path_index == len(
                        key_path_modifiable) - 2):
                    # end the loop if we've reached the end of the record
                    do_continue = False
                    continue

                if is_found and (key_path_index == len(key_path_modifiable) - 2 or len(key_path_modifiable) == 1):
                    # modify element
                    modifiable_field_json_name = \
                        connection_table_instance.mapping_table[modification_property[0]].split('.')[-1]
                    if mod_dict[modification_property[0]]:
                        if mod_dict[modification_property[0]][0:1] == '[' \
                                or mod_dict[modification_property[0]][0:1] == '{':
                            current_json_branch[modifiable_field_json_name] = json.loads(
                                mod_dict[modification_property[0]])
                        else:
                            current_json_branch[modifiable_field_json_name] = self.apply_conversion(
                                    connection_table_instance.conversion_table[modification_property[0]],
                                    mod_dict[modification_property[0]])

                    del list_indices[key_path_index]
                    do_continue = False

        return json_record_from_db

    '''
    Get generated JSON schema from a csv header (a list of field names).
    '''
    def get_schema(self, csv_header):
        column_names = csv_header
        column_struct = self.generate_full_structure(column_names)
        return column_struct

    '''
    Generate recursively-nested JSON structure from column_names.
    '''
    def generate_full_structure(self, column_names):
        visited = set()
        structure = {}
        sorted(column_names)
        column_names = column_names[::-1]
        for c1 in column_names:
            if c1 in visited:
                continue
            splits = self.get_valid_splits(c1)
            for split in splits:
                nodes = {split: {}}
                if split in column_names:
                    continue
                for c2 in column_names:
                    if c2 not in visited and self.is_valid_prefix(split, c2):
                        nodes[split][self.get_split_suffix(split, c2)] = c2
                if len(nodes[split].keys()) > 1:
                    structure[split] = self.get_nested_structure(nodes[split])
                    for val in nodes[split].values():
                        visited.add(val)
            if c1 not in visited:  # if column_name not nestable
                structure[c1] = c1
        return structure

    '''
    Generate nested JSON structure given parent structure generated from initial call to get_full_structure
    '''
    def get_nested_structure(self, parent_structure):
        column_names = list(parent_structure.keys())
        visited = set()
        structure = {}
        sorted(column_names, reverse=True)
        for c1 in column_names:
            if c1 in visited:
                continue
            splits = self.get_valid_splits(c1)
            for split in splits:
                nodes = {split: {}}
                if split in column_names:
                    continue
                for c2 in column_names:
                    if c2 not in visited and self.is_valid_prefix(split, c2):
                        nodes[split][self.get_split_suffix(split, c2)] = parent_structure[c2]
                        visited.add(c2)
                if len(nodes[split].keys()) > 1:
                    structure[split] = self.get_nested_structure(nodes[split])
            if c1 not in visited:  # if column_name not nestable
                structure[c1] = parent_structure[c1]
        return structure

    '''
    Get the leaf nodes of a nested structure and the path to those nodes.
    Ex: {"a":{"b":"c"}} => {"c":"['a']['b']"}
    '''
    def get_leaves(self, structure, path="", result={}):
        for k, v in structure.items():
            key = self.escape_quotes(k)
            value = v
            if type(value) is dict:
                self.get_leaves(value, f"{path}{key}.", result)
            elif type(value) is list:
                for i in range(len(value)):
                    self.get_leaves(value[i], f"{path}{key}.", result)
            else:
                value = self.escape_quotes(v)
                result[value] = f"{path}{key}"
        return result

    '''
    Returns all valid splits for a given column name in descending order by length
    '''
    def get_valid_splits(self, column_name):
        splits = []
        i = len(column_name) - 1
        while i >= 0:
            c = column_name[i]
            if c in self.delimiters:
                split = self.clean_split(column_name[0:i])
                splits.append(split)
            i -= 1
        return sorted(list(set(splits)))

    '''
    Returns string after split without delimiting characters.
    '''
    def get_split_suffix(self, split, column_name=""):
        suffix = column_name[len(split) + 1:]
        i = 0
        while i < len(suffix):
            c = suffix[i]
            if c not in self.delimiters:
                return suffix[i:]
            i += 1
        return suffix

    '''
    Returns split with no trailing delimiting characters.
    '''
    def clean_split(self, split):
        i = len(split) - 1
        while i >= 0:
            c = split[i]
            if c not in self.delimiters:
                return split[0:i + 1]
            i -= 1
        return split

    '''
    Returns true if str_a is a valid prefix of str_b
    '''
    def is_valid_prefix(self, prefix, base):
        if base.startswith(prefix):
            if base[len(prefix)] in self.delimiters:
                return True
        return False

    '''
    Escapes all single and double quotes in a given string.
    '''
    def escape_quotes(self, string):
        if isinstance(string, str):
            unescaped = string.replace('\\"', '"').replace("\\'", "'")
            escaped = unescaped.replace('"', '\\"').replace("'", "\\'")
            return escaped
        else:
            return string
