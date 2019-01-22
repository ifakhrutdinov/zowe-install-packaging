
saf=$1
stcUser=$2
uid=$3

echo "Define STC user ${stcUser} with UID=${uid} (SAF=${saf})"

case $saf in

RACF)
  tsocmd "ADDUSER ${stcUser} DFLTGRP(STCGROUP) OMVS(UID(${uid})) AUTHORITY(USE)" \
    1>/tmp/cmd.out 2>/tmp/cmd.err
  if [[ $? -eq 0 ]]
  then
    echo "Info:  User ${stcUser} has been added"
    exit 0
  else
    echo "Error:  User ${stcUser} has not been added"
    cat /tmp/cmd.out /tmp/cmd.err
    exit 8
  fi
  ;;

ACF2)
  tsocmd "INSERT ${stcUser} GROUP(STCGROUP) SET PROFILE(USER) DIV(OMVS) INSERT ${stcUser} UID(${stcUser})" \
    1>/tmp/cmd.out 2>/tmp/cmd.err
  if [[ $? -eq 0 ]]
  then

    ../scripts/internal/opercmd "F ACF2,REBUILD(USR),CLASS(P)" 1> /dev/null 2> /dev/null \
        1> /tmp/cmd.out 2> /tmp/cmd.err
    if [[ $? -ne 0 ]]
    then
        echo "Error: ACF2 REBUILD failed with the following errors"
        cat /tmp/cmd.out /tmp/cmd.err
        exit 8
    fi

    ../scripts/internal/opercmd "F ACF2,OMVS" 1> /dev/null 2> /dev/null \
        1> /tmp/cmd.out 2> /tmp/cmd.err
    if [[ $? -ne 0 ]]
    then
        echo "Error: ACF2 OMVS failed with the following errors"
        cat /tmp/cmd.out /tmp/cmd.err
        exit 8
    fi

    echo "Info:  User ${stcUser} has been added"
    exit 0
  else
    echo "Error:  User ${stcUser} has not been added"
    cat /tmp/cmd.out /tmp/cmd.err
    exit 8
  fi
  ;;

TSS)
  tsocmd "TSS ADD(${stcUser}) OMVSGRP(STCGROUP) UID(${uid})" \
    1>/tmp/cmd.out 2>/tmp/cmd.err
  if [[ $? -eq 0 ]]
  then
    echo "Info:  User ${stcUser} has been added"
    exit 0
  else
    echo "Error:  User ${stcUser} has not been added"
    cat /tmp/cmd.out /tmp/cmd.err
    exit 8
  fi
  ;;

*)
  echo "Error: Unexpected SAF $saf"
  exit 8
esac

