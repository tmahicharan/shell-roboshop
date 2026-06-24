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

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo 
VALIDATE $? "Coping RabbitMq"

dnf install rabbitmq-server -y &>> $LOG_FILE
VALIDATE $? "Installing RabbitMq"

systemctl enable rabbitmq-server &>> $LOG_FILE
VALIDATE $? "Enabling RabbitMq"

systemctl start rabbitmq-server &>> $LOG_FILE
VALIDATE $? "Start RabbitMq"

rabbitmqctl list_users | grep -q "^roboshop"

if [ $? -ne 0 ]; then
    rabbitmqctl add_user roboshop roboshop123 &>> $LOG_FILE
    VALIDATE $? "Adding RabbitMq user"
else
    echo -e "RabbitMQ user already exists $Y skipping.. $N"
fi

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
VALIDATE $? "Set permissions for RabbitMq"


END_TIME=$(date +%s)

TOTAL_TIME=$(($END_TIME-$START_TIME))
echo "Total script script executed is $TOTAL_TIME"