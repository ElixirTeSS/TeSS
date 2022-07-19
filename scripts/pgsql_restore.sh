#!/bin/sh

# Description: Restore a PostgreSQL database from schema and data dump files 
#
# Author: Fabio Agostinho Boris
#         github.com/fabioboris
#
# Creation: 2013-05-08

# get username
if [ -z $1 ]
then
    echo "Enter the username:"
    read USERNAME
else
    USERNAME=$1
fi

# get new database name
if [ -z $2 ]
then
    echo "Enter the new database name:"
    read DBNAME
else
    DBNAME=$2
fi

# get schema file name
if [ -z $3 ]
then
    echo "Enter the schema file name:"
    read SCHEMA
else
    SCHEMA=$3
fi

# get data file name
if [ -z $4 ]
then
    echo "Enter the data file name:"
    read DATA
else
    DATA=$4
fi

echo "drop database $DBNAME;" | psql --host=localhost --username=$USERNAME template1
echo "create database $DBNAME with encoding 'utf8';" | psql --host=localhost --username=$USERNAME template1

psql --host=localhost --username=$USERNAME $DBNAME < $SCHEMA
psql --host=localhost --username=$USERNAME $DBNAME < $DATA
