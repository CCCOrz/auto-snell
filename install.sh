#!/bin/bash

if cat /etc/*-release | grep -q -E -i "debian|ubuntu|armbian|deepin|mint"; then 	# install dependencies
	apt-get install wget unzip dpkg -y
elif cat /etc/*-release | grep -q -E -i "centos|red hat|redhat"; then
	yum install wget unzip dpkg -y
elif cat /etc/*-release | grep -q -E -i "arch|manjora"; then
	yes | pacman -S wget dpkg unzip
elif cat /etc/*-release | grep -q -E -i "fedora"; then
	dnf install wget unzip dpkg -y
fi

echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf	# enable bbr
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p
sysctl net.ipv4.tcp_available_congestion_control

cd
ARCHITECTURE=$(dpkg --print-architecture)
VERSION="v4.1.0"
wget -c https://dl.nssurge.com/snell/snell-server-$VERSION-linux-$ARCHITECTURE.zip	# download binary
unzip -o snell-server-$VERSION-linux-$ARCHITECTURE.zip

echo -e "[Unit]\nDescription=snell server\n[Service]\nUser=root\nWorkingDirectory=/root\nExecStart=/root/snell-server\nRestart=always\n[Install]\nWantedBy=multi-user.target" > /etc/systemd/system/snell.service
y | ./snell-server
echo -e "\nobfs = http" >> ./snell-server.conf
systemctl start snell
systemctl enable snell			# start service

echo
echo "Copy the following line to surge"			# print profile
echo "$(curl -s ipinfo.io/city) = snell, $(curl -s ipinfo.io/ip), $(cat snell-server.conf | grep -i listen | cut --delimiter=':' -f2),psk=$(grep 'psk' snell-server.conf | cut -d= -f2 | tr -d ' '), obfs = http, version=4, tfo=true"
