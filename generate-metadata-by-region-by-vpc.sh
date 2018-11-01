#/bin/bash
if [ "$#" -ne 4 ];
then
	echo "Usage /usr/local/inforbc/bin/generate-metadata-by-region-by-vpc.sh <region> <vpc id> <mastersnapshotid>"
	echo "Example: "
	echo "/usr/local/inforbc/bin/generate-metadata-by-region-by-vpc.sh us-east-1 vpc-123456 2015-08-18-10-06-29-vpc-9a5faafe-auto11-testing-01"
	exit 1
else

echo "Reading BucketName Grain"

#bucketname=infor-vpc-metadata-devops
{% set bucketname=salt['grains.get']('BucketName') %}
bucketname={{bucketname}}


echo "Running Python Script to generate metadata"
cd /usr/local/inforbc/lib/standard

#/usr/bin/python /usr/local/inforbc/lib/standard/clouddeform.py --region $1 --vpcid $2
#/usr/bin/python "import /usr/local/inforbc/lib/standard/vpcdeform.py as vpcdeform; vpcdeform.VPCDeformer($1,$2,$3);"
echo "import sys,os;sys.path.append(os.path.abspath('/usr/local/inforbc/lib/standard'));import vpcdeform as vpcdeform;vpcdeform.VPCDeformer(\"$1\",\"$2\",\"$3\");" | python
YAML_FILE=`find /usr/local/inforbc/tmp/ -maxdepth 1 -name vpcdeform_*$2.yaml`
T_FILE=`basename $YAML_FILE`




echo "Syncing the Content to S3"

mkdir -p /usr/local/inforbc/tmp/yaml-to-sync

#mv /usr/local/inforbc/tmp/*.yaml /usr/local/inforbc/tmp/yaml-to-sync/.
mv $YAML_FILE /usr/local/inforbc/tmp/yaml-to-sync/$4_$T_FILE

if aws s3 ls "s3://$bucketname" 2>&1 | grep -q 'NoSuchBucket'
then
    echo "$bucketname bucket name does not exist. Creating a new bucket $bucketname"
    aws s3 mb s3://$bucketname
fi
aws s3 cp /usr/local/inforbc/tmp/yaml-to-sync/$4_$T_FILE s3://$bucketname/metadata/DRGDE/

fi

