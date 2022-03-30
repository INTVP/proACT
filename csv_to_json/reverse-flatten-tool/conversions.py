import datetime


class Conversion:

    def __init__(self, settings):
        self.settings = settings

    def date_conversion(self, input_cell, settings):
        if self.is_date(input_cell):
            date_obj = datetime.datetime.strptime(input_cell, settings.date_format_str)
            input_cell = str(date_obj.date())
        return input_cell

    def str_to_int_or_float(self, input_cell):
        input_cell_int_or_float = input_cell
        try:
            if '.' in input_cell:
                input_cell_int_or_float = float(input_cell)
            else:
                input_cell_int_or_float = int(input_cell)
        except:
            pass

        return input_cell_int_or_float

    def str_to_bool(self, input_cell):
        if str(input_cell).upper().rstrip().lstrip() == "T" or str(input_cell).upper().rstrip().lstrip() == "TRUE":
            return True
        elif str(input_cell).upper().rstrip().lstrip() == "F" or str(input_cell).upper().rstrip().lstrip() == "FALSE":
            return False
        else:
            return input_cell

    def is_date(self, string):
        try:
            datetime.datetime.strptime(string, self.settings.date_format_str)
            return True

        except ValueError:
            return False
