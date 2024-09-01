# copir-py

The same as copit project but written using python. Steamdeck doesn't allow to install java or docker
without shaman dancing.

# Usage

## Create virtual environment (not necessary)

`pyenv virtualenv 3.12.4 copir-py`

## Activate virtual environment (not necessary)

`pyenv activate sup`

## Add directories to copy from-to in file dirs

`{directory from} ~ {directory to}`

tilda ~ is a delimiter in case there are spaces in directory names

## Examples

```shell
usage: main.py [-h] [-d [{flat,asis}]] {copy,symlink} ...

Choose type of action

positional arguments:
  {copy,symlink}        Type of action
    copy                copy files
    symlink             symlink nested next to root folders

options:
  -h, --help            show this help message and exit
  -d [{flat,asis}], --destination [{flat,asis}]
                        Destination type. Flat or as is. Default asis
```

```shell
usage: main.py copy [-h] [-c [{copy,symlink}]] [-f | --force | --no-force]

options:
  -h, --help            show this help message and exit
  -c [{copy,symlink}], --copy-type [{copy,symlink}]
  -f, --force, --no-force
                        Force copy directory tree. Default - false

```

### Copy

#### Copy files in flat directory (doesn't copy directories)

`python main.py copy`

#### Copy directories as is

Copies next to root directory with all it's contents.

`python main.py -d asis copy`

#### Copy directories as is with force replace

Copies next to root directory with all it's contents.

`python main.py -d asis copy -f`

### Symlink

Of course works only on same file system

### Symlink files in flat directory (doesn't symlink directories)

Symlinks all files in flat directory

`python main.py symlink`

### Symlink directory

Creates symlink for next to root folder (from) to destination

`python main.py -d asis symlink`



