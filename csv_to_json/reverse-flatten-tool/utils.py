def get_field_index(header, field_names):
    for i in range(len(header)):
        if header[i] in field_names:
            return i
    return -1
