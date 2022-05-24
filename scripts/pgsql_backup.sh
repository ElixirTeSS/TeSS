#!/bin/sh

# get username
if [ -z $1 ]
then
    echo "Enter the username:"
    read USERNAME
else
    USERNAME=$1
fi

# get database name
if [ -z $2 ]
then
    echo "Enter the database name:"
    read DBNAME
else
    DBNAME=$2
fi

# get schema file name
if [ -z $3 ]
then
    echo "Enter the backup folder name:"
    read FOLDER
else
    FOLDER=$3
fi

# extra params on data file
if [ -z $4 ]
then
    echo "Extra params on data file:"
    read EXTRA
else
    EXTRA=$4
fi

# run postgresql dumps for schema and data
pg_dump --host=localhost --username=$USERNAME --schema-only $DBNAME > $FOLDER/$DBNAME.$(date +%Y%m%d-%H%M%S).schema.sql
pg_dump --host=localhost --username=$USERNAME --data-only --disable-triggers $EXTRA $DBNAME > $FOLDER/$DBNAME.$(date +%Y%m%d-%H%M%S).data.sql

# --- end of file --- #
