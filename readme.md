# ansible-seaweedfs
Things for automating installation and management of seaweedfs (primarily focused on using ansible).

## Overview



### Certstrap
Generates cryptographic keys and certificates.

### Seaweedfs installer

## Installation
System packages:
```
$ sudo dnf install ansible

```


Ansible galaxies:
```
$ ansible-galaxy collection install community.general
$ ansible-galaxy install git+https://github.com/DevoInc/ansible-role-systemd-service.git
```


## Configuration
Change the `hosts:`  to point at your desired target(s)

### Seaweedfs release (configuration)
Due to bugs in ansible's git /github modules, you must manually specify the release version of seaweedfs to use.

Update `weed_latest_release: "2.43"` to the latest seaweedfs binary release version.

Refer to https://github.com/chrislusf/seaweedfs/releases/ for a list of releases.


### S3 API credentials (configuration)
You must generate and set your own S3 API credentials, these are used by seaweedfs to control access from user applications and do not relate in any way to Amazon.

Do not use actual Amazon S3 credentials here. Nothing I've written here has anything to do with AWS.

Provided here are some simple oneliner commands to generate random credentials:

To generate a 32 character hexadecimal string: 
```
$ < /dev/urandom tr -dc a-f0-9 | head -c${1:-32};echo;
```

To generate a 32 character alphanumeric string:
```
$ < /dev/urandom tr -dc A-Za-z0-9 | head -c${1:-32};echo;
```

The values in the vars file that need to be replaced come with placeholder values starting with `FIXME_DEFAULT_VALUE.s3json`

Generate values for the S3 credentials, these are marked to be obvious and the template uses placeholder values `FIXME_DEFAULT_VALUE...`, which you should replace with some randomly-generated alphanumeric string.


## Usage
Run playbook(s):
```
$ cd PBDIR
$ ansible-playbook myserver-weed.pb.yml -vv
```


## Test
```
$ cd PBDIR
$ ansible-playbook myserver-weed.pb.yml -vv --syntax-check
$ ansible-playbook myserver-weed.pb.yml -vv --check
```


## Diagnostics
Check playbooks are not obviously invalid:
```
$ ansible-playbook --syntax-check foo.yml
```

Testrun against target but don't change target:
```
$ ansible-playbook --check foo.yml
```

Units recognized:
```
# systemctl list-units 'weed*.service'
```

Running/not running, logs here are unreliable:
```
# systemctl status 'weed*.service'
```

View systemd service logs:
```
# journalctl -b --since='1 hour ago' -u weed_mount_1.service

# systemctl status '*weed*'

# journalctl -b --since='30 minutes ago' -u 'weed_filer_1.service'

# journalctl -b --since='30 minutes ago' -u 'weed_volume_3.service'

```

journalctl -b --since='30 minutes ago' -u weed_filer_1.service
### Fixing broken FUSE mounts
A way to deal with weed mount mountpoint "breaking":

Check if this is the known problem behavior:
```
# df
df: /weedmnt/myapp-02: Transport endpoint is not connected
```

Check if seaweedfs has a process linked to the mountpoint
```
# ps -aux | grep weed

# ps -aux | grep mount
```

If no process is associated with mountpoint, detach it:
```
# umount -l /weedmnt/myapp-02
```

Confirm it's fixed:
```
# df
# ls -lah /weedmnt/
```