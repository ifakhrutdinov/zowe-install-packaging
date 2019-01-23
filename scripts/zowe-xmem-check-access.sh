#!/bin/sh

# This program and the accompanying materials are
# made available under the terms of the Eclipse Public License v2.0 which accompanies
# this distribution, and is available at https://www.eclipse.org/legal/epl-v20.html
# 
# SPDX-License-Identifier: EPL-2.0
# 
# Copyright Contributors to the Zowe Project.

BASEDIR=$(dirname "$0")
saf=$1
class=$2
profile=$3
user=$4

echo "Check if user ${user} has access to profile ${profile} in class ${class} (SAF=${saf})"

case $saf in

RACF)
  tsocmd "SEARCH CLASS(${class}) FILTER(${profile}) USER(${user})" \
    1>/tmp/cmd.out 2>/tmp/cmd.err
  rc=$?
  if [[ $rc -eq 0 ]]
  then
    echo "Info: user ${user} has access to ${profile} in class ${class}"
    exit 0
  elif [[ $rc -eq 4 ]]
  then
    echo "Warning: user ${user} has no access to ${profile} in class ${class}"
    exit 1
  else
    echo Error:  SEARCH failed with the following errors
    cat /tmp/cmd.out /tmp/cmd.err
    exit 8
  fi
;;

ACF2)
  echo "Warning:  ACF2 support has not been implemented," \
    "please manually check if ${user} has access"
  exit 8
;;

TSS)
  echo "Warning:  TopSecret support has not been implemented," \
    "please manually check if ${user} has access"
  exit 8
;;

*)
  echo "Error:  Unexpected SAF $saf"
  exit 8
esac

