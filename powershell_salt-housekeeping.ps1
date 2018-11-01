<#
*****************************************************************************************************************
/*File Name       : salt-housekeeping.ps1
* Project         : CloudSuite Single-Tenant
* Object          :
* Purpose         : This Code is used to collect inputs from arguments & pass the testmation to housekeeping.ps1. 
* Description     :
* Author          : ddd
* Date            : 11-JAN-2015
*****************************************************************************************************************
#>
param(
    [Parameter(Mandatory=$true)] [String]$namedinstance
    )
import-module -Name C:\testbc\lib\standard\Logging.psm1
import-module -Name C:\testbc\lib\standard\errohandling.psm1
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


function deleteSQLBackups($instancename)
{
  try
  {
    write-host "--------------Running deleteSQLBackups----------------"
    write-host '-------------------------'
    $sqlversion = 0
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
     write-host $intexpiryDate
     $strBACKUPfor_ENVDate= "-" + $strBACKUP_ENVDate
     $intexpiryDatefor = [int]$strBACKUPfor_ENVDate
     write-host $intexpiryDatefor
  

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
$strQuery = "declare  @oldest_date datetime = DateAdd(DD," + $intexpiryDatefor + ",GETDATE() );EXEC sp_delete_backuphistory @oldest_date"
Write-Host $strQuery
Invoke-Sqlcmd -Query $strQuery -Database "msdb" -QueryTimeout ([int]::MaxValue) -ErrorAction Stop
write-host "SQL Query completed successfully"
}
catch 
   {
   #The process cannot access
    write-host '#############Error################'
    write-host $_.Exception
    write-host '-----------deleteSQLBackups is having issues. Please contact administrator.-------'
    #exit 1
   }
   }
   deleteSQLBackups

function deletelogs($logfolder,$expirtdays)
{
  try{
  write-host "--------------Running delete log folders----------------"
  write-host "-------------------------"
  write-host "Log location $logfolder"
  write-host "Expiry days : $expirtdays"
  [int]$intExpdays = "-$expirtdays"
  $listexpiryfolders = Get-ChildItem $logfolder | Where { $_.PSIsContainer } | Where{$_.CreationTime  -le (Get-Date).AddDays($intExpdays)}
  write-host "The No of log folders Count is :"
  write-host $listexpiryfolders.count
  if($listexpiryfolders.count -gt 0)
  {
    foreach ($sfolder in $listexpiryfolders)
    {
        if((TEST-PATH -path $sfolder.FullName))
        {
        $deletefolder = $logfolder + $sfolder
        Remove-Item $deletefolder -recurse -ErrorAction SilentlyContinue
        write-host "Deleted $deletefolder"
        }
    }
  }
}
catch 
   {
   #The process cannot access
    write-host '#############Error################'
    write-host $_.Exception
    write-host '-----------delete log folders is having issues. Please contact administrator.-------'
    #exit 1
   }
}

function multisplitdeleteexpirydir($drives,$scustomerprefixval,$instancename)
{
 write-host '--------------Running delete older folders for multi split folders---------------'
 write-host '-------------------------'
[String[]]$sdrives = $drives.Split(";")
for ($ii=0; $ii -lt $sdrives.Length ; $ii++)
   {
  $sfullpath = $sdrives[$ii]+$scustomerprefixval+'\'+$instancename
  if((TEST-PATH -path $sfullpath))
     {
        $sfullfolderlist = Get-ChildItem $sfullpath
        if($sfullfolderlist.count -gt 0)
            {
            write-host "Number of folders retrived : "
            write-host $sfullfolderlist.count
             foreach ($sfolder in $sfullfolderlist)
              {
               #Write-Host 'folder is : ' $sfolder
               $s = [String]$sfolder
                $splitfolder =  $s.split('-')
                 #Write-Host $splitfolder[1]
                  $today = Get-Date
                 [datetime]$dirDate = New-Object DateTime 
                  if([DateTime]::TryParseExact($splitfolder[1], "yyyyMMddHHmmssss",[System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$dirDate))
                      {
                     $tspan=New-TimeSpan $dirDate $today;
                     $diffDays=($tspan).days;
                      #write-host $diffDays
                    if ($diffDays -ge 0)
                            {
                            write-host "Date diffrences is : $diffDays"
                            $sdeletepath = $sfullpath + '\'+$sfolder
                            Remove-Item $sdeletepath -recurse -force
                            write-host "Deleted the following folder : $sdeletepath"
                            }
                      }
              }
            }
            else
             {
              Write-Host ' No folders exist in parent folder'
              #exit 1
             }
     }
     else
     {
         Write-Host "The Parent folder does not exist : $sfullpath"  
         #exit 1
     }
     }
}

function deletes3obj($sbucket,$scustomerprefixval,$instancename)
{
start-sleep -m (Get-Random -minimum 30000 -maximum 80000)
$retries = 5
$retrycount = 0
$completed = $false
while (-not $completed){
try
{
start-sleep -m (Get-Random -minimum 30000 -maximum 80000)
write-host '----------------Running delete S3 object function------------------'
write-host '----------------------'
$getbucket =  Get-S3Bucket -BucketName $sbucket
if ($getbucket.BucketName)
{
$refkey = "/backup/"+$scustomerprefixval+"/"+$instancename
write-host "Getting the following objects : $refkey"
$marker = $null
do
{
Start-Sleep -s 2
$objects = (get-s3object -bucketname $sbucket -KeyPrefix $refkey -MaxKey 900 -Marker $marker)
$marker= $AWSHistory.LastServiceResponse.NextMarker
#$objects1 = get-s3object -bucketname $sbucket -KeyPrefix $refkey
#write-host 'Marker Value is : '$marker
foreach ($file in $objects) 
{
 if(!($file.Key.Contains('$folder$')))
   {
    #write-host $strfile
    $strfile = $file.Key.split("/")
    if($strfile[3].Contains('-'))
     {
      if(!($strfile[3].Contains('.txt')))
        {
            $expdate = $strfile[3].split("-")[-1]
             $today = Get-Date
            [datetime]$dirDate = New-Object DateTime 
            if([DateTime]::TryParseExact($expdate, "yyyyMMddHHmmssss",[System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$dirDate)){
                     $tspan=New-TimeSpan $dirDate $today;
                     $diffDays=($tspan).days;
                     #write-host $diffDays
            if ($diffDays -ge 0)
                    {  
                    write-host "Date diffrences is : $diffDays"
                    Remove-S3Object -BucketName $sbucket -Key $file.Key -Force
                    write-host "Deleted the following file : "
                    write-host $file.Key
                    }
            }
        }
    }
  }
}

} while ($marker)
}
else{
write-host '#############Error################'
write-host 'Bucket name does not exist.Please contact administrator.'
exit 1
}
$completed = $true
}
catch {
     [string]$serror = $_.Exception
     write-host "Into catch..primary Error details"
     write-host $serror
     if ($retrycount -ge $retries) 
     {
      write-host '#############Error################'
      write-host $_.Exception.Message
      write-host '-----------Failed for multiple attempts.-------'
      write-host '-----------deletes3obj is having issues. Please contact administrator.-------'
      exit 1
     }
     else
     {
      if($serror -eq "Request limit exceeded.")
       {
        write-host "Request limit exceeded occured. Again running into the loop."
        start-sleep -m (Get-Random -minimum 200000 -maximum 400000)
        $retrycount++
       }
       else
        {
          write-host "New Exception occured...."
          #write-host '#############Error################'
          write-host "New Exception occured. Again running into the loop."
           write-host $_.Exception.Message
           start-sleep -m (Get-Random -minimum 200000 -maximum 400000)
           $retrycount++
        }
     }
   }
}

}
##During Housekeeping, we use Prune action & will delete the Snapshot based on Expiry Date. 
function deletesnapshot($customerprefix,$scustomerprefixval,$psversion)
{
start-sleep -m (Get-Random -minimum 30000 -maximum 80000)
$retries = 30
$retrycount = 0
$completed = $false
while (-not $completed)
{
  try {
    write-host '---------------Running delete snapshot function----------------------'
    write-host '-------------------------------------------------------'
    $urlinstance = "http://169.254.169.254/latest/meta-data/instance-id"
    $urlavb = "http://169.254.169.254/latest/meta-data/placement/availability-zone/"
    if ($psversion -eq 2)
    {
    write-host "Using System.Net.WebRequest for ps 2.0"
     $r = [System.Net.WebRequest]::Create($urlinstance)
     $resp = $r.GetResponse()
     $reqstream = $resp.GetResponseStream()
     $sr = new-object System.IO.StreamReader $reqstream
     $InstanceName = $sr.ReadToEnd()
     write-host "Instance ID is: $InstanceName"
     $r = [System.Net.WebRequest]::Create($urlavb)
     $resp = $r.GetResponse()
     $reqstream = $resp.GetResponseStream()
     $sr = new-object System.IO.StreamReader $reqstream
     $Region = $sr.ReadToEnd()
     write-host "Region is: $Region"
    }
    else 
    {
        write-host "Using invoke-restmethod for ps 3.0 or more"
        $InstanceName = invoke-restmethod -uri $urlinstance
        write-host "Instance ID is: $InstanceName"
        $Region = invoke-restmethod -uri $urlavb    
    }
    $strhostname = $env:COMPUTERNAME
    $smahinelabel = $strhostname +"-" + $scustomerprefixval
    $Region = $Region.Substring(0,$Region.Length-1)
    Set-DefaultAWSRegion $Region
    $filtertagkey = New-Object Amazon.EC2.Model.Filter
    $filtertagkey.Name = "tag:$customerprefix"
    $filtertagkey.Value.Add($scustomerprefixval)
    
    $filtertagmachinekey = New-Object Amazon.EC2.Model.Filter
    $filtertagmachinekey.Name = "tag:machineLabel"
    $filtertagmachinekey.Value.Add($smahinelabel)
    
    if ($psversion -eq 2)
    {
    write-host 'Using ps version 2 style to get snapshots.'
    $sgetallsnapshotid = Get-EC2Snapshot -Filter $filtertagkey, $filtertagmachinekey
    }
    else
    {
    $smahinelabel = $strhostname +"*"
    write-host 'Using ps version 3 style to get snapshots.'
    $sgetallsnapshotid = Get-EC2Snapshot -Filter $filtertagkey | Where-Object {$_.Tag.Key -eq 'machineLabel' -and $_.Tag.Value -like $smahinelabel -and $_.status -eq 'completed'}
    }
    #$sgetallsnapshotid = Get-EC2Snapshot -Filter $filtertagkey, $filterval | Where-Object {$_.Tag.Key -eq 'machineLabel' -and $_.Tag.Value -eq $smahinelabel -and $_.status -eq 'completed'}
    #write-host $sgetallsnapshotid
    write-host "Number of Snapshots retrived : "
    write-host $sgetallsnapshotid.count
    if($sgetallsnapshotid) {
    foreach ($s in $sgetallsnapshotid)
    {
        $filterresid = New-Object Amazon.EC2.Model.Filter
        $filterresid.Name = "resource-id"
        $filterresid.Value.Add($s.SnapshotId)
        $filterkey = New-Object Amazon.EC2.Model.Filter
        $filterkey.Name = "key"
        $filterkey.Value.Add("Name")
        $ss = Get-EC2Tag -Filter $filterresid, $filterkey
        if($ss.Value.Contains($InstanceName))
            {
                $filterresid = New-Object Amazon.EC2.Model.Filter
                $filterresid.Name = "resource-id"
                $filterresid.Value.Add($s.SnapshotId)
                $filterkey = New-Object Amazon.EC2.Model.Filter
                $filterkey.Name = "key"
                $filterkey.Value.Add("BackupInfo")
                $sec2taginfo = Get-EC2Tag -Filter $filterresid, $filterkey
                $sexpirydatesplit =  $sec2taginfo.Value.split('|')[-1]
                $sdate = $sexpirydatesplit.split(':')[-1]
                $sexpirydate = Get-Date $sdate -Format 'dd-MMM-yyyy'
                $today = Get-Date -format 'dd-MMM-yyyy'
                $tspan=New-TimeSpan $sexpirydate $today;
                $diffDays=($tspan).days;
                
                if ($diffDays -ge 0)
                    {
                    write-host "Date diffrences is: $diffDays"
                    Remove-EC2Snapshot -SnapshotId $s.SnapshotId -Force
                    write-host "Deleted the snapshot : "
                    write-host $s.SnapshotId
                    }
            }
    }
}
$completed = $true
write-host "Completed value is true.."
}
  catch {
     [string]$serror = $_.Exception
     write-host "Into catch..primary Error details"
     write-host $serror
     if ($retrycount -ge $retries) 
     {
      write-host '#############Error################'
      write-host $_.Exception.Message
      write-host '-----------Failed for multiple attempts.-------'
      write-host '-----------CreateSnapshot is having issues. Please contact administrator.-------'
      exit 1
     }
     else
     {
      if($serror -Contains "Request limit exceeded.")
       {
        write-host "Request limit exceeded occured. Again running into the loop."
        start-sleep -m (Get-Random -minimum 300000 -maximum 600000)
        Start-Sleep -s 120
        $retrycount++
       }
       else
        {
          write-host "New Exception occured...."
          #write-host '#############Error################'
          write-host "New Exception occured. Again running into the loop."
           write-host $_.Exception.Message
           Start-Sleep -s 120
           start-sleep -m (Get-Random -minimum 300000 -maximum 600000)
           $retrycount++
        }
     }
   }
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
      write-host $sval
      $finalval = $sval.trim()
      write-host $finalval
      $inum = 1
      return $finalval
    }
 }
 if($inum -eq 0){return $null}
}

function deletes3objp3($sbucket,$scustomerprefixval,$instancename)
{
try
{
write-host '-------------Running delete S3 objects-------------------'
write-host '-------------------------------------------------------'
$getbucket =  Get-S3Bucket -BucketName $sbucket
if ($getbucket.BucketName)
{
$refkey = "/backup/"+$scustomerprefixval+"/"+$instancename
$objects = get-s3object -bucketname $sbucket -Key $refkey
foreach ($file in $objects) {
if(!($file.Key.Contains('$folder$')))
   {
    $strfile = $file.Key.split("/")
    if($strfile[3].Contains('-'))
     {
      if(!($strfile[3].Contains('.txt')))
        {
            $expdate = $strfile[3].split("-")[-1]
             $today = Get-Date
            [datetime]$dirDate = New-Object DateTime 
            if([DateTime]::TryParseExact($expdate, "yyyyMMddHHmmssss",[System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$dirDate)){
                     $tspan=New-TimeSpan $dirDate $today;
                     $diffDays=($tspan).days;
                      #write-host $diffDays
            if ($diffDays -ge 0)
                    {   
                      write-host "Date diffrences is : $diffDays"
                    Remove-S3Object -BucketName $sbucket -Key $file.Key -Force
                    write-host "Deleted the following file :"
                    write-host $file.Key
                    }
            }
      
        }
    }
 }
}

}
else{
Write-Error 'Bucket name does not exist.Please contact administrator.'
exit 1
}
}
catch 
   {
    Write-Error $_.Exception
    write-host '-----------S3 is having issues. Please contact administrator.-------'
    exit 1
   }

}

function runhousekeeping([String]$sbucket,[String]$instancename,[String]$customerPrefix,[String]$psversion,[String]$drives)
{
try{
     write-host '-------------Running runhousekeeping---------------'
   #[String[]]$drives=@($drives)
   write-host "Drives Name is : " 
   write-host $drives
    $dirloc = "c:\testbc\"
    $logloc = "C:\testbc\log\"
    $customerprefixname = 'customerPrefix'
    $strserviceName = "MSSQLSERVER"
    $service = Get-Service -Name $strserviceName -ErrorAction SilentlyContinue
    [string]$serviceName = $service.Name
    if([string]::IsNullOrEmpty($serviceName) -eq $FALSE)
      {
         write-host "SQL Service are running.."
         multisplitdeleteexpirydir -drives $drives -scustomerprefixval $customerPrefix -instancename $instancename
         deleteSQLBackups -instancename $instancename
         If($psversion -eq 2)
         {
             write-host 'deletes3objp3 is executing now'
             deletes3objp3 -sbucket $sbucket -scustomerprefixval $customerPrefix -instancename $instancename
         }
         else{
             write-host 'deletes3obj is executing now'
             deletes3obj -sbucket $sbucket -scustomerprefixval $customerPrefix -instancename $instancename
         }
      }
    deletesnapshot -customerprefix $customerprefixname -scustomerprefixval $customerPrefix -psversion $psversion
    deletelogs -logfolder $logloc -expirtdays "15"
   }
catch 
   {
    write-host '#############Error################'
    write-host "Error occurred during running Housekeeping...."
    write-host $_.Exception
    write-host '-----------House keeping is having issues. Please contact administrator.-------'
    exit 1
   }
}

try{
start-sleep -m (Get-Random -minimum 3000 -maximum 10000)
$instancename = ""
if([string]::IsNullOrEmpty($namedinstance)) { $instancename='default' } else { $instancename=$namedinstance }
#if (($namedinstance).length -eq 0 ) { $instancename='default' } else { $instancename=$namedinstance }
write-host "Instance Name is : $instancename"
$strtimedate = Get-Date -format "MM-dd-yyyy"
$outputfile2='C:\testbc\log\' +$strtimedate+ '\'+ $instancename+ '-salt-housekeeping-history.log'
$contentfile = 'C:\salt\conf\grains'
$strcurrentDate = Get-Date -format "yyyyMMddHHmmss"
$sbucket=$env:BUCKET_NAME
$LogFilePreference = $outputfile2
$strtimestamp = Get-Date -format "MM-dd-yyyy HH:mm:ss:ffffff"
write-host "#################Application started running at $strtimestamp#################"
if([string]::IsNullOrEmpty($sbucket)) 
{
 write-host '#############Error################'
 write-host "Bucket Name does not exist. Please contact administrator."
 exit 1
}
write-host 'Checking the Powershell version..'
$PSVERSION = $(get-host).Version.Major
If($PSVERSION -eq 2)
{
$PSVERSION = 2
}
else
{
$PSVERSION = 3
}
write-host "Final PSVERSION value is $PSVERSION"
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
 $accessKey=$env:AWS_ACCESS_KEY
 $secretKey=$env:AWS_SECRET_ACCESS_KEY
if($accessKey -ne $null -and $secretKey -ne $null)
  {
        write-host "Activated AWS keys.."
        $creds = New-AWSCredentials -AccessKey $accessKey -SecretKey $secretKey
        Set-AWSCredentials -Credential $creds
  }
$CustPrefix = Getparamsvalue -contentfile $contentfile -strparameter "CustPrefix"
if([string]::IsNullOrEmpty($CustPrefix))
     {  
        write-host '#############Error################'          
        write-host "The CustomerPrefix value is having some issues. Please contact administrator.  " 
        exit 1           
     }
write-host "The customer prefix is $CustPrefix"
start-sleep -m (Get-Random -minimum 3000 -maximum 30000)
runhousekeeping -sbucket $sbucket -drives $defaultfullbackupdir -customerPrefix $CustPrefix -instancename $instancename -psversion $PSVERSION
#$strprocessoutput = Start-Process powershell "C:\testbc\lib\standard\housekeeping.ps1 -sbucket $sbucket -drives $defaultfullbackupdir -customerPrefix $CustPrefix -instancename $instancename -psversion $PSVERSION" -RedirectStandardOutput $outputfile -PassThru -windowstyle Hidden -Wait
$strtime = Get-Date -format "MM-dd-yyyy HH:mm:ss:ffffff"
write-host "#################Application ending at $strtime######################"
exit $strprocessoutput.ExitCode
}
catch{
  write-host '#############Error################'
  write-host "Error while running the Housekeeping program. Please contact administrator."
  Write-Host($error)
  $strtime = Get-Date -format "MM-dd-yyyy HH:mm:ss:ffffff"
  write-host "#######################Application ending at $strtime#########################"
  exit 1
  }