#!/bin/sh
# Script to setup AfyaStat
###########################################################################################################################################################################################
###############################################################AfyaStat Intallation #######################################################################################################

echo "Please wait !!!"
if [ -d "/opt/medic" ] 
then
    echo "Directory /opt/medic exists." 
    sudo rm -rf /opt/afyastat/
    echo "Deleting old medic Folder"
    echo "Creating new medic folder"
    sudo mkdir /opt/afyastat
    echo "Done Creating medic folder"
else
    echo "Error: Directory /opt/medic does not exists."
    echo "Creating new medic folder"
    sudo mkdir /opt/afyastat
    echo "Done Creating medic folder"
fi

sudo cp -R medic /opt/afyastat/
sudo chmod -R 777 /opt/afyastat*
#Reading a static IP address from the Afyastat Server
hostname -I
STIP=$(hostname -I)

echo $STIP
echo "Server Static IP Address is $STIP."   

sudo lsof -i :53

#Adding Ip address to etc/host
#Static IP for my server

echo "$STIP  dns.hmislocal.org" >> /etc/hosts
echo "$STIP  cht.hmislocal.org" >> /etc/hosts

#Copy Certs to tls-certs
#sudo rsync /certs/*  /opt/afyastat/medic/tls-certs


#Preparing certs for use by concatenating them as needed:

sudo chmod -R 777 /opt/afyastat/medic/tls-certs*

sudo cat /opt/afyastat/medic/tls-certs/hmislocal.key /opt/afyastat/medic/tls-certs/hmislocal.crt > /opt/afyastat/medic/tls-certs/lighttpd.key.and.pem.pem
sudo cat /opt/afyastat/medic/tls-certs/hmislocal.crt /opt/afyastat/medic/tls-certs/bundle.crt > /opt/afyastat/medic/tls-certs/server.chained.pem

sudo chmod -R 777 /opt/afyastat/medic/tls-certs*

#make pi-hole-docker-compose.yml WEBPASSWORD universal test123 ####### Changed Timezone to Kenya
#installing docker compose
echo "Please wait Installing Docker Compose"

sudo apt install curl -y
sudo apt update
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu  $(lsb_release -cs)  stable"
sudo apt update
sudo apt-get install docker-ce
sudo docker --version
sudo systemctl start docker

# installing Pi-hole on docker
echo "Please wait Installing Pi-Hole"
sudo docker-compose -f /opt/afyastat/medic/pi-hole-docker-compose.yml up --detach

#Opening Pi-Hole on browser 
xdg-open https://dns.hmislocal.org:8443/admin

#Exporting the DOCKER_COUCHDB_ADMIN_PASSWORD
echo "DOCKER_COUCHDB_ADMIN_PASSWORD=cb6f4d4b-73cc-4c42-97cb-0db5a631190a" >> /etc/environment
echo "COUCH_URL=http://medic:cb6f4d4b-73cc-4c42-97cb-0db5a631190a@localhost:5988/medic" >> /etc/environment
echo "COUCH_NODE_NAME=onode@nohost" >> /etc/environment

echo "Done setting  DOCKER_COUCHDB_ADMIN_PASSWORD"
echo "Setting DOCKER_COUCHDB_ADMIN_PASSWORD"

#Assign vakues to Varibles below before restarting machine

DOCKER_COUCHDB_ADMIN_PASSWORD=cb6f4d4b-73cc-4c42-97cb-0db5a631190a
COUCH_URL=http://medic:cb6f4d4b-73cc-4c42-97cb-0db5a631190a@localhost:5988/medic
COUCH_NODE_NAME=onode@nohost

echo $DOCKER_COUCHDB_ADMIN_PASSWORD
echo $COUCH_URL
echo $COUCH_NODE_NAME

sudo docker-compose -f /opt/afyastat/medic/cht-docker-compose-local-host.yml up --detach

#Check if docker is running
sudo docker ps -a
#Copy nginx File to Medic-os Container

sudo docker cp  /opt/afyastat/medic/nginx.conf  medic-os:/srv/settings/medic-core/nginx/nginx.conf

# sudo docker cp medic-os:/srv/settings/medic-core/nginx/nginx.conf /opt/afyastat/nginx.conf
#Enter medic-os container
#sudo docker exec -it medic-os /bin/bash
#Restart Exit the nginx.conf and restart the web server
#sudo /boot/svc-restart medic-core nginx
echo "Restarting Medic-os Container just relax"
sudo docker restart medic-os
echo "Done Restarting Medic-os Container just relax"
#check if the server is up
echo "Accessing the server url then uploading Forms"

#################################################################################################################################################################################
################################# UPLOADING FORMS ###############################################################################################################################

sudo apt update
sudo apt install nodejs
sudo apt install npm
sudo npm -v
sudo npm install -g medic-conf@3.6.0
sudo python -m pip install 
git+https://github.com/medic/pyxform.git@medic-conf-
1.17#egg=pyxform-medic


cd 'AfyaStatForms'
#Add Afyastat Form after the server is up, we are retrying after every 30 Seconds
echo "Kindly wait for system to start !!!"
i=1

while :;
do
  echo "Number of trials: $i"
  ((i++))

if curl -I "http://localhost:5988" 2>&1 | grep -w "200\|301" ; then

echo "Uploading AfyaStat forms please wait ..."
medic-conf --url=https://medic:cb6f4d4b-73cc-4c42-97cb-0db5a631190a@localhost:7200 upload-app-settings delete-all-forms upload-app-forms upload-contact-forms upload-resources upload-custom-translations --accept-self-signed-certs

  echo "AfyaStat Server is now ready"
break
else
  echo "AfyaStat Server not Reachable. Please wait it's coming up in a while..."
fi
sleep 30
done

echo 'All Done!'

#################################################################################################################################################################################
#######################################Update openmrs global_property ###########################################################################################################

# MySQL settings
mysql_user="root"
mysql_password="test12"
mysql_base_database="openmrs"
mysql_information_schema_database="information_schema"
echo "Updating openmrs global_properties"
mysql --user=${mysql_user} --password=${mysql_password} ${mysql_base_database} -e "update global_property set property_value ='cb6f4d4b-73cc-4c42-97cb-0db5a631190a'  where property='medic.chtPwd';"
mysql --user=${mysql_user} --password=${mysql_password} ${mysql_base_database} -e "update global_property set property_value ='https://localhost:7200/medic_bulk_docs'  where property='medic.chtServerUrl';"
mysql --user=${mysql_user} --password=${mysql_password} ${mysql_base_database} -e "update global_property set property_value ='medic'  where property='medic.chtUser';"
echo "Done updating the global_property"

echo "Setup Completed"
