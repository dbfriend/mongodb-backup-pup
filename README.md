# mongodb-backup.sh
## Summary  
This script creates a logical MongoDB backup based on mongodump. 

## Components
| # | File  | Type | Summary |
| ------------- | ------------- | ------------- | ------------- |
| 1 | mongodb-backup.sh  | Main script | Needs to be executed |
| 2 | mongodb-backup.par  | Parameter file | Contains db connection string, secret and many more variables which need to be filled and customized based on your environment  |

## Features
* Perform a backup of your MongoDB 
* Compatible with a standalone, one member replica set or replica set architecture
* Compatible with community- and enterprise edition
* Automated backup deletion based on retention period
* Tested with MongoDB versions 4.2, 4.4, 5.0 and 6.0
* Full process and error logging

## Best practices
* Backup directory: The backup dir should be located outside of the server. e.g on a NAS-share  
* Parameter file (mongodb-backup.par): Should only have 400 permissions otherwise there is a risk that it can be read by someone else  
* Dedicated database user: It is recommended to create an own user for the backup process with db roles: "backup" and "restore" and just use this one for the script 
```
{
        "_id" : "admin.backup_admin",
        "userId" : UUID("******"),
        "user" : "backup_admin",
        "db" : "admin",
        "credentials" : {
                "SCRAM-SHA-256" : {
                        "iterationCount" : 15000,
                        "salt" : "*****",
                        "storedKey" : "*****",
                        "serverKey" : "*****"
                }
        },
        "roles" : [
                {
                        "role" : "restore",
                        "db" : "admin"
                },
                {
                        "role" : "backup",
                        "db" : "admin"
                }
        ]
}
```
* Location: All files _"mongodb-backup.sh", "mongodb-backup.par"_ should be located at the same directory
* Schedule: Use crontab for a daily schedule for instance  
```
mongod@myserver:~ $ crontab -l  
0 22 * * * /bin/bash /home/mongod/mongodb-backup.sh
```

## Script flow
<p align="center">
  <img width="460" height="150" src="[https://github.com/dbfriend/mongodb-backup-pup/blob/version-1-0/mongodb-backup-flow.png](https://github.com/dbfriend/mongodb-backup-pup/blob/main/mongodb-backup-flow.png)">
</p>

## Limitations
* Not compatible with MongoDB sharded cluster
* Not working if MongoDB requires TLS encryption

## Examples
### Parameter-file
For standalone 
```
REPLICASET=mydb
BACKUPDIR="/mnt/mongobackupdir"
URI="mongodb://backup_admin@myserver"
PWLOC=MyPassword
RETENTION=14
MONGODUMP=/bin/mongodump
```
For replica set 
```
REPLICASET=RS1
BACKUPDIR="/mnt/mongobackupdir"
URI="mongodb://backup_admin@myserver1:27017,myserver2:27017,myserver4:27017/?authSource=admin&replicaSet=${REPLICASET}"
PWLOC=MyPassword
RETENTION=14
MONGODUMP=/bin/mongodump
```

### Execution
```
mongod@myserver:$ /home/mongod/mongodb-backup.sh
2023-08-02T15:12:48.457+0200 - Script start
2023-08-02T15:12:48.462+0200 - Backup dir is /mnt/mongobackupdir
2023-08-02T15:12:48.466+0200 - Backup retention is 14 days
2023-08-02T15:12:48.470+0200 - Log is /mnt/mongobackupdir/log/mongodump_2023-08-02-1512_repodb_myserver.log
2023-08-02T15:12:48.474+0200 - Cleanlog is /mnt/mongobackupdir/log/cleanup_2023-08-02-1512_repodb_myserver.log
2023-08-02T15:12:48.490+0200 - FS utilisation of backup dir is "/mnt/mongobackupdir (75% utilisation)"
2023-08-02T15:12:48.493+0200 - Mongodump is processing...
2023-08-02T15:13:30.801+0200 - Current amount of backups 15 .
2023-08-02T15:13:30.819+0200 - Backup completed successfully.
2023-08-02T15:13:30.823+0200 - Script ends

mongod@myserver:$ /mnt/mongobackupdir $ ll
drwxr-x---.   2 mongod mongod 19352 Aug  2 15:12 log
drwxr-x---. 288 mongod mongod 24180 Aug  2 15:13 mongodump_2023-08-02-1512_repodb_myserver

mongod@myserver:$ /mnt/mongobackupdir/mongodump_2023-08-02-1512_repodb_myserver
drwxr-x---. 2 mongod mongod     528 Aug  2 15:12 admin
drwxr-x---. 2 mongod mongod     367 Aug  2 15:13 agentlogs
drwxr-x---. 2 mongod mongod     361 Aug  2 15:13 autoindexing
drwxr-x---. 2 mongod mongod     236 Aug  2 15:13 automationagentlog
drwxr-x---. 2 mongod mongod     234 Aug  2 15:13 automationagentprofiler
drwxr-x---. 2 mongod mongod     765 Aug  2 15:13 automationcore
drwxr-x---. 2 mongod mongod     407 Aug  2 15:13 automationstatus
drwxr-x---. 2 mongod mongod     725 Aug  2 15:13 backupagent
drwxr-x---. 2 mongod mongod     236 Aug  2 15:13 backupagentlogs
drwxr-x---. 2 mongod mongod     419 Aug  2 15:13 backupagentstatus
drwxr-x---. 2 mongod mongod     248 Aug  2 15:13 backupalerts
drwxr-x---. 2 mongod mongod     236 Aug  2 15:13 backupbilling
drwxr-x---. 2 mongod mongod     663 Aug  2 15:13 backupconfig
...
```
