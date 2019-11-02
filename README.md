### DirectAdmin account backups using rclone to BackBlaze B2


#### Summary

We want an automated, 'set and forget', system for our client account backups that stores daily, weekly and monthyly backups (for up to 90 days).

rclone is the tool we use for this for a number of reasons: 
* it's super simple to set up
* it connects to many different external storage types
* it allows copying and syncing (think rsync) with ease
* very easy to make changes. 

With sync it will only upload files that have changed and will automatically delete remote files that are no longer on the local server. 

With copy it will only upload files that have changed to the remote server.  

We are using B2 because it is very easy to set up and **significantly** cheaper than Amazon S3 


#### Resources: 

* https://rclone.org/b2/
* http://coststorage.com/compare/backblaze/
* See below for restoring files


#### B2 Buckets & rclone install

1) Create a B2 account and set up 3 buckets for daily, weekly, monthly backups
2) Create separate API keys for each of the buckets (providing read/write access only to each bucket) and copy the API keys
3) Install rclone from https://rclone.org/downloads as root
4) run `rclone config`to set up the B2 destinations
5) For each destination enter the bucket name and API keys. 

#### DirectAdmin setup

1) Set up daily backups in DirectAdmin saving all accounts to a directory.  In my case I have a linode server and a separate attached network storage for backups at /mnt/backups/.  Backups are stored in their own daily directory such as /mnt/backups/YYYY-MM-DD with a maximum of 2 days local backups (managed by the cron /root/scripts/b2-server-backup.sh script)

The backup currently runs at 2am NZT. 

**IMPORTANT NOTE:**  Because it's separate attached storage if I fill it up it doesn't affect the server disk space. There is no risk of filling up the server disk until the server crashses. 

2) Set up the /root/scripts/b2-server-backup.sh script on a daily cron. 

This script deletes the older backup folders in /mnt/backups and then starts the rclone copy to the b2-daily: storage bucket. 

Basically: 

`rclone --progress --transfers=25 copy /mnt/grl-storage b2-daily:grl-hosting-daily`

**NOTE:** --transfers=25 - massively speeds up transfer to b2. Each transfer process requires 98Mb so this is 2.5Gb of RAM we need spare to run comfortably. 

We then have additional crons to run the weekly & monthly bacups to b2: 

`# Weekly backup to b2 - at 5am on Sunday, lifecycle - keep for 32 days`

`0 5 * * 0 rclone --progress --transfers=25 copy /mnt/grl-storage b2-weekly:grl-hosting-weekly`

`# Monthly - at 06:00 on 1st day of the month - keep for 100 days`

`0 6 1 * * rclone --progress --transfers=25 copy /mnt/grl-storage b2-monthly:grl-hosting-monthly`



#### Old Versions 

* if we have old_versions enabled on a b2 bucket we can view them with: 

`rclone --b2-versions ls b2-daily:grl-hosting-daily/2019-11-02/`

This will show the current verison along with older versions that are normally hidden: 

`126374236 user.phillcoxon.propertyhd.tar.gz
119446988 user.phillcoxon.propertyhd.tar-v2019-11-01-235423-000.gz`

We can delete all old versions of files in a bucket with: 

`rclone --b2--versions cleanup b2-daily:bucket-name`


#### Viewing remote files. 

rclone offers various ways to view files

rclone ls|lsf|lsd|ncdu <-- all useful. 

### Providing links to remote files (not working/)

We can create links to remote files (clients can download etc) 

`./rclone link B2:bucket/path/to/file.txt`

...will repond with a link: 

`https://f002.backblazeb2.com/file/bucket/path/to/file.txt?Authorization=xxxxxxxx`


#### Restoring files / folders

To restore a file from b2 to /mnt/grl-storage: 

`rclone --progress copy b2-daily:grl-hosting-daily/2019-11-02/user.phillcoxon.propertyhd.tar.gz /mnt/grl-storage/`

**IMPORTANT:**  if we want to copy back an old_version of the file we need to use the --b2-versions argument as well: 

`rclone --progress --b2-versions copy b2-daily:grl-hosting-daily/2019-11-02/user.phillcoxon.propertyhd.tar-v2019-11-01-235423-000.gz /mnt/grl-storage/`


#### Still Figuring Out / To Do:

* Whether to use rclone sync or rclone copy. 
* What lifecycle settings to use in B2 for each bucket. 
* Calendar a weekly / monthly check to ensure backups are working correctly to B2
* Set up billing warning at B2

Currently I have set the daily bucket to expire objects after 7 days etc. 

Basically I want to have 7 days or backups stored in B2, 4 weekly backups and 3 monthly backups. But... I also don't want to be paying significant B2 storage fees.  Assuming 50Gb of accounts (not there yet) that's 

350Gb of data storage for daily backups each month (daily backups deleted after 7 days). 
200Gb of weekly storage / month (weekly backups deleted after 7 days)
600Gb of annual storage / month (after 12 years, monthly backups deleted after 30 days)

== 1Tb of data / month after 12 months

Based on the calculator at http://coststorage.com/compare/backblaze/ it will work out at about $7/month for storage fees (compared o $30/month with Amazon S3)

