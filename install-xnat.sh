#!/bin/bash -eux

DEPS=$1
XNAT_DATA=$2
EXT=$3

OWNER=xnat01
PASSWORD=xnat01

sudo adduser --system --no-create-home $OWNER

if [ ! -f $DEPS/apache-tomcat-7.0.53.tar.gz ]; then
	cd $DEPS
	curl -O http://www.mirrorservice.org/sites/ftp.apache.org/tomcat/tomcat-7/v7.0.53/bin/apache-tomcat-7.0.53.tar.gz
fi
tar xf $DEPS/apache-tomcat-7.0.53.tar.gz -C /opt
TOMCAT_HOME=/opt/apache-tomcat-7.0.53

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
sudo -u postgres psql -c "CREATE ROLE $OWNER PASSWORD '$PASSWORD' NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT LOGIN;"
sudo -u postgres createdb -O $OWNER xnat

apt-get install -y openjdk-7-jdk
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64

cd $XNAT_HOME
bin/setup.sh -Ddeploy=true
exit 0
sudo -u $OWNER psql -d xnat <$XNAT_HOME/deployments/xnat/sql/xnat.sql

cd $XNAT_HOME/deployments/xnat
$XNAT_HOME/bin/StoreXML -l security/security.xml -allowDataDeletion true
$XNAT_HOME/bin/StoreXML -dir ./work/field_groups -u admin -p admin -allowDataDeletion true

if [ "$EXT" = "true" ]; then
	test -f $XNAT_HOME/projects/xnat/src/schemas/ext/ext.xsd
	sed -i 's/<!--\(<Data_Model .*\/>\)-->/\1/' $XNAT_HOME/projects/xnat/InstanceSettings.xml
	cd $XNAT_HOME
	bin/update.sh -Ddeploy=true
	sudo -u $OWNER psql -d xnat <$XNAT_HOME/deployments/xnat/sql/xnat-update.sql
fi

chown -R $OWNER $XNAT_HOME $TOMCAT_HOME $XNAT_DATA

sudo -u $OWNER $TOMCAT_HOME/bin/startup.sh
