#!/usr/bin/python
# Program By user
#  From users

#http://vschart.com/compare/c-sharp/vs/python-programming-language
#https://www.tutorialspoint.com/python/python_reg_expressions.htm
#Download Location :
#https://www.python.org/doc/
#http://www.howtogeek.com/197947/how-to-install-python-on-windows/
#SET path 
#c:\Python27\;C:\Python27\Scripts\

#Provide some information on Python folder structure.

#Site packages
#site-packages is the target directory of manually built python packages. When you build and install python packages from source\
# (using distutils, probably by executing python setup.py install), you will find the installed modules in site-pacakges


#OPen Python console & execute hello world.
#cmd --> python
#print "Hello world" --> enter

'''
String
int
float
boolean
list
tuple
dictionary


if __name__ == "__main__":



'''



#-----------Print---------------#
newstring = "This is myworld & welcome to IT"
newstring = newstring + "."
print newstring

print newstring[:-1]

print "The Type returned is : " + type(newstring)

newsplit = newstring.split("&")
print type(newsplit)

print newsplit[0]

#or
print newstring.split("&")[0]

print newsplit[1]

print newsplit[1].strip()
print newsplit[1].strip().lower()
print newsplit[1].strip().upper()

names = ','.join(['someuser','ram','sham'])
print names

newstring = "This is world and we are part of msit in hyderabad."
ss = len(newstring)
print ss
sstart = newstring.index('and')
send = newstring.index('msit')
print dd
endstring = newstring[sstart:send]
print endstring

status = newstring.endswith("hyderabad")
print status
status = newstring.startswith("world")
print status


sstring = "This is 'Mr' someuser"
print sstring
sstring = 'This is "Mr" someuser'
print sstring
#------------------------------------------------


#-----------Single Lines Comments---------------#
# Its just a sample comment

#------------------------------------------------

#-----------Multiple Lines Comments---------------#
'''
This is a sample for multiple line Comments
Note : This is just a sample.
'''

'''
Str - String, text 
int
Float - real number
Bool - True/False

list = [a,b,c]
List represents single name for collection of values & Contains any type..  

Sample : family = ["someuser", 1.73, "ram", 1.69, "vai", 1.09]

List may also contain list itself(list inside list)

listinsidelist = [["someuser", 1.73, "ram", 1.69, "vai", 1.09],["microsoft",1000]]

'''
smultilinestring = '''
This is Microsoft
This is msit'kkkk
This is hyderabad
'''

#Dictionary
#real example :

phonebook = {'Andrew Parson':8806336, 'Emily Everett':6784346, 'Peter Power':7658344, 'Lewis Lame':1122345}
print phonebook['Peter Power']
for key, value in phonebook.iteritems():
    print key
    print value

#real sample of list

Real example : 

import os
fulldirs = os.listdir("C:\Program Files")
print type(fulldirs)
for ff in fulldirs:
    print ff

#real example of tuple

Real example :

months = ('January','February','March','April','May','June',\
'July','August','September','October','November','  December')

print months[0]
print type(months)

for mm in months:
    print mm




print smultilinestring
#-----------Integer---------------#

inumber = 10

print inumber
print("The number you have entered is : ", inumber)


#---------------------------Convert--------------------------

myint= 1
mystring= str(myint)
print mystring

print type(mystring)

#Convert string into int
mynewstring= "1"
myint = int(mynewstring)
print type(myint)
print myint + 10

#Float:
a = "545.2222"
float(a)
int(float(a))
print int(float(a))



#-------------------Boolean--------------


flag = False
print flag




#------------Calculations--------------

height = 1.79
weight = 64.9

BMI = weight/height ** 2
print BMI

type(BMI)


#---------------Round-------------------

print round(2.78,1)

print round(2.78)


#------------list--------------------

family = ["someuser", 1.73, "ram", 1.69, "vai", 1.09]
family[1] = 1.2
print family

print len(family)

family = family + ["vaihaan" ,1]
print family
print family.index("ram")

print family.count("someuser")

family.append("me")
print family
####delete a content

del(family[2])

listinsidelist = [["someuser", 1.73, "ram", 1.69, "vai", 1.09],["microsoft",1000]]

multilist = [[1,2,3], [10,20,30], [100,200,300]]

print len(multilist)

multilist[2].append(400)
multilist[1].append(40)

for myList in multilist:
    for item in myList:
        print(item)



height = [1,5,3,66,77,889,55]
print max(height)
print min(height)

height.sort()
height.reverse()


#----------------Tuple-------------------
'''A tuple is a sequence of immutable Python objects. 
Tuples are sequences, just like lists. 
The differences between tuples and lists are, the tuples cannot be changed unlike lists and tuples use parentheses, whereas lists use square brackets.
'''
tup1 = ('physics', 'chemistry', 1997, 2000);
tup2 = (1, 2, 3, 4, 5 );
tup3 = "a", "b", "c", "d";

print "tup1[0]: ", tup1[0]
print "tup2[1:5]: ", tup2[1:5]

tup1 = (12, 34.56);
tup2 = ('abc', 'xyz');

# Following action is not valid for tuples
# tup1[0] = 100;

# So let's create a new tuple as follows
tup3 = tup1 + tup2;
print tup3

#------------------------Dictionary------------------------

dict = {'Name': 'Zara', 'Age': 7, 'Class': 'First'}

print "dict['Name']: ", dict['Name']
print "dict['Age']: ", dict['Age']



dict = {'Name': 'Zara', 'Age': 7, 'Class': 'First'}

dict['Age'] = 8; # update existing entry
dict['School'] = "DPS School"; # Add new entry


print "dict['Age']: ", dict['Age']
print "dict['School']: ", dict['School']

dict = {'Name': 'Zara', 'Age': 7, 'Class': 'First'}

del dict['Name']; # remove entry with key 'Name'
dict.clear();     # remove all entries in dict
del dict ;        # delete entire dictionary

print "dict['Age']: ", dict['Age']
print "dict['School']: ", dict['School']




help(round())

#--------sleep/pause ---------
import time
time.sleep(60)




#------------------------datetime------------------------
from datetime import datetime
import datetime
strdate = datetime.now().strftime("%d-%b-%Y")
print "Today date is : "+ strdate
strcurrentDate  = datetime.now().strftime("%Y%m%d%H%M%S")
print "Current date & time is : "+ strcurrentDate


sdate = datetime.strptime(sexpiry[1] , '%d-%b-%Y')
print sdate
snow = datetime.now()
ddatediff = snow - sdate
print ddatediff.days # tha

#--------------------------Time--------------------------
import time
strtime = time.ctime()
print "Simple format is : " + strtime
t = (2009, 2, 17, 17, 3, 38, 1, 48, 0)
t = time.mktime(t)
print "Other formats displays : "+ time.strftime("%b %d %Y %H:%M:%S", time.gmtime(t))

#time.strftime('%X %x %Z')
print time.strftime('%X %x %Z')

#-------------------------- get env variable------------------

getEnv = os.environ.get('AWS_SECRET_ACCESS_KEY')
print getEnv

getEnv = os.environ.get('AWS_SECRET_ACCESS_KEY','1')
print getEnv

#------------------------------------------------


#--------------search and replace---------------------

strnewstring = "microsoft is a good software company"
newstring = strnewstring.replace("soft", "new")
print newstring

#---------------------------- iF conditions-----------------------------

strtest = "AO"
if strtest == 'AO':
	print "Its AO"
else:
	print "Its not AO"

if strtest != "BO":
    print "Its notBO"



if not os.path.exists(strfilename):
    print "file exists"



if strcustomerprefix:
    print "Nothing"

if platform.system() =='Windows':
        print "windows OS Detected"
else:
        print "Linux OS Detected"

if sawsaccesskey != 'empty' and sawssecratccesskey != 'empty':
    print "Its not empty"


number = None
if number is not None:
    print "Not null"
else:
    print "Its null"
#-----------------------------------For loop--------------------

for x in range(5): # 0-4
    print x

names = ['someuser','ram']
for name in names:
    print name


initials = {'DH': 'someuser','RA': 'RAM',
}
for key,value in initials.items():
    print '%s: %s' % (key,value)
    print key
    print value


odds = [x for x in range(40) if x % 2]
print odds

import os

letterforms = '''\
           |Ashok      |       |       |       |       |       | |
      000  | someuser  000  |  000  |   0   |       |  000  |  000  |!|
      0  0 |  0  0 |  0  0 |       |       |       |       |"|
      0 0  |  0 0  |0000000|  0 0  |0000000|  0 0  |  0 0  |#|
     00000 |0  0  0|0  0   | 00000 |   0  0|0  0  0| 00000 |$|
    000   0|0 0  0 |000 0  |   0   |  0 000| 0  0 0|0   000|%|
      00   | 0  0  |  00   | 000   |0   0 0|0    0 | 000  0|&|
      000  |  000  |   0   |  0    |       |       |       |'|
       00  |  0    | 0     | 0     | 0     |  0    |   00  |(|
      00   |    0  |     0 |     0 |     0 |    0  |  00   |)|
           | 0   0 |  0 0  |0000000|  0 0  | 0   0 |       |*|
           |   0   |   0   | 00000 |   0   |   0   |       |+|
           |       |       |  000  |  000  |   0   |  0    |,|
    '''.splitlines()
for eachline in letterforms:
        print eachline

#----------------------While---------------------

items = 0
while items < 100:
    print items
    items += 1

count = 0
while count < 5:
   print count, " is  less than 5"
   count = count + 1
else:
   print count, " is not less than 5"






#search & replace a content ina file.
strparamsfile = "C:\Python27\README.txt"
with open(strparamsfile, 'r') as file :
  filedata = file.read()
  print filedata

# Replace the target string
filedata = filedata.replace('someuser', 'ram')
# Write the file out again
with open(strparamsfile, 'w') as file:
  file.write(filedata)






#-------------------- Exceptions handling ------------------
try:

	print "Hello AO Team!"

except Exception, ex:
    print ex
    sys.exit(1)


try:
    innt = "1"
    innt = 1 + innt
    print innt
except Exception, ex:
    print ex


try:
    try:
     innt = "1"
     innt = 1 + innt
     print innt
    finally:
     print "Going to close the file"
except Exception, ex:
    print ex
    print "PLease contct administrator.."

#!/usr/bin/python

try:
   fh = open("testfile", "w")
   try:
      fh.write("This is my test file for exception handling!!")
   finally:
      print "Going to close the file"
      fh.close()
except IOError:
   print "Error: can\'t find file or read data"


#-----------------------Open a file -------------------------


with open(userdata, 'r') as f:
        first_line = f.readline()


#----------------------Logging----------------------


try:
    import logging.handlers as handlers
    import logging
    debug =0
    log_file = "D:\\test.log"
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
except Exception, e:
    print e
    #sys.exit(1)




from xml.dom import minidom
xmldoc = minidom.parse("c:\\python27\\test.xml")
itemlist = xmldoc.getElementsByTagName('item')
print(len(itemlist))
print(itemlist[0].attributes['name'].value)
for s in itemlist:
    print(s.attributes['name'].value)




#-----------------------Reading a file -------------------------

if os.path.isfile(strparamsfile):
             fp = open(strparamsfile, 'r')
             for line in fp:
                  if strname in line:
                      strval = string.split(line, '=')
                      paramsval = strval[1].rstrip()





#-----------------------write in a file -----------------------------


file = open("C:\\cspagent\\logs\\"+agent_cmd_id+".out", "w")
file.write(conJson)
file.close()




#----------------------Delete files-------------------------------


#os.remove() will remove a file.

#os.rmdir() will remove an empty directory.

#shutil.rmtree() will delete a directory and all its contents.

#-----------------------Modules & Packages-----------------------------
#best document : https://www.blog.pythonlibrary.org/2012/07/08/python-201-creating-modules-and-packages/

'''For data science 

Numpy
pip install numpy


Matplotlib -- data virtualization

Scikit - Learn --> Machine Learning..

Numpy is very good for calculation specially for array kind of data.

Example of Numpy: i have 2 list

height = [1.79,2.89,1.23]
weight = [32,45,66]

BMI = weight/height ** 2

This will throw error...
 
import numpy as np

np_height = np.array(height)
np_weight = np.array(weight)

np_bmi = np_height/np_weight ** 2

np_bmi > 5


'''







with open("foo.txt", "a") as f:
     f.write("new line\n")


with open("foo.txt", "r+") as f:
     old = f.read() # read everything in the file
     f.write("new line\n" + old)


#-------------------------Functions & Packages




#---------------------Reading a basic URL--------------------
import httplib, urllib
vpcId = urllib.urlopen(vpcURL).read()


# import requests for API calls
#---------------------Execution of python----------

import subprocess
subprocess.call("sudo wget https://s3.amazonaws.com/stack-utilities/pip/get-pip.py", shell=True)
subprocess.call("sudo python get-pip.py", shell=True)


sresult = subprocess.Popen("python /usr/local/inforbc/lib/standard/createsnapshot-linux.py", bufsize=4096,shell=True)
sout, serr = sresult.communicate()
print sresult.wait()
sys.exit(sresult.wait())




#------------------------Zip file -----------------------------



def extractZip(jar_path,whr2extrac):
    zipTest = ZipFile(jar_path)
    zipTest.extractall(whr2extrac)


#-------------------------YAML-----------------------
import yaml
import sys, os, json

f=open(fname)
settings=yaml.load(f)

ec2Prop = settings[suiteName]['ec2']
for k, v in settings[suiteName]['ec2instances'].iteritems():
	for amino, amiregion in ec2Prop[v]['amimap'].iteritems():
		print amino, amiregion
		print readDynamoDB(v)
		ec2Prop[v][amiregion]['amiid'] = readDynamoDB(v)
		#print ec2Prop

settings[suiteName]['ec2'] = ec2Prop



#---------------------connect mssql databases-------------------
#https://docs.microsoft.com/en-us/sql/connect/python/python-driver-for-sql-server

#pip install pyodbc
import pyodbc
server = 'someusergundra.database.windows.net'
database = 'ao'
username = 'test'
password = 'Password1@3'
driver= '{SQL Server Native Client 11.0}'
cnxn = pyodbc.connect('DRIVER={ODBC Driver 13 for SQL Server};PORT=1433;SERVER='+server+';PORT=1443;DATABASE='+database+';UID='+username+';PWD='+ password)
cursor = cnxn.cursor()
cursor.execute("select top 10 opportunityNumber from newscore where scorewithoutcommitlevel is null")
row = cursor.fetchone()
while row:
    print str(row[0])
    row = cursor.fetchone()



#--------------------------Azure with Python
#pip install azure==2.0.0rc6
#https://azure-sdk-for-python.readthedocs.io/en/latest/