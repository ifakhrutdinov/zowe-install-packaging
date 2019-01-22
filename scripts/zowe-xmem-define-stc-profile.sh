
saf=$1
stcPrefix=$2
stcUser=$3

echo "Define STC prefix ${stcPrefix} with STC user ${stcUser} (SAF=${saf})"

case $saf in

RACF) 
  tsocmd "RDEFINE STARTED ${stcPrefix}*.* UACC(NONE) STDATA(USER(${stcUser}) GROUP(STCGROUP))" \
    1> /tmp/cmd.out 2> /tmp/cmd.err 
  if [[ $? -ne 0 ]]
  then
    echo Error:  RDEFINE failed with the following errors
    cat /tmp/cmd.out /tmp/cmd.err
    exit 8
  else
    tsocmd "SETROPTS REFRESH RACLIST(STARTED)" \
      1> /tmp/cmd.out 2> /tmp/cmd.err
    echo "Info:  RACF setup complete"
    exit 0
  fi
  ;;

ACF2)
  tsocmd "SET CONTROL(GSO)" \
    1> /tmp/cmd.out 2> /tmp/cmd.err 
  if [[ $? -ne 0 ]]
  then
    echo "Error:  SET CONTROL(GSO) failed with the following errors"
    cat /tmp/cmd.out /tmp/cmd.err
    exit 8
  else
    tsocmd "INSERT STC.${stcPrefix}***** LOGONID(${stcUser}) GROUP(STCGROUP) STCID(${stcPrefix}*****)" \
      1> /tmp/cmd.out 2> /tmp/cmd.err 
    if [[ $? -ne 0 ]]
    then
      echo "Error:  INSERT STC failed with the following errors"
      cat /tmp/cmd.out /tmp/cmd.err
      exit 8
    else
      ../scripts/internal/opercmd "F ACF2,REFRESH(STC)" 1> /dev/null 2> /dev/null \
        1> /tmp/cmd.out 2> /tmp/cmd.err 
      if [[ $? -ne 0 ]]
      then
        echo "Error:  ACF2 REFRESH failed with the following errors"
        cat /tmp/cmd.out /tmp/cmd.err
        exit 8
      else
        echo "Info:  ACF2 setup complete"
        exit 0
      fi
    fi
  fi            
  ;;

TSS)
  tsocmd "TSS ADDTO(STC) PROCNAME(${tcProfile}*) ACID(${stcUser})" \
    1> /tmp/cmd.out 2> /tmp/cmd.err 
  if [[ $? -ne 0 ]]
  then
    echo "Error:  TSS ADDTO(STC) failed with the following errors"
    cat /tmp/cmd.out /tmp/cmd.err
    exit 8
  else
    echo "Info:  Top Secret setup complete"
    exit 0
  fi 
  ;;

*)
  echo "Error:  Unexpected SAF $saf"
  exit 8
esac

