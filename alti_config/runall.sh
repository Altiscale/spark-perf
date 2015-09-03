#!/bin/bash -x

iam=`whoami`
if [ "$iam" = "root" ] ; then
  >&2 echo "fail - you can't run test case as root!!! exiting!"
  exit -1
fi

# Run the test case as alti-test-01
# /bin/su - alti-test-01 -c "./test_spark/test_spark_shell.sh"
all_testcase=(shuffle04_config.py shuffle03_config.py shuffle02_config.py shuffle01_config.py serializer02_config.py serializer01_config.py parallel02_config.py parallel01_config.py memory02_config.py memory01_config.py)

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`
log_file="$curr_dir/result.log"
time_file="$curr_dir/time.log"
spark_perf="/home/alti-test-01/spark-perf"
spark_version=1.4.1

if [ "x${spark_perf}" != "x" ] ; then
  if [[ ! -L "$spark_perf" && ! -d "$spark_perf" ]] ; then
    >&2 echo "fail - $spark_perf does not exist, can't continue, exiting! check spark-perf installation."
    exit -1
  fi
fi

pushd `pwd`
cd $spark_perf
# Need to manually build MLLib test via sbt
pushd $spark_perf/mllib-tests
sbt/sbt -Dspark.version=$spark_version clean assembly
popd
pushd "$spark_perf/bin/"
for testcase in ${all_testcase[*]}
do
  echo "ok - executing testcase $testcase"
  echo "ok - executing testcase $testcase" >> $log_file
  echo "=================================" >> $log_file
  # deploy config
  cp $spark_perf/config/config.py $spark_perf/config/backup.config.py
  cp $curr_dir/$testcase $spark_perf/config/config.py
  grep -e JavaOptionSet -e EXTRA -e DRIVER "$curr_dir/$testcase" | tee -a $log_file
  touch $time_file
  /usr/bin/time -p --output="$time_file" ./run 2>&1 | tee -a $log_file
  cat $time_file >> $log_file
  fname=$(echo $testcase | cut -d. -f1)
  dname=$(date -u +%Y%m%d%H)
  rm -f c
  mv -f results $fname.$dname.results 
done
popd
popd

echo "ok - restoring original config.py from backup.config.py"
cp $spark_perf/config/backup.config.py $spark_perf/config/config.py

exit 0

