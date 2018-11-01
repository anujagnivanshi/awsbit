<#
*****************************************************************************************************************
/*File Name       : salt-sqlserver-backup.ps1
* Project         : CloudSuite Single-Tenant
* Object          :
* Purpose         : This Code is used to collect inputs from arguments & get the testmation to fullbackup.ps1
                     to the AWS S3 bucket. 
* Description     :
* Author          : xx
* Date            : 11-JAN-2015
*****************************************************************************************************************
#>
param(
    [Parameter(Mandatory=$true)] [String]$sflag,
    [Parameter(Mandatory=$true)] [String]$namedinstance
    )
import-module -Name C:\testbc\lib\standard\Logging.psm1
$MVERSION = $(get-host).Version.Major
If($MVERSION -eq 2)
{
Import-Module "C:\Program Files (x86)\AWS Tools\PowerShell\AWSPowerShell\AWSPowerShell.psd1"
}
else
{
import-module AWSPowerShell -errorAction Stop
}
#import-module AWSPowerShell -errorAction Stop
$VerbosePreference = 'Continue' 
$DebugPreference = 'Continue'
$ErrorActionPreference = "Stop"

function runbackup([String]$backupdir, [String]$expirydate, [String]$instancename, [String]$customerPrefix, [String]$backupmode, [String]$pversion, [String]$drives)
{
try
{
$errorcode = 0
$sqlpsPath = 'C:\Program Files (x86)\Microsoft SQL Server\100\Tools\Binn'
write-host '----------------Into SQL Backup code ---------------'
write-host "The Backup Mode is $backupmode"
write-host "The Input argument for Backup Directory is $backupdir"
write-host "The Input argument for Expirydate is $expirydate"
write-host "The Instancename is $instancename"
#[String[]]$drives=@($drives)
write-host "The Backup Drives $drives"
$sdrivetrans =""
$sbucket=$env:BUCKET_NAME
$sregistryfolder = ""
$fullbackupflagfolder = 'C:\testbc\tmp\flags\'
$fullbackupflagfile = $fullbackupflagfolder + $instancename + '-fullbackupflag.txt'
$envval = 'ZZ_' + $instancename + '_bck'
if($backupmode -ne 'full'){Start-Sleep -s 3}
# We are using sleep command here because if full & transactional backup runs at same time, then full backup should run first &
# this will stop the transactional backup from running at a time when full backup is running.
if (Test-Path $fullbackupflagfolder){}
else
{ 
   New-Item $fullbackupflagfolder -type directory
  Start-Sleep -s 2
}
if (Test-Path $fullbackupflagfile)
{
    write-host "Task is ignoring as full backup is running in the background.Please wait until full backup task is completed."
    exit 0
}
if([string]::IsNullOrEmpty($customerPrefix) -eq $FALSE)
{
  write-host "Customer Prefix is $customerPrefix"
}
else
{
   write-host '#############Error################'
   write-host "The Customer Prefix is null. Please contact administrator."
   exit 1
}
if($backupmode -eq 'full')
{
  #Here we are using flag file to stop other exection during full backup.
  write-host "Creating the flag file.."
  New-Item $fullbackupflagfile -type file
}
else
{
  #During transactional & Diffrential backup, then parent folder is present in environment variable. We are reading it.
  $sregistryfolder = [environment]::GetEnvironmentVariable($envval,"Machine")
  Start-Sleep -s 2
  if([string]::IsNullOrEmpty($sregistryfolder)) {            
    Write-Host "Given string from envirnement variable to get actual folder name is null."
    Write-Host "Getting the Actual folder Name from parent folder with ascending order."
    #exit 1 
    #############################
    [string[]]$drivesstr = $drives.Split(";")
    #$drivesstr = $drives.Split(";")
    $sdrivetrans = $drivesstr[0]
    $sfullpathdiff = $sdrivetrans + $customerPrefix + '\' + $instancename + '\'
    write-host "Backup folder is $sfullpathdiff"
    if((Test-Path -Path $sfullpathdiff )){
     $sfullfolderlistdiff = Get-ChildItem $sfullpathdiff
     [array]::Reverse($sfullfolderlistdiff)
     if($sfullfolderlistdiff.count -gt 0)
       {
          $sregistryfolder = $sfullfolderlistdiff[0].Name
          write-host "The Sub folder from Parent directory using ascending order is $sregistryfolder"
       }
       else
       {
          write-host "#############Error################"
          write-host "No Sub folders exist in the Parent Folder. Please contact administrator"
          exit 1
       }
    }
    else{
      write-host '#############Error################'
    write-host 'Full backup Parent Folder does not exist. Please run fullbackup code or Please contact administrator.'
      exit 1
      }
}
else {
    write-host 'Actual folder found from reading envirnmental variable'
    write-host "The Sub folder from Parent directory is $sregistryfolder"}
}

if($backupmode -eq 'transaction')
{
 if([string]::IsNullOrEmpty($sbucket) -eq $FALSE)
 #if (($sbucket).length -ne 0)
 {
  write-host "Bucket Name is $sbucket"
 }
 else
 {
   write-host '#############Error################'
   write-host "The bucket name is null. please contact administrator."
   exit 1 
 }
}

$strtimestamp = Get-Date -format "yyyyddMMHHmmss"
write-host "Running at $strtimestamp"
if($sqlversion -eq 2008)
{
    write-host 'Sql Server is 2008'
    if($pversion -eq 2)
    {
        write-host 'pversion is 2'
        start-sleep -m (Get-Random -minimum 1000 -maximum 5000)
        cd $sqlpsPath
        $framework=$([System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory())
        Set-Alias installutil "$($framework)installutil.exe"
        installutil /logfile Microsoft.SqlServer.Management.PSProvider.dll
        Add-PSSnapin SqlServerProviderSnapin100
        installutil /logfile Microsoft.SqlServer.Management.PSSnapins.dll
        Add-PSSnapin SqlServerCmdletSnapin100 | Out-Null

    }
   else
   {
    write-host 'pversion is greater than 2'
    if ( Get-PSSnapin -Registered | where {$_.name -eq 'SqlServerProviderSnapin100'} )
      { 
       write-host 'The SqlServerProviderSnapin100 is Registered'  
       Add-PSSnapin SqlServerProviderSnapin100 | Out-Null
      }
    else
    {
             write-host 'The SQL Snapin SqlServerProviderSnapin100 Providers are not present....Registering..'
             start-sleep -m (Get-Random -minimum 1000 -maximum 5000)
             cd $sqlpsPath
             $framework=$([System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory())
             Set-Alias installutil "$($framework)installutil.exe"
             installutil /logfile Microsoft.SqlServer.Management.PSProvider.dll
             Add-PSSnapin SqlServerProviderSnapin100
    }
            if ( Get-PSSnapin -Registered | where {$_.name -eq 'SqlServerCmdletSnapin100'} )
            {  
                    write-host 'The SqlServerCmdletSnapin100 is Registered'  
                    Add-PSSnapin SqlServerCmdletSnapin100 | Out-Null  
            }
            else
            {
             write-host 'The SQL Snapin SqlServerCmdletSnapin100 Providers are not present....Registering..'
             start-sleep -m (Get-Random -minimum 1000 -maximum 5000)
             cd $sqlpsPath
             $framework=$([System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory())
             Set-Alias installutil "$($framework)installutil.exe"
             installutil /logfile Microsoft.SqlServer.Management.PSSnapins.dll
             Add-PSSnapin SqlServerCmdletSnapin100 | Out-Null
            }
   }

}
else {
    Import-Module sqlps -DisableNameChecking
    write-host 'SQLPS powershell is used for sql backups.'
}

Set-Location SQLSERVER:\SQL\localhost\$instancename
if($backupmode -eq 'full')
{
   $sdbname = Invoke-Sqlcmd "SELECT name from sys.databases WHERE name NOT IN ('tempdb')" -ErrorAction Stop
}
if($backupmode -eq 'differential')
{
    $sdbname = Invoke-Sqlcmd "SELECT name from sys.databases WHERE name NOT IN ('tempdb', 'master', 'model')" -ErrorAction Stop 
}

if($backupmode -eq 'transaction')
{
  #[String[]]$drivesstr=@($drives)
  [String[]]$drivesstr = $drives.Split(";")
  #$drivesstr = $drives.Split(";")
  $sdrivetrans = $drivesstr[0]
  write-host "The Transactional Backup Drive $sdrivetrans"
  $sdbname = Invoke-Sqlcmd "SELECT name FROM sys.databases WHERE name NOT IN ('tempdb', 'master', 'model', 'msdb') and recovery_model_desc ='FULL'" -ErrorAction Stop 
}
[String[]]$qr_db=$null
foreach($db_res in $sdbname) {$qr_db=$qr_db+$db_res.Name}
if($qr_db.Count -eq 0) {
  write-host "#########WARNING############"
  write-host "NO APPLICATION DATABASES ARE PRESENT"
  #write-host '#############Error################'
  exit 0 
  }
write-host "Number of databases : "
write-host $qr_db.Count
$scount = $qr_db.Count - 1
for ($i=0; $i -le $scount ; $i++)
{
  write-host  "Database Name : "
  write-host $qr_db[$i]
  $dbname = $qr_db[$i]
  [String[]]$sdrives = $drives.Split(";")
  $scon = ''
  $sscon = ''
  $diffpath = ''
  for ($ii=0; $ii -lt $sdrives.Length ; $ii++)
   {
     if($backupmode -eq 'full')
     {
     $sfolder = $sdrives[$ii] + $customerPrefix + '\' + $instancename + '\' + $backupdir + '-' + $expirydate + '\'
     if(!(Test-Path -Path $sfolder )){
        New-Item -ItemType directory -Path $sfolder}
        $scon =  $sdrives[$ii] + $customerPrefix + '\' + $instancename + '\' + $backupdir + '-' + $expirydate + '\' + $backupmode + '_' + $dbname + '_' + $strtimestamp + '_' + $ii + '.bak'
     if($ii -eq ($sdrives.Length-1) ) {$sscon = $sscon+ "DISK = '" + $scon + "'"}
     else {$sscon = $sscon+ "DISK = '" + $scon+"',"}    
     }
     if($backupmode -eq 'differential')
     { 
        $diffpath = $sdrives[$ii] + $customerPrefix + '\' + $instancename + '\' + $sregistryfolder + '\'
        if(!(Test-Path -Path $diffpath )){
        New-Item -ItemType directory -Path $diffpath}
        $scon =  $diffpath + $backupmode + '_' + $dbname + '_' + $strtimestamp + '_' + $ii + '.bak'
        write-host "Diffrential backup path :  $scon"
     if($ii -eq ($sdrives.Length-1) ) {$sscon = $sscon+ "DISK = '" + $scon + "'"}
     else {$sscon = $sscon+ "DISK = '" + $scon+"',"}
     }     
   }
  $q = ""
  if($backupmode -eq 'full')
  { 
  $q = "BACKUP DATABASE [" + $dbname + "] TO " + $sscon + " WITH FORMAT, COMPRESSION"
  }
  if($backupmode -eq 'differential')
  { 
  write-host 'diff'
  $q = "BACKUP DATABASE [" + $dbname + "] TO " + $sscon + " WITH DIFFERENTIAL, FORMAT, COMPRESSION"
  }
  
  if($backupmode -eq 'transaction')
  { 
  $sfullpathtrans = $sdrivetrans + $customerPrefix + '\' + $instancename + '\' + $sregistryfolder
  if(!(Test-Path -Path $sfullpathtrans )){New-Item -ItemType directory -Path $sfullpathtrans}
  $fullpath = $sfullpathtrans + '\' + 'trans_' + $dbname + '_' + $strtimestamp + '.TRN' 
  write-host "Full path for transaction backup is : $fullpath"
  $q = "BACKUP log [" + $dbname + "] TO DISK = '" + $fullpath + "' WITH INIT,COMPRESSION"
  }
  $strstarttime = Get-Date -format "yyyy-MM-dd HH:mm:ss:ffffff"
  write-host "SQL Query started running at $strstarttime"
  write-host "Running Query is : $q"
  try
   {
      Invoke-Sqlcmd -Query $q -QueryTimeout ([int]::MaxValue) -ErrorAction Stop
      $strendtime = Get-Date -format "yyyy-MM-dd HH:mm:ss:ffffff"
      write-host "SQL Query completed successfully at $strendtime"
   }
   catch
   {
     $errorcode = 1
     write-host '#############Error################'
     write-host "Error occurred during running backup's.Please contact administrator."
     write-Host($error)
   }
}

if($backupmode -eq 'full')
# After completing on full backup, we are deleting the flag file & then setting the environment variable so that
#transactional and differential backups reads the parent folder
  { 
  Remove-Item $fullbackupflagfile -force
  $fullbackloc = $backupdir + '-' + $expirydate
  write-host "Env val is : $envval"
  [System.Environment]::SetEnvironmentVariable($envval, $fullbackloc, "Machine")
  Start-Sleep -s 2
  }
  if($backupmode -eq 'transaction')
  { 
    write-host 'Uploading to S3..'
    $spath = $sdrivetrans + $customerPrefix + '\' + $instancename + '\' + $sregistryfolder + '\'
    uploadtos3 -sfullpath $spath -sbucketname $sbucket -strtransfolder $sregistryfolder
  }
  if($errorcode -eq 1)
  {
    write-host '#############Error################'
    write-host "Error may be on Single database because of diffrent mode or New database with no full backup. Please check the logs.."
    write-host "Error occurred during running backup's.Please contact administrator."

    exit 1
  }
  }
  catch{
  write-host '#############Error################'
  write-host "Error occurred during running backup's.Please contact administrator."
  Write-Host($error)
  if($backupmode -eq 'full')
  {if($fullbackupflagfile -and  (Test-Path $fullbackupflagfile)){Remove-Item $fullbackupflagfile -force}
  }
  exit 1
  }
}

function uploadtos3([String]$sfullpath, [String]$sbucketname , [String]$strtransfolder)
{
#This function is used to upload the transactional backup to aws s3 bucket. The input variables are full path Set-Location
# of the backup folder,AWS S3 bucket name & timestamp of the created transactional backup.
write-host 'In Upload S3 function..'
#import-module AWSPowerShell -errorAction Stop
$accessKey=$env:AWS_ACCESS_KEY
$secretKey=$env:AWS_SECRET_ACCESS_KEY
$PSVERSION = $(get-host).Version.Major
$urlavb = "http://169.254.169.254/latest/meta-data/placement/availability-zone/"
$urlinstance = "http://169.254.169.254/latest/meta-data/instance-id"
start-sleep -m (Get-Random -minimum 1000 -maximum 3000)
if($accessKey -ne $null -and $secretKey -ne $null)
{
    write-host 'Able to read the AWS keys from environment variables.Using AWS Keys to complete this task..'
    $creds = New-AWSCredentials -AccessKey $accessKey -SecretKey $secretKey
    Set-AWSCredentials -Credential $creds
}
If($PSVERSION -eq 2)
{
 write-host "Using System.Net.WebRequest for ps 2.0"
 $r = [System.Net.WebRequest]::Create($urlavb)
 $resp = $r.GetResponse()
 $reqstream = $resp.GetResponseStream()
 $sr = new-object System.IO.StreamReader $reqstream
 $Region = $sr.ReadToEnd()
 write-host "Region is $Region"
}
else
{
write-host "Using invoke-restmethod for ps 3.0 or more"
$Region = invoke-restmethod -uri $urlavb -errorAction Stop
}
[String]$Region = $Region.Substring(0,$Region.Length-1)
write-host "Region is : $Region"
if ($Region.Contains("gov")) { Initialize-AWSDefaults -Region $Region }
if (Test-Path -path $sfullpath)
  {
  $getbucket =  Get-S3Bucket -BucketName $sbucketname
  if ($getbucket.BucketName){}
     #if ((Get-S3Bucket -BucketName $sbucketname).BucketName){}
     else
         {
             write-host 'Bucket is creating...'
            New-S3Bucket -BucketName $sbucketname
           
         }
     write-host $strtransfolder
    $strkey = "backup/$customerPrefix/$instancename/$strtransfolder/"
    write-host "Key details : $strkey"
    $S3FileList = Get-S3Object -BucketName $sbucketname -KeyPrefix $strkey | Select-Object -ExpandProperty Key | ForEach-Object -Process {
    $_.ToString().Replace($strkey, '') }
    write-host "No of objects from S3 Objects : "
    write-host $S3FileList.Count
     #$slist =  Get-ChildItem $sfullpath | Where-Object {$_.Extension -eq ".TRN" -and $_.Name -like $sfilefilter }
     $slist = Get-ChildItem $sfullpath | Where-Object {$_.Extension -eq ".TRN"}
     #Only .TRN file will be moved to the array.This filter will filter only .TRN files with files which
     # are just created transactional backup.
     if($slist)
       {
       write-host "Total count of files(.TRN) in folder :"
       write-host $slist.count
          foreach ($sfiles in $slist)
             {
                #if ($S3FileList.Count -eq 0 -or !($S3FileList -Contains $sfiles)){
                if ($S3FileList.Count -eq 0 -or !($S3FileList -Contains $sfiles)){
                   $finalkey = $sfiles.FullName.Substring(2).Replace("\", "/")
                   write-host "Uploading the transaction log file : $finalkey"
                   Write-S3Object -BucketName $sbucketname -Key $finalkey -File $sfiles.FullName -ServerSideEncryption 'AES256'
                   }
             } 
       }
      else{
      write-host '#############Error###############'
      write-host 'No TRN exists in the selected folder. Please contact administrator.'
           exit 1
          }
  }
  else
  {
  write-host '#############Error################'
  write-host 'Parent folder does not exists. Please contact administrator.'
   exit 1
  }
}

function Getparamsvalue
{
param(
    [Parameter(Mandatory=$true)] [String]$contentfile,
    [Parameter(Mandatory=$true)] [String]$strparameter
)
$inum = 0
$content = Get-Content $contentfile
$fullstrparameter = $strparameter + ':'
foreach ($line in $content)
 {
  if($line.StartsWith($fullstrparameter))
    {
      $slen = $fullstrparameter.length
      $sval = $line.Substring($slen)
      #write-host $sval
      $finalval = $sval.trim()
      #write-host $finalval
      $inum = 1
      return $finalval
    }
 }
 if($inum -eq 0){return $null}
}

try{
    $strtime = Get-Date -format "MM-dd-yyyy HH:mm:ss:ffffff"
    write-host "#################Backup Application started running at $strtime#################"
    write-host 'The Backup mode is :'
    write-host $sflag
    $instancename = ""
    $sqlversion = 0
    #$namedinstance = $args[1]
    if([string]::IsNullOrEmpty($sflag)){
      write-host 'Arguments are not passed correctly. Please contact administrator.'
      exit 1
    }
     start-sleep -m (Get-Random -minimum 1000 -maximum 3000)
     $strtimeformat = Get-Date -format "yyyyMMddHHmmss"
     if([string]::IsNullOrEmpty($namedinstance)) { $instancename='default' } else { $instancename=$namedinstance }
     #if (($namedinstance).length -eq 0 ) { $instancename='default' } else { $instancename=$namedinstance }
     write-host "The Instance Name is $instancename"
     $strtimedate = Get-Date -format "MM-dd-yyyy"
     $outputfile2='C:\testbc\log\' +$strtimedate + '\salt-sql-db-' + $sflag + '-backup-' + $instancename + '-history.log'
     $LogFilePreference = $outputfile2
     write-host "#################Backup Application started running at $strtime#################"
     $contentfile = 'C:\salt\conf\grains'
     $CustPrefix = Getparamsvalue -contentfile $contentfile -strparameter "CustPrefix"
     write-host "The customer prefix is $CustPrefix" 
     [string]$defaultfullbackupdir = Getparamsvalue -contentfile $contentfile -strparameter "backupdrive"
     if([string]::IsNullOrEmpty($defaultfullbackupdir))
     {
       write-host "The default full backup directory value is null. Adding the default value."
       $defaultfullbackupdir = "E:\backup\"
       write-host "The default full backup directory value is $defaultfullbackupdir"
     }
     else
     {
      write-host "The default full backup directory value is "
      write-host $defaultfullbackupdir
      #$defaultfullbackupdir= "'"+$defaultfullbackupdir+"'"
     }
    $PSVERSION = $(get-host).Version.Major
    If($PSVERSION -eq 2){$PSVERSION = 2}else{$PSVERSION = 3}
    #$PSVERSION = Getparamsvalue -contentfile $contentfile -strparameter "PSVERSION" 
    [String]$sresult = $(Get-ItemProperty HKLM:\SOFTWARE\Microsoft\MSSQLServer\MSSQLServer\CurrentVersion).currentversion
    write-host "SQL Actual Version is $sresult"
    if([string]::IsNullOrEmpty($sresult) -eq $FALSE)
    {
           if ([int]$sresult.Split(".")[0] -lt 11)
           {
            write-host "SQL Server Version is sql server 2008 R2 or lower."
            $sqlversion = 2008
           }
           else
           {
             write-host "SQL server version is sql server 2012 or higher"
             $sqlversion = 2012
           }
    }
    else{
          write-host 'SQL Version registry --> HKLM:\SOFTWARE\Microsoft\MSSQLServer\MSSQLServer\CurrentVersion is null. Please contact administrator.'
          exit 1
    }
     write-host "PSVERSION value is $PSVERSION"
     $strBACKUP_ENVDate=$env:BACKUP_EXPIRY_DAYS
     if([string]::IsNullOrEmpty($strBACKUP_ENVDate)) { $strBACKUP_ENVDate=30 }
     write-host "Expiry Days is $strBACKUP_ENVDate"
     $intexpiryDate = [int]$strBACKUP_ENVDate
     $strexpirydate = [DateTime]::Now.AddDays($intexpiryDate)
     $strexpirydate = $strexpirydate.ToString("yyyyMMddHHmmss")
     $strMsg="Starting "+ $sflag + " backup for the instance " + $instancename
     write-host $strMsg
     start-sleep -m (Get-Random -minimum 1000 -maximum 30000)
     runbackup -backupmode $sflag -instancename $instancename -backupdir $strtimeformat -expirydate $strexpirydate -customerPrefix $CustPrefix -drives $defaultfullbackupdir -pversion $PSVERSION
     $strtime = Get-Date -format "MM-dd-yyyy HH:mm:ss:ffffff"
     write-host "##################Backup Application ending at $strtime##################"

     Start-Sleep -s 3
    }
    catch{
     write-host "###############Error while running the sql main program. Please contact administrator.############"
     Write-Host($error)
     $strtime = Get-Date -format "MM-dd-yyyy HH:mm:ss:ffffff"
     write-host "##################Application ending at $strtime##################"
     exit 1
    }
