# Install Homeserver cloud infrastructure with Nextcloud, Matrix, and VPN

100% Handsfree & Ready to login.

This playbook allows you to integrate with a protonmail server, and uses Nginx instead of apache.

## Preparation

Install [Ansible](https://www.ansible.com/) on your dev machine

Clone this repo and change into the directory nextcloud_setup.
```bash
git clone https://github.com/enewbury/cloud

cd cloud
```

Note that root must have also sudo right otherwise the script will complain. Some hoster use distros where root is not in the sudoers file. In this case you have to add `root ALL=(ALL) NOPASSWD:ALL` to /etc/sudoers.

## Configuration

Now you can configure the whole thing by duplicating `inventory.template.cfg` to `inventory.cfg` and making changes, starting with the remote ssh address for the server.

### Preliminary variables

First of all you must define the server fqdn. If you want to get a Let's Encrypt certificate this must be a valid DNS record pointing to your server. Port 80+443 must be open to the internet. 

If you have a private server or if you use an AWS domain name like `ec2-52-3-229-194.compute-1.amazonaws.com`, you'll end up with a self-signed certificate. This is fine but annoying, because you have to accept this certificate manually in your browser. If you don't have a fqdn use the server IP address.

*Important:* You will only be able to access Nextcloud through this address. 
```ini
# The domain name for your cloud instance. You'll get a Let's Encrypt certificate for this domain.
cloud_server_fqdn       = cloud.example.tld
```

Let's Encrypt wants your email address. Enter it here:
```ini
# Your email address (for Let's Encrypt).
ssl_cert_email              = me@example.tld
```

Define where you want to find all your application config and data files in the server.
```ini
# Choose a directory for all of the data for this cloud server.

cloud_base_dir          = /opt/cloud
```

### Nextcloud variables

Define your Nextcloud admin user.
```ini
# Choose a username and password for your Nextcloud admin user.
nextcloud_admin             = 'admin'
nextcloud_passwd            = ''              # If empty the playbook will generate a random password.
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
./cloud.yml
```

Your Nextcloud access credentials will be displayed at the end of the run.

```json
ok: [localhost] => {
    "msg": [
        "Your Nextcloud at https://nextcloud.example.com is ready.",
        "Login with user: admin and password: <password> ",
        "Other secrets you'll find in your current directory under ./secrets "
    ]
}
....
ok: [localhost] => {
    "msg": [
        "Manage your container at https://portainer.example.com/ .",
        "Login with user: admin and password: <password> "
    ]
}
....
ok: [localhost] => {
    "msg": [
        "restic backup is configured. Keep your credentials in a safe place.",
        "RESTIC_REPOSITORY='/var/nc-backup'",
        "RESTIC_PASSWORD='<password>'"
    ]
}

```

If you are in a hurry you can set the inventory variables on the cli. But remember if you run the playbook again without the -e options all default values will apply and your systems is likely to be broken.

```bash
./cloud.yml -e "cloud_server_fqdn=nextcloud.example.tld"
```

## Expert setup

If you want to do more fine tuning you may have a look at:

- `group_vars\all.yml` for settings of directories, docker image tags and the rclone setup for restic backups.
- `roles\docker_container\file` for php settings
- `roles\docker_container\file` for webserver, php, turnserver and traefik settings

and

- `roles\nextcloud_config\defaults\main.yml` for nextcloud settings

Also if you are working on a remote computer through ssh be sure to check the **firewall settings** in `roles/prep_ufw/defaults/main.yml` Only ports 22,80,443 will be opened by default, plus ports for a turnserver. Please test locally before deploying on your remote (ssh) server, you will get locked out if you use a custom port.

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
```
