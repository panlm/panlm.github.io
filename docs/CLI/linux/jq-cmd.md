---
title: jq
description: 常用命令
created: 2021-07-25T03:45:39.000Z
last_modified: 2023-11-28
tags:
  - cmd/jq
  - python
---
> [!WARNING] This is a github note
# how-to-use-jq
## reference 
- https://programminghistorian.org/en/lessons/json-and-jq
- https://jqplay.org/
- https://stedolan.github.io/jq/manual/#Invokingjq
- https://ubuntu.com/blog/improving-cli-output-with-jq

## sample
### snapshot sort 
!!! note "refer [[git/git-mkdocs/CLI/awscli/ebs-cmd#get-each-snapshot-change-blocks-]]"
    ![[../awscli/ebs-cmd#get-each-snapshot-change-blocks-]]


### select  
```python
t = pyjq.all('.entities[] | select (.uuid==\"' + i + '\") ', full)
```

### output
```sh
jq -r '[...]|@csv' |column -t -s','
jq -r '[...]|@tsv' |column -t 
```

```sh
# add table head
az resource list |jq -r '\
["name","resgrp"], ["--","--"], \
(.[] | [.name, .resourceGroup])|@tsv' |column -t

az resource list |jq -r '\
(["name", "resgrp", "Owner"] | (., map(length*"-"))), \
(.[] | [.name, .resourceGroup, .tags.owner//"-"])|@tsv' |column -t
```

### if else 
```sh
aws translate list-text-translation-jobs |jq -r '.TextTranslationJobPropertiesList[] | (if .JobStatus == "IN_PROGRESS" then .JobStatus, .JobName, .JobId else empty end)' |xargs
```

### combine output to a array
```sh
... |jq -s .
```

### filter value based on regexp
```sh
#get all script from blueprint
cat *.json | jq -r '.. | select (.|tostring|test("^#!.*"))'
```
and
```sh
#sample, replace REGEXHERE to your string
#Key name is "Name", replace it
| select((.Tags[]|select(.Key=="Name")|.Value) | match("REGEXHERE") )

```

### edit-json-file-directly-
```sh
jq '. += { "cpuManagerPolicy":"static"}' /etc/kubernetes/kubelet/kubelet-config.json

```

- refer: 
    - [[../awscli/ecs-cmd#modify-task-definition-]]
    - [[../awscli/apigw-cmd#update-access-log-for-rest-api-]]
    - [[../../cloud9/setup-cloud9-for-eks]]
    - [[assume-tool]]
    - [[../awscli/route53-cmd#create-ns-record-]]

### good sample
```yaml
developer:
  android:
    members:
    - alice
    - bob
    oncall:
    - bob
hr:
  members:
  - charlie
  - doug
this:
  is:
    really:
      deep:
        nesting:
          members:
          - example deep nesting
```

to

```yaml
developer-android-members:
  - alice
  - bob
developer-android-oncall:
  - bob
hr-members:
  - charlie
  - doug
this-is-really-deep-nesting-members:
  - example deep nesting
```

code 

```sh
yq . | # convert yaml to json using python-yq
    jq ' 
    . as $input | # Save the input for later
    . | paths | # Get the list of paths 
        select(.[-1] | tostring | test("^(members|oncall|priv)$"; "ix")) | # Only find paths which end with members, oncall, and priv
        . as $path | # save each path in the $path variable
    ( $input | getpath($path) ) as $members | # Get the value of each path from the original input
    {
        "key": ( $path | join("-") ), # The key is the join of all path keys
        "value": $members  # The value is the list of members
    }
    ' |
    jq -s 'from_entries' | # collect kv pairs into a full object using slurp
    yq --sort-keys -y . # Convert back to yaml using python-yq
```



## reinvent breakout session
download json
```sh
youtube-dl https://www.youtube.com/playlist?list=PL2yQDdvlhXf-Jdg0SkHt85s-YvTUaNmgT --skip-download --write-info-json --write-annotations
```

get title url and description
```
cat *json |jq -r '[
(if (.title|test("\\([A-Z]{3}[0-9]{3}")) then (.title|scan("[A-Z]{3}[0-9]{3}")) else (" ") end),
.title,
.webpage_url,
(.description
|gsub("\n";"#")
|gsub("\"";"")
|gsub("#Subscribe:.*$";"")
|gsub("Learn more about[^#]*#";""))
]|@csv'  > ../a.txt
```
upload a.txt

match following line
```
xx xx xx xx xx xx xx (CON312 xx xx xx xx
```

and print following line, if not match, then print " "
```
CON312
```

```sh
#!/bin/bash

for i in $a ; do
    file=$(ls |egrep '\('"$i"'\)' )
    if [[ -z $file ]]; then
	    echo $i
    else
	    url=$(cat "$file" |jq -r '.webpage_url')
	    echo $i $url
    fi
done

```

## get lengh
```sh
jq -r '.TransitGateways | length'
```


