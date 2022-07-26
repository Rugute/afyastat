#!/bin/sh

sudo apt update
sudo apt install ansible
sudo ansible-playbook install_afyastat.yml
#################Update openmrs global_property ###########################################################################################################

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
