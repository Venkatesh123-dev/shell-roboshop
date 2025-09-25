#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-script/16-logs.log
SCRIPT_DIR=$PWD
MONGODB_HOST="mongodb.venkatesh.fun"
START_TIME=$(date +%s)
mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" | tee -a $LOG_FILE

### Checking For Root Access #####
if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run this script with root privelege"
    exit 1 # failure is other than 0
fi


#### Validate Function #####
VALIDATE(){ # functions receive inputs through args just like shell script args
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

### NodeJs ###
dnf module disable nodejs -y &>>LOG_FILE
VALIDATE $? "disable nodejs"

dnf module enable nodejs:20 -y &>>LOG_FILE
VALIDATE $? "enableing  nodejs:20"

dnf install nodejs -y &>>LOG_FILE
VALIDATE $? "installing  nodejs"


id roboshop &>>LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "roboshop system user"
else
    echo -e " roboshop system user already exist ... $Y SKIPPING $N" 
fi

mkdir -p /app 
VALIDATE $? "Creaing app directory"

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip 
VALIDATE $? "Downloading  app directory"

cd /app 
VALIDATE $? "Changing app directory"

rm -rf /app
VALIDATE $? "Removing existing app directory"


unzip /tmp/user.zip
VALIDATE $? "Unzip  app directory"

npm install 
VALIDATE $? "Installing depecncies"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service
VALIDATE $? "Copy user service"

systemctl daemon-reload
systemctl enable user &>>LOG_FILE
VALIDATE $? "enable user"

systemctl restart user &>>LOG_FILE
VALIDATE $? "Restarted user"


END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"
