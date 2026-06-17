#!/bin/bash

AMI-ID="ami-0220d79f3f480ecf5"
SG-ID="sg-04659521e2b75d264"

for instance in $@
do
   #launching server and generating instance id
   INSTANCE-ID=$(aws ec2 run-instances --image-id $AMI-ID --instance-type t3.micro --security-group-ids $SG-ID  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Test}]' --query "Instances[0].InstanceId" --output text)

   if [ $instance != "frontend" ]; then
    ID=$(aws ec2 describe-instances --instance-ids $INSTANCE-ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
   else
    ID=$(aws ec2 describe-instances --instance-ids $INSTANCE-ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
   fi
   echo " $instance = $ID"
done
