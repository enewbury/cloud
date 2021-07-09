# Install Nextcloud (Latest) + Database (MariaDB/PostgreSQL/SQLite) + Encryption (Let's Encrypt Certificate/Self-signed) + Extra options on Docker

100% Handsfree & Ready to login.

Right now this will run on Ubuntu 18/20, Debian 9/10, CentOS 7, Amazon Linux 2, VMWare Photon OS

The playbook runs on x86_64 and ARM(64) servers. It's tested on AWS EC2, Scaleway Server and on Rasberry 3+ running Debian 9.

Onlyoffice and Collabora work only on a x86_64 server because there are no ARM(64) images.

> **WARNING**: This a new version of this Playbook using Traefik v2. Don't run this Playbook to update your installation from a previous version of this Playbook. This may break your system.

## Preparation

Install [Ansible](https://www.ansible.com/) on your dev machine

Clone this repo and change into the directory nextcloud_setup.
```bash
git clone https://github.com/enewbury/nextcloud_setup

cd nextcloud_setup
```

Note that root must have also sudo right otherwise the script will complain. Some hoster use distros where root is not in the sudoers file. In this case you have to add `root ALL=(ALL) NOPASSWD:ALL` to /etc/sudoers.

VMWARE PHOTON OS: Install using the ISO version, currently with OVA of PHOTON OS when an update is preformed the docker service does not restart. Photon OS requires a restart after running prepare_system.sh, that is part of script.

## Configuration

Now you can configure the whole thing by duplicating `inventory.template` to `inventory` and making changes, starting with the remote ssh address for the server.

### Preliminary variables

First of all you must define the server fqdn. If you want to get a Let's Encrypt certificate this must be a valid DNS record pointing to your server. Port 80+443 must be open to the internet. 

If you have a private server or if you use an AWS domain name like `ec2-52-3-229-194.compute-1.amazonaws.com`, you'll end up with a self-signed certificate. This is fine but annoying, because you have to accept this certificate manually in your browser. If you don't have a fqdn use the server IP address.

*Important:* You will only be able to access Nextcloud through this address. 
```ini
# The domain name for your cloud instance. You'll get a Let's Encrypt certificate for this domain.
cloud_server_fqdn       = nextcloud.example.tld
```

Let's Encrypt wants your email address. Enter it here:
```ini
# Your email address (for Let's Encrypt).
ssl_cert_email              = nextcloud@example.tld
```

### Nextcloud variables

Define where you want to find all your application config and data files in the server.
```ini
# Choose a directory for all of the data for this cloud server.
cloud_base_dir          = /opt/cloud
```

Define your Nextcloud admin user.
```ini
# Choose a username and password for your Nextcloud admin user.
nextcloud_admin             = 'admin'
nextcloud_passwd            = ''              # If empty the playbook will generate a random password.
```

Now it's time to choose and configure your favorite database management system.
```ini
# You must choose one database management system.
# Choose between 'pgsql' (PostgreSQL, default), 'mysql' (MariaDB) and 'sqlite' (SQLite).
nextcloud_db_type           = 'pgsql'

# Options for Mariadb and PostgreSQL.
nextcloud_db_host           = 'cloud-db'
nextcloud_db_name           = 'nextcloud'
nextcloud_db_user           = 'nextcloud'
nextcloud_db_passwd         = ''              # If empty the playbook will generate a random password (stored in {{ cloud_base_dir }}/secrets ).
nextcloud_db_prefix         = 'oc_'
```

### Optional variables

If you want to setup the Nextcloud mail system put your mail server config here.
```ini
# Setup the Nextcloud mail server.
nextcloud_configure_mail    = false
nextcloud_mail_from         =
nextcloud_mail_smtpmode     = smtp
nextcloud_mail_smtpauthtype = LOGIN
nextcloud_mail_domain       =
nextcloud_mail_smtpname     =
nextcloud_mail_smtpsecure   = tls
nextcloud_mail_smtpauth     = 1
nextcloud_mail_smtphost     =
nextcloud_mail_smtpport     = 587
nextcloud_mail_smtpname     =
nextcloud_mail_smtppwd      =
```

You can also configure a protonmail bridge to run a local smtp server that connects to Protonmail's secure apis.
```ini
# Setup the Nextcloud protonmail server.
nextcloud_configure_protonmail    = false
protonmail_username         =
protonmail_password         =
nextcloud_mail_from         =
nextcloud_mail_smtpmode     = smtp
nextcloud_mail_smtpauthtype = LOGIN
nextcloud_mail_domain       = localhost
nextcloud_mail_smtpname     =
nextcloud_mail_smtpsecure   = tls
nextcloud_mail_smtpauth     = 1
nextcloud_mail_smtphost     =
nextcloud_mail_smtpport     = 1025
```


Setup S3 Buckets as [primary storage](https://docs.nextcloud.com/server/latest/admin_manual/configuration_files/primary_storage.html)

Create a AWS user with permission to accces the S3 bucket. 
Provide your AWS Key and Secret below. The default bucket name is: 'nextcloud-{{ cloud_server_fqdn }}'.

This only works on the initial run of the playbook. **If a file config.php exists already it won't be changed.** This will not migrate an existing Nextcloud installation to a S3 bucket.

```ini
# Use S3 Bucket as primary storage
aws_s3_key            = 'AKIAUYIK6HF7ZKUBFG5D'
aws_s3_secret         = 'Kpb1exYZGyqZguPZGeZ65g5u5wtnzGVgY6RS/uHH'
aws_s3_bucket_name    = 'nextcloud-nextcloud.example.tld'
aws_s3_hostname       = 's3.amazonaws.com'
aws_s3_port           = '443'
aws_s3_use_ssl        = 'true'
aws_s3_region         = 'us-east-1'
aws_s3_use_path_style = 'true'
```

Setup the [restic](https://restic.readthedocs.io/en/latest/) backup tool.
```ini
# The restic backup tool will be installed when 'restic_repo' is not empty.
restic_repo                 = ''              # e.g. '/var/nc-backup' .
# Configure the crontab settings for restic.
backup_day                  = *
backup_hour                 = 4
backup_minute               = 0
```

If using rclone with backblaze, include these variables
```
b2_account                  = 
b2_key                      =
```

This playbook even supports the integration with an online office suite! You can choose between [Collabora](https://www.collaboraoffice.com/) and [ONLYOFFICE](https://www.onlyoffice.com).
```ini
# Choose an online office suite to integrate with your Nextcloud. Your options are (without quotation marks): 'none', 'collabora' and 'onlyoffice'.
online_office               = none
# When using Collabora, you're able to install dictionaries alongside with it. Collabora's default is German (de).
# collabora_dictionaries    = 'en'            # Separate ISO 639-1 codes with a space.
```

(DEPRECATED) Using a custom turnserver setup with matrix instead.
You can also install the TURN server needed for [Nextcloud Talk](https://nextcloud.com/talk/).
```ini
# Set to true to install TURN server for Nextcloud Talk.
talk_install                = false
```

If you want to use fulltext search.  
```ini
# Set to true to fulltext search.
fulltextsearch_enabled      = false
```

If you want to, you can get access to your database with [Adminer](https://www.adminer.org/). Adminer is a web frontend for your database (like phpMyAdmin).
```ini
# Set to true to enable access to your database with Adminer at https://cloud_server_fqdn/adminer. The password will be stored in {{ cloud_base_dir }}/secrets.
adminer_enabled             = false           # The password will be stored in {{ cloud_base_dir }}/secrets.
```

You can install [Portainer](https://www.portainer.io/), a webgui for Docker.
```ini
# Set to true to install Portainer webgui for Docker at https://cloud_server_fqdn/portainer/. 
portainer_enabled           = false
portainer_passwd            = ''      # If empty the playbook will generate a random password.
```

## Installation

Run the Ansible playbook.
```bash
./nextdocker.yml
```

Your Nextcloud access credentials will be displayed at the end of the run.

```json
ok: [localhost] => {
    "msg": [
        "Your Nextcloud at https://nextcloud.example.com is ready.",
        "Login with user: admin and password: fTkLgvPYdmjfalP8XgMsEg7plnoPsTvp ",
        "Other secrets you'll find in the directory /opt/nextcloud/secrets "
    ]
}
....
ok: [localhost] => {
    "msg": [
        "Manage your container at https://portainer.example.com/ .",
        "Login with user: admin and password: CqDy4SqAXC5kEU0hHGQ5IucdBegwaVXa "
    ]
}
....
ok: [localhost] => {
    "msg": [
        "restic backup is configured. Keep your credentials in a safe place.",
        "RESTIC_REPOSITORY='/var/nc-backup'",
        "RESTIC_PASSWORD='ILIOxgRbmrvmvsUhtI7VtOcIz6II10jq'"
    ]
}

```

If you are in a hurry you can set the inventory variables on the cli. But remember if you run the playbook again without the -e options all default values will apply and your systems is likely to be broken.

```bash
./nextdocker.yml -e "cloud_server_fqdn=nextcloud.example.tld nextcloud_db_type=mysql"
```

## Expert setup

If you change anything in the below mentioned files the playbook might not work anymore. You need a basic understanding of Linux, Ansible, Jinja2 and yaml to do so.

If you want to do more fine tuning you may have a look at:

- `group_vars\all.yml` for settings of directories, docker image tags and the rclone setup for restic backups.
- `roles\docker_container\file` for php settings
- `roles\docker_container\file` for webserver, php, turnserver and traefik settings

and

- `roles\nextcloud_config\defaults\main.yml` for nextcloud settings

Also if you are working on a remote computer through ssh be sure to check the **firewall settings** in `roles/prep_ufw/defaults/main.yml` Only ports 22,80,443 will be opened by default, plus ports for a turnserver. Please test locally before deploying on your remote (ssh) server, you will get locked out if you use a custom port.

### Serving web apps in other containers on the server

If you have other containers serving apps on your server and wish to use the Traefik2-container created by this playbook as a reverse proxy for them take a look [routing other containers to traefik](docker/routing-other-containers-to-traefik.md). There is also a [sample config](./docker/docker-compose-whoami.yml).

## Remove Nextcloud

If you want to get rid of the containers run the following command.
```bash
scripts/remove_all_container.sh
```
or 
```bash
scripts/remove_all_docker_stuff.sh
```
to remove **all** docker artifacts. That includes the database volume!

Your data files won't be deleted. You have to do this manually by executing the following.
```bash
rm -rf {{ cloud_base_dir }}
rm /usr/local/bin/dynamic_dns_check.py
rm /usr/local/bin/nextcloud_optimize.sh
rm /usr/local/bin/backup_cloud.sh
```

If you find this Playbook helpful and want to donate something. Please go to this web page donate to children in need. 

https://wir-fuer-kinder-in-not.org/ and click on "Spenden" (Donate)
