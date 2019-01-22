#!/bin/sh

ZSS=../../zss
XMEM_MODULE=ZISSRV01
XMEM_LOADLIB=${USER}.LOADLIB
XMEM_PARM=ZISPRM00
XMEM_PARMLIB=${USER}.PARMLIB
XMEM_JCL=ZISSRV01
XMEM_PROCLIB=${USER}.PROCLIB
XMEM_KEY=4
XMEM_STC_USER=ZISSTC
XMEM_STC_USER_UID=11111
XMEM_STC_PREFIX=ZIS
XMEM_PROFILE=ZIS.SERVER01.RES01

# MVS install steps

datasetExists() {
  dsn=$1
  echo "info: check if $dsn exists"
  lastcc=`tsocmd "listcat entries('$dsn')" 2>/dev/null | sed -n "s/.*LASTCC=\([0-9]*\).*/\1/p"`
  if [[ -z "$lastcc" ]]
  then
    echo "info: dataset $dsn exists"
    true
  else
    echo "info: dataset $dsn doesn't exit"
    false
  fi
}

isPDSE=false
if datasetExists ${XMEM_LOADLIB}; then
  echo "info: check if dataset ${XMEM_LOADLIB} is PDSE"
  dsntype=`tsocmd "listcat entries('${XMEM_LOADLIB}') all" 2>/dev/null | sed -n "s/.*DSNTYPE[-]*\([^ ]*\).*/\1/p"`
  if [[ ! -z "$dsntype" ]]
  then
    echo "info: dataset ${XMEM_LOADLIB} is PDSE"
  isPDSE=true
  else
    echo "error: dataset ${XMEM_LOADLIB} is not PDSE"
    isPDSE=false
  fi
else
  echo "info: allocating ${XMEM_LOADLIB}"
  allocRc=`tsocmd "allocate da('${XMEM_LOADLIB}') dsntype(library) dsorg(po) recfm(u) blksize(6144) space(10,2) tracks new " 2>/dev/null | sed -n "s/.*RETURN CODE IS \([0-9]*\).*/\1/p"`
  if [[ -z "$allocRc" ]]
  then
    echo "info: dataset ${XMEM_LOADLIB} has been successfully allocated"
  else
    echo "error: dataset ${XMEM_LOADLIB} has not been allocated"
  exit 8
  fi
fi

if ../scripts/opercmd "SETPROG APF,ADD,DSNAME=${XMEM_LOADLIB},SMS" | grep "CSV410I" 1>/dev/null; then
  echo "info: dataset ${XMEM_LOADLIB} has been added to APF list"
else
  echo "error: dataset ${XMEM_LOADLIB} has not been added to APF list"
  exit 8
fi

echo "info: copying load module ${XMEM_MODULE}"
if cp ${ZSS}/LOADLIB/${XMEM_MODULE} "//'${XMEM_LOADLIB}'" 2>/dev/null
then
  echo "info: module ${XMEM_MODULE} has been successfully copied to dataset ${XMEM_LOADLIB}"
else
  echo "error: module ${XMEM_MODULE} has not been copied to dataset ${XMEM_LOADLIB}"
  exit 8
fi

if datasetExists ${XMEM_PARMLIB}; then
  echo "info: copying PARMLIB member ${XMEM_PARM}"
  if cp ${ZSS}/SAMPLIB/${XMEM_PARM} "//'${XMEM_PARMLIB}'" 2>/dev/null
  then
    echo "info: PARMLIB member ${XMEM_PARM} has been successfully copied to dataset ${XMEM_PARMLIB}"
  else
    echo "error: PARMLIB member ${XMEM_PARM} has not been copied to dataset ${XMEM_PARMLIB}"
    exit 8
  fi
else
  echo "error: PARMLIB ${XMEM_PARMLIB} doesn't exist"
  exit 8
fi

cp ${ZSS}/SAMPLIB/${XMEM_JCL} ${ZSS}/SAMPLIB/${XMEM_JCL}.tmp
sed -i "s/ZIS.SZISLOAD/${XMEM_LOADLIB}/g" ${ZSS}/SAMPLIB/${XMEM_JCL}.tmp
if datasetExists ${XMEM_PROCLIB}; then
  echo "info: copying PROCLIB member ${XMEM_JCL}"
  if cp ${ZSS}/SAMPLIB/${XMEM_JCL}.tmp "//'${XMEM_PROCLIB}(${XMEM_JCL})'" 2>/dev/null
  then
    echo "info: PROCLIB member ${XMEM_JCL} has been successfully copied to dataset ${XMEM_PROCLIB}"
  else
    echo "error: PROCLIB member ${XMEM_JCL} has not been copied to dataset ${XMEM_PROCLIB}"
    exit 8
  fi
else
  echo "error: PROCLIB ${XMEM_PROCLIB} doesn't exist"
  exit 8
fi

echo "info: obtaining PPT information"
ppt=`../scripts/opercmd "d ppt,name=${XMEM_MODULE}" | grep "${XMEM_MODULE}  ."`
module=$(echo $ppt | cut -f1 -d ' ')
isNonSwappable=$(echo $ppt | cut -f3 -d ' ')
key=$(echo $ppt | cut -f8 -d ' ')
if [[ "${module}" -eq "${XMEM_MODULE}" ]]; then
  echo "info: module ${XMEM_MODULE} has a PPT-entry with NS=${isNonSwappable}, key=${key}"
  if [[ "${isNonSwappable}" -ne "Y" ]]; then
    echo "error: module ${XMEM_MODULE} must be non-swappable"
    exit 8
  fi
  if [[ "${key}" -ne "${XMEM_KEY}" ]]; then
    echo "error: module ${XMEM_MODULE} must run in key 4"
    exit 8
  fi
else
  echo "error: PPT-entry has not been found for module ${XMEM_MODULE}"
  exit 8
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

safFound=false
for saf in RACF ACF2 TSS
do
  if checkJob $saf; then
    safFound=true
    break
  fi
done

if [[ $safFound -ne true ]]
then
  echo "error: SAF has not been found"
  exit 8
fi

echo "info: SAF=${saf}"

sh ../scripts/zowe-xmem-check-user.sh ${saf} ${XMEM_STC_USER}
rc=$?
if [[ $rc -eq 1 ]]; then
  sh ../scripts/zowe-xmem-define-stc-user.sh ${saf} ${XMEM_STC_USER} ${XMEM_STC_USER_UID}
  if [[ $? -ne 0 ]]; then
    exit 8
  fi
elif [[ $rc -ne 0 ]]; then
  exit 8
fi

sh ../scripts/zowe-xmem-check-stc-profile.sh ${saf} ${XMEM_STC_PREFIX}
rc=$?
if [[ $rc -eq 1 ]]; then
  sh ../scripts/zowe-xmem-define-stc-profile.sh ${saf} ${XMEM_STC_PREFIX} ${XMEM_STC_USER}
  if [[ $? -ne 0 ]]; then
    exit 8
  fi
elif [[ $rc -ne 0 ]]; then
  exit 8
fi

sh ../scripts/zowe-xmem-check-profile.sh ${saf} FACILITY ${XMEM_PROFILE}
rc=$?
if [[ $rc -eq 1 ]]; then
  sh ../scripts/zowe-xmem-define-xmem-profile.sh ${saf} ${XMEM_PROFILE}
  if [[ $? -ne 0 ]]; then
    exit 8
  fi
elif [[ $rc -ne 0 ]]; then
  exit 8
fi

