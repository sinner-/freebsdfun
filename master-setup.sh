#!/bin/sh -x 

#Upgrade Base OS
#freebsd-update fetch
#freebsd-update install

hostname master

if [ "`grep "^hostname=" /etc/rc.conf`" ]; then 
  sed -i .bk 's/hostname=.*/hostname=master/' /etc/rc.conf
else
  echo "hostname=\"master\"" >> /etc/rc.conf
fi

if ! [ "`grep "^@daily ntpdate -u pool.ntp.org" /etc/crontab`" ]; then
  echo "@daily ntpdate -u pool.ntp.org" >> /etc/crontab
else
  echo "ntp sync command already exists."
fi

if [ -f /etc/ssh/sshd_config ]; then
  cp -f config/master/sshd_config /etc/ssh/sshd_config
  chmod og-rwx /etc/ssh/sshd_config
  service sshd restart
else
  echo "sshd not installed, exiting."
  exit 1
fi

if ! [ -f /usr/local/bin/sudo ]; then
  echo y | pkg install sudo
else
  echo "sudo already installed."
fi

if [ -d /usr/local/etc/sudoers.d ]; then
  echo "%nonroot ALL=(ALL) PASSWD: /usr/bin/su" > /usr/local/etc/sudoers.d/nonroot
  chmod og-rwx /usr/local/etc/sudoers.d/nonroot
  chmod u-wx /usr/local/etc/sudoers.d/nonroot
else
  echo "sudo not installed. exiting."
  exit 1
fi

if ! [ "`grep nonroot /etc/passwd`" ]; then
  pw useradd nonroot -m 
  echo "***Please set a password for nonroot user***"
  passwd nonroot
  mkdir /home/nonroot/.ssh
else
  echo "nonroot user already exists."
fi

if [ -f config/master/authorized_keys ]; then
  cp -f config/master/authorized_keys /home/nonroot/.ssh/
  chmod -R og-rwx /home/nonroot/.ssh
  chown -R nonroot:nonroot /home/nonroot/.ssh
else
  echo "no authorized_keys found. exiting."
  exit 1
fi

cp -f config/master/hosts.allow /etc/hosts.allow
chmod og-wx /etc/hosts.allow

if ! [ -f /usr/local/bin/denyhosts.py ]; then
  echo y | pkg install denyhosts

  #TODO: put error handling here for denyhosts install failure

  if ! [ "`grep "^syslogd_flags" /etc/rc.conf`" ]; then
    echo "syslogd_flags=\"-ss -c\"" >> /etc/rc.conf
  else
    sed -i .bk 's/^syslogd_flags=.*/syslogd_flags="-ss -c"/' /etc/rc.conf
  fi

  service syslogd restart

  if ! [ "`grep "^denyhosts_enable" /etc/rc.conf`" ]; then
    echo "denyhosts_enable=\"YES\"" >> /etc/rc.conf
  else
    sed -i .bk 's/^denyhosts_enable.*/denyhosts_enable="YES"/' /etc/rc.conf
  fi

  if ! [ -f /etc/hosts.deniedssh ]; then 
    touch /etc/hosts.deniedssh
  else
    echo "/etc/hosts.deniedssh already exists."
  fi

else
  echo "denyhosts already installed."
fi

cp -f config/master/denyhosts.conf /usr/local/etc/denyhosts.conf

service denyhosts restart

if [ "`grep "^pf_enable=" /etc/rc.conf`" ]; then 
  sed -i .bk 's/pf_enable=.*/pf_enable="YES"/' /etc/rc.conf
else
  echo "pf_enable=\"YES\"" >> /etc/rc.conf
fi

NETIF=`netstat -rn | grep default | awk '{print $4}'`
IPADDR=`ifconfig $NETIF | grep inet | grep -v 192.168.254 | awk '{print $2}'`
NETIF_STATIC=`ifconfig $NETIF | grep inet | grep -v 192.168.254`
NETIF_ROUTE=`netstat -rn | grep default | awk '{print $2}'`

cp -f config/master/rc.conf.local /etc/rc.conf.local
sed -i .bk "s/if999/$NETIF/g" /etc/rc.conf.local

sed -i .bk "s/^ifconfig_$NETIF=.*/ifconfig_$NETIF=\"$NETIF_STATIC\"/" /etc/rc.conf
if [ "`grep "^defaultrouter=" /etc/rc.conf`" ]; then 
  sed -i .bk "s/defaultrouter=.*/defaultrouter=\"$NETIF_ROUTE\"/" /etc/rc.conf
else
  echo "defaultrouter=\"$NETIF_ROUTE\"" >> /etc/rc.conf
fi

service netif restart ; service routing restart

cp -f config/master/resolv.conf /etc/resolv.conf

echo "setting up jaildirs."
if ! [ -f base.txz ]; then
  curl -O http://mirror.aarnet.edu.au/pub/FreeBSD/releases/amd64/10.1-RELEASE/base.txz
fi

for jaildir in `grep path config/master/jail.conf | awk -F \" '{print $2}'`; do
  if ! [ -d $jaildir ]; then
    mkdir $jaildir
    tar -xf base.txz -C $jaildir
    cp -f config/master/jail_rc.conf.local $jaildir/etc/rc.conf.local
  fi
done

echo "copying jail.conf."
cp -f config/master/jail.conf /etc/jail.conf

for jail in `ls /home | grep -v nonroot`; do
  jail -cmr $jail
done

echo "configuring pf.conf."
cp -f config/master/pf.conf /etc/pf.conf
sed -i .bk "s/if999/$NETIF/" /etc/pf.conf
sed -i .bk "s/ip999/$IPADDR/" /etc/pf.conf

if [ "`service pf onestatus | grep Status`" ]; then
  service pf reload
else
  service pf start
fi
