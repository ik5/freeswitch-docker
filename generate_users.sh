#!/usr/bin/env bash

export begin=${1:-5000}
export end=${2:-5099}

export path="${3:-/etc/freeswitch/directory/default}"

echo "args: ${*} | $begin .. $end | $path"

for counter in $(seq $begin $end)
do
  echo "counter: $counter"

  cat <<-EOF >> "${path}${counter}.xml"
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
done
echo 'done'
