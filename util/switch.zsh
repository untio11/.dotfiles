echo 'Building home manager config'
home-manager build 2> $TMPDIR/hm-switch.log

if [[ $? -ne 0 ]]; then
  echo 'Build failed:'
  echo ''
  cat $TMPDIR/hm-switch.log
  exit 1
else
  ./result/activate &> hm-switch.log
  if [[ $? -ne 0 ]]; then
    echo 'Activation failed:'
    echo ''
    cat $TMPDIR/hm-switch.log
    rm ./result
    exit 2;
  else
    git -C $HM_HOME add -u
    hm_status=$(grep "profile generation" $TMPDIR/hm-switch.log)
    echo "$hm_status"
    if [[ "$hm_status" == *"reusing"* ]]; then
      exit 3
    else
      git -C $HM_HOME status
    fi
  fi
  exit 0
fi
