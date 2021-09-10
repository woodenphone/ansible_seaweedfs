# Guide to using myserver-weed.pb.yml


## Installing prerequisites
Misc:
```
$ sudo dnf install -y git
```

Ansible:
```
$ sudo dnf install -y ansible
```

Ansible modules:
```
$ ansible-galaxy collection install community.general
$ ansible-galaxy install git+https://github.com/DevoInc/ansible-role-systemd-service.git
$ ansible-galaxy install 0x0i.systemd
```

## Altering playbook to your system
### Target host
Ansible playbooks are targeted at one or more hosts.

To target at the local machine:
```
  hosts: localhost
```

To target at a defined target machine:
```
  hosts: my-ansible-target-host
```

#### Defining an ansible host
* TODO: Verify correctness of hosts definition information.
Ansible target hosts are defined vy several configuration files. The one in your honedir is good enough.

Create dir and edit file:
```
$ mkdir -vp ~/.ansible
$ nano ~/.ansible/hosts
```

Contents of `~/.ansible/hosts`
```
# ~/.ansible/hosts
---
servers:
  hosts:
    myserver: ## Name used in playbook
      ansible_host: '192.168.69.69' ## This is what is looked for on the network.
      ansible_port: '22' ## SSH port.
      ansible_user: "root" ## Username ansible logs in as.
```



Alternate:

Create dir and edit file:
```
$ mkdir -vp ~/.ansible/host_vars/
$ nano ~/.ansible/host_vars/myserver.yml
```

Contents of `~/.ansible/host_vars/myserver.yml`
```
# host_vars/myserver.yml
---
ansible_host: '192.168.69.69'  ## This is what is looked for on the network.
ansible_port: '22' ## SSH port.
ansible_user: "root" ## Username ansible logs in as.
```

To list the host ansible knows about:
```
$ ansible-inventory --list
```



### Weed and certstrap version number
Installing seaweedfs and certstrap is handled by sub-playbooks, which are controlled by special variables they inherit from the playbook that calls then (in this case "myserver-weed.pb.yml")

Seaweedfs is downloaded from github based on the version number you specify in the vars section:
`weed_latest_release: "2.64"`

Certstrap is downloaded from github based on the version number you specify in the vars section:
`certstrap_latest_release: 'v1.2.0'`


#### Seaweedfs release (configuration)
Due to bugs in ansible's git / github modules, you must manually specify the release version of seaweedfs to use.

Update `weed_latest_release: "2.43"` to the latest seaweedfs binary release version.

Refer to https://github.com/chrislusf/seaweedfs/releases/ for a list of releases.

You probably want the "large-disk" version of the release, as it allows larger volumes.


### Editing services
* Ensure "service_names" in the vars definitions matches the names of the services you defined later in the playbook (in role: "0x0i.systemd")

The services that run seaweedfs are defined in `roles -> role: "0x0i.systemd" -> vars -> unit_config`

At an absolute minimum you require 1 master, 1 filer, and 1 volume.

An ansible role converts YML into systemd unit files.

See the github page for the ansible role for more info on how it works here: https://github.com/0x0I/ansible-role-systemd

Note that `enabled` and `state` are not inside `Unit` or `Service`, but various other values are. Overlooking the correct location of directives can be a cause of errors.

Example service definition:
```
## Master(s)
          # path: /etc/systemd/system/seaweedfs_ansible_master_1.service
          - name: 'seaweedfs_ansible_master_1'
            enabled: "yes"
            state: "started"
            Unit:
              Description: "Seaweedfs master"
            Service:
              Type: simple
              User: "{{ user }}"
              Group: "{{ group }}"
              WorkingDirectory: "{{ workdir }}"
              ExecStart: >-
                /usr/local/bin/weed
                -v={{ log_level }}
                -logdir=/var/log/seaweedfs_ansible/master_1
                master
                -mdir=/etc/seaweedfs_ansible/master_1/mdir
                -defaultReplication=002
                -volumeSizeLimitMB=200000
            Install:
              WantedBy: multi-user.target
```


#### Creation of dirs
* Ensure any filepaths you refer to in service definitions are created somewhere in the playbook, as seaweedfs typically does not implicitly create dirs, and weed will just fail to run with an error message.

Example of creating the folders used by seaweedfs:
```
## Prep dirs for SeaweedFS Services
    - name: 'Make dirs for seaweedfs components'
      ansible.builtin.file:
        state: 'directory'
        owner: "{{ user }}"
        group: "{{ group }}"
        mode: 'u=rwX,g=rwX,o=rX' # 'X' = Set dirs listable.
        path: "{{ item }}"
      with_items:
        ## Shared
        - "/etc/seaweedfs/"
        - "{{ workdir }}"
        - "{{ logdir }}"
        - "{{ pprof_dir }}"
        ## Master 1
        - "{{workdir}}/master_1/mdir"
        - "{{logdir}}/master_1"
        ## Filer 1
        - "{{workdir}}/filer_1/leveldb2"
        - "{{logdir}}/filer_1"
        ## S3 API host 1
        - "{{logdir}}/s3api_1"
        ## FUSE mount 1
        - "{{logdir}}/mount_1"
        ## Volumes
        - "{{logdir}}/volume_1"
        - "{{logdir}}/volume_2"
        - "{{logdir}}/volume_3"
        - "{{logdir}}/volume_4"
        - "{{logdir}}/volume_5"
        - "{{logdir}}/volume_6"
        ## FUSE Mounts
        - "/weedmnt/"
```


#### Permissions for dirs
A helper script to recursively edit permissions backwards from a final absolute filepath is available. `files/recuse_listable_permission.sh`


### Adding more filers
If you want to have multiple filers, you must tell them about eachother, and tell other components about the multiple filers.

Syntax for multiple filers:
```
$ weed filer -ip=xxx.xxx.xxx.xxx -master=ip1:9333,ip2:9333,ip3:9333 -peers=filer1:8888,filer2:8888
```
* https://github.com/chrislusf/seaweedfs/wiki/Production-Setup#setup-multiple-filers

```
$ weed mount -filer="filer1:8888,filer2:8888" -dir="/weedmnt/filer-root" -dirAutoCreate=true
```



## Secrets
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


#### Helper script
A helper script to generate random credentials exists.

To autogenerate random credentials for the weed s3 API:
```
$ bash im-too-lazy-to-edit-creds.sh "vars.default.yml"
```



## Testing playbook(s)
```
$ cd REPODIR
$ ansible-playbook myserver-weed.pb.yml -vv --syntax-check
$ ansible-playbook myserver-weed.pb.yml -vv --check
```


## Running playbook(s)
Deploying the state defined by the playbook to the server:
```
$ cd REPODIR
$ ansible-playbook myserver-weed.pb.yml -vv
```



## Backups
(Letting you restore if the weed cluster is wrecked.)
### Backing up filer metadata
(Without this you just have chunks with no names or association between them!)

Export filer metadata to a file:
```
$ echo "fs.meta.save -o seaweedfs.$(hostname).$(date +%Y-%m-%d_%H-%M%z).filer.meta" | time weed shell
```

### Volume backups
TODO

### Automating backups
TODO


## Replication
(Duplicating data across multiple volume servers, racks, datacenters, or weed clusters.)



## Diagnostics
Check playbooks are not obviously invalid:
```
$ ansible-playbook --syntax-check foo.yml
```

Testrun against target but don't change target:
```
$ ansible-playbook --check foo.yml
```

Ansible accepts multiple `-v` flags to increase verbosity of output text:
```
$ ansible-playbook foo.pb.yml
$ ansible-playbook foo.pb.yml -v
$ ansible-playbook foo.pb.yml -vv
$ ansible-playbook foo.pb.yml -vvv
...
```



### systemd / services / units
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

# journalctl -b --since='30 minutes ago' -u weed_filer_1.service
```

Reload systemd units from files:
```
$ sudo systemctl daemon-reload
```


### Logfiles
Read logfiles:
```
$ head -n30 /var/log/seaweedfs/master_1/weed.INFO
$ head -n30 /var/log/seaweedfs/master_1/weed.WARNING
```
(Seaweedfs makes symlinks to the latest logfile at weed.LOG_LEVEL)


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


### File/dir permissions
Seaweedfs needs permissions to dirs and files it will work on.
Seaweedfs often does not implicitly create directories.

Useful:
```
$ ls -lahQ /some/path/here

$ mkdir -vp /some/path/here/

## Capital X sets dir listing permission if relevant
$ chmod -v u=g=o= FILE
$ chmod -v u+rwX FILE
$ chmod -R u+rwX DIR

$ sudo chown -v USER:GROUP FILE
```

See: `files/recuse_listable_permission.sh`



## Inspecting seaweedfs
Seaweedfs presents some information as webpages
* Filer infopage: http://WEED_HOST:8888/
* Master infopage: http://WEED_HOST:9333/
* Volume infopage: http://WEED_HOST:VOLUME_PORT/ui/index.html


### Weed shell
The weed shell can provide info and perform administrative tasks:
```
$ weed shell
> volume.list
> exit
```

There is help info in weed shell about the commands, be sure to try both methods as they may have different info?
```
$ weed shell
> help
> help volume.list
> volume.list -help
> exit
```

Weed shell accepts command on STDIN:
```
$ echo -e "volume.list\nexit\n" | weed shell
```

Note that output may be emitted from STDERR.
```
$ echo -e "volume.list\nexit\n" | weed shell 2>&1 | python3 volume_list_human_many_vals.py ;
```


## Weed command help
Each weed command has its own help message giving usage information.
```
$ weed --help
$ weed mount --help
$ weed master --help
```

To save weed help message to some file:
```
$ weed mount --help  > mount.txt" 2>&1
```

Scripts to save these help messages to files in bulk are provided.
* See: `files/mk-weed-help-msgs.sh` 
* See: `files/mk-certstrap-help-msgs.sh`

### weed help messages
To get help message from your installed version of weed:
```
$ weed help
$ weed help COMMAND_NAME
```

To save help message from your installed version of weed to a file:
```
$ weed help COMMANDNAME 2>&1 > COMMANDNAME.txt
```



## Links & References etc,
* https://github.com/chrislusf/seaweedfs
* https://github.com/chrislusf/seaweedfs/wiki/Production-Setup
* https://github.com/chrislusf/seaweedfs/releases
* https://github.com/chrislusf/seaweedfs/wiki
* https://github.com/chrislusf/seaweedfs/wiki/Security-Configuration