#!/bin/bash

# BashTomato Validators API start

function logs_time() {
  date -u +%s
}

function logs_clear() {
  BASHTOMATO_LOGS=''
}

function logs_append() {
  local logs="$1"

  BASHTOMATO_LOGS="$BASHTOMATO_LOGS
$logs"
}

function validators_exit() {
  logs="$1"
  fail_fast="$2"

  if [ -n "$fail_fast" ]
  then
    logs_append "$logs"
    echo "$BASHTOMATO_LOGS"
    exit 1
  fi
}

function validators_filename_with_extension() {
  local filename="$1"
  local extension="$2"
  local exit="$3"

  local test=`echo "$filename" | grep -oE "^[a-zA-Z0-9_-]+\.${extension}$"`

  if [ -z "$test" ]
  then
    if [ -z "$exit" ]
    then
      logs_append "`logs_time` | WARNING | INPUT | function=<${FUNCNAME[0]}> | filename=<${filename}>, extension=<${extension}>, exit=<${exit}>"
      logs_append "`logs_time` | WARNING | OUTPUT | Given filename=<${filename}> does not have extension=<${extension}> or contains not valid characters. Must match /^[a-zA-Z0-9_-]+\.${extension}$/"
    else
      logs_append "`logs_time` | ERROR | INPUT | function=<${FUNCNAME[0]}> | filename=<${filename}>, extension=<${extension}>, exit=<${exit}>"
      validators_exit "`logs_time` | ERROR | OUTPUT | Given filename=<${filename}> does not have extension=<${extension}> or contains not valid characters. Must match /^[a-zA-Z0-9_-]+\.${extension}$/" "$TRUE"
    fi
  else
    logs_append "`logs_time` | OK | INPUT | function=<${FUNCNAME[0]}> | filename=<${filename}>, extension=<${extension}>, exit=<${exit}>"
    logs_append "`logs_time` | OK | OUTPUT | function=<${FUNCNAME[0]}> | test=<${test}>"
  fi

  echo "$test"
}

function validators_directory() {
  local directory="$1"
  local exit="$2"

  local test=`echo "$directory" | grep -oE '^/?([a-zA-Z0-9_\.-]+/?)+$'`

  if [ -z "$test" ]
  then
    if [ -z "$exit" ]
    then
      logs_append "`logs_time` | WARNING | INPUT | function=<${FUNCNAME[0]}> | directory=<${directory}>, exit=<${exit}>"
      logs_append "`logs_time` | WARNING | OUTPUT | Given directory=<${directory}> is not valid. Must match /^/?([a-zA-Z0-9_\.-]+/?)+$/"
    else
      logs_append "`logs_time` | ERROR | INPUT | function=<${FUNCNAME[0]}> | directory=<${directory}>, exit=<${exit}>"
      validators_exit "`logs_time` | ERROR | OUTPUT | Given directory=<${directory}> is not valid. Must match /^/?([a-zA-Z0-9_\.-]+/?)+$/" "$TRUE"
    fi
  else
    logs_append "`logs_time` | OK | INPUT | function=<${FUNCNAME[0]}> | directory=<${directory}>, exit=<${exit}>"
    logs_append "`logs_time` | OK | OUTPUT | function=<${FUNCNAME[0]}> | test=<${test}>"
  fi

  echo "$test"
}

function validators_filepath_with_extension() {
  local filepath="$1"
  local extension="$2"
  local exit="$3"

  local filename=`echo "$filepath" | rev | cut -d'/' -f1 | rev`
  local directory=`echo "$filepath" | rev | cut -d'/' -f2- | rev`

  test_a=`validators_filename_with_extension "$filename" "$extension"`
  test_b=`validators_directory "$directory"`

  # echo "DIR: $directory, FN: $filename"
  # echo "TEST_A: $test_a, TEST_B: $test_b"

  if [ -z "${test_a}" ] || [ -z "${test_b}" ]
  then
    if [ -z "$exit" ]
    then
      logs_append "`logs_time` | WARNING | INPUT | function=<${FUNCNAME[0]}> | filepath=<${filepath}>, extension=<${extension}>, exit=<${exit}>"
      logs_append "`logs_time` | WARNING | OUTPUT | Given filepath=<${filepath}>, extension=<${extension}> is not valid. Path must be build from valid directory, filename and extension"
    else
      logs_append "`logs_time` | ERROR | INPUT | function=<${FUNCNAME[0]}> | filepath=<${filepath}>, extension=<${extension}>, exit=<${exit}>"
      validators_exit "`logs_time` | ERROR | OUTPUT | Given filepath=<${filepath}>, extension=<${extension}> is not valid. Path must be build from valid directory, filename and extension" "$TRUE"
    fi
  else
    logs_append "`logs_time` | OK | INPUT | function=<${FUNCNAME[0]}> | filepath=<${filepath}>, extension=<${extension}>, exit=<${exit}>"
    logs_append "`logs_time` | OK | OUTPUT | function=<${FUNCNAME[0]}> | test_a=<${test_a}>, test_b=<${test_b}>"
  fi

  echo "${test_a}${test_b}"
}

function validators_filepath_png() {
  local filepath="$1"
  local exit="$2"

  logs_append "`logs_time` | UNKNOWN | INPUT | function=<${FUNCNAME[0]}> | filepath=<${filepath}>, exit=<${exit}>"
  validators_filepath_with_extension "$filepath" 'png' "$exit"
}

function validators_filepath_xml() {
  local filepath="$1"
  local exit="$2"

  logs_append "`logs_time` | UNKNOWN | INPUT | function=<${FUNCNAME[0]}> | filepath=<${filepath}>, exit=<${exit}>"
  validators_filepath_with_extension "$filepath" 'xml' "$exit"
}

function validators_device_id() {
  local device_id="$1"

  test=`adb devices | grep -oE "$device_id"`

  if [ -n "$test" ]
  then
    logs_append "`logs_time` | OK | INPUT | function=<${FUNCNAME[0]}> | device_id=<${device_id}>"
  else
    validators_exit "`logs_time` | ERROR | OUTPUT | Connection with device '$device_id' seems to be lost" "$TRUE"
  fi
}

function validators_node() {
  local node="$1"
  local exit="$2"

  test=`echo "$node" | grep -oE "^null|NR[0-9]{1,4} DEPTH[0-9]{1,4} <[a-zA-Z\.]+ ([a-z-]+?=".*?")+>$"`

  if [ -z "$test" ]
  then
    if [ -z "$exit" ]
    then
      logs_append "`logs_time` | WARNING | INPUT | function=<${FUNCNAME[0]}> | node=<${node}>, exit=<${exit}>"
      logs_append "`logs_time` | WARNING | OUTPUT | Given node=<${node}> is not valid /^NR[0-9]{1,4} DEPTH[0-9]{1,4} <[a-z-]>$/"
    else
      logs_append "`logs_time` | ERROR | INPUT | function=<${FUNCNAME[0]}> | node=<${node}>, exit=<${exit}>"
      validators_exit "`logs_time` | ERROR | OUTPUT | Given node=<${node}> is not valid /^NR[0-9]{1,4} DEPTH[0-9]{1,4} <[a-z-]>$/" "$TRUE"
    fi
  else
    logs_append "`logs_time` | OK | INPUT | function=<${FUNCNAME[0]}> | node=<${node}>, exit=<${exit}>"
    logs_append "`logs_time` | OK | OUTPUT | function=<${FUNCNAME[0]}> | test=<${test}>"
  fi
}

function validators_unsigned_integer() {
  local unsigned_integer="$1"
  local exit="$2"

  test=`echo "$unsigned_integer" | grep -oE "^(0|[1-9][0-9]*)$"`

  if [ -z "$test" ]
  then
    if [ -z "$exit" ]
    then
      logs_append "`logs_time` | WARNING | INPUT | function=<${FUNCNAME[0]}> | unsigned_integer=<${unsigned_integer}>, exit=<${exit}>"
      logs_append "`logs_time` | WARNING | OUTPUT | Given unsigned_integer=<${unsigned_integer}> is not unsigned integer"
    else
      logs_append "`logs_time` | ERROR | INPUT | function=<${FUNCNAME[0]}> | unsigned_integer=<${unsigned_integer}>, exit=<${exit}>"
      validators_exit "`logs_time` | ERROR | OUTPUT | Given unsigned_integer=<${unsigned_integer}> is not unsigned integer" "$TRUE"
    fi
  else
    logs_append "`logs_time` | OK | INPUT | function=<${FUNCNAME[0]}> | unsigned_integer=<${unsigned_integer}>, exit=<${exit}>"
    logs_append "`logs_time` | OK | OUTPUT | function=<${FUNCNAME[0]}> | test=<${test}>"
  fi
}

function validators_integer() {
  local integer="$1"
  local exit="$2"

  test=`echo "$integer" | grep -oE "^-?(0|[1-9][0-9]*)$"`

  if [ -z "$test" ]
  then
    if [ -z "$exit" ]
    then
      logs_append "`logs_time` | WARNING | INPUT | function=<${FUNCNAME[0]}> | integer=<${integer}>, exit=<${exit}>"
      logs_append "`logs_time` | WARNING | OUTPUT | Given integer=<${integer}> is not integer"
    else
      logs_append "`logs_time` | ERROR | INPUT | function=<${FUNCNAME[0]}> | integer=<${integer}>, exit=<${exit}>"
      validators_exit "`logs_time` | ERROR | OUTPUT | Given integer=<${integer}> is not integer" "$TRUE"
    fi
  else
    logs_append "`logs_time` | OK | INPUT | function=<${FUNCNAME[0]}> | integer=<${integer}>, exit=<${exit}>"
    logs_append "`logs_time` | OK | OUTPUT | function=<${FUNCNAME[0]}> | test=<${test}>"
  fi
}

function validators_percent() {
  local percent="$1"
  local exit="$2"

  test=`echo "$percent" | grep -oE "^-?(0|[1-9][0-9]*)%$"`

  if [ -z "$test" ]
  then
    if [ -z "$exit" ]
    then
      logs_append "`logs_time` | WARNING | INPUT | function=<${FUNCNAME[0]}> | percent=<${percent}>, exit=<${exit}>"
      logs_append "$test" "`logs_time` | WARNING | OUTPUT | Given percent=<${percent}> is not percantage"
    else
      logs_append "`logs_time` | ERROR | INPUT | function=<${FUNCNAME[0]}> | percent=<${percent}>, exit=<${exit}>"
      validators_exit "$test" "`logs_time` | ERROR | OUTPUT | Given percent=<${percent}> is not percantage" "$TRUE"
    fi
  else
    logs_append "`logs_time` | OK | INPUT | function=<${FUNCNAME[0]}> | percent=<${percent}>, exit=<${exit}>"
    logs_append "`logs_time` | OK | OUTPUT | function=<${FUNCNAME[0]}> | test=<${test}>"
  fi
}

function validators_seconds() {
  local seconds="$1"
  local exit="$2"

  logs_append "`logs_time` | UNKNOWN | INPUT | function=<${FUNCNAME[0]}> | seconds=<${seconds}>, exit=<${exit}>"
  validators_unsigned_integer "$seconds" "$exit"
}

function validators_milliseconds() {
  local milliseconds="$1"
  local exit="$2"

  logs_append "`logs_time` | UNKNOWN | INPUT | function=<${FUNCNAME[0]}> | milliseconds=<${milliseconds}>, exit=<${exit}>"
  validators_unsigned_integer "$milliseconds" "$exit"
}

function validators_bounds_name() {
  local bound_name="$1"
  local exit="$2"

  test=`echo "$bound_name" | grep -oE "^(top|right|bottom|left)$"`

  if [ -z "$test" ]
  then
    if [ -z "$exit" ]
    then
      logs_append "`logs_time` | WARNING | INPUT | function=<${FUNCNAME[0]}> | bound_name=<${bound_name}>, exit=<${exit}>"
      logs_append "`logs_time` | WARNING | OUTPUT | Given bound_name=<${bound_name}> is not valid. Only top, right, bottom, left are allowed"
    else
      logs_append "`logs_time` | ERROR | INPUT | function=<${FUNCNAME[0]}> | bound_name=<${bound_name}>, exit=<${exit}>"
      validators_exit "`logs_time` | ERROR | OUTPUT | Given bound_name=<${bound_name}> is not valid. Only top, right, bottom, left are allowed" "$TRUE"
    fi
  else
    logs_append "`logs_time` | OK | INPUT | function=<${FUNCNAME[0]}> | bound_name=<${bound_name}>, exit=<${exit}>"
    logs_append "`logs_time` | OK | OUTPUT | function=<${FUNCNAME[0]}> | test=<${test}>"
  fi
}

function validators_direction() {
  local direction="$1"
  local exit="$2"

  test=`echo "$direction" | grep -oE "^(UP|RIGHT|DOWN|LEFT)$"`

  if [ -z "$test" ]
  then
    if [ -z "$exit" ]
    then
      logs_append "`logs_time` | WARNING | INPUT | function=<${FUNCNAME[0]}> | direction=<${direction}>, exit=<${exit}>"
      logs_append "`logs_time` | WARNING | OUTPUT | Given direction=<${direction}> is not valid. Only UP, RIGHT, DOWN, LEFT are allowed"
    else
      logs_append "`logs_time` | ERROR | INPUT | function=<${FUNCNAME[0]}> | direction=<${direction}>, exit=<${exit}>"
      validators_exit "`logs_time` | ERROR | OUTPUT | Given direction=<${direction}> is not valid. Only UP, RIGHT, DOWN, LEFT are allowed" "$TRUE"
    fi
  else
    logs_append "`logs_time` | OK | INPUT | function=<${FUNCNAME[0]}> | direction=<${direction}>, exit=<${exit}>"
    logs_append "`logs_time` | OK | OUTPUT | function=<${FUNCNAME[0]}> | test=<${test}>"
  fi
}

# BashTomato Validators API end