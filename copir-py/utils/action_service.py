import logging
import os
import shutil
import ntpath


def copy_file_action(path_from, path_to):
    try:
        shutil.copy2(path_from, path_to)
    except shutil.SameFileError:
        logging.error(f"File '{path_from}' already exists in {path_to}. Check for symlinks")


def copy_file_tree_action(dir_from, dir_to):
    shutil.copytree(dir_from, dir_to)


def symlink_file_action(path_from, path_to):
    try:
        basename = ntpath.basename(path_from)
        path_to_with_file_name = os.path.join(path_to, basename)
        if not basename.startswith('.'):
            os.symlink(path_from, path_to_with_file_name)
        else:
            logging.info("Ignore hidden files")
    except FileExistsError:
        logging.info(f"Unable to symlink from - {path_from}. File already exists - {path_to}")


def symlink_directory_action(path_from, path_to):
    os.symlink(path_from, path_to, target_is_directory=True)
