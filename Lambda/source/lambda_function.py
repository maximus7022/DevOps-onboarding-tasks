import os
import time
import json
import boto3

def lambda_handler(event, context):
    ec2_client = boto3.client('ec2')
    s3_client = boto3.client('s3')
    
    # EC2 information gathering
    reservations = ec2_client.describe_instances()['Reservations']
    records = []
    
    for reservation in reservations:
      for instance in reservation['Instances']:
        instance_info = {
          "Instance Name": instance['Tags'][0]['Value'],
          "Instance ID": instance['InstanceId'],
          "Instance State": instance['State']['Name']
        }
        if instance['State']['Name'] == 'running':
          status_check_response = ec2_client.describe_instance_status(InstanceIds=[instance['InstanceId']])
          if 'InstanceStatuses' in status_check_response and len(status_check_response['InstanceStatuses']) > 0:
            instance_info.update({
              "Instance status check": status_check_response['InstanceStatuses'][0]['InstanceStatus']['Details'][0]['Status'],
              "System status check": status_check_response['InstanceStatuses'][0]['SystemStatus']['Details'][0]['Status']
            })
        records.append(instance_info)
    
    # pushing gathered info to S3 bucket
    json_output = json.dumps(records, indent=4)
    bucket_name = os.environ["BUCKET"]
    file_name = 'instance_data.json'
    s3_client.put_object(Body=json_output, Bucket=bucket_name, Key=file_name)
    print(f"JSON data sent to S3 bucket: {bucket_name}/{file_name}")
    return records