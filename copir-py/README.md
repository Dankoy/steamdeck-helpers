# copir-py

The same as copit project but written using python. Steamdeck doesn't allow to install java or docker
without shaman dancing.

## Usage

### Create virtual environment (not necessary)

`pyenv virtualenv 3.12.4 copir-py`

### Activate virtual environment (not necessary)

`pyenv activate sup`

### Add directories to copy from-to in file dirs

`{directory from} ~ {directory to}`

tilda ~ is a delimiter in case there are spaces in directory names

### Run script to copy files

`python main.py -t copy`

### ### Run script to symlink files

`python main.py -t symlink`

Of course works only on same file system