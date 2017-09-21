# Java Flight Recorder Step for Wercker
This project provides a Wercker Step to run Java Flight Recorder standalone, i.e. outside of a build tool like Maven or Gradle.


__Note:__ Java Flight Recorder requires a commercial license for use in production. To learn more about commercial features and how to enable them please visit http://www.oracle.com/technetwork/java/javaseproducts/.


## Requirements

The `box` that you run your pipeline in must have the Oracle JDK installed. 

## Usage 

To use the step, add the step to your pipeline (`wercker.yml`) with the appropriate properties, as in the example below:

```
  steps:
    - java/java-flight-recorder:
        application: com.example.your.JavaApplication
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

* `application` (required) 
<br>The name of the application that is under test.  This application will be run with Java Flight Recording enabled.  This is not be confused with the test driver. 

* `classpath` 
<br>Used to specify classpath entries needed to run the application.

* `java_opts`
<br>Used to specify any other java options needed to run the application.

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

* `dumponexit`

* `dumponexitpath`
