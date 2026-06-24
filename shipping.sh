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

dnf install maven -y &>> $LOG_FILE
VALIDATE $? "Installing maven"

id roboshop 
if [ $? -ne 0 ]; then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Adding roboshop user"
else
    echo -e "User already exist $y SKKIPPING.. $N "
fi

mkdir -p /app 
VALIDATE $? "Creating directory app"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip 
VALIDATE $? "Downloading code"

cd /app 
VALIDATE $? "locating to app"

rm -rf /app/* &>> $LOG_FILE

unzip /tmp/shipping.zip
VALIDATE $? "unzip app"

cd /app 
VALIDATE $? "locating to app"

mvn clean package &>> $LOG_FILE
VALIDATE $? "Clean package"

mv target/shipping-1.0.jar shipping.jar &>> $LOG_FILE
VALIDATE $? "Move shiping file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>> $LOG_FILE
VALIDATE $? "Copy shipping service"

systemctl daemon-reload &>> $LOG_FILE
VALIDATE $? "Daemon reload"

systemctl enable shipping 
VALIDATE $? "Enable shipping"

systemctl start shipping
VALIDATE $? "Start shipping"

dnf install mysql -y &>> $LOG_FILE
VALIDATE $? "Install mysql"

mysql -h mysql.mahidevops.fun -uroot -pRoboShop@1 -e 'use mysql' 
if [ $? -ne 0 ]; then
    mysql -h mysql.mahidevops.fun -uroot -pRoboShop@1 < /app/db/schema.sql
    mysql -h mysql.mahidevops.fun -uroot -pRoboShop@1 < /app/db/app-user.sql 
    mysql -h mysql.mahidevops.fun -uroot -pRoboShop@1 < /app/db/master-data.sql
else
    echo -e "Shipping data is already exist.. $Y SKKIPING $N "
fi

systemctl restart shipping
VALIDATE $? "Restart shipping"

END_TIME=$(date +%s) 
 
TOTAL_TIME=$(($END_TIME-$START_TIME)) 
echo "Total script script executed is $TOTAL_TIME"