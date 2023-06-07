from utils.copy_service import copy_files_from_to_flat_directory, copy_directory_from_to_as_is
from utils.property_reader_service import parse_file

WII_U_FOLDER_NAME = "wiiu"

# Press the green button in the gutter to run the script.
if __name__ == '__main__':
    dirs_dict = parse_file()

    for dir_from, dir_to in dirs_dict.items():

        # If destination folder is wii u then copy folders as is.
        if str(dir_to).__contains__(WII_U_FOLDER_NAME):

            copy_directory_from_to_as_is(dir_from, dir_to)

        else:

            copy_files_from_to_flat_directory(dir_from, dir_to)
