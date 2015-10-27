#!/bin/bash

if [ $# -ne 1 ]
then
    echo "Usage: mk_user_home.sh <data_location>"
    exit 1
fi

DATA_LOC=$1
JUSER_HOME=/tmp/juser
PKG_DIR=/tmp/jpkg
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#SUDO_JUSER="sudo -u#1000 -g#1000"
SUDO_JUSER=""

function error_exit {
	echo "$1" 1>&2
	exit 1
}

sudo rm -rf ${JUSER_HOME}
sudo rm -rf ${PKG_DIR}
mkdir -p ${JUSER_HOME}
mkdir -p ${PKG_DIR}
mkdir -p ${JUSER_HOME}/.juliabox

cp ${DIR}/setup_julia.sh ${JUSER_HOME}

sudo chown -R 1000:1000 ${JUSER_HOME}
sudo chown -R 1000:1000 ${PKG_DIR}
docker run -i -v ${JUSER_HOME}:/home/juser -v ${PKG_DIR}:/opt/julia_packages -e "JULIA_PKGDIR=/opt/julia_packages/.julia" --entrypoint="/home/juser/setup_julia.sh" juliabox/juliabox:latest || error_exit "Could not run juliabox image"

sudo chown -R 1000:1000 ${JUSER_HOME}
sudo chown -R 1000:1000 ${PKG_DIR}
${SUDO_JUSER} rm ${JUSER_HOME}/setup_julia.sh

${SUDO_JUSER} cp ${DIR}/IJulia/ipython_notebook_config.py ${JUSER_HOME}/.ipython/profile_default/ipython_notebook_config.py
${SUDO_JUSER} cp ${DIR}/IJulia/custom.css ${JUSER_HOME}/.ipython/profile_default/static/custom/custom.css
${SUDO_JUSER} cp ${DIR}/IJulia/custom.js ${JUSER_HOME}/.ipython/profile_default/static/custom/custom.js

# install RISE (slideshow plugin)
#${SUDO_JUSER} cd /home/juser && git clone https://github.com/damianavila/RISE.git && cd RISE && git checkout -b 3.x 3.x && python setup.py install && cd .. && rm -rf RISE

${SUDO_JUSER} cp -R ${DIR}/IJulia/tornado ${JUSER_HOME}/.juliabox/tornado
${SUDO_JUSER} cp ${DIR}/IJulia/supervisord.conf ${JUSER_HOME}/.juliabox/supervisord.conf
${SUDO_JUSER} cp -R ${DIR}/IJulia/tutorial ${JUSER_HOME}/.juliabox/tutorial

sudo rm ${DATA_LOC}/julia_packages.tar.gz
sudo tar -czf ${DATA_LOC}/julia_packages.tar.gz -C ${PKG_DIR} .

sudo rm ${DATA_LOC}/user_home.tar.gz
sudo tar -czf ${DATA_LOC}/user_home.tar.gz -C ${JUSER_HOME} .

sudo rm -rf ${JUSER_HOME}
sudo rm -rf ${PKG_DIR}
for id in `docker ps -a | grep Exited | cut -d" " -f1 | grep -v CONTAINER`
do
    echo "removing $id..."
    docker rm $id
done
