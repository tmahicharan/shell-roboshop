#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-04659521e2b75d264"
ZONE_ID="Z0333367NHGBMIBI3F"
DOMAIN_NAME="mahidevops.fun"

for instance in $@
do
   #launching server and generating instance id
   INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SG_ID  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query "Instances[0].InstanceId" --output text)

   if [ $instance != "frontend" ]; then
    IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
    RECORD_NAME="$instance.$DOMAIN_NAME"
   else
    IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
    RECORD_NAME="$DOMAIN_NAME"
   fi
   echo " $instance = $IP"

   aws route53 change-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --change-batch '
  {
    "Comment": "Updating record set"
    ,"Changes": [{
      "Action"              : "UPSERT"
      ,"ResourceRecordSet"  : {
        "Name"              : "'$RECORD_NAME'"
        ,"Type"             : "A"
        ,"TTL"              : 1
        ,"ResourceRecords"  : [{
            "Value"         : "'$IP'"
        }]
      }
    }]
  }
  '
done
