import argparse

from enum import Enum


class Type(Enum):
    copy = 'copy'
    symlink = 'symlink'

    def __str__(self):
        return self.value


def parse_arguments():
    parser = argparse.ArgumentParser(description='Choose type of action')
    parser.add_argument("-t", "--type", type=Type, choices=list(Type), required=True)
    return parser.parse_args()
