### prereqs
## install libraries and tools
sudo su
cd /tmp
# add repos
zypper addrepo http://download.opensuse.org/repositories/devel:/tools:/scm/SLE_11_SP3/devel:tools:scm.repo
zypper addrepo http://download.opensuse.org/repositories/server:/http/SLE_11_SP3/server:http.repo
zypper refresh
# install binaries
zypper install unzip wget autoconf automake gcc gcc-c++ glibc-devel libcurl-devel libdb-4_5-devel libopenssl-devel libstdc++43-devel linux-kernel-headers zlib-devel git openssl
# downloads
cd /tmp
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u60-b27/jdk-8u60-linux-x64.tar.gz" > jdk-8u60-linux-x64.tar.gz
wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip > jce_policy-8.zip
wget http://mirror.cogentco.com/pub/apache/tomcat/tomcat-7/v7.0.64/bin/apache-tomcat-7.0.64.tar.gz --no-check-certificate
wget https://www.gerritcodereview.com/download/gerrit-2.11.3.war --no-check-certificate
wget http://download.opensuse.org/repositories/Application:/Geo/SLE_11_SP3/x86_64/GeoIP-data-1.6.5-6.1.x86_64.rpm
wget http://download.opensuse.org/repositories/Application:/Geo/SLE_11_SP3/x86_64/libGeoIP1-1.6.5-6.1.x86_64.rpm

## add user(s)
useradd -g users -d /home/gerrit2 -m gerrit

# create folders and set permissions
mkdir -p /opt/gerrit /var/repo
chown -R gerrit /opt/gerrit
chown -R gerrit /var/repo

## java
cd /tmp
tar xvf jdk-8u60-linux-x64.tar.gz
mv jdk1.8.0_60/ /opt/
/usr/sbin/update-alternatives --install /usr/bin/java java /opt/jdk1.8.0_60/bin/java 2
/usr/sbin/update-alternatives --config java
# JDK unlimited strength
unzip -q /tmp/jce_policy-8.zip
cp /tmp/UnlimitedJCEPolicyJDK8/local_policy.jar /opt/jdk1.8.0_60/jre/lib/security/

## git
# configure
git config --global user.name user1
git config --global user.email user1@email.com
git config --global color.ui auto

## nginx
cd /tmp
rpm -ihv GeoIP-data-1.6.5-6.1.x86_64.rpm
rpm -ihv libGeoIP1-1.6.5-6.1.x86_64.rpm
zypper install nginx

## SSL
mkdir -p /etc/nginx/ssl/
cd /etc/nginx/ssl/
openssl genrsa -des3 -out server.key 2048
openssl req -new -key server.key -out server.csr
openssl rsa -in /etc/nginx/ssl/server.key -out /etc/nginx/ssl/server.nocrypt.key
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt

## mysql
zypper install mysql mysql-client
/etc/init.d/mysql start
# alter folder database
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

## apache tomcat
tar -xf apache-tomcat-7.0.64.tar.gz
cp apache-tomcat-7.0.64 /opt/

## gerrit install 
cp /tmp/gerrit-2.11.3.war /opt/apache-tomcat-7.0.64/webapps/gerrit.war
java -XX:-UseCompressedClassPointers -jar /tmp/gerrit-2.11.3.war init -d .
# config
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
# Canonical URL                  [http://ip-url:8080/]: https://<gerrit-ip>/gerrit
# Install plugin download-commands version v2.11.3 [y/N]?y
# Install plugin reviewnotes version v2.11.3 [y/N]?y
# Install plugin singleusergroup version v2.11.3 [y/N]?y
# Install plugin replication version v2.11.3 [y/N]?y
# Install plugin commit-message-length-validator version v2.11.3 [y/N]?y

#stop gerrit
/opt/gerrit/bin/./gerrit.sh stop

# add gitweb in gerrit
git config -f /opt/gerrit/etc/gerrit.config gitweb.cgi /usr/share/gitweb/gitweb.cgi
# copy libs gerrit to tomcat
cp /opt/gerrit/lib/bcprov-jdk15on-151.jar /opt/apache-tomcat-7.0.64/lib/
cp /opt/gerrit/lib/mysql-connector-java-5.1.21.jar /opt/apache-tomcat-7.0.64/lib/
# alter ports tomcat (optional)
# sed -i 's/port="8080"/port="4000"/' /opt/apache-tomcat-7.0.64/conf/server.xml 
# sed -i 's/port="8443"/port="4443"/' /opt/apache-tomcat-7.0.64/conf/server.xml 
# sed -i 's/port="8009"/port="4009"/' /opt/apache-tomcat-7.0.64/conf/server.xml 
# sed -i 's/port="8005"/port="4005"/' /opt/apache-tomcat-7.0.64/conf/server.xml

# add reviewdb in tomcat
vi /opt/apache-tomcat-7.0.64/conf/context.xml

<Resource name="jdbc/reviewdb" auth="Container" type="javax.sql.DataSource"
             maxTotal="100" maxIdle="30" maxWaitMillis="10000"
             username="gerrit" password="Acc1234$$" driverClassName="com.mysql.jdbc.Driver"
             url="jdbc:mysql://localhost:3306/reviewdb"/>

#create setenv.sh             
vi /opt/apache-tomcat-7.0.64/bin/setenv.sh
JAVA_OPTS="-XX:-UseCompressedClassPointers"
CATALINA_OPTS="$CATALINA_OPTS -server -XX:-UseCompressedClassPointers"
CATALINA_OPTS="-Dgerrit.site_path=/opt/gerrit/ -Dorg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=true"
chmod a+x /opt/apache-tomcat-7.0.64/bin/setenv.sh
#start tomcat
/opt/apache-tomcat-7.0.64/bin/startup.sh
