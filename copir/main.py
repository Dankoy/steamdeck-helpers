import logging
import os
import shutil
import sys


def copy_files_from_to(path_from, path_to):
        try:
            dirs = get_all_nested_dirs(path_from)
            logging.info(dirs)

            for directoty in dirs:
                files = get_all_files_in_dir(directoty)

                for file in files:
                    logging.info(f"Copy file {file} to {path_to}")
                    shutil.copy2(file, path_to)

                copy_files_from_to(directoty, path_to)

        except FileNotFoundError:
            logging.error(f"Directory not found'{path_from}'")


def get_all_nested_dirs(path):
    dirs = []
    for file in os.listdir(path):
        d = os.path.join(path, file)
        if os.path.isdir(d):
            dirs.append(d)

    return dirs


def get_all_files_in_dir(path):
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
    copy_files_from_to(path_from, path_to)
