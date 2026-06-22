#!/bin/bash

USERId=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

SCRIPT_DIR=$(pwd)

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

dnf module disable nodejs -y &>> $LOG_FILE
VALIDATE $? "Disabling nodejs module"

dnf module enable nodejs:20 -y &>> $LOG_FILE
VALIDATE $? "Enabling nodejs module"

dnf install nodejs -y &>> $LOG_FILE
VALIDATE $? "Installing nodejs"

id roboshop &>> $LOG_FILE
if [ $? -ne 0 ]; then &>> $LOG_FILE
    useradd -r -d /app -s /sbin/nologin -c "RoboShop system User" roboshop
    VALIDATE $? "Adding roboshop user" &>> $LOG_FILE
else
   echo -e "roboshop user already exists $Y SKIPPING $N"
fi
mkdir -p /app
VALIDATE $? "Creating /app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip  &>> $LOG_FILE
VALIDATE $? "Downloading catalogue app"

cd /app
VALIDATE $? "Changing directory to /app"

rm -rf /app/*
VALIDATE $? "Cleaning /app directory"

unzip /tmp/catalogue.zip &>> $LOG_FILE
VALIDATE $? "unzipping catalogue app"

npm install &>> $LOG_FILE
VALIDATE $? "Installing nodejs dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copying systemctl services"

systemctl daemon-reload
VALIDATE $? "Reloading systemctl daemon"

systemctl enable catalogue
VALIDATE $? "Enabling catalogue service"

systemctl start catalogue
VALIDATE $? "Starting catalogue service"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding mongo repo"

dnf install mongodb-mongosh -y &>> $LOG_FILE
VALIDATE $? "Installing mongodb-mongosh"

mongosh --host mongodb.mahidevops.fun </app/db/master-data.js &>> $LOG_FILE
VALIDATE $? "Loading master data to mongodb"

systemctl restart catalogue
VALIDATE $? "Restarting catalogue service"