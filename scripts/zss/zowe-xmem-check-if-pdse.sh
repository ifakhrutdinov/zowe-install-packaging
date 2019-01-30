#!/bin/sh

# This program and the accompanying materials are
# made available under the terms of the Eclipse Public License v2.0 which accompanies
# this distribution, and is available at https://www.eclipse.org/legal/epl-v20.html
#
# SPDX-License-Identifier: EPL-2.0
#
# Copyright Contributors to the Zowe Project.

BASEDIR=$(dirname "$0")
dsn=$1

echo "Check if dataset ${dsn} is PDSE"

cmdout="$(tsocmd "listds '${dsn}' label" 2>&1)"
if [[ $? -ne 0 ]]; then
  echo "Error:  LISTDS failed"
  echo "$cmdout"
  exit 8
fi

if [[ $rc -eq 0 ]]; then
  dscb="$(echo $cmdout | sed -n "s/.*--FORMAT 1 DSCB-- \(.*\)/\1/p")"
fi

if [[ -z "$dscb" ]]; then
  echo "Error:  DSCB1 not found"
  echo "$cmdout"
  exit 8
fi

ds1smsfg="$(echo $dscb | sed -n "s/.\{77\}\(.\{2\}\).*/\1/p")"
if [[ -z "ds1smsfg" ]]; then
  echo "Error:  DS1SMSFG not found in DSCB1"
  echo "$cmdout"
  exit 8
fi

ds1smsfg_masked="$((0x$ds1smsfg & 0x0A))"

if [[ $ds1smsfg_masked == "8" ]]; then
  echo "Info:  dataset ${dsn} is PDSE"
  exit 1
else
  echo "Info:  dataset ${dsn} is not PDSE"
  echo "$cmdout"
  exit 0
fi

