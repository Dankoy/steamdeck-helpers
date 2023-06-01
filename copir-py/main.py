from utils.copy_service import copy_files_from_to
from utils.property_reader_service import parse_file

# Press the green button in the gutter to run the script.
if __name__ == '__main__':
    dirs_dict = parse_file()

    for dir_from, dir_to in dirs_dict.items():
        copy_files_from_to(dir_from, dir_to)
