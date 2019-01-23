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
proclib=$2
jcl=$3

sh $BASEDIR/zowe-xmem-dataset-exists.sh ${proclib}
if [[ $? -eq 0 ]]; then
  echo "Error:  PROCLIB ${XMEM_PROCLIB} doesn't exist"
  exit 8
fi

echo "Copy PROCLIB member ${jcl} to ${proclib}"
if cp ${ZSS}/SAMPLIB/${jcl} "//'${proclib}'" 2>/dev/null
then
  echo "Info:  PROCLIB member ${jcl} has been successfully copied to dataset ${proclib}"
  exit 0
else
  echo "Error:  PROCLIB member ${jcl} has not been copied to dataset ${proclib}"
  exit 8
fi

