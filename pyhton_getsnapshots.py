#!/usr/bin/python
# -*- coding: utf-8 -*-
"""
(c) 2016 test, inc. All Rights Reserved
"""
from sys import platform as _platform
import logging.handlers as handlers
from logging import info, error,warning
import logging
from random import randint

import os
import sys
import argparse
from datetime import datetime
import re
import time

import boto3
from boto3.session import Session
from botocore import exceptions

def ec2_connection(region):
    session = Session(region_name=region)
    return session


logger=logging.getLogger()
debug=0
BASE_PATH = "/usr/local/testbc"
FILE_NAME = "getsnapshots"+datetime.now().strftime("%Y%b%d%M%S")+".txt"
MAX_ATTEMPTS = 5
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
    log_file = strlogfolder + '/' + strdate +'/snapshot-details.log'

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
    sys.exit(1)
def createDirectory(dirPath):
    """
    Function to check if folder exists or not and creates if not exists
    :param dirPath: directory path
    :return: Boolean False if directory already exists or Directory Path if newly created
    """
    if not os.path.exists(dirPath):
        try:
            os.makedirs(dirPath)
            writeFile(os.path.join(dirPath,FILE_NAME),"Region|Customer Prefix|VPC ID|Machine Label|Volume ID|Snapshot ID|Backup Date|Expired Date|No of Days Old")
            return dirPath
        except OSError as exception:
            error('##################Error################')
            error(exception)
            raise error("There is a error in BASE_PATH. Check the Path you defined in file")
            sys.exit(1)
    else:
        if not os.path.isfile(os.path.join(dirPath,FILE_NAME)):
            try:
                writeFile(os.path.join(dirPath,FILE_NAME),"Region|Customer Prefix|VPC ID|Machine Label|Volume ID|Snapshot ID|Backup Date|Expired Date|No of Days Old")
            except Exception,ex:
                error('##################Error################')
                error(ex)
                error("Error occurred while Writing the File. please contact administrator")
        # writeFile(os.path.join(dirPath,FILE_NAME),"Region|Customer Prefix|VPC ID|Machine Label|Volume Id|Snapshotid|Backup Date|Expiry Date|No.of days old")





def writeFile(fileName,content):
    """
    This function writes the content to the file, Also one new line will be inserted at the end
    :param fileName: Complete valid file name
    :param content: text that need to write to file
    :return:None
    """
    try:
        file = open(fileName,"a")
        file.write(content+"\n")
    except Exception,ex:
        error('##################Error################')
        error(ex)
        raise error("Unable to Open the File. Please contact administrator")
    finally:
        file.close()

def getVpcIdByInstanceId(connection,instanceId):
    info(instanceId)
    vpcId = 'None'
    try:
        res = connection.describe_instances(InstanceIds=[instanceId])
        vpcId = res['Reservations'][0]['Instances'][0]['VpcId']
    except Exception,ex:
        warning('###########')
        warning(ex)
    return vpcId



def getVpcId(connection, volumeId, snapshotId):
    info(volumeId)
    vpcId = 'None'
    response = {}
    try:
        response = connection.describe_volumes(VolumeIds=[volumeId])
    except Exception,ex:
        warning("This Volume has been deleted, Volume Id:"+str(volumeId))
        warning(ex)
        return vpcId
    try:
        info('Getting VPC id via Instance')
        vpcId = getVpcIdByInstanceId(connection,response['Volumes'][0]['Attachments'][0]['InstanceId'])

    except Exception,ex:
        error("This Volume has been deleted, Volume Id:"+str(volumeId))
        error(ex)
    return vpcId


def processSnapshots(connection,region, elements,outputfile):
    """
    THis Function takes the Snapsshots  data in JSON formmat(Boto3) and checks for expired snapshots, Writes details in file if expired
    :param connection: Boto3 connection object
    :param region: current regiona name
    :param elements: boto3 snapshots list
    :param outputfile: destination output directory
    :return:
    """
    global FILE_NAME
    global FLAG
    regex = re.compile("ExpiryDate:(.*)")
    regex_vpc = re.compile("(vpc-.*?)-.*")
    regex_backupdate = re.compile("CreatedDate:(.*)\|.*")
    todaydate = datetime.today().date()

    for element in elements:
        # print element
        if element['Description'].find("CreateImage") == -1:
            tags = element.get('Tags',[])
            if len(tags) != 0:
                tags_modified = {}
                if element['SnapshotId'] == 'snap-ac695268':
                    print 'debug'
                for tag in tags:
                    tags_modified[tag['Key']] = tag['Value']
                if 'BackupInfo' in tags_modified.keys():
                    backUpInfo = tags_modified.get('BackupInfo','None')
                    matchStr = regex.search(backUpInfo)
                    if matchStr is not None:
                        expiryDate = datetime.strptime(matchStr.group(1).strip(),"%d-%b-%Y").date()
                        diff = (todaydate - expiryDate).days
                        expiryDate = expiryDate.strftime("%Y-%b-%d")
                        if diff > 0:
                            FLAG = True
                            customerPrefix = tags_modified.get('customerPrefix','None')
                            dir_path = os.path.join(outputfile,datetime.now().strftime("%Y-%b-%d"))
                            vpc_id_str = tags_modified.get('masterSnapshotID','None')
                            vpcmatchStr = regex_vpc.search(vpc_id_str)
                            if vpcmatchStr is not None:
                                vpc_id_str = vpcmatchStr.group(1)
                            else:
                                vpc_id_str = getVpcId(connection, element['VolumeId'], element['SnapshotId'])
                            backupdateStr = regex_backupdate.search(backUpInfo)
                            if backupdateStr is not None:
                                backupDateValue = backupdateStr.group(1)
                            else:
                                backupDateValue = 'None'
                            try:
                                # info("*******************")
                                # info(dir_path)
                                createDirectory(dir_path)
                            except Exception,ex:
                                error('##################Error################')
                                error(ex)
                                error("Error occurred while running the Script. please contact administrator")
                            LineString = str(region)+"|"+str(customerPrefix)+"|"+str(vpc_id_str)+"|"+str(tags_modified.get('machineLabel','None'))+"|"+str(element['VolumeId'])+"|"+str(element['SnapshotId'])+"|"+str(backupDateValue)+"|"+str(expiryDate)+"|"+str(diff)
                            writeFile(os.path.join(dir_path,FILE_NAME),LineString)
                else:
                    backUpInfo = tags_modified.get('BackupInfo','None')
                    FLAG = True
                    customerPrefix = tags_modified.get('customerPrefix','None')
                    dir_path = os.path.join(outputfile,datetime.now().strftime("%Y-%b-%d"))
                    vpc_id_str = tags_modified.get('masterSnapshotID','None')
                    vpcmatchStr = regex_vpc.search(vpc_id_str)

                    if vpcmatchStr is not None:
                        vpc_id_str = vpcmatchStr.group(1)
                    else:
                        # vpc_id_str = 'None'
                        vpc_id_str = getVpcId(connection, element['VolumeId'], element['SnapshotId'])
                    backupdateStr = regex_backupdate.search(backUpInfo)
                    if backupdateStr is not None:
                        backupDateValue = backupdateStr.group(1)
                    else:
                        backupDateValue = 'None'
                        diff = 'None'


                    try:
                        # info("*******************")
                        # info(dir_path)
                        createDirectory(dir_path)
                    except Exception,ex:
                        error('##################Error################')
                        error(ex)
                        error("Error occurred while running the Script. please contact administrator")

                        # writeFile(os.path.join(dir_path,FILE_NAME),"Old Snapshots For Customer Prefix: "+customerPrefix)
                        # writeFile(os.path.join(dir_path,FILE_NAME),"----------------------------------------")


                    LineString = str(region)+"|"+str(customerPrefix)+"|"+str(vpc_id_str)+"|"+str(tags_modified.get('machineLabel','None'))+"|"+str(element['VolumeId'])+"|"+str(element['SnapshotId'])+"|"+str(backupDateValue)+"|"+str(backUpInfo)+"|"+str(diff)
                    writeFile(os.path.join(dir_path,FILE_NAME),LineString)
            else:
                backUpInfo = 'None'
                FLAG = True
                customerPrefix = 'None'
                dir_path = os.path.join(outputfile,datetime.now().strftime("%Y-%b-%d"))
                vpc_id_str = 'None'
                vpcmatchStr = regex_vpc.search(vpc_id_str)

                if vpcmatchStr is not None:
                    vpc_id_str = vpcmatchStr.group(1)
                else:
                    # vpc_id_str = 'None'
                    vpc_id_str = getVpcId(connection, element['VolumeId'], element['SnapshotId'])
                backupdateStr = regex_backupdate.search(backUpInfo)
                if backupdateStr is not None:
                    backupDateValue = backupdateStr.group(1)
                else:
                    backupDateValue = 'None'
                    diff = 'None'
                try:
                    # info("*******************")
                    # info(dir_path)
                    createDirectory(dir_path)
                except Exception,ex:
                    error('##################Error################')
                    error(ex)
                    error("Error occurred while running the Script. please contact administrator")

                    # writeFile(os.path.join(dir_path,FILE_NAME),"Old Snapshots For Customer Prefix: "+customerPrefix)
                    # writeFile(os.path.join(dir_path,FILE_NAME),"----------------------------------------")


                LineString = str(region)+"|"+str(customerPrefix)+"|"+str(vpc_id_str)+"|"+str('None')+"|"+str(element['VolumeId'])+"|"+str(element['SnapshotId'])+"|"+str(backupDateValue)+"|"+str(backUpInfo)+"|"+str(diff)
                writeFile(os.path.join(dir_path,FILE_NAME),LineString)


        else:
            print "This is the Snapshot created for AMI, Hence skipping id:"+str(element['SnapshotId'])
            info("This is the Snapshot created for AMI, Hence skipping id:"+str(element['SnapshotId']))
def getSnapshotsByCustomerprefix(connection, region, customerprefix, outputfile):
    """
    Function to retrieve snapshots in region filtered by customer prefix
    :param connection: boto3 connection object
    :param region: Region name
    :param customerprefix: Customer prefix that to be filtered
    :param outputfile: Destination ooutput directory
    """
    info(connection)
    info("Checking for Customerprefix: "+str(customerprefix))
    sum = 0
    filters=[
        {
            'Name': 'tag:customerPrefix',
            'Values': [
                customerprefix,
            ]
        },
    ]
    nextToken = ''
    sum = 0
    while True:
        if nextToken =='':
            x = 1
            success = False
            while x <= MAX_ATTEMPTS:
                x = x+1
                try:
                    page = connection.describe_snapshots(OwnerIds = ['self'],Filters = filters, MaxResults=1000)
                    processSnapshots(connection,region, page['Snapshots'], outputfile)
                    success = True
                    break
                except exceptions.EndpointConnectionError:
                    print "#####Exception raised,Looks like There is something error in region you specified####"
                    logging.info("#####Exception raised,Looks like There is something error in region you specified####")
                    print region
                    info(region)
                    sys.exit(1)
                except Exception,ex:
                    print "#####Exception raised,trying to recall again####"
                    logging.info("#####Exception raised,trying to recall again####")
                    print ex
                    logging.info(ex)
                    number = randint(60,80)
                    print "Waiting "+str(number)+" seconds before retry"
                    time.sleep(number)
            if not success:
                logging.error("Error after "+str(MAX_ATTEMPTS)+" attempts, Exiting Application")
                sys.exit(1)
        else:
            x = 1
            success = False
            while x <= MAX_ATTEMPTS:
                x = x+1
                try:
                    page = connection.describe_snapshots(OwnerIds = ['self'],Filters = filters, MaxResults=1000,NextToken=nextToken)
                    processSnapshots(connection,region, page['Snapshots'], outputfile)
                    success = True
                    break
                except exceptions.EndpointConnectionError:
                    print "#####Exception raised,Looks like There is something error in region you specified####"
                    logging.info("#####Exception raised,Looks like There is something error in region you specified####")
                    print region
                    info(region)
                    sys.exit(1)
                except Exception,ex:
                    print "#####Exception raised,trying to recall again####"
                    logging.info("#####Exception raised,trying to recall again####")
                    print ex
                    logging.info(ex)
                    number = randint(60,80)
                    print "Waiting "+str(number)+" seconds before retry"
                    time.sleep(number)
            if not success:
                logging.error("Error after "+str(MAX_ATTEMPTS)+" attempts, Exiting Application")
                sys.exit(1)
        print len(page['Snapshots'])
        sum = sum+len(page['Snapshots'])
        print "Total snapshots processed so far:"+str(sum)
        info("Total snapshots processed so far:"+str(sum))
        if 'NextToken' in page.keys():
            nextToken = page['NextToken']
        else:
            break

    # for page in paginator.paginate(OwnerIds = ['self'],Filters = filters, MaxResults = 1000):
    #     sum = sum+len(page['Snapshots'])
    #     # print len(page['Snapshots'])
    #     print "Total snapshots processed so far:"+str(sum)
    #     processSnapshots(connection,region, page['Snapshots'], outputfile)

    print "Total Snapshots Processed with your inputs:"+str(sum)
    info("Total Snapshots Processed with your inputs:"+str(sum))


def processViaInstanceId(connection, region,instanceid, outputfile):
    """
    Function to retrieve snapshots based on Instance id
    :param connection: boto3 connection object
    :param region: Region Name
    :param instanceid: Instance Id
    :param outputfile:
    :return: Destination output directory
    """
    info("getting Snapshots for instance id:"+str(instanceid))
    strtaginstance = instanceid + '-*'
    print strtaginstance
    # paginator = connection.get_paginator('describe_snapshots')
    filters=[
        {
            'Name': 'tag:Name',
            'Values': [
                strtaginstance,
            ]
        },
    ]
    sum = 0
    for page in paginator.paginate(OwnerIds = ['self'],Filters = filters, MaxResults = 1000):
        sum = sum+len(page['Snapshots'])
        processSnapshots(connection,region, page['Snapshots'], outputfile)
    info("Total Snapshots Processed with this Instance ID:"+str(sum))
    print "Total Snapshots Processed with this Instance ID:"+str(sum)



def getSnapshotsByVpcid(connection, region, vpcid, outputfile):
    """

    Function to Retrieve instances based on VPC id
    :param connection: Boto3 connection obbject
    :param region: Region Name
    :param vpcid: VPC id
    :param outputfile: Destionation output directory
    """
    info(region)
    info("Checking for Vpc Id: "+str(vpcid))
    print "Checking for Vpc Id: "+str(vpcid)
    info("##################Processing for each instance in VPC starts##############")
    sum = 0
    filters=[
        {
            'Name': 'vpc-id',
            'Values': [
                vpcid,
            ]
        },
    ]
    paginator = connection.get_paginator('describe_instances')
    for page in paginator.paginate(Filters = filters, MaxResults = 1000):
        for reservation in page['Reservations']:
            sum = sum+len(reservation['Instances'])
            for instance in reservation['Instances']:
                processViaInstanceId(connection, region,instance['InstanceId'], outputfile)



    print "Total instances in VPC:"+str(sum)
    info("Total instances in VPC:"+str(sum))
    info("##################Processing for each instance in VPC ends##############")

def getSnapshotsByRegion(connection, region, outputfile):

    """
    Function to retrieve expired snapshots based on region
    :param connection: Boto3 connection object
    :param region: Region Name
    :param outputfile: Destination output directory
    """
    info(connection)

    nextToken = ''
    sum = 0
    while True:
        if nextToken =='':
            x = 1
            success = False
            while x <= MAX_ATTEMPTS:
                x = x+1
                try:
                    # raise ZeroDivisionError
                    page = connection.describe_snapshots(OwnerIds = ['self'], MaxResults=1000)
                    processSnapshots(connection,region, page['Snapshots'], outputfile)
                    success = True
                    break
                except exceptions.EndpointConnectionError:
                    print "#####Exception raised,Looks like There is something error in region you specified####"
                    logging.info("#####Exception raised,Looks like There is something error in region you specified####")
                    print region
                    info(region)
                    sys.exit(1)
                except exceptions.EndpointConnectionError:
                    print "#####Exception raised,Looks like There is something error in region you specified####"
                    logging.info("#####Exception raised,Looks like There is something error in region you specified####")
                    print region
                    info(region)
                    sys.exit(1)
                except Exception,ex:
                    print "#####Exception raised,trying to recall again####"
                    logging.info("#####Exception raised,trying to recall again####")
                    print ex
                    logging.info(ex)
                    number = randint(60,80)
                    print "Waiting "+str(number)+" seconds before retry"
                    time.sleep(number)
            if not success:
                logging.error("Error after "+str(MAX_ATTEMPTS)+" attempts, Exiting Application")
                sys.exit(1)
        else:
            x = 1
            success = False
            while x <= MAX_ATTEMPTS:
                x = x+1
                try:
                    # raise ZeroDivisionError
                    page = connection.describe_snapshots(OwnerIds = ['self'], MaxResults=1000,NextToken=nextToken)
                    processSnapshots(connection,region, page['Snapshots'], outputfile)
                    success = True
                    break
                except exceptions.EndpointConnectionError:
                    print "#####Exception raised,Looks like There is something error in region you specified####"
                    logging.info("#####Exception raised,Looks like There is something error in region you specified####")
                    print region
                    info(region)
                    sys.exit(1)
                except exceptions.EndpointConnectionError:
                    print "#####Exception raised,Looks like There is something error in region you specified####"
                    logging.info("#####Exception raised,Looks like There is something error in region you specified####")
                    print region
                    info(region)
                    sys.exit(1)
                except Exception,ex:
                    print "#####Exception raised,trying to recall again####"
                    logging.info("#####Exception raised,trying to recall again####")
                    print ex
                    logging.info(ex)
                    number = randint(60,80)
                    print "Waiting "+str(number)+" seconds before retry"
                    time.sleep(number)
            if not success:
                logging.error("Error after "+str(MAX_ATTEMPTS)+" attempts, Exiting Application")
                sys.exit(1)
        print len(page['Snapshots'])
        sum = sum+len(page['Snapshots'])
        print "Total snapshots processed so far:"+str(sum)
        info("Total snapshots processed so far:"+str(sum))
        if 'NextToken' in page.keys():
            nextToken = page['NextToken']
        else:
            break

    #
    # sum = 0
    # paginator = connection.get_paginator('describe_snapshots')
    # for page in paginator.paginate(OwnerIds = ['self'],MaxResults = 1000):
    #     sum = sum+len(page['Snapshots'])
    #     print len(page['Snapshots'])
    #     print "Total:"+str(sum)
    #     processSnapshots(connection,region, page['Snapshots'], outputfile)

    print "Total Snapshots Processed with your inputs:"+str(sum)
    info("Total Snapshots Processed with your inputs:"+str(sum))



def main(region, customerprefix=None, vpcid=None, outputfile=None):
    """

    Main function to retrieve expired snapshots based on user inputs
    :param region: Region Name
    :param customerprefix: Customer prefix
    :param vpcid: Vpc id
    :param outputfile: Destination output directory
    """
    info("#######################Starting for the Region: "+str(region)+"#######################")
    print "#######################Starting for the Region: "+str(region)+"#######################"
    try:
        EC2Conn = ec2_connection(region)
        print EC2Conn
        info(str(EC2Conn))
        connection = EC2Conn.client('ec2')
    except Exception,ex:
        error("##########Error##########")
        error("Please check the region you are trying to connect")
        sys.exit(1)
    if customerprefix:
        getSnapshotsByCustomerprefix(connection, region, customerprefix, outputfile)
    elif vpcid:
        getSnapshotsByVpcid(connection, region, vpcid, outputfile)
    else:
        getSnapshotsByRegion(connection, region, outputfile)

# Calling main method
if __name__ == "__main__":
    info(":::Get expired snapshots started:::")
    parser = argparse.ArgumentParser()
    parser.add_argument('-region', '--region', dest='region'
                    , default=None,
                    help='Please provide Region'
                    )
    parser.add_argument('-customerPrefix', '--customerPrefix', dest='customerPrefix'
                    , default=None,
                    help='Please provide Customer Prefix'
                    )
    parser.add_argument('-vpcId', '--vpcId', dest='vpcId'
                    , default=None,
                    help='Please provide VPC ID'
                    )
    parser.add_argument('-outputFile', '--outputFile', dest='outputFile'
                    , default=None,
                    help='Please provide Output Folder'
                    )
    args = parser.parse_args()
    try:
        if len(args.outputFile.split(os.sep)) == 1:
            raise OSError("Error in Path")
        if not os.path.exists(args.outputFile):
            raise OSError("Error in Path")
    except:
        error('##################Error################')
        error("Error in Folder path you specified, please provide the correct path")
        print "Error in Folder path you specified, please provide the correct path"
        sys.exit(1)
    if args.region == '':
        print "##########Region should not be None##########"
        error("##########Region should not be None##########")
        sys.exit(1)
    try:

        main(args.region,args.customerPrefix,args.vpcId, args.outputFile)
        if not FLAG:
            info("No Expired snapshots found with given inputs")
            print "No Expired snapshots found with given inputs"
            info("#######################Completed for the Region: "+args.region+"#######################")
        else:
            info("Completed: Output file is generated "+args.outputFile+os.sep+str(datetime.now().strftime("%Y-%b-%d"))+os.sep+FILE_NAME)
            print "Completed: Output file is generated "+args.outputFile+os.sep+str(datetime.now().strftime("%Y-%b-%d"))+os.sep+FILE_NAME
            info("#######################Completed for the Region: "+args.region+"#######################")
    except Exception,ex:
        error("##################Error################")
        error("Error occurred while running the Script. please contact administrator")
        print "Error occurred while running the Script. please contact administrator"
        print ex
        error(ex)
        sys.exit(1)
