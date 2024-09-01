import logging

from utils.arg_parser_service import Type, Destination
from utils.copy_service import copy_files_from_to_flat_directory, copy_directory_from_to_as_is
from utils.property_reader_service import parse_file
from utils.arg_parser_service import parse_arguments
import utils.action_service as ase

WII_U_FOLDER_NAME = "wiiu"

# Press the green button in the gutter to run the script.
if __name__ == '__main__':

    argopt = parse_arguments()

    logging.info(f"Chosen type {argopt}")
    logging.info(f"Chosen type {argopt.destination}")

    dirs_dict = parse_file()

    # Copy to flat folder
    if argopt.copy_type == Type.copy and argopt.destination == Destination.flat:

        # force copy
        if argopt.force:
            for dir_from, dir_to in dirs_dict.items():
                # If destination folder is wii u then copy folders as is.
                if str(dir_to).__contains__(WII_U_FOLDER_NAME):
                    copy_directory_from_to_as_is(ase.copy_file_tree_replace_existing_action, dir_from, dir_to)
                else:
                    copy_files_from_to_flat_directory(ase.copy_file_action, dir_from, dir_to)

        else:

            for dir_from, dir_to in dirs_dict.items():

                # If destination folder is wii u then copy folders as is.
                if str(dir_to).__contains__(WII_U_FOLDER_NAME):
                    copy_directory_from_to_as_is(ase.copy_file_tree_action, dir_from, dir_to)

                else:

                    copy_files_from_to_flat_directory(ase.copy_file_action, dir_from, dir_to)


    # Symlink to flat folder
    elif argopt.copy_type == Type.symlink and argopt.destination == Destination.flat:

        for dir_from, dir_to in dirs_dict.items():

            # If destination folder is wii u then copy folders as is.
            if str(dir_to).__contains__(WII_U_FOLDER_NAME):

                copy_directory_from_to_as_is(ase.symlink_directory_action, dir_from, dir_to)

            else:

                copy_files_from_to_flat_directory(ase.symlink_file_action, dir_from, dir_to)

    # Copy to folder as is
    elif argopt.copy_type == Type.copy and argopt.destination == Destination.asis:

        if argopt.force:
            for dir_from, dir_to in dirs_dict.items():
                copy_directory_from_to_as_is(ase.copy_file_tree_replace_existing_action, dir_from, dir_to)
        else:
            for dir_from, dir_to in dirs_dict.items():
                copy_directory_from_to_as_is(ase.copy_file_tree_action, dir_from, dir_to)


    # Symlink to folder as is
    elif argopt.copy_type == Type.symlink and argopt.destination == Destination.asis:
        for dir_from, dir_to in dirs_dict.items():
            copy_directory_from_to_as_is(ase.symlink_directory_action, dir_from, dir_to)
