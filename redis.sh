#!/bin/bash

USERId=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"



LOG_FOLDER="/var/log/shell-script"
SCRIPT_NAME=$(echo "$0" | cut -d "." -f1)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
START_TIME=$(date +%s) 
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

dnf module disable redis -y &>> $LOG_FILE
VALIDATE $? "disabling redis"

dnf module enable redis:7 -y &>> $LOG_FILE
VALIDATE $? "Enabing redis"

dnf install redis -y &>> $LOG_FILE
VALIDATE $? "Installing redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c\protected-mode no' /etc/redis/redis.conf
VALIDATE $? "Changing configuration"

systemctl enable redis 
VALIDATE $? "enable redis"

systemctl start redis 
VALIDATE $? "start redis"

END_TIME=$(date +%s) 

TOTAL_TIME=$(($END_TIME-$START_TIME)) 
echo "Total script script executed is $TOTAL_TIME "
