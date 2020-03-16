#!/usr/bin/env bash

export begin=${1:-5000}
export end=${2:-5099}

export path="${3:-/etc/freeswitch/directory/default/}"

if [[ ! "$path" == */  ]]
then
  path="$path/"
fi

echo "args: ${*} | $begin .. $end | $path"

for counter in $(seq $begin $end)
do
  file_name="${path}${counter}.xml"
  if [ -e "$file_name" ]
  then
    echo "$file_path already exists"
    continue
  fi

  echo -n "creating $file_name ... "

  cat <<EOF  >"$file_name"
<include>
  <user id="${counter}">
    <params>
      <param name="jsonrpc-allowed-methods" value="verto"/>
      <param name="jsonrpc-allowed-event-channels" value="demo,conference,presence"/>
    </params>
    <variables>
      <variable name="user_context" value="webrtc"/>
    </variables>
  </user>
</include>
EOF

  if [ "$?" -eq 0 ]
  then
    echo "created $file_name"
    continue
  fi
  echo "unable to create $file_name"
done

ls -lhA $path

echo 'done'
