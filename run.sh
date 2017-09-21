#!/bin/bash
echo "Hello from the Java Flight Recorder Wercker Step, I am currently under development, I don't work yet!"

if [ -z "$JAVA_HOME" ] ; then
  JAVACMD=`which java`
else
  JAVACMD="$JAVA_HOME/bin/java"
fi

# find real location of java
if [ -z "$JAVA_HOME" ] ; then
  # resolve links - $JAVACMD may be a link
  PRG="$JAVACMD"

  # need this for relative symlinks
  while [ -h "$PRG" ] ; do
    ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '.*-> \(.*\)$'`
    if expr "$link" : '/.*' > /dev/null; then
      PRG="$link"
    else
      PRG="`dirname "$PRG"`/$link"
    fi
  done

  saveddir=`pwd`

  JAVA_HOME=`dirname "$PRG"`/..

  # make it fully qualified
  JAVA_HOME=`cd "$JAVA_HOME" && pwd`

  cd "$saveddir"
fi

# check if any classpath entries were provided
if [[ -z "$WERCKER_JAVA_FLIGHT_RECORDER_CLASSPATH" ]]; then
    CLASSPATH=""
else
    CLASSPATH="-classpath $WERCKER_JAVA_FLIGHT_RECORDER_CLASSPATH"
fi

# start the application under test
$JAVA_HOME/bin/java \
  -XX:+UnlockCommercialFeatures \
  -XX:+FlightRecorder \
  $WERCKER_JAVA_FLIGHT_RECORDER_JAVA_OPTS \
  $CLASSPATH \
  $WERCKER_JAVA_FLIGHT_RECORDER_APPLICATION &

#save the Process ID
PID=$!

# start the recording
$JAVA_HOME/bin/jcmd $PID JFR.start \
  duration=$WERCKER_JAVA_FLIGHT_RECORDER_DURATION \
  filename=$WERCKER_JAVA_FLIGHT_RECORDER_FILENAME

