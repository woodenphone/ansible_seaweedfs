#!/bin/bash
## lazy-creds.sh
## Randomly generate credentials for lazy users.
## USAGE: $ bash lazy-creds.sh "vars.sed-example.yml"
##
## Example target line: s3json_admin_access_key: 'FIXME_DEFAULT_VALUE.s3json_admin_access_key'
##
## AUTHOR: Ctrl-S
## CREATED: 2021-05-15
## MODIFIED: 2021-05-15

p="## [${0##*/}]" ## Message prefix.
echo $p "Replacing credential placeholders with random values..."

## Get target from CLI params
conf_file="${1?}"
echo $p "conf_file=${conf_file}"


## Replace each value with a different random string:
for i in {1..20..1} ## {START..END[..INCREMENT]}
do
  echo $p "Iteration: $i"

  ## Generate a random string, 16 hexadecimal chars.
  random_val="$( < /dev/urandom tr -dc a-f0-9 | head -c${1:-16};)"
  
  ## Only replace first match: $ sed '1 s/foo/bar/'
  sed --in-place=".bkup" -E \
   "1 s/FIXME_DEFAULT_VALUE[a-zA-Z0-9-_]+/${random_val?}/" \
   "${conf_file?}"
  ## ^ Multiline-split for puny terminals. ^
done

echo $p "End of script."
## 
## https://www.man7.org/linux/man-pages/man1/sed.1.html
## https://linuxhint.com/50_sed_command_examples/
##