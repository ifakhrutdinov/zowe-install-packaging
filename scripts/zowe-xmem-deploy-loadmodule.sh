#!/bin/sh

# This program and the accompanying materials are
# made available under the terms of the Eclipse Public License v2.0 which accompanies
# this distribution, and is available at https://www.eclipse.org/legal/epl-v20.html
#
# SPDX-License-Identifier: EPL-2.0
#
# Copyright Contributors to the Zowe Project.

BASEDIR=$(dirname "$0")
ZSS=$1
loadlib=$2
loadmodule=$3

sh $BASEDIR/zowe-xmem-dataset-exists.sh ${loadlib}
if [[ $? -ne 0 ]]; then
  echo "Check if dataset ${loadlib} is PDSE"
  dsntype=`tsocmd "listcat entries('${loadlib}') all" 2>/dev/null | sed -n "s/.*DSNTYPE[-]*\([^ ]*\).*/\1/p"`
  if [[ ! -z "$dsntype" ]]
  then
    echo "Info:  dataset ${loadlib} is PDSE"
  else
    echo "Error:  dataset ${loadlib} is not PDSE"
    exit 8
  fi
else
  echo "Allocate ${loadlib}"
  tsocmd "allocate da('${loadlib}') dsntype(library) dsorg(po) recfm(u) blksize(6144) space(10,2) tracks new " \
    1>/tmp/cmd.out 2>/tmp/cmd.err
  if [[ $? -eq 0 ]]
  then
    echo "Info:  dataset ${loadlib} has been successfully allocated"
    sleep 1 # Looks like the system needs some time to catalog the dataset
  else
    echo "Error:  dataset ${loadlib} has not been allocated"
    exit 8
    cat /tmp/cmd.out /tmp/cmd.err
  fi
fi

echo "Copying load module ${loadmodule}"
if cp ${ZSS}/LOADLIB/${loadmodule} "//'${loadlib}'"
then
  echo "Info:  module ${loadmodule} has been successfully copied to dataset ${loadlib}"
  exit 0
else
  echo "Error:  module ${loadmodule} has not been copied to dataset ${loadlib}"
  exit 8
fi

