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


dnf module disable nodejs -y &>> $LOG_FILE
VALIDATE $? "Disable NOdejs"

dnf module enable nodejs:20 -y &>> $LOG_FILE
VALIDATE $? "Enable NOdejs"

dnf install nodejs -y &>> $LOG_FILE
VALIDATE $? "Install NOdejs"

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Adding user "
else
    echo -e "User already exist-- $Y SKIPPING $N "
fi

mkdir -p /app 
VALIDATE $? "Creating app directory"

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip
VALIDATE $? "Download code"

cd /app 
VALIDATE $? "Change app directory"

rm -rf /app/*
VALIDATE $? "Removing app info"

unzip /tmp/cart.zip &>> $LOG_FILE
VALIDATE $? "Unzip code"

npm install &>> $LOG_FILE
VALIDATE $? "Install maven packages"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service 
VALIDATE $? "Copying services"

systemctl daemon-reload 
VALIDATE $? "Reload daemon"

systemctl enable cart
VALIDATE $? "Enable cart"

systemctl start cart
VALIDATE $? "start cart"

END_TIME=$(date +%s) 

TOTAL_TIME=$(($END_TIME-$START_TIME)) 
echo "Total script script executed is $TOTAL_TIME"