## Requirements
### Icinga IDOUtils
Installed via source or packages, the database backend will be used. 

For additional Documentation refer to: https://www.icinga.com/docs/icinga2/latest/doc/02-getting-started/#installing-the-ido-modules-for-mysql

Validate IDOUtils
```
$ icinga2 feature list
Enabled features: [...] ido-mysql [...]

$ grep -Po "information.*MySQL IDO instance id.*" /var/log/icinga2/icinga2.log
information/IdoMysqlConnection: MySQL IDO instance id: 1 (schema version: '1.xx')
```

#### MySQL/MariaDB
Starting with Icinga 1.8 there is a function providing all needed sla-information. This function needs to installed in addition to the jasper base packages.

Import the function into your existing IDOUtils database.
```sh
$ mysql icinga < icinga-reports/db/icinga/mysql/availability.sql
```
as well as make sure your db user has the correct GRANT for EXECUTE.
```mysql
$ mysql -u root -p
> GRANT EXECUTE ON icinga.* To <username>@<host>;
```

### JasperServer
! Minimum supported JasperServer Version 6.1.0 !
 
Depending on your architecture (uname -a), fetch the appropriate installer - below is x64

Refer to http://community.jaspersoft.com/project/jasperreports-server/releases for latest Release and additional documentation.

```sh
$ wget https://sourceforge.net/projects/jasperserver/files/JasperServer/JasperReports%20Server%20Community%20Edition%206.4.0/TIB_js-jrs-cp_6.4.0_linux_x86_64.run

$ chmod +x jasperreports-server-cp-6.4.0-linux-x64-installer.run
$ sudo ./jasperreports-server-cp-6.4.0-linux-x64-installer.run
> Agree to license
> select bundled tomcat
> select bundled postgresql
> select a different postgresql port, like 5433 not to interfere with existing setups
> install sample reports
```
The installer will automatically create the needed database, create the schema and install samples.

! The default install location will be /opt/jasperreports-server-cp-6.4.0/ - so make sure to work on the correct jasperserver if you are doing an upgrade !

#### Start
```
$ /opt/jasperreports-server-cp-5.0.0/ctlscript.sh start
```
For individual components
```
$ /opt/jasperreports-server-cp-5.0.0/ctlscript.sh postgresql start|stop
$ /opt/jasperreports-server-cp-5.0.0/ctlscript.sh tomcat start|stop
```
### Java

jasperserver its bundled java binaries, but we need javac (compiler) for icinga-reports helper functions. 
We need this only for the install process, you can erase these packages on a running Server.

Install the required packages with:
#### CentOS/RHEL
```
$ sudo yum install java-1.7.0-openjdk-devel
```
#### Debian/Ubuntu
```
$ sudo aptitude install openjdk-7-jdk 
```
#### Test:
```
$ javac -version
```

## Icinga Reporting
As from Icinga 1.6 on, the package provides configure and make scripts.

Either download from sourceforge and extract, or get the latest developer snapshot from git. 
Note: Versions will differ depending on releases

icinga-reports 1.10 is the last Release which has been optimized for icinga1.
As from icinga-report 1.14 is optimized for icinga2 and jasper Studio when it comes to design.

### Download sources

```
$ git clone https://github.com/Icinga/icinga-reports.git ; cd icinga-reports
```
or
```
$ wget http://sourceforge.net/projects/icinga/files/icinga-reporting/1.14.0/icinga-reports-1.14.0.tar.gz ; tar xzf icinga-reports-1.14.0.tar.gz; cd icinga-reports-1.14.0
```

Default branch is master, which contains latest developement. For a special Verion checkout its tag.
```
$ git checkout v1.xx.x
```

If a developer told you to use his/her branch, check that out with
```
$ git branch localbranch origin/devhead/devbranch
$ git checkout localbranch
$ git log
```

### Configure
If you did not install the JasperServer into the default prefix before, you need to tell configure the location.
```
$ ./configure --with-jasper-server=/opt/jasperreports-server-cp-6.4.0
```
### Setup
Invoke 'make' without params to get a full list of available options.

#### Install
make install will copy all reports and compile and install all necessary jar files.
! Jasperserver must be running !
```
$ make install
```
or as update
```
$ make update
```
Restart the Tomcat server
```
$ /opt/jasperreports-server-cp-6.4.0/ctlscript.sh stop tomcat
$ /opt/jasperreports-server-cp-6.4.0/ctlscript.sh start tomcat
```
#### install-jar-files
Test if jar file is installed:
```
$ ls /opt/jasperreports-server-cp-6.4.0/apache-tomcat/webapps/jasperserver/WEB-INF/lib/icinga-reporting.jar
```
install them separately:
```
$ make install-jar-files
```

