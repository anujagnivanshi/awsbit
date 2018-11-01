'''
*****************************************************************************************************************
/*File Name     : Create Snapshot - Linux.PY
* Project         : CloudSuite
* Object          :
* Purpose         : This Code is used to Create Snapshot from AWS
* Description :
* Author          : test
* Date            : 11-JUN-2014
*****************************************************************************************************************
'''
import os
import sys
import glob
import time
import datetime
from datetime import date, timedelta
from datetime import datetime
import logging
import shutil
import httplib, urllib
import logging.handlers as handlers
import ConfigParser
import sys, string
import boto
from boto import ec2
from boto.s3.key import Key
import socket
from boto.s3.connection import OrdinaryCallingFormat


def geturlinfo(strlink):
    try:
        logging.info('Executing geturlinfo function')
        logging.info("The input URL is " + strlink)
        strlink = urllib.urlopen(strlink)
        sinfo = strlink.readline()
        print sinfo
        logging.info("The result of URL is " + sinfo)
        if (len(sinfo) > 0):
                        logging.info('The output for the following URL=  '+ sinfo)
                        return sinfo
        else:
                       logging.error('The output for '+ strlink + ' parameter is null. please contact administrator')
    except Exception, ex:
      print ex
      logging.error(ex)
      logging.error('Error occured while getting information from URL. please contact administrator')
      raise

def uploadtxttos3(strfile,strbucket,strcust):
    try:
        sbucket = 1
        strregionlink = 'http://169.254.169.254/latest/meta-data/placement/availability-zone/'
        str_avb_id = geturlinfo(strregionlink)
        s_region = str_avb_id[:-1]
        logging.info('Executing uploadtxttos3 function')
        if sawsaccesskey != 'empty' and sawssecratccesskey != 'empty':
             print 'AWS env present'
             conn = boto.s3.connect_to_region(s_region,aws_access_key_id=str(sawsaccesskey),aws_secret_access_key=str(sawssecratccesskey),calling_format = boto.s3.connection.OrdinaryCallingFormat())
             #conn = boto.connect_s3(aws_access_key_id=str(sawsaccesskey), aws_secret_access_key=str(sawssecratccesskey),calling_format = boto.s3.connection.OrdinaryCallingFormat())
        else:
             print 'Using roles'
             #conn = boto.connect_s3(calling_format = boto.s3.connection.OrdinaryCallingFormat())
             conn = boto.s3.connect_to_region(s_region,calling_format = boto.s3.connection.OrdinaryCallingFormat(),)
        logging.info('Bucket Name is : '+strbucket)
        print 'hi'

        chkbucket = conn.get_all_buckets()
        for bval in chkbucket:
         if bval.name == strbucket:
            sbucket = 0
            break
         else:
            sbucket = 1

        if sbucket == 0:
          print 'Bucket exist'
        else:
                print 'No bucket is present..creating bucket..'
                cbucket = conn.create_bucket(strbucket)
        cbucket = conn.get_bucket(strbucket)
        if cbucket:
            k = Key(cbucket)
            sbasename = os.path.basename(strfile)
            k.key = '/backup/'+strcust+'/'+sbasename
            logging.info('Key  is : '+'/backup/'+strcust+'/'+sbasename)
            k.set_contents_from_filename(strfile, encrypt_key=True)
    except Exception, ex:
      print ex
      logging.error(ex)
      logging.error('Error occured while uploadtxttos3. please contact administrator')
      raise

def getconfigparams(strparamsfile,strname):
    try:
         paramsval = ''
         logging.info('Executing getconfigparams function')
         logging.info('Getting value from params file is ' + strname)
         if os.path.isfile(strparamsfile):
             fp = open(strparamsfile, 'r')
             for line in fp:
                  if strname in line:
                      strval = string.split(line, '=')
                      paramsval = strval[1].rstrip()
                      #paramsval = string.lower(strval[1]).rstrip()
                      if (len(paramsval) > 0):
                        logging.info('The value returned for the following param=  '+ strname + ' parameter is= '+ paramsval)
                        return paramsval
                      else:
                       logging.error('The value returned for '+ strname + ' parameter is null. please contact administrator')
                       raise
         else:
            logging.error(strparamsfile + ' params file does not exist. Please contact administrator.')
            raise
    except Exception, ex:
      print ex
      logging.error(ex)
      logging.error('Error occured while getting information on params file. please contact administrator')
      raise

try:

    strlogfolder = "c:\\test\\logs"
    #strwinfolder = "C:/Windows/cwi/wininit.params"
    strwinfolder = "c:\\test\\wininit.params"
    #strsnapshotfolder = "C:/snapshot/"
    strsnapshotfolder = "c:\\test\\snapshot\\"
    sinstanceurl = "http://169.254.169.254/latest/meta-data/instance-id/"
    strregionlink = 'http://169.254.169.254/latest/meta-data/placement/availability-zone/'
    debug=0
    strdate = datetime.now().strftime("%d-%b-%Y")
    #Log defining information.
    if not os.path.exists(strlogfolder):
        os.makedirs(strlogfolder)
    if not os.path.exists(strlogfolder + '/' + strdate):
        os.makedirs(strlogfolder + '/' + strdate)
    log_file = strlogfolder + '/' + strdate +'/createsnapshot-main.log'
    if not os.path.exists(log_file):
        open(log_file, 'w').close()
    if not os.path.exists(strsnapshotfolder):
        os.makedirs(strsnapshotfolder)
    logger=logging.getLogger()
    logger_fh = handlers.RotatingFileHandler(log_file, maxBytes=10485760, backupCount=10)
    if debug:
        logger.setLevel(logging.DEBUG)
        logger_fh.setLevel(logging.DEBUG)
    else:
        logger.setLevel(logging.INFO)
        logger_fh.setLevel(logging.INFO)

    LogfileFormatter = logging.Formatter('%(asctime)s [%(process)-5d] [%(levelname)-8s] %(funcName)s %(message)s')
    logger_fh.setFormatter(LogfileFormatter)
    logger.addHandler(logger_fh)
    logging.info("###############The Program is started. Executing Create Snapshot Code######################")
    strbucket ="testbucket"
    logging.info('Bucket name is '+strbucket)
    iexpirydays = os.getenv('BACKUP_EXPIRY_DAYS','empty')
    if iexpirydays == 'empty':
        logging.info('Setting expirydate to 30 days')
        iexpirydays = 30
    iexpirydays = int(iexpirydays)
    str_instance_id = geturlinfo(sinstanceurl)
    logging.info('The instance id is '+ str_instance_id)
    str_avb_id = geturlinfo(strregionlink)
    s_region = str_avb_id[:-1]
    logging.info('The region is '+ s_region)
    sawsaccesskey = os.environ.get('AWS_ACCESS_KEY','AKIAIMC3PWZ624U5VP4Q')
    sawssecratccesskey = os.environ.get('AWS_SECRET_ACCESS_KEY','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')
    strcustomerprefix = "kelly"
    #strcustomerprefix = getconfigparams(strwinfolder,"CustPrefix")
    #strcustomerprefix = "{{grains['CustPrefix']}}"
    logging.info('The customer prefix is '+ strcustomerprefix)
    macId = urllib.urlopen("http://169.254.169.254/latest/meta-data/network/interfaces/macs").read()
    vpcURL = "http://169.254.169.254/latest/meta-data/network/interfaces/macs/" + macId + "vpc-id"
    vpcId = urllib.urlopen(vpcURL).read()
    smachine = socket.gethostname() + '-' +strcustomerprefix
    strfilename = strsnapshotfolder+str_instance_id+ '-' + smachine + '-' + vpcId + '.txt'
    
    if not os.path.exists(strfilename):
        open(strfilename, 'w').close()
    if strcustomerprefix:
        logging.info('--connect EC2')
        print '--connect EC2'
        if sawsaccesskey != 'empty' and sawssecratccesskey != 'empty':
            print 'AWS env present'
            ec2conn = boto.ec2.connect_to_region(s_region,aws_access_key_id=str(sawsaccesskey),aws_secret_access_key=str(sawssecratccesskey))
            print 'hi'
        else:
            print 'Using roles'
            ec2conn = boto.ec2.connect_to_region(s_region)
        #s3 = boto.connect_s3()
        #bucket = s3.get_bucket('mybucket')
        logging.info('--out connect EC2')
        volumes = ec2conn.get_all_volumes(filters={'attachment.instance-id': str_instance_id})
        if len(volumes) > 0:
            print volumes
            logging.info('---------volume list-----')
            logging.info(volumes)
            print len(volumes)
            for strvolumes in volumes:
                 print strvolumes.id
                 strvolumeid = str(strvolumes.id)
                 logging.info('The volume id is : '+ strvolumeid)
                 strvolumedevice = str(strvolumes.attach_data.device)
                 logging.info('The volume id device is : '+ strvolumedevice)
                 print strvolumes.attach_data.device
                 #print strvolumes.attach_data.instance_id
                 sdate = datetime.now().strftime("%Y%m%d%H%M%S")
                 ssdateformat= datetime.now().strftime("%d-%b-%Y")
                 sadddate = date.today() + timedelta(iexpirydays)
                 sexpirtdate =  sadddate.strftime("%d-%b-%Y")
                 sexpformat =  sadddate.strftime("%Y%m%d%H%M%S")
                 logging.info('The expiry Date set is : '+ sexpformat)
                 sdesc = 'Snapshot created for volume id '+strvolumeid+' from instance id '+str_instance_id+' at time '+sdate
                 logging.info('Snapshot description is : '+ sdesc)
                 logging.info('..Creating Snapshot..')
                 snewsnapid = ec2conn.create_snapshot(strvolumeid, sdesc)
                 snewsnapidname = str(snewsnapid.id)
                 logging.info('New snapshot created is '+ snewsnapidname)
                 print 'New snapshot created is '+ snewsnapidname
                 strnametag = str_instance_id + '-' +strvolumeid + '-' +strvolumedevice + '-' + sdate
                 strbackupinfotag = 'online|CreatedDate:'+ssdateformat+'|ExpiryDate:'+sexpirtdate
                 strmachinelabeltag = socket.gethostname() + '-' +strcustomerprefix
                 strcusromertag = strcustomerprefix
                 logging.info('...Creating the Tags....')
                 ec2conn.create_tags([snewsnapidname], {"Name": strnametag,"BackupInfo": strbackupinfotag,"machineLabel": strmachinelabeltag,"customerPrefix": strcusromertag})
                 strtext = 'YYYYMMDDHHMMSS:'+sdate + ' & expdate:'+sexpformat + ' & SnapshotID:' + snewsnapidname +' & VolumeID:'+str(strvolumeid) +' & region:'+s_region + '& Deviceid:'+strvolumedevice
                 logging.info('Snapshot file location : '+strfilename)
                 logging.info('Text appeding into file is : '+strtext)
                 with open(strfilename, "a") as myfile:
                    myfile.write(strtext + '\n')
                    logging.info('Writing into the file')
        else:
            print 'No Volume are present....'
            logging.info('No Volume are present....')
        #uploadtxttos3(strfilename,strbucket,strcustomerprefix)

except Exception, ex:
    print ex
    logging.error(ex)
    logging.error('Error occured while running the Create snapshot. please contact administrator')
    sys.exit(1)




