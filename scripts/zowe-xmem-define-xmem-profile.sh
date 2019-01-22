
saf=$1
profile=$2

echo "Define cross-memory server profile ${profile} (SAF=${saf})"

case $saf in

RACF) 
  tsocmd "RDEFINE FACILITY ${profile} UACC(NONE)" \
    1> /tmp/cmd.out 2> /tmp/cmd.err 
  if [[ $? -ne 0 ]]
  then
    echo Error:  RDEFINE failed with the following errors
    cat /tmp/cmd.out /tmp/cmd.err
    exit 8
  else
    tsocmd "SETROPTS REFRESH RACLIST(FACILITY)" \
      1> /tmp/cmd.out 2> /tmp/cmd.err
    echo "Info:  RACF setup complete"
    exit 0
  fi
;;

ACF2)
  echo "Warning:  ACF2 support has not been implemented," \
    "please manually create ${profile} in the FACILITY class with UACC(NONE)"
  exit 8
;;

TSS)
  echo "Warning:  TopSecret support has not been implemented," \
    "please manually create ${profile} in the FACILITY class with UACC(NONE)"
  exit 8
;;

*)
  echo "Error:  Unexpected SAF $saf"
  exit 8
esac

