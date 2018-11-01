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
import-module -Name C:\testbc\lib\standard\errohandling.psm1
#import-module AWSPowerShell -errorAction Stop
$VerbosePreference = 'Continue' 
$DebugPreference = 'Continue'
start-sleep -m (Get-Random -minimum 1000 -maximum 3000)
$strtimestamp = Get-Date -format "yyyyMMddHHmmssffffff"
write-host "###################Application starting at $strtimestamp#####################"
$strtimedate = Get-Date -format "MM-dd-yyyy"
$outputfile2='C:\testbc\log\' +$strtimedate+'\salt-createsnapshot-history.log'

function uploadtxttos3($snapshotloc,$sbucket,$scustomerprefixval)
{
try
{
  write-host '--------------In the uploadtxttos3 function.-----------'
    if (!(Test-Path -path $snapshotloc)){New-Item -ItemType directory -Path $snapshotloc}
    if ((Get-S3Bucket -BucketName $sbucket).BucketName)
  {
  write-host 'Bucket Name exists...'
  }
    else
        {
            New-S3Bucket -BucketName $sbucket -errorAction Stop
            write-host 'Bucket is creating...'
        }
        $slist = Get-ChildItem $snapshotloc | Where-Object {$_.Extension -eq ".txt"}
    if($slist)
    {
        foreach ($sfiles in $slist)
        {
         write-host $sfiles.Basename
         $finalkey = '/backup/'+$scustomerprefixval+'/'+ $sfiles.Basename+'.txt'
         write-host $finalkey
         $fName = $snapshotloc + $sfiles.Basename +'.txt'
         write-host "File Name : $fName"
         Write-S3Object -BucketName $sbucket -Key $finalkey -File $fName -ServerSideEncryption 'AES256' -errorAction Stop 
         write-host "The file is uploaded to aws S3 : $fName"
        }
   }
   else
   {
   write-host 'No txt files present to upload to s3.'
   }

}
 catch 
   {
    write-host '#############Error################'
    write-host $_.Exception.Message
    write-host '-----------uploadtxttos3 is having issues. Please contact administrator.-------'
    exit 1
   }

}

function createsnapshot($customerprefix,$scustomerprefixval,$psversion)
{
$retries = 30
$retrycount = 0
$completed = $false
while (-not $completed)
{
try
{
  write-host '-----------------Running createsnapshot Function---------------------'
  if (!(Test-Path -path $snapshotloc)){New-Item -ItemType directory -Path $snapshotloc}
    $urlinstance = "http://169.254.169.254/latest/meta-data/instance-id"
    $urlavb = "http://169.254.169.254/latest/meta-data/placement/availability-zone/"
    $macId = "http://169.254.169.254/latest/meta-data/network/interfaces/macs/"
    $vpcid = ""


    $backuptype = 'online'
    if ($psversion -eq 2)
    {
    write-host "Using System.Net.WebRequest for ps 2.0"
    $r = [System.Net.WebRequest]::Create($urlinstance)
    $resp = $r.GetResponse()
    $reqstream = $resp.GetResponseStream()
    $sr = new-object System.IO.StreamReader $reqstream
    $InstanceName = $sr.ReadToEnd()
    write-host "Instance ID is $InstanceName"
    $r = [System.Net.WebRequest]::Create($urlavb)
    $resp = $r.GetResponse()
    $reqstream = $resp.GetResponseStream()
    $sr = new-object System.IO.StreamReader $reqstream
    $Region = $sr.ReadToEnd()
    write-host "Region is $Region"
    $rmacId = [System.Net.WebRequest]::Create($macId)
    $respmacid = $rmacId.GetResponse()
    $reqstreammacid = $respmacid.GetResponseStream()
    $srmacid = new-object System.IO.StreamReader $reqstreammacid
    $macid = $srmacid.ReadToEnd()
    write-host "THe Mac ID is $macid "
    $vpcId = "http://169.254.169.254/latest/meta-data/network/interfaces/macs/"+$macid+"vpc-id"
    $rvpcId = [System.Net.WebRequest]::Create($vpcId)
    $respvpcid = $rvpcId.GetResponse()
    $reqstreamvpcid = $respvpcid.GetResponseStream()
    $srvpcid = new-object System.IO.StreamReader $reqstreamvpcid
    $vpcid = $srvpcid.ReadToEnd()
    write-host "THe VPC ID is $vpcid "
    }
    else 
    {
     write-host "Using invoke-restmethod for ps 3.0 or more"
     $InstanceName = invoke-restmethod -uri $urlinstance -errorAction Stop
     write-host "Instance ID is $InstanceName"
     $Region = invoke-restmethod -uri $urlavb -errorAction Stop
     $macid = invoke-restmethod -uri $macId -errorAction Stop
     write-host "Instance ID is $macid"
     $vpcId = "http://169.254.169.254/latest/meta-data/network/interfaces/macs/"+$macid+"vpc-id"
     $vpcid = invoke-restmethod -uri $vpcId -errorAction Stop
     write-host "Instance ID is $vpcid"
    }
    $Region = $Region.Substring(0,$Region.Length-1)
    Set-DefaultAWSRegion $Region
    $filtertagkey = New-Object Amazon.EC2.Model.Filter -errorAction Stop 
    $filtertagkey.Name = "attachment.instance-id"
    $filtertagkey.Value.Add($InstanceName)
    $filterval = New-Object Amazon.EC2.Model.Filter -errorAction Stop
    $filterval.Name = "tag-value"
    $stime = Get-Date -format 'yyyyMMddHHmmss'
    $filterval.Value.Add($scustomerprefixval)
    $sgetallsnapshotid = Get-EC2Volume -Filter $filtertagkey -errorAction Stop 
    write-host $sgetallsnapshotid.VolumeId
    $Attachments = $sgetallsnapshotid.VolumeId.Attachment
    write-host $Attachments.Device
    
    foreach ($s in $sgetallsnapshotid)
     {
         write-host "In the loop.."
         $sdesc = "Snapshot created for volume id "+$s.VolumeId+" from instance id "+$InstanceName+" at time "+$stime
         start-sleep -m (Get-Random -minimum 2000 -maximum 6000)
         $getsnapshotID = New-EC2Snapshot -VolumeId $s.VolumeId -Description $sdesc -errorAction Stop 
         write-host "The New snapshot created is :"
         write-host $getsnapshotID.SnapshotId
         write-host "The device ID is :"
         $sdriveid = $s.Attachment | select device
         write-host $sdriveid.Device
         $createdate = Get-Date -format 'dd-MMM-yyyy'
         $expirydate = (get-date).AddDays($expirydays).ToString("dd-MMM-yyyy")
         $expiryformat = (get-date).AddDays($expirydays).ToString("yyyyMMddHHmmss")
         $sBackupInfo = $backuptype +'|CreatedDate:'+$createdate+'|ExpiryDate:'+$expirydate
         write-host $sBackupInfo
         $snamelabel = $InstanceName + '-'+$s.VolumeId+'-'+$sdriveid.Device+'-'+$stime
         write-host $snamelabel
         $strhostname = $env:COMPUTERNAME
         $smahinelabel = $strhostname +"-" + $scustomerprefixval
         $tagname = New-Object Amazon.EC2.Model.Tag 
         $tagname.Key = "Name" 
         $tagname.Value = $snamelabel

         $tagBackupInfo = New-Object Amazon.EC2.Model.Tag 
         $tagBackupInfo.Key = "BackupInfo" 
         $tagBackupInfo.Value = $sBackupInfo

         $tagcustprefix = New-Object Amazon.EC2.Model.Tag 
         $tagcustprefix.Key = "customerPrefix" 
         $tagcustprefix.Value = $scustomerprefixval

         $tagmachinel = New-Object Amazon.EC2.Model.Tag 
         $tagmachinel.Key = "machineLabel" 
         $tagmachinel.Value = $smahinelabel
         New-EC2Tag -ResourceId $getsnapshotID.SnapshotId -Tag $tagname, $tagBackupInfo, $tagmachinel, $tagcustprefix -errorAction Stop 
         $sappendtxt = 'YYYYMMDDHHMMSS:'+$stime + ' & expdate:'+$expiryformat +' & SnapshotID:'+ $getsnapshotID.SnapshotId +' & VolumeID:'+$s.VolumeId + ' & region:'+ $Region+ ' & Deviceid:'+$sdriveid.Device
         $file = $snapshotloc+$InstanceName+ '-' + $smahinelabel + '-' + $vpcid +'.txt'
         if (Test-Path $file)
         {
            write-host 'File exists.'
          if ((Get-Item $file).length -gt 10240kb)
          {
            write-host 'File is greater than 5 mb'
            $strtimestamp = Get-Date -format "yyyyMMddHHmmss"
            $filerename = $snapshotloc+$InstanceName+$strtimestamp+'.txt'
            Rename-Item $file $filerename
          }
         }
         write-host 'Appending the Text.'
         Start-Sleep -s 4
         start-sleep -m (Get-Random -minimum 1000 -maximum 4000)
         Add-Content $file "`n$sappendtxt" -errorAction SilentlyContinue
         write-host 'Appended to the Text file.'
     }
     $completed = $true
     write-host "Completed value is true.."
   }
   catch 
   {
     $serror = $_.Exception
     write-host "Into catch..primary Error details"
     write-host $serror
     if ($retrycount -ge $retries) 
     {
      write-host '#############Error################'
      write-host $_.Exception.Message
      write-host '-----------Failed for 5 attempts.-------'
      write-host '-----------CreateSnapshot is having issues. Please contact administrator.-------'
      exit 1
     }
     else
     {
      if($serror -Contains "Request limit exceeded")
       {
        write-host "Request limit exceeded occured. Again running into the loop."
        Start-Sleep -s 120
        start-sleep -m (Get-Random -minimum 90000 -maximum 300000)
        $retrycount++
       }
       else
        {
          write-host "New Exception occured...."
          write-host '#############Error################'
           write-host $_.Exception.Message
           Start-Sleep -s 120
           start-sleep -m (Get-Random -minimum 90000 -maximum 300000)
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

function runcreatesnapshot([String]$sbucket,[String]$expirydays,[String]$customerPrefix,[String]$pversion)
{
try{
$backuptype = 'online'
write-host '---------------Running the Create snapshot-------------------'
write-host "The Backup Type is $backuptype"
$customerprefixTag = 'customerPrefix'
$dirloc = "c:\testbc\"
$snapshotloc = "c:\snapshot\"
if([string]::IsNullOrEmpty($customerPrefix))
     {
        write-host '#############Error################'            
        write-host "The CustomerPrefix value is having some issues. Please contact administrator." 
        exit 1           
     }
     else
     {
     createsnapshot -customerprefix $customerprefixTag -scustomerprefixval $customerprefix -psversion $pversion
     start-sleep -m (Get-Random -minimum 2000 -maximum 6000)
     uploadtxttos3 -snapshotloc $snapshotloc -sbucket $sbucket -scustomerprefixval $customerprefix
     }
}
  catch{
  write-host '#############Error################'
  write-host "Error occurred during runcreatesnapshot createsnapshot...."
  write-host $_.Exception.Message
  #Write-Host($error)
  exit 1
  }
}


try{
$contentfile = 'C:\salt\conf\grains'
$strcurrentDate = Get-Date -format "yyyyMMddHHmmss"
$sbucket=$env:BUCKET_NAME
$LogFilePreference = $outputfile2
$strtime = Get-Date -format "MM-dd-yyyy HH:mm:ss:ffffff"
write-host "###################Application started running at $strtime###################"
#if([string]::IsNullOrEmpty($sbucket)) 
#{
# write-host "#############Error################"
# write-host "Bucket Name does not exist. Please contact administrator."
# exit 1
#}
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
$CustPrefix = Getparamsvalue -contentfile $contentfile -strparameter "CustPrefix"
write-host "The customer prefix is $CustPrefix"
$accessKey=$env:AWS_ACCESS_KEY
$secretKey=$env:AWS_SECRET_ACCESS_KEY
if($accessKey -ne $null -and $secretKey -ne $null)
{
    write-host 'Able to read the AWS keys from Envirnment variables.Using AWS Keys to complete this task..'
    $creds = New-AWSCredentials -AccessKey $accessKey -SecretKey $secretKey
    Set-AWSCredentials -Credential $creds
} 
$strBACKUP_ENVDate=$env:BACKUP_EXPIRY_DAYS
if([string]::IsNullOrEmpty($strBACKUP_ENVDate)) { $strBACKUP_ENVDate=30 }
$intexpiryDate = [int]$strBACKUP_ENVDate
start-sleep -m (Get-Random -minimum 1000 -maximum 30000)
#runcreatesnapshot([String]$sbucket,[String]$expirydays,[String]$customerPrefix,[String]$psversion)
runcreatesnapshot -sbucket $sbucket -expirydays $intexpiryDate -customerPrefix $CustPrefix -pversion $PSVERSION
#$strprocessoutput = Start-Process powershell "C:\testbc\lib\standard\createsnapshot.ps1 -sbucket $sbucket -expirydays $intexpiryDate -customerPrefix $CustPrefix -pversion $PSVERSION" -RedirectStandardOutput $outputfile -PassThru -windowstyle Hidden -Wait
$strtime = Get-Date -format "MM-dd-yyyy HH:mm:ss:ffffff"
write-host "###################Application ending at $strtime###################"
}
catch{
  write-host '#############Error################'
  write-host "Error while running the sql calling program. Please contact administrator."
  write-host $_.Exception.Message
  #write-host($error)
  $strtime = Get-Date -format "MM-dd-yyyy HH:mm:ss:ffffff"
  write-host "###################Application ending at $strtime###################"
  exit 1
  }