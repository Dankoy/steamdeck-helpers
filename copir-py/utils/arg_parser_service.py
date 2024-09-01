import argparse

from enum import Enum


class Type(Enum):
    copy = 'copy'
    symlink = 'symlink'

    def __str__(self):
        return self.value


class Destination(Enum):
    flat = 'flat'
    asis = 'asis'

    def __str__(self):
        return self.value


def parse_arguments():
    parser = argparse.ArgumentParser(description='Choose type of action')

    parser.add_argument("-d", "--destination", type=Destination, choices=list(Destination), nargs='?',
                        const=Destination.asis, default=Destination.asis,
                        help="Destination type. Flat or as is. Default asis")

    subparsers = parser.add_subparsers(help="Type of action")

    # subparser for copy command adds argument hidden to user
    copy_parser = subparsers.add_parser("copy", help='copy files')
    copy_parser.add_argument("-c", "--copy-type", type=Type, choices=list(Type), nargs='?', const=Type.copy,
                             default=Type.copy)
    copy_parser.add_argument("-f", "--force", type=bool, action=argparse.BooleanOptionalAction, default=False,
                             help="Force copy directory tree. Default - false")

    # subparser for symlink command adds argument hidden to user
    symlink_parser = subparsers.add_parser("symlink", help='symlink nested next to root folders')
    symlink_parser.add_argument("-c", "--copy-type", type=Type, choices=list(Type), nargs='?', const=Type.symlink,
                                default=Type.symlink)

    return parser.parse_args()
