pip3 install --user --upgrade boto3 > /dev/null
export instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
echo "Resizing OS disk"
python3 -c "import boto3
import os
from botocore.exceptions import ClientError 
ec2 = boto3.client('ec2')
print('instance_id=' + os.getenv('instance_id'))
volume_info = ec2.describe_volumes(
    Filters=[
        {
            'Name': 'attachment.instance-id',
            'Values': [
                os.getenv('instance_id')
            ]
        }
    ]
)
volume_id = volume_info['Volumes'][0]['VolumeId']
print('volume_id=' + volume_id)
try:
    resize = ec2.modify_volume(    
            VolumeId=volume_id,    
            Size=30
    )
    print('Resized to 30GB')
except ClientError as e:
    if e.response['Error']['Code'] == 'InvalidParameterValue':
        print('ERROR MESSAGE: {}'.format(e))"
if [ $? -eq 0 ]; then
    echo "Rebooting ...."
    sudo reboot
fi

