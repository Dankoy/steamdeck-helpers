import logging

from utils.arg_parser_service import Type
from utils.copy_service import copy_files_from_to_flat_directory, copy_directory_from_to_as_is
from utils.property_reader_service import parse_file
from utils.arg_parser_service import parse_arguments
import utils.action_service as ase

WII_U_FOLDER_NAME = "wiiu"

# Press the green button in the gutter to run the script.
if __name__ == '__main__':

    argopt = parse_arguments()

    logging.info(f"Chosen type {argopt.type}")

    dirs_dict = parse_file()

    if argopt.type == Type.copy:

        for dir_from, dir_to in dirs_dict.items():

            # If destination folder is wii u then copy folders as is.
            if str(dir_to).__contains__(WII_U_FOLDER_NAME):

                copy_directory_from_to_as_is(ase.copy_file_tree_action, dir_from, dir_to)

            else:

                copy_files_from_to_flat_directory(ase.copy_file_action, dir_from, dir_to)

    elif argopt.type == Type.symlink:

        for dir_from, dir_to in dirs_dict.items():

            # If destination folder is wii u then copy folders as is.
            if str(dir_to).__contains__(WII_U_FOLDER_NAME):

                copy_directory_from_to_as_is(ase.symlink_directory_action, dir_from, dir_to)

            else:

                copy_files_from_to_flat_directory(ase.symlink_file_action, dir_from, dir_to)
