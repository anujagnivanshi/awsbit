#! /bin/bash

#LOADING DOMAIN PROPERTIES FILE
. /data02/app/installation_files/scripts/domain.properties.tmp

#################################################################
#         USER AND SERVER VALIDATION
#################################################################
echo -e "#################################################################\n\n"

echo "Starting install_cognos.sh script"

# PRE-REQ CHECK
$SCRIPT_HOME/pre_req_check.sh
if [ $? = 0 ];then 
	echo "Pre-check was successful... Proceeding with the installation"
else 
	echo "Prerequisite check failed.... EXITING"
	exit $?
fi

echo "######install_cognos.sh####### Validating installation SERVER"
CURRENT_SERVER_ADDR=`ifconfig | awk NR==2 | awk '{print $2}' | cut -d':' -f2`
if [ "$CURRENT_SERVER_ADDR" != "$COG_LISTEN_ADDR" -a "$CURRENT_SERVER_ADDR" != "$WEB1_LISTEN_ADDR" -a "$CURRENT_SERVER_ADDR" != "$WEB2_LISTEN_ADDR" ];
then
        echo "**************Running script on wrong server. Server IP does not match with either Cognos CM or GW server IPs"
        echo "**************Exiting Cognos Installation"
        exit 1
fi
echo "######install_cognos.sh####### SERVER Validation Successful"


echo "######install_cognos.sh####### Printing property file domain.properties"
grep -v '^#' $SCRIPT_HOME/domain.properties.tmp
#grep -v '^#' $SCRIPT_HOME/domain.properties.tmp >> $INSTALL_LOG_FILE

echo -e "\n\nPlease verify the properties for correctness...."
#read -p "Continue with the Cognos install (y/n)?"
#if [[ $REPLY != [yY] ]]; then
#        echo "Exiting..."
#        exit 99
#fi


#################################################################
#         COGNOS INITIALIZATION
#################################################################

echo "Creating required Cognos directory structure...."
cd $INSTALLATION_HOME
#cp -R $SCRIPT_HOME/../jdbc/ .
mkdir $INSTALLATION_HOME/jdbc	
cp $ORA64_CLIENT/ojdbc6.jar $INSTALLATION_HOME/jdbc/ojdbc6.jar_11_204_x64
mkdir -p $INSTALLATION_HOME/temp/cognos_install_1021

CM_INSTALL_ATS="Content_Manager_ts-BISRVR-10.2-5000.275-20140513_1553.ats"
CM_UPDATE_ATS="Content_Manager_ts-UPDATE_BISRVR_NC_10.2.5000.1076-10.2-5000.1076-20150125_2056.ats"
GW_INSTALL_ATS="Gateway_ts-BISRVR-10.2-5000.275-20140505_1519.ats"
GW_UPDATE_ATS="Gateway_ts-UPDATE_BISRVR_NC_10.2.5000.1076-10.2-5000.1076-20150125_2055.ats"


#################################################################
#         EXTRACT COGNOS BINARY AND FIX PACK
#################################################################
echo -e "\n\nExtracting Cognos installation Binary...."
cp $SCRIPT_HOME/../cognos/$COGNOS_BINARY $INSTALLATION_HOME/temp
if tar xzf $INSTALLATION_HOME/temp/$COGNOS_BINARY -C $INSTALLATION_HOME/temp/cognos_install_1021
then
	echo "untar $INSTALLATION_HOME/temp/$COGNOS_BINARY successfully"
else
        echo "Error with untar $INSTALLATION_HOME/temp/$COGNOS_BINARY"
        exit $?
fi

if [ $COGNOS_FIXPACK != "" ]; then
	echo "Extracting Cognos Fixpack...."
	mkdir $INSTALLATION_HOME/temp/fixpack
	cp $SCRIPT_HOME/../cognos/$COGNOS_FIXPACK $INSTALLATION_HOME/temp
	if tar xzf $INSTALLATION_HOME/temp/$COGNOS_FIXPACK -C $INSTALLATION_HOME/temp/fixpack
	then 
		echo "untar successfull"
	else
		echo "couldnot untar $INSTALLATION_HOME/temp/$COGNOS_FIXPACK"
		exit $?
	fi
fi


#################################################################
#         CREATE ATS FILES
#################################################################
if [ $CURRENT_SERVER_ADDR == $COG_LISTEN_ADDR ]; then
	echo -e "\n\nProceeding with Cognos Content Manager installation...."
	echo "Creating Installation ATS for Content Manager...."
	cp $SCRIPT_HOME/sample/$CM_INSTALL_ATS $INSTALLATION_HOME/temp/cognos_install.ats
	sed -i "s/REPLACE_SLOT_NAME/$SLOT_NAME/g" $INSTALLATION_HOME/temp/cognos_install.ats
	
	if [ $COGNOS_FIXPACK != "" ]; then
                echo "Creating Update fixpack ATS file"
                cp $SCRIPT_HOME/sample/$CM_UPDATE_ATS $INSTALLATION_HOME/temp/cognos_update.ats
                sed -i "s/REPLACE_SLOT_NAME/$SLOT_NAME/g" $INSTALLATION_HOME/temp/cognos_update.ats
	fi

elif [ $CURRENT_SERVER_ADDR == $WEB1_LISTEN_ADDR -o $CURRENT_SERVER_ADDR == $WEB2_LISTEN_ADDR ];then
        echo -e "\n\nProceeding with Cognos Gateway Installation...."
	echo "Creating Installation ATS for Gateway...."
        cp $SCRIPT_HOME/sample/$GW_INSTALL_ATS $INSTALLATION_HOME/temp/cognos_install.ats
        sed -i "s/REPLACE_SLOT_NAME/$SLOT_NAME/g" $INSTALLATION_HOME/temp/cognos_install.ats
	
	if [ $COGNOS_FIXPACK != "" ]; then
                echo "Creating Update fixpack ATS file for Gateway"
                cp $SCRIPT_HOME/sample/$GW_UPDATE_ATS $INSTALLATION_HOME/temp/cognos_update.ats
                sed -i "s/REPLACE_SLOT_NAME/$SLOT_NAME/g" $INSTALLATION_HOME/temp/cognos_update.ats
	fi
fi


#################################################################
#         COGNOS INSTALLATION
#################################################################

echo "Installing Cognos Binary...."
$INSTALLATION_HOME/temp/cognos_install_1021/linuxi38664h/issetup -s $INSTALLATION_HOME/temp/cognos_install.ats
if [ $? = 0 ];then
        echo -e "Installation is  successful... Proceeding with the update\n"
else
        exit $?
fi

if [ $COGNOS_FIXPACK != "" ]; then
	echo "Installing Fixpack $COGNOS_FIXPACK..."
	$INSTALLATION_HOME/temp/fixpack/linuxi38664h/issetup -s $INSTALLATION_HOME/temp/cognos_update.ats
	if [ $? = 0 ];then
			echo -e "Update was successful... Proceeding with silent configuration.\n"
	else
			exit $?
	fi
else
	echo "No Fix pack provided... Not updating"
fi


#################################################################
#         COGNOS CONTENT MANAGER CONFIGURATION
#################################################################
if [ $CURRENT_SERVER_ADDR == $COG_LISTEN_ADDR ]; then
	cp $ORA64_CLIENT/ojdbc6.jar $INSTALLATION_HOME/cognos1021/c10/webapps/p2pd/WEB-INF/lib/
	cp $ORA64_CLIENT/ojdbc6.jar $INSTALLATION_HOME/cognos1021/c10/tomcat/lib/
	sed -i "s/MaxPermSize=128m/MaxPermSize=384m/g" $INSTALLATION_HOME/cognos1021/c10/bin64/bootstrap_linuxi38664.xml
	sed -i "s/MaxPermSize=128m/MaxPermSize=384m/g" $INSTALLATION_HOME/cognos1021/c10/bin64/cbs_cnfgtest_linuxi38664.xml
	sed -i "s/-Xmx1g/-Xmx1g -XX:MaxPermSize=384m/g" $INSTALLATION_HOME/cognos1021/c10/bin64/cgsServer.sh

	sed -i "s/<Environment name=\"maxExemptions\".*/& \\n   <Resource name=\"jdbc\/workbrain\" auth=\"Container\" type=\"javax.sql.DataSource\" username=\"workbrain\" password=\"workbrain\" driverClassName=\"oracle.jdbc.OracleDriver\" url=\"jdbc:oracle:thin:@$DB_LISTEN_ADDR:${PORT_PRIFIX}051:$DB_SID\" maxActive=\"8\" maxIdle=\"4\" validationQuery=\"SELECT 1 FROM WB_DUMMY\"\/>/g" $INSTALLATION_HOME/cognos1021/c10/tomcat/conf/server.xml

##	echo -e  "\n\nConfiguring tnsnames.ora file"
##  MOVED TNSNAMES FILE EDIT TO SILENT SCRIPT FOR ALL SERVERS 

	#sed -i "s/REPLACE_DB_SID/$DB_SID/g" $ORACLE_HOME/network/admin/tnsnames.ora
	#sed -i "s/REPLACE_DB_LISTEN_ADDR/$DB_LISTEN_ADDR/g" $ORACLE_HOME/network/admin/tnsnames.ora
    #sed -i "s/REPLACE_PORT_PRIFIX/$PORT_PRIFIX/g" $ORACLE_HOME/network/admin/tnsnames.ora

fi


#################################################################
#         COGNOS cogstartup.xml FILE CREATION
#################################################################
echo -e "\n\nConfiguring cogstartup.xml file... "
mv $INSTALLATION_HOME/cognos1021/c10/configuration/cogstartup.xml $INSTALLATION_HOME/cognos1021/c10/configuration/cogstartup.xml_original
if [ $CURRENT_SERVER_ADDR == $COG_LISTEN_ADDR ]; then
	cp $SCRIPT_HOME/sample/sample_CM_cogstartup.xml $INSTALLATION_HOME/cognos1021/c10/configuration/cogstartup.xml
else
	cp $SCRIPT_HOME/sample/sample_GW_cogstartup.xml $INSTALLATION_HOME/cognos1021/c10/configuration/cogstartup.xml
fi
sed -i "s/REPLACE_DB_LISTEN_ADDR/$DB_LISTEN_ADDR/g" $INSTALLATION_HOME/cognos1021/c10/configuration/cogstartup.xml
sed -i "s/REPLACE_CLIENT_ENV/$CLIENT_ENV/g" $INSTALLATION_HOME/cognos1021/c10/configuration/cogstartup.xml
sed -i "s/REPLACE_COG_LISTEN_ADDR/$COG_LISTEN_ADDR/g" $INSTALLATION_HOME/cognos1021/c10/configuration/cogstartup.xml
sed -i "s/REPLACE_CLIENT_URL/$CLIENT_URL/g" $INSTALLATION_HOME/cognos1021/c10/configuration/cogstartup.xml
sed -i "s/REPLACE_DB_SID/$DB_SID/g" $INSTALLATION_HOME/cognos1021/c10/configuration/cogstartup.xml
sed -i "s/REPLACE_PORT_PRIFIX/$PORT_PRIFIX/g" $INSTALLATION_HOME/cognos1021/c10/configuration/cogstartup.xml


#################################################################
#         WFM PACKAGE
#################################################################
echo -e "\n\nExtracting WBBusiness package..."
cp $ISO_HOME/WBBusinessIntelligence* $INSTALLATION_HOME/cognos1021/
unzip -oq $INSTALLATION_HOME/cognos1021/WBBusinessIntelligence* -d $INSTALLATION_HOME/cognos1021/
#rm $INSTALLATION_HOME/cognos1021/WBBusinessIntelligence*


#################################################################
#         COGNOS CONFIG VALIDATION AND STARTUP
#################################################################
if [ $CURRENT_SERVER_ADDR != $COG_LISTEN_ADDR ];then
	echo "Please make sure Cognos BI server is up and running before Continuing with the rest of the installation"
	#read -p "Press any key to continue"
	#sleep 600
fi


$INSTALLATION_HOME/cognos1021/c10/bin64/cogconfig.sh -test
if [ $? -eq 0 -a $CURRENT_SERVER_ADDR == $COG_LISTEN_ADDR ];then
	#### ADDING AUTOSTART COMMAND 
	sed -i "s/.*Starting Application with DB dependency.*/& \\n\\t\\t\\tsu - \$SLOT_NAME -c \"${INSTALLATION_HOME//\//\\/}\/cognos1021\/c10\/bin64\/cogconfig.sh -s\" \&/g" $INSTALLATION_HOME/install_logs/app_autostart_${CLIENT_ENV}
	
	echo "starting Cognos Application Tier..."
	$INSTALLATION_HOME/cognos1021/c10/bin64/cogconfig.sh -s
	sleep 120
	
	# CREATING COGNOS DATASOURCES
	echo -e "\n\nCreating Cognos Datasource..."
	sed -i "s/REPLACE_SCRIPT_HOME/${SCRIPT_HOME//\//\\/}/g" $SCRIPT_HOME/cognos_create_datasource.sh
	echo "$SCRIPT_HOME/cognos_create_datasource.sh -cd http://${COG_LISTEN_ADDR}:${PORT_PRIFIX}233/p2pd/servlet/dispatch -cu workbrain -cp 1 -ds jdbc:oracle:thin:@${DB_LISTEN_ADDR}:${PORT_PRIFIX}051:${DB_SID} -du workbrain -dp workbrain"
	$SCRIPT_HOME/cognos_create_datasource.sh -cd http://${COG_LISTEN_ADDR}:${PORT_PRIFIX}233/p2pd/servlet/dispatch -cu workbrain -cp 1 -ds jdbc:oracle:thin:@${DB_LISTEN_ADDR}:${PORT_PRIFIX}051:${DB_SID} -du workbrain -dp workbrain
	
	#IMPORTING WFM CORE REPORTS
	echo -e "\n\nImporting WFM Cognos Core package..."
	sed -i "s/REPLACE_SCRIPT_HOME/${SCRIPT_HOME//\//\\/}/g" $SCRIPT_HOME/cognos_deploy_reports.sh
	echo "$SCRIPT_HOME/cognos_deploy_reports.sh -c WBStandardReports -a WBStandardReports -d http://${COG_LISTEN_ADDR}:${PORT_PRIFIX}233/p2pd/servlet/dispatch -u workbrain -p 1"
	$SCRIPT_HOME/cognos_deploy_reports.sh -c WBStandardReports -a WBStandardReports -d http://${COG_LISTEN_ADDR}:${PORT_PRIFIX}233/p2pd/servlet/dispatch -u workbrain -p 1
	
fi

echo "Cognos Installation has finished. Please check log files for any Errors"
exit 0


