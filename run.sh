#!/bin/bash
# Copyright 2017, Oracle and/or its affliates. All rights reserved. 

echo "Hello from the Java Flight Recorder Wercker Step"
echo "For information on how to use this step, please review the documentation in the Wercker Marketplace,"
echo "or visit https://github.com/wercker/java-flight-recorder"

# check that all of the required parameters were provided
# note that wercker does not enforce this for us, so we have to check
if [[ -z "$WERCKER_JAVA_FLIGHT_RECORDER_APPLICATION" || -z "$WERCKER_JAVA_FLIGHT_RECORDER_FILENAME" || -z "$WERCKER_JAVA_FLIGHT_RECORDER_DURATION" ]]; then
  echo "All required parameters: application, filename, and duration MUST be specified"
  exit 9
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
  echo "Could not find Java in this box - please make sure you have Oracle JDK installed"
  exit 8
fi
echo "Found JAVA_HOME at $JAVA_HOME"

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

if [[ -z "$WERCKER_JAVA_FLIGHT_RECORDER_DUMPONEXIT" ]]; then
  DUMPONEXIT=""
else
  DUMPONEXIT="dumponexit=$WERCKER_JAVA_FLIGHT_RECORDER_DUMPONEXIT"
fi

if [[ -z "$WERCKER_JAVA_FLIGHT_RECORDER_DUMPONEXITPATH" ]]; then
  DUMPONEXITPATH=""
else
  DUMPONEXITPATH="dumponexitpath=$WERCKER_JAVA_FLIGHT_RECORDER_DUMPONEXITPATH"
fi

if [[ -z "$DUMPONEXIT" && -z "$DUMPONEXITPATH" ]]; then
  JFR_OPTS=""
else
  JFR_OPTS="-XX:FlightRecorderOptions=$DUMPONEXIT,$DUMPONEXITPATH"
fi

if [[ -z "$WERCKER_JAVA_FLIGHT_RECORDER_TIMEOUT" ]]; then
  TIMEOUT=""
else
  TIMEOUT="timeout -k $WERCKER_JAVA_FLIGHT_RECORDER_TIMEOUT $WERCKER_JAVA_FLIGHT_RECORDER_TIMEOUT "
fi

# start the application under test
echo "$(date +%H:%M:%S): Starting the application under test..."
APPCMD="$JAVA_HOME/bin/java -XX:+UnlockCommercialFeatures -XX:+FlightRecorder $JFR_OPTS $CLASSPATH $EXPERIMENTAL $WERCKER_JAVA_FLIGHT_RECORDER_JAVA_OPTS $WERCKER_JAVA_FLIGHT_RECORDER_APPLICATION"

echo "The app command is: $APPCMD"
$TIMEOUT $APPCMD &

#save the Process ID
PIDS=()
PIDS+=($!)

#
# Get ready to run the load driver
#

if [[ -z "$WERCKER_JAVA_FLIGHT_RECORDER_DRIVER" ]]; then
  echo "You did not provide a load driver, so I will not try to start one"
else

    # check if any classpath entries were provided
    if [[ -z "$WERCKER_JAVA_FLIGHT_RECORDER_DRIVER_CLASSPATH" ]]; then
        DRIVER_CLASSPATH=""
    else
        DRIVER_CLASSPATH="-classpath $WERCKER_JAVA_FLIGHT_RECORDER_DRIVER_CLASSPATH"
    fi

    echo "$(date +%H:%M:%S): Starting the load driver..."
    DRIVERCMD="$JAVA_HOME/bin/java $DRIVER_CLASSPATH $WERCKER_JAVA_FLIGHT_RECORDER_DRIVER_JAVA_OPTS $EXPERIMENTAL $WERCKER_JAVA_FLIGHT_RECORDER_DRIVER"

    echo "The load driver command is: $DRIVERCMD"
    $TIMEOUT $DRIVERCMD &
    PIDS+=($!)
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
echo "Starting Java Flight Recorder..."
JFRCMD="$JAVA_HOME/bin/jcmd ${PIDS[0]} JFR.start duration=$WERCKER_JAVA_FLIGHT_RECORDER_DURATION $DELAY $MAXSIZE $MAXAGE $COMPRESS filename=$WERCKER_JAVA_FLIGHT_RECORDER_FILENAME"

echo "The JFR command is: $JFRCMD"
$JFRCMD &
JFRPID=$!

#
# Wait for everything to finish
#

# wait for the application and the recording to finish
# note that timeout will kill them if they go over the specified timeout
echo "Waiting for the application and load driver to finish..."
wait "${PIDS[@]}"

#
# tell JFR to save and stop (if it has not already)
#

# check if the recording is still running
if ! pgrep $JFRPID > /dev/null; then
  $JAVA_HOME/bin/jcmd ${PIDS[0]} JFR.dump
  $JAVA_HOME/bin/jcmd ${PIDS[0]} JFR.stop
fi

# push the output to the next pipeline
echo "Saving the recordings..."
cp $WERCKER_JAVA_FLIGHT_RECORDER_FILENAME /pipeline/output
if [ -e $WERCKER_JAVA_FLIGHT_RECOREDER_DUMPONEXIT ]; then 
  cp $WERCKER_JAVA_FLIGHT_RECORDER_DUMPONEXITPATH /pipeline/output
fi

echo "Java Flight Recorder Wercker Step Finished"
