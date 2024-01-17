import os
import json
import boto3

def lambda_handler(event, context):
    ec2_client = boto3.client('ec2')
    s3_client = boto3.client('s3')
    
    # EC2 information gathering
    reservations = ec2_client.describe_instances()['Reservations']
    instances_data = {"instances": []}
    
    for reservation in reservations:
      for instance in reservation['Instances']:
        instance_info = {
          "name": instance['Tags'][0]['Value'],
          "id": instance['InstanceId'],
          "state": instance['State']['Name']
        }
        if instance['State']['Name'] == 'running':
          status_check_response = ec2_client.describe_instance_status(InstanceIds=[instance['InstanceId']])
          if 'InstanceStatuses' in status_check_response and len(status_check_response['InstanceStatuses']) > 0:
            instance_info.update({
              "instance_status_check": status_check_response['InstanceStatuses'][0]['InstanceStatus']['Details'][0]['Status'],
              "system_status_check": status_check_response['InstanceStatuses'][0]['SystemStatus']['Details'][0]['Status']
            })
        instances_data["instances"].append(instance_info)
    
    # pushing gathered info to S3 bucket
    json_output = json.dumps(instances_data, indent=4)
    bucket_name = os.environ["BUCKET"]
    file_name = 'instance_data.json'
    s3_client.put_object(Body=json_output, Bucket=bucket_name, Key=file_name)
    print(f"JSON data sent to S3 bucket: {bucket_name}/{file_name}")
    return instances_data