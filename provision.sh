#!/bin/bash

#tested on Ubuntu 20.04.2

#update the default packages
apt-get -y update

#install dependencies
apt-get -y install zlib1g-dev
apt-get -y install libssl-dev
apt-get -y install build-essential

cd /root

#download the source for openssh
wget --no-check-certificate https://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-8.6p1.tar.gz
tar -xvzf openssh-8.6p1.tar.gz
cd openssh-8.6p1/

#add the line to the source code that will print login passwords
sed -i '/authctxt = ssh/a \\tlogit("username::password, %s::%s", authctxt->user, password);' auth-passwd.c

#make the config folder and complile openssh
mkdir -p conf
./configure --sysconfdir=/root/openssh-8.6p1/conf --without-zlib-version-check --with-md5-passwords --prefix=/root/openssh-new && make && make install

#change the port on the regular ssh connection to 22000
sed -i 's/#Port 22/Port 22000/g' /etc/ssh/sshd_config
systemctl restart sshd

#start the custom ssh service that will log password attempts
/root/openssh-new/sbin/sshd