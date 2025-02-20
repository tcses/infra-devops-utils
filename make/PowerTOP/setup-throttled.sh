sudo apt-get install -y python3-setuptools python3-virtualenv python3-pip python3-dbus python3-gi

cd /tmp
git clone https://github.com/erpalma/throttled.git
cd throttled
sudo ./install.sh

# Verify throttled service
sudo systemctl status throttled