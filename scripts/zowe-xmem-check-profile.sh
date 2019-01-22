
saf=$1
class=$2
profile=$3

echo "Check if profile ${profile} is defined in class ${class} (SAF=${saf})"

case $saf in

RACF)
  tsocmd "SEARCH CLASS(${class}) FILTER(${profile})" \
    1>/tmp/cmd.out 2>/tmp/cmd.err
  rc=$?
  if [[ $rc -eq 0 ]]
  then
    cat /tmp/cmd.out | grep -F "${profile}" 1>/dev/null
    if [[ $? -eq 0 ]]
    then
      echo "Info: profile ${profile} is defined in class ${class}"
      exit 0
    else
      echo "Warning: profile ${profile} is not defined in class ${class}"
      exit 1
    fi
  elif [[ $rc -eq 4 ]]
  then
    echo "Warning: profile ${profile} is not defined in class ${class}"
    exit 1
  else
    echo Error:  RDEFINE failed with the following errors
    cat /tmp/cmd.out /tmp/cmd.err
    exit 8
  fi
  if tsocmd "SEARCH CLASS(${class}) FILTER(${profile})" 2>/dev/null | grep -F "${profile}" 1>/dev/null; then
    echo "Info:  profile ${profile} is defined in class ${class}"
    exit 0
  else
    echo "Warning:  profile ${profile} is not defined or insufficient authority to issue RACF SEARCH"
    exit 1
  fi
;;

ACF2)
  echo "Warning:  ACF2 support has not been implemented," \
    "please manually check if ${profile} is defined in class ${class}"
  exit 8
;;

TSS)
  echo "Warning:  TopSecret support has not been implemented," \
    "please manually check if ${profile} is defined in class ${class}"
  exit 8
;;

*)
  echo "Error:  Unexpected SAF $saf"
  exit 8
esac

