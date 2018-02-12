#!/bin/bash
# Copyright 2017, 2018, Oracle and/or its affliates. All rights reserved. 

echo "$(date +%H:%M:%S):  Hello from the Java Flight Recorder Wercker Step"
echo "For information on how to use this step, please review the documentation in the Wercker Marketplace,"
echo "or visit https://github.com/wercker/java-flight-recorder"

# check that all of the required parameters were provided
# note that wercker does not enforce this for us, so we have to check
if [[ -z "$WERCKER_JAVA_FLIGHT_RECORDER_APPLICATION" || -z "$WERCKER_JAVA_FLIGHT_RECORDER_FILENAME" || -z "$WERCKER_JAVA_FLIGHT_RECORDER_DURATION" ]]; then
  fail "$(date +%H:%M:%S): All required parameters: application, filename, and duration MUST be specified"
fi

# try to find Java
if [ -z "$JAVA_HOME" ] ; then
  JAVACMD=`which java`
else
  JAVACMD="$JAVA_HOME/bin/java"
fi

# find the real location of java - in case it is a symlink
if [ -z "$JAVA_HOME" ] ; then
  # resolve links - $JAVACMD may be a link
  PRG="$JAVACMD"

  # need this for relative symlinks
  while [ -h "$PRG" ] ; do
    ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '.*-> \(.*\)$'`
    if expr "$link" : '/.*' > /dev/null; then
      PRG="$link" else
      PRG="`dirname "$PRG"`/$link"
    fi
  done

  saveddir=`pwd`

  JAVA_HOME=`dirname "$PRG"`/..

  # make it fully qualified
  JAVA_HOME=`cd "$JAVA_HOME" && pwd`

  cd "$saveddir"
fi

if [[ -z "$JAVA_HOME" ]]; then
  fail "$(date +%H:%M:%S): Could not find Java in this box - please make sure you have Oracle JDK installed"
fi
echo "$(date +%H:%M:%S): Found JAVA_HOME at $JAVA_HOME"

#
#  Get ready to run the application under test
#

# check if any classpath entries were provided
if [[ -z "$WERCKER_JAVA_FLIGHT_RECORDER_CLASSPATH" ]]; then
    CLASSPATH=""
else
    CLASSPATH="-classpath $WERCKER_JAVA_FLIGHT_RECORDER_CLASSPATH"
fi

# turn on experimental options if requested
if [ "$WERCKER_JAVA_FLIGHT_RECORDER_EXPERIMENTAL" = "true" ]; then
  EXPERIMENTAL="-XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap"
else
  EXPERIMENTAL=""
fi

if [[ -z "$WERCKER_JAVA_FLIGHT_RECORDER_TIMEOUT" ]]; then
  TIMEOUT=""
else
  TIMEOUT="timeout -k $WERCKER_JAVA_FLIGHT_RECORDER_TIMEOUT $WERCKER_JAVA_FLIGHT_RECORDER_TIMEOUT "
fi

# start the application under test
echo "$(date +%H:%M:%S): Starting the application under test..."
APPCMD="$JAVA_HOME/bin/java -XX:+UnlockCommercialFeatures -XX:+FlightRecorder $CLASSPATH $EXPERIMENTAL $WERCKER_JAVA_FLIGHT_RECORDER_JAVA_OPTS $WERCKER_JAVA_FLIGHT_RECORDER_APPLICATION"

echo "The app command is: $APPCMD"
$TIMEOUT $APPCMD &
APPPID=$!

#
# Get ready to run the load driver
#

if [[ -z "$WERCKER_JAVA_FLIGHT_RECORDER_DRIVER" ]]; then
  echo "$(date +%H:%M:%S): You did not provide a load driver, so I will not try to start one"
else

    # check if any classpath entries were provided
    if [[ -z "$WERCKER_JAVA_FLIGHT_RECORDER_DRIVER_CLASSPATH" ]]; then
        DRIVER_CLASSPATH=""
    else
        DRIVER_CLASSPATH="-classpath $WERCKER_JAVA_FLIGHT_RECORDER_DRIVER_CLASSPATH"
    fi

    echo "$(date +%H:%M:%S): Starting the load driver..."
    DRIVERCMD="$JAVA_HOME/bin/java $DRIVER_CLASSPATH $WERCKER_JAVA_FLIGHT_RECORDER_DRIVER_JAVA_OPTS $EXPERIMENTAL $WERCKER_JAVA_FLIGHT_RECORDER_DRIVER"

    echo "$(date +%H:%M:%S): The load driver command is: $DRIVERCMD"
    $TIMEOUT $DRIVERCMD &
    DRIVERPID=$!
fi

#
# Get ready to start the flight recorder
#

if [[ -z "$WERCKER_JAVA_FLIGHT_RECORDER_DELAY" ]]; then
  DELAY=""
else
  DELAY="delay=$WERCKER_JAVA_FLIGHT_RECORDER_DELAY"
fi

if [[ -z "$WERCKER_JAVA_FLIGHT_RECORDER_MAXSIZE" ]]; then
  MAXSIZE=""
else
  MAXSIZE="maxsize=$WERCKER_JAVA_FLIGHT_RECORDER_MAXSIZE"
fi

if [[ -z "$WERCKER_JAVA_FLIGHT_RECORDER_MAXAGE" ]]; then
  MAXAGE=""
else
  MAXAGE="maxage=$WERCKER_JAVA_FLIGHT_RECORDER_MAXAGE"
fi

if [[ -z "$WERCKER_JAVA_FLIGHT_RECORDER_COMPRESS" ]]; then
  COMPRESS=""
else
  COMPRESS="compress=$WERCKER_JAVA_FLIGHT_RECORDER_COMPRESS"
fi

# start the recording
echo "$(date +%H:%M:%S): Starting Java Flight Recorder..."
JFRCMD="$JAVA_HOME/bin/jcmd $WERCKER_JAVA_FLIGHT_RECORDER_APPLICATION JFR.start duration=$WERCKER_JAVA_FLIGHT_RECORDER_DURATION filename=$WERCKER_JAVA_FLIGHT_RECORDER_FILENAME $DELAY $MAXSIZE $MAXAGE $COMPRESS "

echo "$(date +%H:%M:%S): The JFR command is: $JFRCMD"
$JFRCMD &
JFRPID=$!

#
# Wait for everything to finish
#

# wait for the application and the recording to finish
# note that timeout will kill them if they go over the specified timeout
echo "$(date +%H:%M:%S): Waiting for the application and load driver to finish..."
PIDS=()
PIDS+=$APPPID
PIDS+=$DRIVERPID
wait "${PIDS[@]}"
echo ""

#
# tell JFR to save and stop (if it has not already)
#

# check if the recording is still running
RUNNING=`$JAVA_HOME/bin/jcmd | grep $JFRPID | wc | awk ' { print $1; } '`
if [ "$RUNNING" == "1" ]; then
  $JAVA_HOME/bin/jcmd $WERCKER_JAVA_FLIGHT_RECORDER_APPLICATION JFR.dump
  $JAVA_HOME/bin/jcmd $WERCKER_JAVA_FLIGHT_RECORDER_APPLICATION JFR.stop
fi

# push the output to the next pipeline
echo "$(date +%H:%M:%S): Saving the recordings..."
cp $WERCKER_JAVA_FLIGHT_RECORDER_FILENAME /pipeline/output

echo "$(date +%H:%M:%S): Java Flight Recorder Wercker Step Finished"
