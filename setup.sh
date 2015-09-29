### prereqs
# install libraries and tools
sudo su
zypper install unzip wget autoconf automake gcc gcc43 gcc43-c++ gcc-c++ glibc-devel libcurl-devel libdb-4_5-devel libopenssl-devel libstdc++43-devel linux-kernel-headers zlib-devel

# add user(s)
useradd -g users -d /home/gerrit2 -m gerrit

# create folders and set permissions
mkdir -p /opt/gerrit /var/repo
chown -R gerrit /opt/gerrit
chown -R gerrit /var/repo

### java
cd /tmp
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u60-b27/jdk-8u60-linux-x64.tar.gz"
ls jdk* | cut -d"?" -f1 | xargs mv jdk* $1
tar xvf jdk-8u60-linux-x64.tar.gz
mv jdk1.8.0_60/ /opt/
/usr/sbin/update-alternatives --install /usr/bin/java java /opt/jdk1.8.0_60/bin/java 2
/usr/sbin/update-alternatives --config java
#JDK unlimited strength
wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip
ls jce* | cut -d"?" -f1 | xargs mv jce* $1
unzip -q jce_policy-8.zip
cp UnlimitedJCEPolicyJDK8/local_policy.jar /opt/jdk1.8.0_60/jre/lib/security/

### git
zypper addrepo http://download.opensuse.org/repositories/devel:/tools:/scm/SLE_11_SP3/devel:tools:scm.repo
zypper install git
# configure
git config --global user.name user1
git config --global user.email user1@email.com
git config --global color.ui auto

### nginx
cd /tmp
wget http://download.opensuse.org/repositories/Application:/Geo/SLE_11_SP3/x86_64/GeoIP-data-1.6.5-6.1.x86_64.rpm
wget http://download.opensuse.org/repositories/Application:/Geo/SLE_11_SP3/x86_64/libGeoIP1-1.6.5-6.1.x86_64.rpm
zypper addrepo http://download.opensuse.org/repositories/server:/http/SLE_11_SP3/server:http.repo
rpm -ihv GeoIP-data-1.6.5-6.1.x86_64.rpm
rpm -ihv libGeoIP1-1.6.5-6.1.x86_64.rpm
zypper install nginx

### SSL
zypper install openssl
mkdir -p /etc/nginx/ssl/
cd /etc/nginx/ssl/
openssl genrsa -des3 -out server.key 2048
openssl req -new -key server.key -out server.csr
openssl rsa -in /etc/nginx/ssl/server.key -out /etc/nginx/ssl/server.nocrypt.key
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt

### gitweb
#zypper install git-web
#zypper install flex fcgiwrap FastCGI-devel FastCGI-scripts FastCGI spawn-fcgi
#zypper addrepo http://download.opensuse.org/repositories/home:aevseev/SLE-11_SP3/home:aevseev.repo 
##config sys
#git config -f /opt/gerrit/etc/gerrit.config gitweb.type custom
#git config -f /opt/gerrit/etc/gerrit.config gitweb.project ?p=\{project}\;a=summary
#git config -f /opt/gerrit/etc/gerrit.config gitweb.revision ?p=\{project}\;a=commit\;h=\{commit}
#git config -f /opt/gerrit/etc/gerrit.config gitweb.branch ?p=\{project}\;a=shortlog\;h=\{branch}
#git config -f /opt/gerrit/etc/gerrit.config gitweb.roottree ?p=\{project}\;a=tree\;hb=\{commit}
#git config -f /opt/gerrit/etc/gerrit.config gitweb.file ?p=\{project}\;hb=\{commit}\;f=\{file}
#git config -f /opt/gerrit/etc/gerrit.config gitweb.filehistory ?p=\{project}\;a=history\;hb=\{branch}\;f=\{file}
## gerrit.config
git config -f /opt/gerrit/etc/gerrit.config gitweb.cgi /usr/share/gitweb/gitweb.cgi

### mysql
zypper install mysql mysql-client
/etc/init.d/mysql start
## alter folder database
/etc/init.d/mysql stop
cp -rap /var/lib/mysql /var/db
chown mysql.mysql /var/db
vi /etc/my.cnf
datadir=/var/db
socket=/var/db/mysql.sock
/etc/init.d/mysql start
##create gerrit database
mysql -u root
#SELECT User, Host, Password FROM mysql.user;
CREATE USER 'gerrit'@'localhost' IDENTIFIED BY 'Acc1234$$';
CREATE DATABASE reviewdb;
ALTER DATABASE reviewdb charset=latin1;
GRANT ALL ON reviewdb.* TO 'gerrit'@'localhost';
FLUSH PRIVILEGES;
ALTER DATABASE reviewdb charset=latin1;
exit

# choose defaults
mysql_secure_installation 

### JavaSSL
## Configure LDAPS (LDAP over SSL) in Gerrit Application
sudo su
cd /tmp
openssl s_client -connect <ldap-ip>:636  < /dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > javacert.crt
cp -r /opt/jdk1.8.0_60/jre/lib/security/cacerts /opt/jdk1.8.0_60/jre/lib/security/cacerts.bak
/opt/jdk1.8.0_60/bin/./keytool -import -alias ad -keystore /opt/jdk1.8.0_60/jre/lib/security/cacerts -file javacert.crt
# password is changeit

### gerrit
#  java -jar bin/gerrit.war reindex
cd /tmp
wget https://www.gerritcodereview.com/download/gerrit-2.11.3.war --no-check-certificate
chown gerrit gerrit-2.11.3.war
su - gerrit
cd /opt/gerrit
# ref automatizado: http://codingbee.net/tutorials/gerrit/gerrit-installation-setup/#Silent_or_Semi-automated_Gerrit_Instalation
java -jar /tmp/gerrit-2.11.3.war init -d .
## config
# Create '/opt/gerrit'           [Y/n]? Y
# Location of Git repositories   [git]: /var/repo
# Database server type           [h2]: mysql
# Download and install it now [Y/n]? Y
# Server hostname                [localhost]: localhost
# Server port                    [(mysql default)]:
# Database name                  [reviewdb]:
# Database username              [root]: gerrit
# gerrit2's password             :
#              confirm password :
# Type                           [LUCENE/?]:
# Authentication method          [OPENID/?]: LDAP
# LDAP server                    [ldap://localhost]: ldaps://<ldap-ip>:636
# LDAP username                  : fellipecm\aduser
# fellipecm\aduser's password    :
#              confirm password :
# Account BaseDN                 [DC=232,DC=253,DC=38:636]: DC=fellipecm,DC=local
# Group BaseDN                   [DC=fellipecm,DC=local]: CN=gitadmins,CN=Users,DC=fellipecm,DC=local
# Install Verified label         [y/N]?
# SMTP server hostname           [localhost]:
# SMTP server port               [(default)]:
# SMTP encryption                [NONE/?]:
# SMTP username                  :
# Run as                         [root]: gerrit
# Java runtime                   [/opt/jdk1.8.0_60/jre]:
# Copy gerrit-2.11.3.war to /opt/gerrit/bin/gerrit.war [Y/n]?
# Listen on address              [*]:
# Listen on port                 [29418]:
# Y
# Y
# Behind reverse proxy           [y/N]? Y
# Use SSL (https://)             [y/N]? Y 
# Listen on address              [*]:
# Listen on port                 [8080]:
# Canonical URL                  [http://ip-172-31-21-52.sa-east-1.compute.internal:8080/]: https://<gerrit-ip>/gerrit
# Install plugin download-commands version v2.11.3 [y/N]?
# Install plugin reviewnotes version v2.11.3 [y/N]?
# Install plugin singleusergroup version v2.11.3 [y/N]?
# Install plugin replication version v2.11.3 [y/N]?
# Install plugin commit-message-length-validator version v2.11.3 [y/N]?

### Adding services to system startup
## Configure Gerrit http://review.cyanogenmod.org/Documentation/install.html#rc_d
#NOT USED: echo "su - gerrit -c '/opt/gerrit/bin/./gerrit.sh start'" /opt/gerrit/bin/startup.sh
#edit gerrit.sh uncommenting :
# chkconfig: 3 99 99
# description: Gerrit Code Review
# processname: gerrit

# create service link
sudo ln -snf /opt/gerrit/bin/gerrit.sh /etc/init.d/gerrit
sudo ln -snf /etc/init.d/gerrit /etc/rc.d/rc3.d/S90gerrit
## add all
yast runlevel add service=nginx,mysql,gerrit
# verify current runlevel
runlevel
# check if the startup sequence "SXX" is mysql,gerrit,nginx. Example for runlevel 3:
ls -la /etc/init.d/rc3.d | egrep "mysql|gerrit|nginx"
# if not, change it:
sudo mv /etc/init.d/rc3.d/S07gerrit /etc/init.d/rc3.d/S12gerrit

#Tune
git config --file /usr/opt/gerrit/etc/gerrit.config container.heapLimit 7g
git config --file /usr/opt/gerrit/etc/gerrit.config sshd.threads 24
git config --file /usr/opt/gerrit/etc/gerrit.config sshd.batchThreads 2
git config --file /usr/opt/gerrit/etc/gerrit.config core.packedGitOpenFiles 4096
git config --file /usr/opt/gerrit/etc/gerrit.config core.packedGitLimit 2g
git config --file /usr/opt/gerrit/etc/gerrit.config core.packedGitWindowSize 16k
git config --file /usr/opt/gerrit/etc/gerrit.config database.poolMaxIdle 16
git config --file /usr/opt/gerrit/etc/gerrit.config database.poolLimit 64

### Wrap-up
## Backup configs and initial DB
cd /tmp
tar -zcvf gerrit_etc.tar.gz /opt/gerrit/etc/
tar -zcvf nginx_etc.tar.gz /etc/nginx/
mysqldump -u gerrit -p 'Acc1234$$' --databases reviewdb > reviewdb.sql

## Delete installers
rm jce_policy-8.zip jdk-8u60-linux-x64.tar.gz GeoIP-data-1.6.5-6.1.x86_64.rpm libGeoIP1-1.6.5-6.1.x86_64.rpm gerrit-2.11.3.war