# Easy SSH Password Logging
A simple script that will setup an SSH honeypot that logs attempted SSH passwords.

Let's say you want to quickly setup a server that logs the passwords that were used to try and login with through SSH. I found some [articles](https://hackernoon.com/how-ive-captured-all-passwords-trying-to-ssh-into-my-server-d26a2a6263ec) that talk about the process, but this script has everything you need to quickly and easily setup SSH to start logging passwords.

### Getting Started
Run the following commands on an Ubuntu server (tested on Ubuntu 20.04.2)
```
git clone https://github.com/mtagius/easy-ssh-honeypot.git
sudo bash ./easy-ssh-honeypot/provision.sh
```

You can then view any login attempts using this command 

`grep username::password /var/log/auth.log | uniq`
```
Aug 26 02:06:41 ubuntu-s-1vcpu-1gb-nyc1-01 sshd[19811]: username::password, ron::ron
Aug 26 02:07:19 ubuntu-s-1vcpu-1gb-nyc1-01 sshd[19813]: username::password, root::'win@2012'  
Aug 26 02:07:57 ubuntu-s-1vcpu-1gb-nyc1-01 sshd[19815]: username::password, ts3bot::bot
```

### How it Works
At a high level this script downloads the openssl source code, adds the line to log passwords, then sets up the new SSH service on port 22. Here is a walk through of the script.


First, dependencies are installed
```shell
#update the default packages
apt-get -y update

#install dependencies
apt-get -y install zlib1g-dev
apt-get -y install libssl-dev
apt-get -y install build-essential
```

Then the source code for openssh is downloaded
```shell
wget --no-check-certificate https://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-8.6p1.tar.gz
tar -xvzf openssh-8.6p1.tar.gz
cd openssh-8.6p1/
```

I use sed to find the line `authctxt = ssh` in auth-passwd.c and append `logit("username::password, %s::%s", authctxt->user, password);` after it
```shell
sed -i '/authctxt = ssh/a \\tlogit("username::password, %s::%s", authctxt->user, password);' auth-passwd.c
```

I then setup the ssh config folder as `/root/openssh-8.6p1/conf` and the installation folder as `/root/openssh-new`. OpenSSH is then compiled
```shell
mkdir -p conf
./configure --sysconfdir=/root/openssh-8.6p1/conf --without-zlib-version-check --with-md5-passwords --prefix=/root/openssh-new && make && make install
```

These commands edit the existing SSH service to use port 22,000 so that our new SSH service can use port 22. You will login using port 22,000 so that your password is not logged.
```shell
sed -i 's/#Port 22/Port 22000/g' /etc/ssh/sshd_config
systemctl restart sshd
```

Finally, we start the new SSH service that logs passwords!
```shell
/root/openssh-new/sbin/sshd
```