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
echo "JAVA_HOME is $JAVA_HOME"

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

# start the application under test
APPCMD="$JAVA_HOME/bin/java -XX:+UnlockCommercialFeatures -XX:+FlightRecorder $CLASSPATH $EXPERIMENTAL $WERCKER_JAVA_FLIGHT_RECORDER_JAVA_OPTS $WERCKER_JAVA_FLIGHT_RECORDER_APPLICATION"

echo "The app command is: $APPCMD"
$APPCMD &

#save the Process ID
PID=$!

if [[ -z "$WERCKER_JAVA_FLIGHT_RECORDER_DELAY" ]]; then
  DELAY=""
else
  DELAY="delay=$WERCKER_JAVA_FLIGHT_RECORDER_DELAY"
fi

# start the recording
JFRCMD="$JAVA_HOME/bin/jcmd $PID JFR.start duration=$WERCKER_JAVA_FLIGHT_RECORDER_DURATION $DELAY filename=$WERCKER_JAVA_FLIGHT_RECORDER_FILENAME"

echo "The JFR command is: $JFRCMD"
$JFRCMD &

# wait for the application and the recording to finish
wait

# push the output to the next pipeline
cp $WERCKER_JAVA_FLIGHT_RECORDER_FILENAME /pipeline/output

