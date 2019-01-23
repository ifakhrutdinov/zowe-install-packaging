#!/bin/sh

# This program and the accompanying materials are
# made available under the terms of the Eclipse Public License v2.0 which accompanies
# this distribution, and is available at https://www.eclipse.org/legal/epl-v20.html
# 
# SPDX-License-Identifier: EPL-2.0
# 
# Copyright Contributors to the Zowe Project.

BASEDIR=$(dirname "$0")

ZSS=$BASEDIR/../../zss
XMEM_ELEMENT_ID=ZIS
XMEM_MODULE=${XMEM_ELEMENT_ID}SRV01
XMEM_LOADLIB=${USER}.LOADLIB
XMEM_PARMLIB=${USER}.PARMLIB
XMEM_PARM=${XMEM_ELEMENT_ID}PRM00
XMEM_JCL=${XMEM_ELEMENT_ID}SRV01
XMEM_PROCLIB=${USER}.PROCLIB
XMEM_KEY=4
XMEM_STC_USER=${XMEM_ELEMENT_ID}STC
XMEM_STC_USER_UID=11111
XMEM_STC_PREFIX=${XMEM_ELEMENT_ID}
XMEM_PROFILE=${XMEM_ELEMENT_ID}.SERVER01.RES01
ZOWE_USER=SSUSER6

loadlibOk=false
apfOk=false
parmlibOk=false
proclibOk=false
pptOk=false
safOk=false
stcUserOk=false
stcProfileOk=false
xmemProfileOk=false
xmemProfileAccessOk=false

# MVS install steps

# 0. Preapre STC JCL
cp ${ZSS}/SAMPLIB/${XMEM_JCL} ${ZSS}/SAMPLIB/${XMEM_JCL}.tmp
sed -i "s/${XMEM_ELEMENT_ID}.S${XMEM_ELEMENT_ID}LOAD/${XMEM_LOADLIB}/g" ${ZSS}/SAMPLIB/${XMEM_JCL}.tmp
sed -i "s/${XMEM_ELEMENT_ID}.S${XMEM_ELEMENT_ID}PARM/${XMEM_PARMLIB}/g" ${ZSS}/SAMPLIB/${XMEM_JCL}.tmp

# 1. Deploy loadlib
sh $BASEDIR/zowe-xmem-deploy-loadmodule.sh ${ZSS} ${XMEM_LOADLIB} ${XMEM_MODULE}
if [[ $? -eq 0 ]]
then
  # 2. APF-authorize loadlib
  loadlibOk=true
  sh $BASEDIR/zowe-xmem-apf.sh ${XMEM_LOADLIB}
  if [[ $? -eq 0 ]]; then
    apfOk=true
  fi
fi

# 3. Deploy parmlib
sh $BASEDIR/zowe-xmem-deploy-parmlib.sh ${ZSS} ${XMEM_PARMLIB} ${XMEM_PARM}
if [[ $? -eq 0 ]]
  parmlibOk=true
then
fi

# 4. Deploy PROCLIB
sh $BASEDIR/zowe-xmem-deploy-proclib.sh ${ZSS} ${XMEM_PROCLIB} ${XMEM_JCL}
if [[ $? -eq 0 ]]
  proclibOk=true
then
fi

# 5. PPT-entry
sh $BASEDIR/zowe-xmem-ppt.sh ${XMEM_MODULE} ${XMEM_KEY}
if [[ $? -eq 0 ]]
  pptOk=true
then
fi

# Security install steps

function checkJob {
jobname=$1
tsocmd status ${jobname} 2>/dev/null | grep "JOB ${jobname}(S.*[0-9]*) EXECUTING" > /dev/null
if [[ $? -eq 0 ]]
then
  true 
else
  false
fi
}

# 6. Get SAF
echo "Get SAF"
for saf in RACF ACF2 TSS
do
  if checkJob $saf; then
    echo "Info:  SAF=${saf}"
    safOk=true
    break
  else
    echo "Error:  SAF has not been found"
  fi
done

if [[ $safOk -eq true ]]
then

  # 7. Handle STC user
  sh $BASEDIR/zowe-xmem-check-user.sh ${saf} ${XMEM_STC_USER}
  rc=$?
  if [[ $rc -eq 1 ]]; then
    sh $BASEDIR/zowe-xmem-define-stc-user.sh ${saf} ${XMEM_STC_USER} ${XMEM_STC_USER_UID}
    if [[ $? -eq 0 ]]; then
      stcUserOk=true
    fi
  elif [[ $rc -eq 0 ]]; then
    stcUserOk=true
  fi

  # 8. Handle STC profile
  sh $BASEDIR/zowe-xmem-check-stc-profile.sh ${saf} ${XMEM_STC_PREFIX}
  rc=$?
  if [[ $rc -eq 1 ]]; then
    sh $BASEDIR/zowe-xmem-define-stc-profile.sh ${saf} ${XMEM_STC_PREFIX} ${XMEM_STC_USER}
    if [[ $? -eq 0 ]]; then
      stcProfileOk=true
    fi
  elif [[ $rc -eq 0 ]]; then
    stcProfileOk=true
  fi

  # 9. Handle security profile
  sh $BASEDIR/zowe-xmem-check-profile.sh ${saf} FACILITY ${XMEM_PROFILE} ${ZOWE_USER}
  rc=$?
  if [[ $rc -eq 1 ]]; then
    sh $BASEDIR/zowe-xmem-define-xmem-profile.sh ${saf} ${XMEM_PROFILE}
    if [[ $? -eq 0 ]]; then
      xmemProfileOk=true
    fi
  elif [[ $rc -eq 0 ]]; then
    xmemProfileOk=true
  fi

  # 10. Check access
  if [[ "$xmemProfileOk" = "true" ]]; then
    sh $BASEDIR/zowe-xmem-check-access.sh ${saf} FACILITY ${XMEM_PROFILE} ${ZOWE_USER}
    rc=$?
    if [[ $rc -eq 1 ]]; then
      sh $BASEDIR/zowe-xmem-permit.sh ${saf} ${XMEM_PROFILE} ${ZOWE_USER}
      if [[ $? -eq 0 ]]; then
        xmemProfileAccessOk=true
      fi
    elif [[ $rc -eq 0 ]]; then
      xmemProfileAccessOk=true
    fi
  fi

fi

echo "****************************************"
echo "**************** Report ****************"
echo "****************************************"

if $loadlibOk ; then
  echo "LOADLIB - Ok"
else
  echo "LOADLIB - Error"
fi

if $apfOk ; then
  echo "APF-auth - Ok"
else
  echo "APF-auth - Error"
fi

if $parmlibOk ; then
  echo "PARMLIB - Ok"
else
  echo "PARMLIB - Error"
fi

if $proclibOk ; then
  echo "PROCLIB - Ok"
else
  echo "PROCLIB - Error"
fi

if $pptOk ; then
  echo "PPT-entry - Ok"
else
  echo "PPT-entry - Error"
fi

if $safOk ; then
  echo "SAF type - Ok"
else
  echo "SAF type - Error"
fi

if $stcUserOk ; then
  echo "STC user - Ok"
else
  echo "STC user - Error"
fi

if $stcProfileOk ; then
  echo "STC profile - Ok"
else
  echo "STC profile - Error"
fi

if $xmemProfileOk ; then
  echo "Security profile - Ok"
else
  echo "Securoty profile - Error"
fi

if $xmemProfileAccessOk ; then
  echo "Security profile access - Ok"
else
  echo "Security profile access - Error"
fi

echo "****************************************"
echo "****************************************"
echo "****************************************"

