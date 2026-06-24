#!/bin/bash

USERId=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"


START_TIME=$(date +%s) 
LOG_FOLDER="/var/log/shell-script"
SCRIPT_NAME=$(echo "$0" | cut -d "." -f1)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOG_FOLDER

if [ $USERId -ne 0 ]; then
    echo -e " $R ERROR:: Run this script as root user $N "
    exit 1
fi

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "Installing $2 is $R failed $N"
        exit 1
    else
        echo -e "Installing $2 is $G Success $N"
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding mongo repo"

dnf install mongodb-org -y &>> $LOG_FILE
VALIDATE $? "Installing mongodb"

systemctl enable mongod
VALIDATE $? "Enabling MongoDB service"

systemctl start mongod
VALIDATE $? "Starting MongoDB service"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Updating MongoDB configuration"

systemctl restart mongod
VALIDATE $? "Restarting MongoDB service"

END_TIME=$(date +%s) 

TOTAL_TIME=$(($END_TIME-$START_TIME)) 
echo "Total script script executed is $TOTAL_TIME "