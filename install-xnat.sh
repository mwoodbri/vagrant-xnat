#!/bin/bash -eu

DEPS=$1
OWNER=$2
XNAT_DATA=$3
EXT=$4

DB_NAME=xnat
DB_USER=$OWNER
DB_PASS=xnat

sudo adduser --system --no-create-home $OWNER

TOMCAT_VERSION=7.0.54
if [ ! -f $DEPS/apache-tomcat-$TOMCAT_VERSION.tar.gz ]; then
	cd $DEPS
	curl -O http://www.mirrorservice.org/sites/ftp.apache.org/tomcat/tomcat-7/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz
fi
tar xf $DEPS/apache-tomcat-$TOMCAT_VERSION.tar.gz -C /opt
TOMCAT_HOME=/opt/apache-tomcat-$TOMCAT_VERSION

if [ ! -f $DEPS/xnat-1.6.3.tar.gz ]; then 
	cd $DEPS
	curl -O ftp://ftp.nrg.wustl.edu/pub/xnat/xnat-1.6.3.tar.gz
fi
tar xf $DEPS/xnat-1.6.3.tar.gz -C /opt
XNAT_HOME=/opt/xnat

mkdir $XNAT_DATA

ln -s $DEPS/build.properties $XNAT_HOME

apt-get update

apt-get -y install postgresql-9.3
sudo -u postgres psql -c "CREATE ROLE $DB_USER PASSWORD '$DB_PASS' NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT LOGIN;"
sudo -u postgres createdb -O $DB_USER $DB_NAME

apt-get install -y openjdk-7-jdk
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64

cd $XNAT_HOME
bin/setup.sh -Ddeploy=true
sudo -u $OWNER psql -d $DB_NAME <$XNAT_HOME/deployments/xnat/sql/xnat.sql

cd $XNAT_HOME/deployments/xnat
$XNAT_HOME/bin/StoreXML -l security/security.xml -allowDataDeletion true
$XNAT_HOME/bin/StoreXML -dir ./work/field_groups -u admin -p admin -allowDataDeletion true

if [ "$EXT" = "true" ]; then
	test -f $XNAT_HOME/projects/xnat/src/schemas/ext/ext.xsd
	sed -i 's/<!--\(<Data_Model .*\/>\)-->/\1/' $XNAT_HOME/projects/xnat/InstanceSettings.xml
	cp -r $DEPS/src $XNAT_HOME/projects/xnat
	cd $XNAT_HOME
	bin/update.sh -Ddeploy=true
	sudo -u $OWNER psql -d $DB_NAME <$XNAT_HOME/deployments/xnat/sql/xnat-update.sql
fi

chown -R $OWNER $XNAT_HOME $TOMCAT_HOME $XNAT_DATA

sudo -u $OWNER $TOMCAT_HOME/bin/startup.sh
