
saf=$1
user=$2

echo "Check if user ${user} is defined (SAF=${saf})"

case $saf in

RACF)
  msg=`tsocmd "LU ${user}" 2>/dev/null | head -1`

  case $msg in
  UNABLE\ TO\ LOCATE\ USER\ *)
    echo "Warning:  User ${user} is not defined"
    exit 1
  ;;

  NOT\ AUTHORIZED\ TO\ LIST\ *)
    echo "Error: User ${user} is defined but you are not authorized to list it"
    exit 8
  ;;

  USER=${user}\ *)
    echo "Info:  User ${user} is defined and you are authorized to list it"
    exit 0
  ;;

  *)
    echo "Error:  Unexpected response to LU command"
    echo $msg
    exit 8
  esac
;;

ACF2)
  echo "Warning:  ACF2 support has not been implemented," \
    "please manually check if user ${user} is defined"
  exit 8
;;

TSS)
  echo "Warning:  TopSecret support has not been implemented," \
    "please manually check if user ${user} is defined"
  exit 8
;;

*)
  echo "Error:  Unexpected SAF $saf"
  exit 8
esac

