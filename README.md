# RPI_scripts	
A collection of scripts i use for my Raspberry Pi
# RPI_scripts
A collection of scripts i use for my Raspberry Pi
## Backup-scripts:
### Preconditions:

SD-Card has the following partitions:

*p1: boot partition

*p2: system partition

*p3: partition for: home, database and other data that can be backuped by using "tar"

### backup_sd.sh:
Will do a "dd" backup of the first 3GB of SD Card. Content of *p3 partition will be backuped by "tar". Database will be backuped as databasedump.

Attention: In case of recovery the filesystem of *p3 is invalid and has to restored manually!

### backup.sh:
Used for daily backup. Does not contain system partition!
## init-scripts:
tbd...

