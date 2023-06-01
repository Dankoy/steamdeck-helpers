DIR_FILE = "dirs.txt"

directories_dict = {}


def parse_file():
    with open("dirs.txt") as f:
        for line in f:
            (key, val) = line.split("~")
            key = key.strip()
            val = val.strip()
            directories_dict[key] = val

    return directories_dict
