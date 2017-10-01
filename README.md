# Java Flight Recorder Step for Wercker

An official Wercker step to run Java Flight Recorder standalone, i.e. outside of a build tool like Maven or Gradle.

## Requirements

The `box` that you run your pipeline in must have the Oracle JDK installed. 

Supported versions of Java are 8u131 or later or Java 9.

## Usage 

This step will execute two or three processes in the container - first it will run the application that you request, it will start your load driver (if you provided one), and then it will start a Java Flight Recorder recording.  The step assumes that both of these will eventually end on their own unless you provide a timeout, in which case it will stop your application and driver, and the recording for you.  It will then save the recordings for you.

You may delay the start of the recording to give your application time to get into a steady state if desired.

You may consider using the `experimental` property which will turn on the new container-aware memory management in the JVM.

To use the step, add the step to your pipeline (`wercker.yml`) with the appropriate properties, as in the example below:

```
  steps:
    - java/java-flight-recorder:
        application: com.example.your.JavaApplication
        classpath: my-awesome-app.jar
        duration: 60s
        filename: my-recording.jfr
        maxsize: 100M
        maxage: 1h
        delay: 60s
        compress: true
        dumponexit: true
        dumponexitpath: exit-dump.jfr
```

### Parameters
Parameters are optional unless specified otherwise.

Global parameters:

* `timeout`
<br>If the application or load driver have not finished after the specified number of seconds, then they will be terminated.  Append the letter `s` to indicate seconds, `m` to indicate minutes, `h` to indicate hours, or `d` to indicate days. 

Parameters that describe the application under test:

* `application` (required) 
<br>The name of the application that is under test, i.e. the fully qualified name of the class that contains the main method.  This application will be run with Java Flight Recording enabled.  This is not be confused with the test driver. 

* `classpath` 
<br>Used to specify classpath entries needed to run the application. Should be a colon-separated list of classpath entries.

* `java_opts`
<br>Used to specify any other java options needed to run the application, e.g. -XX options.  Should be a space-separated list of options, no enclosing quotes required.

* `experimental`
<br>If set to `true` will turn on experimental JVM options, specifically `-XX:+UnlockExperimentalVMOptions` and `-XX:+UseCGroupMemoryLimitForHeap`.  For other combinations, you should use `java_opts` to specify what you want.

Parameters that describe your load driver (optional):

* `driver` 
<br>The name of the load driver application, i.e. the fully qualified name of the class that contains the main method.  This application should create load on the application under test.

* `driver_classpath`
<br>Used to specify classpath entries needed to run the load driver.  Should be a colon-separated list of classpath entries.

* `driver_java_opts`
<br>Used to specify any other java options needed to run the application, e.g. -XX options.  Should be a space-separated list of options, no enclosing quotes required.

Parameters that control the Java Flight Recording options: 

* `duration` (required)
<br>The length of time to run the recording.

* `filename` (required) 
<br>The filename for the output recording.

* `maxsize` 
<br>Set the maximum size of the recording. Append the letter `k` or `K` to indicate kilobytes, `m` or `M` to indicate megabytes, `g` or `G` to indicate gigabytes, or do not specify any suffix to set the size in bytes.

* `maxage`
<br>Set the maximum age of the recording. Append the letter `s` to indicate seconds, `m` to indicate minutes, `h` to indicate hours, or `d` to indicate days.

* `delay`
<br>Add a delay before the recording is actually started; for example, you might want the application to boot or reach a steady state before starting the recording.  Append the letter `s` to indicate seconds, `m` to indicate minutes, `h` to indicate hours, or `d` to indicate days.

* `compress`
<br>Compress the output in ZIP format. Note that CPU resources are required for the compression, which can negatively impact performance.

After the step has completed, the recording file and/or dump file will be available.  You can open the file in Java Mission Control to view the recorded data. You can start Java Mission Control with the command:

`$JAVA_HOME/bin/jmc &` 

Then you can select `File/Open File...` from the main menu and choose your recording file.  Here is an exmaple of what a recording looks like when viewed in Java Misson Control: 

![sample screen](doc/jfr-sample.jpg)

A sample application is provided on GitHub that demonstrates how to use this Wercker Step.  For more information, please review that sample application at [https://github.com/markxnelson/sample-jfr-step](https://github.com/markxnelson/sample-jfr-step).
