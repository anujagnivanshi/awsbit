aws cloudwatch help
aws cloudwatch get-metric-statistics --generate-cli-skeleton
--------------------------------------------------disk size-------------------------------------------
$disk = Get-WmiObject Win32_LogicalDisk -ComputerName 'localhost' -Filter "DeviceID='c:'" |
Select-Object Size,FreeSpace
$disk.Size
$disk.FreeSpace

$SDKLibraryLocation = dir "C:\Program Files (x86)\AWS SDK for .NET\past-releases\Version-1" -Recurse -Filter "AWSSDK.dll"

### Create a MetricDatum .NET object
$Metric = New-Object -TypeName Amazon.CloudWatch.Model.MetricDatum
$Metric.Timestamp = [DateTime]::UtcNow
$Metric.MetricName = 'C-Drive-Free Space'
$Metric.Value = $disk.FreeSpace

### Write the metric data to the CloudWatch service
Write-CWMetricData -Namespace instance1 -MetricData $Metric
Write-host "Done"
-----------------Service------------------------------------------------------------------------------
$SDKLibraryLocation = dir "C:\Program Files (x86)\AWS SDK for .NET\past-releases\Version-1" -Recurse -Filter "AWSSDK.dll"
$s = Get-Service -Displayname "AVCTP service"
$s
$servicestatus = 0
if($s.Status -ne "Running")
{
$servicestatus = 0
}
else
{
$servicestatus = 1
}

$Metric = New-Object -TypeName Amazon.CloudWatch.Model.MetricDatum
$Metric.Timestamp = [DateTime]::UtcNow
$Metric.MetricName = 'Windows Service'
$Metric.Value = $servicestatus

### Write the metric data to the CloudWatch service
Write-CWMetricData -Namespace instance1 -MetricData $Metric
--------------------------------------------------------------------------------------------------

Cloud watch log agent(Linux) :

sudo yum install -y awslogs

Log Stream Vs Log Groups

Sequence of logging events  that share a common  source 
Ex : Single instance logging

Log group :
Collection of Logs from multiple servers.

For linux :

sudo cat /etc/awslogs/awscli.conf
sudo vi /etc/awslogs/awslogs.conf




---------------------
Cloud watch log agent(Linux) :

sudo yum install -y awslogs

Log Stream Vs Log Groups

Sequence of logging events  that share a common  source 
Ex : Single instance logging

Log group :
Collection of Logs from multiple servers.

For linux :

sudo cat /etc/awslogs/awscli.conf
sudo vi /etc/awslogs/awslogs.conf

Then restart
Sudo service awslogs restart
Add to boot strap  Sudo chkconfig awslogs on
