#!/bin/bash

USERId=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

SCRIPT_DIR=$(pwd)
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

dnf module disable nginx -y &>> $LOG_FILE
VALIDATE $? "Diable nginx"

dnf module enable nginx:1.24 -y &>> $LOG_FILE
VALIDATE $? "Enable nginx"

dnf install nginx -y &>> $LOG_FILE
VALIDATE $? "Install nginx"

systemctl enable nginx 
VALIDATE $? "Enable nginx"

systemctl start nginx
VALIDATE $? "Start nginx"

rm -rf /usr/share/nginx/html/* &>> $LOG_FILE
VALIDATE $? "Remove previous code"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
VALIDATE $? "Download code"

cd /usr/share/nginx/html 
VALIDATE $? "changing directory"

rm -rf /app/*
VALIDATE $? "removing app data"

unzip /tmp/frontend.zip &>> $LOG_FILE
VALIDATE $? "Unzipping code"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "copy script"

systemctl restart nginx 
VALIDATE $? "Restart nginx"

END_TIME=$(date +%s) 
 
TOTAL_TIME=$(($END_TIME-$START_TIME))
echo "Total script script executed is $TOTAL_TIME"