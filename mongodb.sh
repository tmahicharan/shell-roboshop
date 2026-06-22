#!/bin/bash

USERId=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

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
        echo -e "$R Installing $2 is failed $N"
        exit 1
    else
        echo -e "$G Installing $2 is Success $N"
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding mongo repo"

dnf install mongodb-org -y &>> $LOG_FILE
VALIDATE $? "Installing mongodb"

systemctl enable mongodb
VALIDATE $? "Enabling MongoDB service"

systemctl start mongodb
VALIDATE $? "Starting MongoDB service"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Updating MongoDB configuration"

systemctl restart mongodb
VALIDATE $? "Restarting MongoDB service"