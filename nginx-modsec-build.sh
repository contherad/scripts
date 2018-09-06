#/bin/bash

#This script installs and Modsecurity v3 as a dynamic module on a centos server that has nginx 1.14.0 installed and running from yum install. 
#After this script is run the you must turn on modsecurity in the conf file and configure modsecurity conf file for rules you would like used. 
#Step 6.3 and Step 6.4 from https://www.nginx.com/blog/compiling-and-installing-modsecurity-for-open-source-nginx/
#Test with step 6.5



cd /opt/

#Step 1: Install Dependencies

yum groupinstall -y 'Development Tools'
yum install -y yum-utils autoconf automake git wget libtool pkgconfig libxml2-devel lmdb-devel pcre-devel geoip-devel libcurl-devel openssl-devel

#Step 2: Download and Compile ModSec v3.
git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity
cd /opt/ModSecurity
git submodule init
git submodule update
/opt/ModSecurity/build.sh
/opt/ModSecurity/configure
make
make install

#Step 4: Download the NGINX Connector for ModSec and Compile it as a Dynamic Module
cd /opt/
git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git
wget http://nginx.org/download/nginx-1.14.0.tar.gz
tar zxvf nginx-1.14.0.tar.gz
cd /opt/nginx-1.14.0
/opt/nginx-1.14.0/configure --with-compat --add-dynamic-module=../ModSecurity-nginx
make modules
cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules


#Step 5: Load the NGINX ModSecurity Connector Dynamic Module
grep -q -F 'load_module modules/ngx_http_modsecurity_module.so;' /etc/nginx/nginx.conf || echo 'load_module modules/ngx_http_modsecurity_module.so;' | cat - /etc/nginx/nginx.conf > /tmp/out && mv /tmp/out /etc/nginx/nginx.conf
#sed -i '1s/^/load_module modules\/ngx_http_modsecurity_module.so;\n /' /etc/nginx/nginx.conf
nginx -t

#Step 6: Configure, Enable, and Test ModSecurity
if [ -d /etc/nginx/modsec ]
then
	echo "Folder Exists"
else
	mkdir /etc/nginx/modsec
fi

if [ -f /etc/nginx/modsec/modsecurity.conf-recommended ]
then
	echo "File Exists"
else
	wget -P /etc/nginx/modsec/ https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended
fi

if [ -f /etc/nginx/modsec/modsecurity.conf ]
then
	echo "files exist"
else
	mv /etc/nginx/modsec/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf
fi

nginx -t
