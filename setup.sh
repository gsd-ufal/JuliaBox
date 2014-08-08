#! /usr/bin/env bash
# On Ubuntu 13.04, amd64, Ubuntu provided ami image 
# ami-ef277b86

source ${PWD}/jdockcommon.sh
NGINX_VER=1.7.0.1
NGINX_INSTALL_DIR=/usr/local/openresty
mkdir -p $NGINX_INSTALL_DIR

function usage {
  echo
  echo 'Usage: ./setup.sh -u <admin_username> optional_args'
  echo ' -u  <username> : Mandatory admin username. If -g option is used, this must be the complete Google email-id'
  echo ' -d             : Only recreate docker image - do not install/update other software'
  echo ' -g             : Use Google Openid for user authentication. Options -k and -s must be specified.'
  echo ' -n  <num>      : Maximum number of active containers. Deafult 10.'
  echo ' -t  <seconds>  : Auto delete containers older than specified seconds. 0 means never expire. Default 0.'
  echo ' -k  <key>      : Google OAuth2 key (client id).'
  echo ' -s  <secret>   : Google OAuth2 client secret.'
  echo
  echo 'Post setup, additional configuration parameters may be set in jdock.user '
  echo 'Please see README.md for more details '
  
  exit 1
}

OPT_INSTALL=1
OPT_GOOGLE=0
NUM_LOCALMAX=10 
EXPIRE=0

while getopts  "u:dgn:t:k:s:" FLAG
do
  if test $FLAG == '?'
     then
        usage

  elif test $FLAG == 'u'
     then
        ADMIN_USER=$OPTARG

  elif test $FLAG == 'd'
     then
        OPT_INSTALL=0

  elif test $FLAG == 'g'
     then
        OPT_GOOGLE=1

  elif test $FLAG == 'n'
     then
        NUM_LOCALMAX=$OPTARG

  elif test $FLAG == 't'
     then
        EXPIRE=$OPTARG

  elif test $FLAG == 'k'
     then
        CLIENT_ID=$OPTARG

  elif test $FLAG == 's'
     then
        CLIENT_SECRET=$OPTARG
  fi
done

if test -v $ADMIN_USER
  then
    usage
fi

#echo $ADMIN_USER $OPT_INSTALL $OPT_GOOGLE


if test $OPT_INSTALL -eq 1; then
    # Stuff required for docker and openresty
    sudo apt-get -y install build-essential libreadline-dev libncurses-dev libpcre3-dev libssl-dev netcat git python-setuptools supervisor python-dev python-isodate python-pip

    # INSTALL docker as per http://docs.docker.io/en/latest/installation/ubuntulinux/
    sudo apt-get -y update
    sudo apt-get -y install linux-image-extra-`uname -r`
    sudo sh -c "wget -qO- https://get.docker.io/gpg | apt-key add -"
    sudo sh -c "echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list"
    sudo apt-get -y update
    sudo apt-get -y install lxc-docker

    # docker stuff
    sudo gpasswd -a $USER docker

    # nginx
    echo "Building nginx openresty for install at ${NGINX_INSTALL_DIR} ..."
    sudo mkdir -p /tmp/resty
    sudo wget -P /tmp/resty http://openresty.org/download/ngx_openresty-${NGINX_VER}.tar.gz
    sudo bash -c "cd /tmp/resty; tar -xvzf ngx_openresty-${NGINX_VER}.tar.gz; cd ngx_openresty-${NGINX_VER}; ./configure --prefix=${NGINX_INSTALL_DIR}; make; make install"
    sudo rm -Rf /tmp/resty
    sudo mkdir -p ${NGINX_INSTALL_DIR}/lualib/resty/http
    sudo cp -f libs/lua-resty-http-simple/lib/resty/http/simple.lua ${NGINX_INSTALL_DIR}/lualib/resty/http/

    # python stuff
    sudo easy_install tornado
    sudo easy_install futures
    sudo easy_install google-api-python-client
    sudo pip install PyDrive
    
    git clone https://github.com/dotcloud/docker-py 
    cd docker-py
    sudo python setup.py install
    cd ..

fi

# On EC2 we use the ephemeral storage for the images and the docker aufs filsystem store.
sudo mkdir -p /mnt/docker
sudo service docker stop
if grep -q "^DOCKER_OPTS" /etc/default/docker ; then
  echo "/etc/default/docker has an entry for DOCKER_OPTS..."
  echo "Please ensure DOCKER_OPTS has option '-g /mnt/docker' to use ephemeral storage (on EC2) "
else
  echo "Configuring docker to use /mnt/docker for image/container storage"
  sudo sh -c "echo 'DOCKER_OPTS=\" -g /mnt/docker \"' >> /etc/default/docker"
fi
sudo service docker start

# Wait for the docker process to bind to the required ports
sleep 1

DOCKER_IMAGE=juliabox/juliabox
DOCKER_IMAGE_VER=1
echo "Building docker image ${DOCKER_IMAGE}:${DOCKER_IMAGE_VER} ..."
DOCKER_IMAGE_ID=$(sudo docker build docker/IJulia/)
sudo docker tag ${DOCKER_IMAGE_ID} ${DOCKER_IMAGE}:${DOCKER_IMAGE_VER}
sudo docker tag ${DOCKER_IMAGE_ID} ${DOCKER_IMAGE}:latest

echo "Setting up nginx.conf ..."
sed  s/\$\$NGINX_USER/$USER/g $NGINX_CONF_DIR/nginx.conf.tpl > $NGINX_CONF_DIR/nginx.conf
sed  -i s/\$\$ADMIN_KEY/$1/g $NGINX_CONF_DIR/nginx.conf

echo "Generating random session validation key"
SESSKEY=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c10`
sed  -i s/\$\$SESSKEY/$SESSKEY/g $NGINX_CONF_DIR/nginx.conf 
sed  s/\$\$SESSKEY/$SESSKEY/g $TORNADO_CONF_DIR/tornado.conf.tpl > $TORNADO_CONF_DIR/tornado.conf

if test $OPT_GOOGLE -eq 1; then
    sed  -i s/\$\$GAUTH/True/g $TORNADO_CONF_DIR/tornado.conf
else
    sed  -i s/\$\$GAUTH/False/g $TORNADO_CONF_DIR/tornado.conf
fi
sed  -i s/\$\$ADMIN_USER/$ADMIN_USER/g $TORNADO_CONF_DIR/tornado.conf
sed  -i s/\$\$NUM_LOCALMAX/$NUM_LOCALMAX/g $TORNADO_CONF_DIR/tornado.conf
sed  -i s/\$\$EXPIRE/$EXPIRE/g $TORNADO_CONF_DIR/tornado.conf
sed  -i s,\$\$DOCKER_IMAGE,$DOCKER_IMAGE,g $TORNADO_CONF_DIR/tornado.conf
sed  -i s,\$\$CLIENT_SECRET,$CLIENT_SECRET,g $TORNADO_CONF_DIR/tornado.conf
sed  -i s,\$\$CLIENT_ID,$CLIENT_ID,g $TORNADO_CONF_DIR/tornado.conf


echo
echo "DONE!"

 
 
