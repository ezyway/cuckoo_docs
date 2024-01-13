#!/bin/bash

echo "[*] Updating System"
sudo apt-get -y update

echo "[*] Creating user “cuckoo” and add them to sudo:"
sudo adduser cuckoo
sudo adduser cuckoo sudo

echo "[*] Adding  libraries for cuckoo"

sudo apt-get install -y python-dev libffi-dev libssl-dev libfuzzy-dev libtool flex autoconf libjansson-dev git curl python mongodb postgresql libpq-dev python-setuptools libjpeg-dev zlib1g-dev swig ssdeep net-tools
curl https://bootstrap.pypa.io/pip/2.7/get-pip.py -o pip.py
sudo python pip.py
git clone https://github.com/volatilityfoundation/volatility.git
sudo python /volatility/setup.py build
sudo python /volatility/setup.py install
sudo -H pip install distorm3==3.4.4
sudo -H pip install yara-python==3.6.3 
sudo -H pip install pydeep
sudo -H pip install openpyxl
sudo -H pip install ujson
sudo -H pip install jupyter 
sudo -H pip install -U cuckoo
cuckoo
curl https://www.virtualbox.org/download/oracle_vbox_2016.asc | gpg --dearmor > oracle_vbox_2016.gpg
curl https://www.virtualbox.org/download/oracle_vbox.asc | gpg --dearmor > oracle_vbox.gpg
sudo install -o root -g root -m 644 oracle_vbox_2016.gpg /etc/apt/trusted.gpg.d/
sudo install -o root -g root -m 644 oracle_vbox.gpg /etc/apt/trusted.gpg.d/
echo "deb [arch=amd64] http://download.virtualbox.org/virtualbox/debian $(lsb_release -sc) contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
sudo apt update
sudo apt install -y linux-headers-$(uname -r) dkms
sudo apt install virtualbox-6.1 -y
vboxmanage hostonlyif create
vboxmanage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 
sudo mkdir /opt/systemd/

printf "!/bin/bash\nhostonlyif create\nvboxmanage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1" > /opt/systemd/vboxhostonly

sudo chmod a+x /opt/systemd/vboxhostonly


printf "Description=Setup VirtualBox Hostonly Adapter\nAfter=vboxdrv.service\n[Service]\nType=oneshot\nExecStart=/opt/systemd/vboxhostonly\n[Install]\nWantedBy=multi-user.target" > /etc/systemd/system/vboxhostonlynic.service

sudo systemctl daemon-reload
sudo systemctl enable vboxhostonlynic.service
sudo systemctl start vboxhostonlynic.service

sudo apt install -y iptables-persistent

nic_interface_name=$(ip -o -4 route show to default | awk '{print $5}')


sudo iptables -A FORWARD -o $nic_interface_name -i vboxnet0 -s 192.168.56.0/24 -m conntrack --ctstate NEW -j ACCEPT
sudo iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -t nat -A POSTROUTING -o $nic_interface_name -j MASQUERADE

echo 1 | sudo tee -a /proc/sys/net/ipv4/ip_forward
sudo sysctl -w net.ipv4.ip_forward=1

sudo su -c "iptables-save > /etc/iptables/rules.v4"
