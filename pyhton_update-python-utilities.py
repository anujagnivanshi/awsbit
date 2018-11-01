#!/usr/bin/python
# -*- coding: utf-8 -*-
"""
(c) 2016 test, inc. All Rights Reserved
"""
from sys import platform as _platform
import logging.handlers as handlers
from logging import info, error,warning
import logging
import urllib2
import subprocess
import shlex

import os
import sys
import argparse
from datetime import datetime

logger=logging.getLogger()
debug=0
FLAG = False

try:
    strlogfolder=None
    if _platform == "linux" or _platform == "linux2":
        strlogfolder = "/usr/local/testbc/log"
        BASE_PATH = "/usr/local/testbc"
        # linux
    elif _platform == "darwin":
        strlogfolder = "C:/testbc/log"
        BASE_PATH = "C:/testbc"
        # OS X
    elif _platform == "win32":
        strlogfolder = "C:/testbc/log"
        BASE_PATH = "C:/testbc"
    #strwinfolder = "C:/cwi/wininit.params"
    #sinstanceurl = "http://169.254.169.254/latest/meta-data/instance-id/"
    #strregionlink = 'http://169.254.169.254/latest/meta-data/placement/availability-zone/'
    sawslogexpirirydate = os.environ.get('AWS_LOGEXPIRYDAYS',30)

    debug=0
    #Log defining testmation.
    strdate = datetime.now().strftime("%d-%b-%Y")

    if not os.path.exists(strlogfolder):
        os.makedirs(strlogfolder)
    if not os.path.exists(strlogfolder + '/' + strdate):
        os.makedirs(strlogfolder + '/' + strdate)
    log_file = strlogfolder + '/' + strdate +'/update-python-utilities.log'

    if not os.path.exists(log_file):
        open(log_file, 'w').close()
    logger=logging.getLogger()
    logger_fh = handlers.RotatingFileHandler(log_file, maxBytes=10485760, backupCount=10)
    if debug:
        logger.setLevel(logging.DEBUG)
        logger_fh.setLevel(logging.DEBUG)
    else:
        logger.setLevel(logging.INFO)
        logger_fh.setLevel(logging.INFO)

    LogfileFormatter = logging.Formatter('%(asctime)s [%(levelname)-8s] %(funcName)s %(message)s')
    logger_fh.setFormatter(LogfileFormatter)
    logger.addHandler(logger_fh)

except Exception, ex:
    error('##################Error################')
    error(ex)
    error("Error occurred while running the Script. please contact administrator")

def main(packagesList):
    global FLAG
    info("Installing Pip...")
    print "Installing Pip..."
    if _platform == "linux" or _platform == "linux2":
        info("Processing for Linux machine...")
        try:
            import pip
            info("Pip already available in this machine, proceeding to install packages")
            print "Pip already available in this machine, proceeding to install packages"
        except ImportError,ex:
            info("Pip not installed in sys, installing pip")
            subprocess.call("yum -y install python-pip", shell=True)
            try:
                import pip
            except ImportError,ex:
                subprocess.call("sudo wget https://s3.amazonaws.com/stack-utilities/pip/get-pip.py", shell=True)
                subprocess.call("sudo python get-pip.py", shell=True)
                FLAG = True
        except Exception, ex:
            error("#############error################")
            print "#############error################"
            error("Unexpected error occurred in installing pip, Please contact administrator")
            print "Unexpected error occurred in installing pip, Please contact administrator"
            error(ex)
            print ex
            sys.exit(1)
    elif _platform == "win32":
        info("Processing for windows machine...")
        try:
            import pip
            info("Pip already available in this machine, proceeding to install packages")
            print "Pip already available in this machine, proceeding to install packages"
        except ImportError,ex:
            info("Pip not installed in sys, installing pip")
            response = urllib2.urlopen('https://s3.amazonaws.com/stack-utilities/pip/get-pip.py').read()
            output = open('C:\testbc\lib\standard\get-pip.py','wb')
            output.write(response)
            output.close()
            subprocess.call("C:\Python27\python.exe C:\testbc\lib\standard\get-pip.py", shell=True)
            # subprocess.call('$env:Path = "C:\Python27";', shell=True)
            # subprocess.call('$env:Path = "C:\Python27\Scripts";', shell=True)
        except Exception, ex:
            error("#############error################")
            print "#############error################"
            error("Unexpected error occurred in installing pip, Please contact administrator")
            print "Unexpected error occurred in installing pip, Please contact administrator"
            error(ex)
            print ex
            sys.exit(1)
    else:
        error("Currently we are not supporting this OS, please contact administrator")
        print "Currently we are not supporting this OS, please contact administrator"
        error(_platform)
        print _platform
        sys.exit(1)
    import pip
    installed_packages = pip.get_installed_distributions()
    installed_package_names = {}
    for package in installed_packages:
        installed_package_names[package.project_name] = package.version
    print installed_package_names
    info(installed_package_names)
    for packageInfo in packagesList:
        package_details = packageInfo.split('=')
        if len(package_details) == 2:
            info("Trying to install package :"+str(package_details[0])+", version:"+str(package_details[1]))
            if package_details[0] in installed_package_names.keys():
                if package_details[1] == installed_package_names[package_details[0]]:
                    info("Package installed and version is as required, hence skipping")
                else:
                    info("Package installed but Version is not matching.")
                    info("package :"+str(package_details[0])+", version:"+str(package_details[1]))
                    if _platform == "linux" or _platform == "linux2":
                        if FLAG:
                            command = "/usr/local/bin/pip install "+str(package_details[0])+"=="+str(package_details[1])
                        else:
                            command = "/usr/bin/pip install "+str(package_details[0])+"=="+str(package_details[1])
                    else:
                        command = "C:\Python27\Scripts\pip install "+str(package_details[0])+"=="+str(package_details[1])
                    info("Command: "+str(command))
                    print "Command: "+str(command)
                    try:
                        subprocess.call(command, shell=True)
                        info('---Package installed successfully---')
                    except Exception, ex:
                        warning("#####Warning#####")
                        warning("Unable to install package, proceeding with next package")
                        warning(ex)
                info("Package already installed:"+str(package_details[0]))
            else:
                info("package not installed, Installing Package:"+str(package_details[0]))
                if _platform == "linux" or _platform == "linux2":
                    if FLAG:
                        command = "/usr/local/bin/pip install "+str(package_details[0])+"=="+str(package_details[1])
                    else:
                        command = "/usr/bin/pip install "+str(package_details[0])+"=="+str(package_details[1])
                else:
                    command = "C:\Python27\Scripts\pip install "+str(package_details[0])+"=="+str(package_details[1])

                info("Command: "+str(command))
                print "Command: "+str(command)
                try:
                    subprocess.call(command, shell=True)
                    info('---Package installed successfully---')
                except Exception, ex:
                    warning("#####Warning#####")
                    warning("Unable to install package, proceeding with next package")
                    warning(ex)
        elif len(package_details) == 1:
            info("Trying to install package :"+str(package_details[0])+", No version mentioned ")
            if package_details[0] in installed_package_names.keys():
                info("Package installed and version not mentioned, hence skipping")
            else:
                if _platform == "linux" or _platform == "linux2":
                    if FLAG:
                        command = "/usr/local/bin/pip install "+str(package_details[0])+"=="+str(package_details[1])
                    else:
                        command = "/usr/bin/pip install "+str(package_details[0])
                else:
                    command = "C:\Python27\Scripts\pip install "+str(package_details[0])
                info("Command: "+str(command))
                print "Command: "+str(command)
                try:
                    subprocess.call(command, shell=True)
                    info('---Package installed successfully---')
                except Exception, ex:
                    warning("#####Warning#####")
                    warning("Unable to install package, proceeding with next package")
                    warning(ex)
        else:
            warning("###Warning###")
            warning("There is error in argument you have passed, please check and retry")
            warning("Skipping this Package and proceeding with next package")


if __name__ == "__main__":
    info(":::Update Python Utilities started:::")
    parser = argparse.ArgumentParser()
    parser.add_argument('-packages', '--packages', dest='packages'
                    , default=None,
                    help='Please provide Package Name'
                    )
    args = parser.parse_args()
    if not args.packages:
        print "Please mention atleast one python utility to install"
        error("Please mention atleast one python utility to install")
        sys.exit(1)
    packagesList = args.packages.split(",")
    print packagesList

    try:
        main(packagesList)
        info("####Python utilities are installed successfully####")
    except Exception,ex:
        error("##################Error################")
        error("Error occurred while running the Script. please contact administrator")
        print "Error occurred while running the Script. please contact administrator"
        print ex
        error(ex)
        sys.exit(1)