import json
import logging

counter = 0

logger = logging.getLogger('buffered_reader')
logger.setLevel(logging.DEBUG)


class BufferInput:
    file_name = None
    fd = None
    position = 0
    buffer = None
    buffer_actual_size = 0

    def __init__(self, file_name, settings):
        self.file_name = file_name
        self.settings = settings
        with open(settings.input_json_filename, "rb") as input_file:
            self.buffer = input_file.read(settings.json_reader_buffer_size)
        logging.basicConfig(level=settings.log_level,
                            format='%(asctime)s.%(msecs)03d %(levelname)s [%(threadName)s] %(module)s: %(message)s',
                            datefmt='%Y-%m-%d %H:%M:%S')

    def correct_size(self, corrected_size):
        self.position = self.position - self.settings.json_reader_buffer_size + corrected_size

    def read(self, position):
        self.buffer_actual_size = 0
        with open(self.settings.input_json_filename, "rb", self.settings.json_reader_buffer_size) as input_json_file:
            input_json_file.seek(position)
            self.buffer = input_json_file.read(self.settings.json_reader_buffer_size)
        return self.buffer


class FreezableList(list):
    OPEN = ord("{")
    CLOSE = ord("}")
    QUOTATION = ord("\"")
    BACKSLASH = ord("\\")

    def __init__(self, *args, **kwargs):
        list.__init__(self, *args)
        self.frozen = kwargs.get('frozen', False)

    def __setitem__(self, i, y):
        if self.frozen:
            raise TypeError("can't modify frozen list")
        return list.__setitem__(self, i, y)

    def __setslice__(self, i, j, y):
        if self.frozen:
            raise TypeError("can't modify frozen list")
        return list.__setslice__(self, i, j, y)

    def freeze(self):
        self.frozen = True

    def thaw(self):
        self.frozen = False


class JsonScanner:
    start = 0
    end = 0
    buffer = None
    buffer_size = 0
    results = []

    def __init__(self, buffer, buffer_size):
        self.buffer = buffer
        self.buffer_size = buffer_size

    def scan(self, buffer, prev_position):
        self.results = []
        open_char = FreezableList.OPEN
        close_char = FreezableList.CLOSE
        quotation_char = FreezableList.QUOTATION
        backslash_char = FreezableList.BACKSLASH

        in_string = False
        escaped = False
        start = -1
        token_stack = 0

        for position in range(len(self.buffer) - 1):
            char_code = buffer[position]

            if in_string:
                if escaped:
                    escaped = False
                    continue

                if char_code == backslash_char:
                    escaped = True

                if char_code == quotation_char:
                    if not in_string:
                        in_string = True
                    else:
                        in_string = False
                    continue
            else:
                if char_code == quotation_char:
                    in_string = True
                    continue
                if char_code == open_char:
                    token_stack += 1
                    if start == -1:
                        start = position
                    continue
                if char_code == close_char:
                    token_stack -= 1
                    if token_stack == 0:
                        self.results.append([prev_position + start, prev_position + position + 1])
                        start = -1


def read_json_records(settings, prev_position=None):
    json_list = list()
    try:
        if not prev_position:
            prev_position = 0
        buffer_reader = BufferInput(settings.json_reader_buffer_size, settings)
        data = buffer_reader.read(prev_position)
        scanner = JsonScanner(data, settings.json_reader_buffer_size)
        scanner.scan(data, prev_position)
        with open(settings.input_json_filename, "rb") as input_json_file:
            for index in range(len(scanner.results)):
                start_byte = scanner.results[index][0]
                end_byte = scanner.results[index][1]
                input_json_file.seek(start_byte)
                json_list.append((json.loads(input_json_file.read(end_byte - start_byte)), end_byte))
    except Exception as error:
        logger.debug(str(error))
    finally:
        return json_list
