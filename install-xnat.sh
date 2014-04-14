#!/bin/bash -eu

DEPS=$1
OWNER=$2
GROUP=$3
XNAT_DATA=$4
EXT=$5

if [ ! -f $DEPS/apache-tomcat-7.0.52.tar.gz ]; then
	cd $DEPS
	curl -O http://www.mirrorservice.org/sites/ftp.apache.org/tomcat/tomcat-7/v7.0.52/bin/apache-tomcat-7.0.52.tar.gz
fi
tar xf $DEPS/apache-tomcat-7.0.52.tar.gz -C /opt
TOMCAT_HOME=/opt/apache-tomcat-7.0.52

if [ ! -f $DEPS/xnat-1.6.3.tar.gz ]; then 
	cd $DEPS
	curl -O ftp://ftp.nrg.wustl.edu/pub/xnat/xnat-1.6.3.tar.gz
fi
tar xf $DEPS/xnat-1.6.3.tar.gz -C /opt
XNAT_HOME=/opt/xnat

mkdir $XNAT_DATA

ln -s $DEPS/build.properties $XNAT_HOME

yum install -y postgresql-server
service postgresql initdb
sed -i 's/ident$/trust/' /var/lib/pgsql/data/pg_hba.conf
service postgresql start
createuser -U postgres -S -D -R xnat01
createdb -U postgres -O xnat01 xnat
createlang -U postgres -d xnat plpgsql

yum install -y java-1.7.0-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java

cd $XNAT_HOME
bin/setup.sh -Ddeploy=true
psql -d xnat -f $XNAT_HOME/deployments/xnat/sql/xnat.sql -U xnat01

cd $XNAT_HOME/deployments/xnat
$XNAT_HOME/bin/StoreXML -l security/security.xml -allowDataDeletion true
$XNAT_HOME/bin/StoreXML -dir ./work/field_groups -u admin -p admin -allowDataDeletion true

if [ "$EXT" = "true" ]; then
	test -f $XNAT_HOME/projects/xnat/src/schemas/ext/ext.xsd
	sed -i 's/<!--\(<Data_Model .*\/>\)-->/\1/' $XNAT_HOME/projects/xnat/InstanceSettings.xml
	cd $XNAT_HOME
	bin/update.sh -Ddeploy=true
	psql -d xnat -f $XNAT_HOME/deployments/xnat/sql/xnat-update.sql -U xnat01
fi

chown -R $OWNER.$GROUP $XNAT_HOME $TOMCAT_HOME $XNAT_DATA

RULENUM=$(iptables -L INPUT --line-numbers | grep 'REJECT' | awk '{print $1}')
iptables -I INPUT $RULENUM -m state --state NEW -m tcp -p tcp --dport 8080 -j ACCEPT
service iptables save

su $OWNER $TOMCAT_HOME/bin/startup.sh
