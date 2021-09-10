#!/bin/bash
## mk-weed-help-msgs.sh
## Dump seaweedfs help text to files for easier reading.
## USAGE: $ bash mk-weed-help-msgs.sh '/usr/local/bin/weed' '/var/seaweedfs/help-weed'
## TESTING: $ bash mk-weed-help-msgs.sh 'echo' '/var/seaweedfs/help-weed'
## Author: Ctrl-S
## Created: 2021-04-29
## Updated: 2021-05-13

## Take CLI args for variables
weed="{$1}" # Weed executable path.
docroot="${2}" # Dir to put docs in.
p="## [${0##*/}]" # Message prefix.

echo $p "args=$@"

##
### Get weed binary user-side so we don't have to care about copyright or licences
##
# weed_dl_url="https://github.com/chrislusf/seaweedfs/releases/download/2.41/linux_amd64_large_disk.tar.gz" # Latest release as of 2021-04-29.
# weed_dl_fn="weed.2.41.linux_amd64_large_disk.tar.gz" # Because we want the version in the filename.
# mkdir -vp ".tmp"

# echo "## Downloading weed binary"
# wget "${weed_dl_url}" -O ".tmp/${weed_dl_fn}"

# echo "## Extracting weed binary"
# tar -xzvf ".tmp/${weed_dl_fn}" -C ".tmp"
# chmod +x .tmp/weed


## Weed binary path:
# weed="$PWD/.tmp/weed"
echo $p "weed=${weed}"
echo $p "docroot=${docroot}"
echo $p "Version of weed:"
$weed version

# Record version docs apply to:
$weed version > "${help_dir}/installed_version.txt" 2>&1

##
### Weed foo --help
##
echo $p "Populate a folder with the weed help messages"
help_dir="${docroot?}/weed-help/"
echo $p "help_dir=${help_dir}"
mkdir -vp "${help_dir?}"
## Plain weed --help text:
$weed --help  > "${help_dir}/weed.txt" 2>&1
## Subcommand --help text:
$weed help --help  > "${help_dir}/help.txt" 2>&1
$weed benchmark --help  > "${help_dir}/benchmark.txt" 2>&1
$weed backup --help  > "${help_dir}/backup.txt" 2>&1
$weed compact --help  > "${help_dir}/compact.txt" 2>&1
$weed filer.copy --help  > "${help_dir}/copy.txt" 2>&1
$weed download --help  > "${help_dir}/download.txt" 2>&1
$weed export --help  > "${help_dir}/export.txt" 2>&1
$weed filer --help  > "${help_dir}/filer.txt" 2>&1
$weed filer.backup --help  > "${help_dir}/backup.txt" 2>&1
$weed filer.cat --help  > "${help_dir}/cat.txt" 2>&1
$weed filer.meta.backup --help  > "${help_dir}/backup.txt" 2>&1
$weed filer.meta.tail --help  > "${help_dir}/tail.txt" 2>&1
$weed filer.replicate --help  > "${help_dir}/replicate.txt" 2>&1
$weed filer.sync --help  > "${help_dir}/sync.txt" 2>&1
$weed fix --help  > "${help_dir}/fix.txt" 2>&1
$weed gateway --help  > "${help_dir}/gateway.txt" 2>&1
$weed master --help  > "${help_dir}/master.txt" 2>&1
$weed mount --help  > "${help_dir}/mount.txt" 2>&1
$weed s3 --help  > "${help_dir}/s3.txt" 2>&1
$weed iam --help  > "${help_dir}/iam.txt" 2>&1
$weed msgBroker --help  > "${help_dir}/msgBroker.txt" 2>&1
$weed scaffold --help  > "${help_dir}/scaffold.txt" 2>&1
$weed server --help  > "${help_dir}/server.txt" 2>&1
$weed shell --help  > "${help_dir}/shell.txt" 2>&1
$weed upload --help  > "${help_dir}/upload.txt" 2>&1
$weed version --help  > "${help_dir}/version.txt" 2>&1
$weed volume --help  > "${help_dir}/volume.txt" 2>&1
$weed webdav --help  > "${help_dir}/webdav.txt" 2>&1




##
### weed scaffold foo
##
echo $p "Generate weed scaffold files"
scaffold_dir="${docroot?}/weed-scaffold"
echo $p "scaffold_dir=${scaffold_dir}"
mkdir -vp ${scaffold_dir?}
echo $p "Scaffold helptext"
$weed scaffold --help > ${scaffold_dir}/weed-scaffold-help.txt 2>&1
echo $p "Config TOML templates:"
$weed scaffold -config=filer > ${scaffold_dir}/filer.toml 2>&1
$weed scaffold -config=notification > ${scaffold_dir}/notification.toml 2>&1
$weed scaffold -config=replication > ${scaffold_dir}/replication.toml 2>&1
$weed scaffold -config=security > ${scaffold_dir}/security.toml 2>&1
$weed scaffold -config=master > ${scaffold_dir}/master.toml 2>&1

echo $p "End of script."