import logging
import os
import pathlib
import sys

logging.root.setLevel(
    level=logging.INFO
)


def copy_directory_from_to_as_is(action, path_from, path_to):
    """
    Copy folder of games as is

    :param action lambda from {utils.action_service.py}
    :param path_from: path from which contains multiple folders with games
    :param path_to: path to
    :return: None
    """

    # Get all nested folders inside (would be name of games)
    dirs_from = get_all_nested_dirs(path_from)

    # Add all these nested folder names to path_to

    full_dirs_paths_to = add_dir_names_to_path(dirs_from, path_to)

    # Create hashmap for from game path to game path

    map = connect_path_from_and_path_to_to_dict(dirs_from, full_dirs_paths_to)

    # Iterate through hashmap to copy

    for dir_from, dir_to in map.items():

        try:
            action(dir_from, dir_to)
            # shutil.copytree(dir_from, dir_to)
            logging.info(f"Copied directory as is from {dir_from} to {dir_to}")
        except FileExistsError:
            logging.info(f"Unable to copy from - {dir_from}. Directory already exists - {dir_to}")


def copy_files_from_to_flat_directory(action, path_from, path_to):
    """

    Copy all files from directory hierarchy to flat folder

    :param action lambda from utils.action_service.py
    :param path_from: path from
    :param path_to:  path to
    :return: None
    """

    try:
        dirs = get_all_nested_dirs(path_from)
        logging.info(dirs)

        for directory in dirs:
            files = get_all_files_in_dir(directory)

            for file in files:
                logging.info(f"Copy file {file} to {path_to}")
                action(file, path_to)

            copy_files_from_to_flat_directory(action, directory, path_to)

    except FileNotFoundError:
        logging.error(f"Directory not found'{path_from}'")


def get_all_nested_dirs(path):
    """
    Get all nested directories in folder

    :param path: path
    :return: list of paths to directories
    """

    dirs = []

    if os.path.exists(path):
        for file in os.listdir(path):
            d = os.path.join(path, file)
            if os.path.isdir(d):
                dirs.append(d)
    else:
        logging.warning(f"Couldn't find directory {path}. Ignoring it.")

    return dirs


def add_dir_names_to_path(dirs, path):
    """
    Adds all last folder names to a path

    :param dirs: list of directory paths
    :param path: the path to add last folder name
    :return: list of paths
    """

    full_dir_paths = []
    for d in dirs:
        last_folder_name = get_last_folder_name_from_path(d)

        full_dir_path = os.path.join(path, last_folder_name)
        full_dir_paths.append(full_dir_path)

    return full_dir_paths


def get_last_folder_name_from_path(path):
    """
    Extract last folder name from path

    :param path: the path
    :return: string contains last folder name in path
    """

    pure_path = pathlib.PurePath(path)
    last_folder_name = pure_path.name
    return last_folder_name


def connect_path_from_and_path_to_to_dict(dirs_from, dirs_to):
    """
    Merging two separate lists of paths into one dictionary. Rule is both paths must have
    same last folder name in it.

    :param dirs_from: list of paths to copy from
    :param dirs_to: list of paths to copy to
    :return: dictionary of paths where key - is copy from, and value - is copy to
    """

    result = {}

    for dir_from in dirs_from:

        last_folder_name_from = get_last_folder_name_from_path(dir_from)

        for dir_to in dirs_to:

            last_folder_name_to = get_last_folder_name_from_path(dir_to)

            if last_folder_name_from == last_folder_name_to:
                result[dir_from] = dir_to

    return result


def get_all_files_in_dir(path):
    """
    Get all files in folder

    :param path: path
    :return: list of paths to files
    """

    files = []
    for file in os.listdir(path):
        f = os.path.join(path, file)
        if os.path.isfile(f):
            files.append(f)

    return files


# Press the green button in the gutter to run the script.
if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)
    logging.info(f"First arg - {sys.argv[1]}")
    logging.info(f"Second arg - {sys.argv[2]}")
    path_from = sys.argv[1]
    path_to = sys.argv[2]
    copy_files_from_to_flat_directory(path_from, path_to)
