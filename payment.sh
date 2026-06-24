#!/bin/bash

USERId=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"


START_TIME=$(date +%s)

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
        echo -e "Installing $2 is $R failed $N"
        exit 1
    else
        echo -e "Installing $2 is $G Success $N"
    fi
}

dnf install python3 gcc python3-devel -y &>> $LOGS_FILE
VALIDATE $? "Installing python"

id roboshop &>> $LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Adding user "
else
    echo -e "User already exist-- $Y SKIPPING $N "

mkdir -p /app 
VALIDATE $? "Creating directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>> $LOGS_FILE
VALIDATE $? "Download code"

cd /app 
VALIDATE $? "Changing directory"

rm -rf /app/*

unzip /tmp/payment.zip &>> $LOGS_FILE
VALIDATE $? "Unzip code"

cd /app
VALIDATE $? "Changing directory"

pip3 install -r requirements.txt &>> $LOGS_FILE
VALIDATE $? "Installing requirments"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service
VALIDATE $? "Copying payments service"

systemctl daemon-reload
VALIDATE $? "Daaemon reload"

systemctl enable payment
VALIDATE $? "Enable payment"

systemctl start payment
VALIDATE $? "Start payment"

END_TIME=$(date +%s) 
 
TOTAL_TIME=$(($END_TIME-$START_TIME)) 
echo "Total script script executed is $TOTAL_TIME"