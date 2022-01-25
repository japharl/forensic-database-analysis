# Assume a debian box.
# This just installs the necessary underlying libraries for the labs.

sudo apt update

sudo apt install -y build-essential
sudo apt install -y git 

sudo apt install -y python3-chardet

sudo apt install -y cpanminus

sudo cpanm Config::Tiny
sudo cpanm DBI

sudo apt install -y mariadb-server mariadb-client

# verify need
sudo cpanm DBD::SQLite
sudo apt install -y sqlite3

cd ..
cd lab/lab3/
git clone https://github.com/major/MySQLTuner-perl.git
