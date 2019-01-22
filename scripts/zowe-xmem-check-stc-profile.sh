
saf=$1
prefix=$2
profile=$prefix"*.*"

echo "Check STC profile ${profile} (SAF=${saf})"

sh ../scripts/zowe-xmem-check-profile.sh $saf STARTED $profile

exit $?

