// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library browser;

import "dart:async";
import "dart:core";
import "dart:io";

import 'android.dart';

/** Class describing the interface for communicating with browsers. */
abstract class Browser {
  // Browsers actually takes a while to cleanup after itself when closing
  // Give it sufficient time to do that.
  static final Duration killRepeatInternal = const Duration(seconds: 10);
  static final int killRetries = 5;
  StringBuffer _stdout = new StringBuffer();
  StringBuffer _stderr = new StringBuffer();
  StringBuffer _usageLog = new StringBuffer();
  // This function is called when the process is closed.
  // This is extracted to an external function so that we can do additional
  // functionality when the process closes (cleanup and call onExit)
  Function _processClosed;
  // This is called after the process is closed, after _processClosed has
  // been called, but before onExit. Subclasses can use this to cleanup
  // any browser specific resources (temp directories, profiles, etc)
  Function _cleanup;

  /** The version of the browser - normally set when starting a browser */
  String version = "";
  /**
   * The underlying process - don't mess directly with this if you don't
   * know what you are doing (this is an interactive process that needs
   * special threatment to not leak).
   */
  Process process;

  /**
   * Id of the browser
   */
  String id;

  /** Callback that will be executed when the browser has closed */
  Function onClose;

  /** Print everything (stdout, stderr, usageLog) whenever we add to it */
  bool debugPrint = true;

  void _logEvent(String event) {
    String toLog = "$this ($id) - ${new DateTime.now()}: $event \n";
    if (debugPrint) print("usageLog: $toLog");
    _usageLog.write(toLog);
  }

  void _addStdout(String output) {
    if (debugPrint) print("stdout: $output");
    _stdout.write(output);
  }

  void _addStderr(String output) {
    if (debugPrint) print("stderr: $output");
    _stderr.write(output);
  }

  // Kill the underlying process using the supplied kill function
  // If there is a alternativeKillFunction we will use that after trying
  // the default killFunction.
  Future _killIt(killFunction, retries, [alternativeKillFunction = null]) {
    Completer<bool> completer = new Completer<bool>();

    // To capture non successfull attempts we set up a timer that will
    // trigger a retry (using the alternativeKillFunction if supplied).
    Timer timer =  new Timer(killRepeatInternal, () {
      // Remove the handler, we will set this again in the call to killIt
      // below
      if (retries <= 0) {
        _logEvent("Could not kill the process, not trying anymore");
        // TODO(ricow): Should we crash the test script here and
        // write out all our log. This is basically not a situation
        // that we want to ignore. We could potentially have a handler we
        // can call if this happens, which will shutdown the main process
        // with info that people should contact [ricow,kustermann,?]
        completer.complete(false);
      }
      _logEvent("Could not kill the process, retrying");
      var nextKillFunction = killFunction;
      if (alternativeKillFunction != null) {
        nextKillFunction = alternativeKillFunction;
      }
      _killIt(nextKillFunction, retries - 1).then((success) {
        completer.complete(success);
      });
    });

    // Make sure we intercept onExit calls and eliminate the timer.
    _processClosed = () {
      timer.cancel();
      _logEvent("Proccess exited, cancel timer in kill loop");
      _processClosed = null;
      process = null;
      completer.complete(true);
    };


    _logEvent("calling kill function");
    if (killFunction()) {
      // We successfully sent the signal.
      _logEvent("killing signal sent");
    } else {
      _logEvent("The process is already dead, kill signal could not be send");
      completer.complete(true);
    }
    return completer.future;
  }


  /** Close the browser */
  Future<bool> close() {
    _logEvent("Close called on browser");
    if (process == null) {
      _logEvent("No process open, nothing to kill.");
      return new Future.immediate(true);
    }
    var killFunction = process.kill;
    // We use a SIGKILL signal if we don't kill the process in the first go.
    var alternativeKillFunction =
        () { return process.kill(ProcessSignal.SIGKILL);};
    return _killIt(killFunction, killRetries, alternativeKillFunction);
  }

  /**
   * Start the browser using the supplied argument.
   * This sets up the error handling and usage logging.
   */
  Future<bool> startBrowser(String command, List<String> arguments) {
    return Process.start(command, arguments).then((startedProcess) {
      process = startedProcess;
      process.stdout.transform(new StringDecoder()).listen((data) {
        _addStdout(data);
      }, onError: (error) {
        // This should _never_ happen, but we really want this in the log
        // if it actually does due to dart:io or vm bug.
        _usageLog.add(
            "An error occured in the process stdout handling: $error");
      });

      process.stderr.transform(new StringDecoder()).listen((data) {
        _addStderr(data);
      }, onError: (error) {
        // This should _never_ happen, but we really want this in the log
        // if it actually does due to dart:io or vm bug.
        _usageLog.add(
            "An error occured in the process stderr handling: $error");
      });

      process.exitCode.then((exitCode) {
        _logEvent("Browser closed with exitcode $exitCode");
        if (_processClosed != null) _processClosed();
        if (_cleanup != null) _cleanup();
        if (onClose != null) onClose(exitCode);
      });
      return true;
    }).catchError((error) {
      _logEvent("Running $command $arguments failed with $error");
      return false;
    });
  }

  /**
   * Get any stdout that the browser wrote during execution.
   */
  String get stdout => _stdout.toString();
  String get stderr => _stderr.toString();
  String get usageLog => _usageLog.toString();

  String toString();
  /** Starts the browser loading the given url */
  Future<bool> start(String url);
}

class Chrome extends Browser {
  /**
   * The binary used to run chrome - changing this can be nececcary for
   * testing or using non standard chrome installation.
   */
  const String binary = "google-chrome";

  Future<bool> start(String url) {
    _logEvent("Starting chrome browser on: $url");
    // Get the version and log that.
    return Process.run(binary, ["--version"]).then((var versionResult) {
      if (versionResult.exitCode != 0) {
        _logEvent("Failed to chrome get version");
        _logEvent("Make sure $binary is a valid program for running chrome");
        return new Future.immediate(false);
      }
      version = versionResult.stdout;
      _logEvent("Got version: $version");

      return new Directory('').createTemp().then((userDir) {
        _cleanup = () { userDir.delete(recursive: true); };
        var args = ["--user-data-dir=${userDir.path}", url,
                    "--disable-extensions", "--disable-popup-blocking",
                    "--bwsi", "--no-first-run"];
        return startBrowser(binary, args);

      });
    }).catchError((e) {
      _logEvent("Running $binary --version failed with $e");
      return false;
    });
  }

  String toString() => "Chrome";
}

class AndroidChrome extends Browser {
  const String viewAction = 'android.intent.action.VIEW';
  const String mainAction = 'android.intent.action.MAIN';
  const String chromePackage = 'com.android.chrome';
  const String browserPackage = 'com.android.browser';
  const String firefoxPackage = 'org.mozilla.firefox';
  const String turnScreenOnPackage = 'com.google.dart.turnscreenon';

  AndroidEmulator _emulator;
  AdbDevice _adbDevice;

  AndroidChrome(this._adbDevice);

  Future<bool> start(String url) {
    var browserIntent = new Intent(
        viewAction, browserPackage, '.BrowserActivity', url);
    var chromeIntent = new Intent(viewAction, chromePackage, '.Main', url);
    var firefoxIntent = new Intent(viewAction, firefoxPackage, '.App', url);
    var turnScreenOnIntent =
        new Intent(mainAction, turnScreenOnPackage, '.Main');

    var chromeAPK = new Path(
        'third_party/android_testing_resources/com.android.chrome-1.apk');
    var turnScreenOnAPK = new Path(
        'third_party/android_testing_resources/TurnScreenOn.apk');
    var chromeConfDir = new Path(
        'third_party/android_testing_resources/chrome_configuration');
    var chromeConfDirRemote = new Path(
        '/data/user/0/com.android.chrome/');

    return _adbDevice.waitForBootCompleted().then((_) {
      return _adbDevice.forceStop(chromeIntent.package);
    }).then((_) {
      return _adbDevice.killAll();
    }).then((_) {
      return _adbDevice.adbRoot();
    }).then((_) {
      return _adbDevice.installApk(turnScreenOnAPK);
    }).then((_) {
      return _adbDevice.installApk(chromeAPK);
    }).then((_) {
      return _adbDevice.pushData(chromeConfDir, chromeConfDirRemote);
    }).then((_) {
      return _adbDevice.chmod('777', chromeConfDirRemote);
    }).then((_) {
      return _adbDevice.startActivity(turnScreenOnIntent).then((_) => true);
    }).then((_) {
      return _adbDevice.startActivity(chromeIntent).then((_) => true);
    });
  }

  Future<bool> close() {
    if (_adbDevice != null) {
      return _adbDevice.forceStop(chromePackage).then((_) {
        return _adbDevice.killAll().then((_) => true);
      });
    }
    return new Future.immediate(true);
  }

  String toString() => "chromeOnAndroid";
}

class Firefox extends Browser {
  /**
   * The binary used to run firefox - changing this can be nececcary for
   * testing or using non standard firefox installation.
   */
  const String binary = "firefox";

  const String enablePopUp =
      "user_pref(\"dom.disable_open_during_load\", false);";

  Future _createPreferenceFile(var path) {
    var file = new File("${path.toString()}/user.js");
    var randomFile = file.openSync(FileMode.WRITE);
    randomFile.writeStringSync(enablePopUp);
    randomFile.close();
  }


  Future<bool> start(String url) {
    _logEvent("Starting firefox browser on: $url");
    // Get the version and log that.
    return Process.run(binary, ["--version"]).then((var versionResult) {
      if (versionResult.exitCode != 0) {
        _logEvent("Failed to firefox get version");
        _logEvent("Make sure $binary is a valid program for running firefox");
        return new Future.immediate(false);
      }
      version = versionResult.stdout;
      _logEvent("Got version: $version");

      return new Directory('').createTemp().then((userDir) {
        _createPreferenceFile(userDir.path);
        _cleanup = () { userDir.delete(recursive: true); };
        var args = ["-profile", "${userDir.path}",
                    "-no-remote", "-new-instance", url];
        return startBrowser(binary, args);

      });
    }).catchError((e) {
      _logEvent("Running $binary --version failed with $e");
      return false;
    });
  }

  String toString() => "Firefox";
}


/**
 * Describes the current state of a browser used for testing.
 */
class BrowserTestingStatus {
// TODO(ricow): Add prefetching to the browsers. We spend a lot of time waiting
// for the next test. Handling timeouts is the hard part of this!

  Browser browser;
  BrowserTest currentTest;
  // This is currently not used for anything except for error reporting.
  // Given the usefulness of this in debugging issues this should not be
  // removed even when we have really stable system.
  BrowserTest lastTest;
  bool timeout = false;
  BrowserTestingStatus(Browser this.browser);
}


/**
 * Describes a single test to be run int the browser.
 */
class BrowserTest {
  // TODO(ricow): Add timeout callback instead of the string passing hack.
  Function doneCallback;
  String url;
  int timeout;
  // We store this here for easy access when tests time out (instead of
  // capturing this in a closure)
  Timer timeoutTimer;

  // Used for debugging, this is simply a unique identifier assigned to each
  // test.
  int id;
  static int _idCounter = 0;

  BrowserTest(this.url, this.doneCallback, this.timeout) {
    id = _idCounter++;
  }
}


/**
 * Encapsulates all the functionality for running tests in browsers.
 * The interface is rather simple. After starting the runner tests
 * are simply added to the queue and a the supplied callbacks are called
 * whenever a test completes.
 */
class BrowserTestRunner {
  String local_ip;
  String browserName;
  int maxNumBrowsers;

  bool underTermination = false;

  List<BrowserTest> testQueue = new List<BrowserTest>();
  Map<String, BrowserTestingStatus> browserStatus =
      new Map<String, BrowserTestingStatus>();

  var adbDeviceMapping = new Map<String, AdbDevice>();
  // This cache is used to guarantee that we never see double reporting.
  // If we do we need to provide developers with this information.
  // We don't add urls to the cache until we have run it.
  Map<int, String> testCache = new Map<int, String>();
  List<int> doubleReportingTests = new List<int>();

  BrowserTestingServer testingServer;

  BrowserTestRunner(this.local_ip, this.browserName, this.maxNumBrowsers);

  Future<bool> start() {
    testingServer = new BrowserTestingServer(local_ip);
    return testingServer.start().then((_) {
      testingServer.testDoneCallBack = handleResults;
      testingServer.nextTestCallBack = getNextTest;
      return getBrowsers().then((browsers) {
        var futures = [];
        for (var browser in browsers) {
          var url = testingServer.getDriverUrl(browser.id);
          var future = browser.start(url).then((success) {
            if (success) {
              browserStatus[browser.id] = new BrowserTestingStatus(browser);
            }
            return success;
          });
          futures.add(future);
        }
        return Future.wait(futures).then((values) {
          return !values.contains(false);
        });
      });
    });
  }

  Future<List<Browser>> getBrowsers() {
    // TODO(kustermann): This is a hackisch way to accomplish it and should
    // be encapsulated
    var browsersCompleter = new Completer();
    if (browserName == 'chromeOnAndroid') {
      AdbHelper.listDevices().then((deviceIds) {
        if (deviceIds.length > 0) {
          var browsers = [];
          for (int i = 0; i < deviceIds.length; i++) {
            var id = "BROWSER$i";
            var device = new AdbDevice(deviceIds[i]);
            adbDeviceMapping[id] = device;
            var browser = new AndroidChrome(device);
            browsers.add(browser);
            // We store this in case we need to kill the browser.
            browser.id = id;
          }
          browsersCompleter.complete(browsers);
        } else {
          throw new StateError("No android devices found.");
        }
      });
    } else {
      var browsers = [];
      for (int i = 0; i < maxNumBrowsers; i++) {
        var id = "BROWSER$i";
        var browser = getInstance();
        browsers.add(browser);
        // We store this in case we need to kill the browser.
        browser.id = id;
      }
      browsersCompleter.complete(browsers);
    }
    return browsersCompleter.future;
  }

  var timedOut = [];

  void handleResults(String browserId, String output, int testId) {
    var status = browserStatus[browserId];
    if (testCache.containsKey(testId)) {
      doubleReportingTests.add(testId);
      return;
    }

    if (status.timeout) {
      // We don't do anything, this browser is currently being killed and
      // replaced.
    } else if (status.currentTest != null) {
      status.currentTest.timeoutTimer.cancel();
      if (status.currentTest.id != testId) {
        print("Expected test id ${status.currentTest.id} for"
              "${status.currentTest.url}");
        print("Got test id ${testId}");
        print("Last test id was ${status.lastTest.id} for "
              "${status.currentTest.url}");
        throw("This should never happen, wrong test id");
      }
      testCache[testId] = status.currentTest.url;
      status.currentTest.doneCallback(output);
      status.lastTest = status.currentTest;
      status.currentTest = null;
    } else {
      print("\nThis is bad, should never happen, handleResult no test");
      print("URL: ${status.lastTest.url}");
      print(output);
      terminate().then((_) {
        exit(1);
      });
    }
  }

  void handleTimeout(BrowserTestingStatus status) {
    // We simply kill the browser and starts up a new one!
    // We could be smarter here, but it does not seems like it is worth it.
    status.timeout = true;
    timedOut.add(status.currentTest.url);
    var id = status.browser.id;
    status.browser.close().then((closed) {
      if (!closed) {
        // Very bad, we could not kill the browser.
        print("could not kill browser $id");
        return;
      }
      var browser;
      if (browserName == 'chromeOnAndroid') {
        browser = new AndroidChrome(adbDeviceMapping[id]);
      } else {
        browser = getInstance();
      }
      browser.start(testingServer.getDriverUrl(id)).then((success) {
        // We may have started terminating in the mean time.
        if (underTermination) {
          browser.close().then((success) {
            // We should never hit this, print it out.
            if (!success) {
              print("Could not kill browser ($id) started due to timeout");
            }
          });
          return;
        }
        if (success) {
          browser.id = id;
          status.browser = browser;
          status.timeout = false;
        } else {
          // TODO(ricow): Handle this better.
          print("This is bad, should never happen, could not start browser");
          exit(1);
        }
      });
    });

    status.currentTest.doneCallback("TIMEOUT");
    status.currentTest = null;
  }

  BrowserTest getNextTest(String browserId) {
    if (testQueue.isEmpty) return null;
    var status = browserStatus[browserId];
    if (status == null) return null;
    // We are currently terminating this browser, don't start a new test.
    if (status.timeout) return null;
    BrowserTest test = testQueue.removeLast();
    if (status.currentTest == null) {
      status.currentTest = test;
    } else {
      // TODO(ricow): Handle this better.
      print("This is bad, should never happen, getNextTest all full");
      print("Old test was: ${status.currentTest.url}");
      print("Timed out tests:");
      for (var v in timedOut) {
        print("  $v");
      }
      exit(1);
    }
    Timer timer = new Timer(new Duration(seconds: test.timeout),
                            () { handleTimeout(status); });
    status.currentTest.timeoutTimer = timer;
    return test;
  }

  void queueTest(BrowserTest test) {
    testQueue.add(test);
  }

  void printDoubleReportingTests() {
    if (doubleReportingTests.length == 0) return;
    // TODO(ricow): die on double reporting.
    // Currently we just report this here, we could have a callback to the
    // encapsulating environment.
    print("");
    print("Double reporting tests");
    for (var id in doubleReportingTests) {
      print("  ${testCache[id]}");
    }
  }

  Future<bool> terminate() {
    var futures = [];
    underTermination = true;
    testingServer.underTermination = true;
    for (BrowserTestingStatus status in browserStatus.values) {
      futures.add(status.browser.close());
    }
    return Future.wait(futures).then((values) {
      testingServer.httpServer.close();
      printDoubleReportingTests();
      return !values.contains(false);
    });
  }

  Browser getInstance() {
    if (browserName == "chrome") {
      return new Chrome();
    } else if (browserName == "ff") {
      return new Firefox();
    }
    throw "Non supported browser for browser controller";
  }
}

class BrowserTestingServer {
  /// Interface of the testing server:
  ///
  /// GET /driver/BROWSER_ID -- This will get the driver page to fetch
  ///                           and run tests ...
  /// GET /next_test/BROWSER_ID -- returns "WAIT" "TERMINATE" or "url#id"
  /// where url is the test to run, and id is the id of the test.
  /// If there are currently no available tests the waitSignal is send
  /// back. If we are in the process of terminating the terminateSignal
  /// is send back and the browser will stop requesting new tasks.
  /// POST /report/BROWSER_ID?id=NUM -- sends back the dom of the executed
  ///                                   test

  final String local_ip;

  const String driverPath = "/driver";
  const String nextTestPath = "/next_test";
  const String reportPath = "/report";
  const String waitSignal = "WAIT";
  const String terminateSignal = "TERMINATE";

  var testCount = 0;
  var httpServer;
  bool underTermination = false;

  Function testDoneCallBack;
  Function nextTestCallBack;

  BrowserTestingServer(this.local_ip);

  Future start() {
    return HttpServer.bind(local_ip, 0).then((createdServer) {
      httpServer = createdServer;
      void handler(HttpRequest request) {
        if (request.uri.path.startsWith(reportPath)) {
          var browserId = request.uri.path.substring(reportPath.length + 1);
          var testId = int.parse(request.queryParameters["id"].split("=")[1]);

          handleReport(request, browserId, testId);
          // handleReport will asynchroniously fetch the data and will handle
          // the closing of the streams.
          return;
        }
        var textResponse = "";
        if (request.uri.path.startsWith(driverPath)) {
          var browserId = request.uri.path.substring(driverPath.length + 1);
          textResponse = getDriverPage(browserId);
        } else if (request.uri.path.startsWith(nextTestPath)) {
          var browserId = request.uri.path.substring(nextTestPath.length + 1);
          textResponse = getNextTest(browserId);
        } else {
          // We silently ignore other requests.
        }
        request.response.write(textResponse);
        request.listen((_) {}, onDone: request.response.close);
        request.response.done.catchError((error) {
        if (!underTermination) {
          print("URI ${request.uri}");
          print("Textresponse $textResponse");
          throw("Error returning content to browser: $error");
        }
      });
      }
      void errorHandler(e) {
        if (!underTermination) print("Error occured in httpserver: $e");
      };
      httpServer.listen(handler, onError: errorHandler);
      return true;
    });
  }

  void handleReport(HttpRequest request, String browserId, var testId) {
    StringBuffer buffer = new StringBuffer();
    request.transform(new StringDecoder()).listen((data) {
      buffer.write(data);
      }, onDone: () {
        String back = buffer.toString();
        request.response.close();
        testDoneCallBack(browserId, back, testId);
      }, onError: (error) { print(error); });
  }

  String getNextTest(String browserId) {
    var nextTest = nextTestCallBack(browserId);
    if (underTermination) {
      // Browsers will be killed shortly, send them a terminate signal so
      // that they stop pulling.
      return terminateSignal;
    } else if (nextTest == null) {
      // We don't currently have any tests ready for consumption, wait.
      return waitSignal;
    } else {
      return "${nextTest.url}#id=${nextTest.id}";
    }
  }

  String getDriverUrl(String browserId) {
    if (httpServer == null) {
      print("Bad browser testing server, you are not started yet. Can't "
            "produce driver url");
      exit(1);
      // This should never happen - exit immediately;
    }
    return "http://$local_ip:${httpServer.port}/driver/$browserId";
  }


  String getDriverPage(String browserId) {
    String driverContent = """
<!DOCTYPE html><html>
<head>
  <title>Driving page</title>
  <script type='text/javascript'>
    var number_of_tests = 0;
    var processed_ids = {};
    var current_id;
    var testing_window;

    function newTaskHandler() {
      if (this.readyState == this.DONE) {
        if (this.status == 200) {
          if (this.responseText == '$waitSignal') {
            setTimeout(getNextTask, 500);
          } else if (this.responseText == '$terminateSignal') {
            // Don't do anything, we will be killed shortly.
          } else {
            // TODO(ricow): Do something more clever here.
            if (nextTask != undefined) alert('This is really bad');
            // The task is send to us as:
            // URL#ID
            var split = this.responseText.split('#');
            var nextTask = split[0];
            if (testing_window != undefined) {
              testing_window.location = '_blank';
            }
            function doAfterEmptyEventLoop() {
              current_id = split[1];
              processed_ids[current_id] = 0;
              run(nextTask);
            }
            setTimeout(doAfterEmptyEventLoop(), 0);
          }
        } else {
          // We are basically in trouble - do something clever.
        }
      }
    }

    function getNextTask() {
      var client = new XMLHttpRequest();
      client.onreadystatechange = newTaskHandler;
      client.open('GET', '$nextTestPath/$browserId');
      client.send();
    }

    function run(url) {
      number_of_tests++;
      document.getElementById('number').innerHTML = number_of_tests;
      if (testing_window == undefined) {
        testing_window = window.open(url);
      } else {
        testing_window.location = url;
      }
    }

    function reportMessage(msg) {
      var client = new XMLHttpRequest();
      function handleReady() {
        if (this.readyState == this.DONE) {
          if (processed_ids[current_id] == 0) {
            getNextTask();
            processed_ids[current_id] = 1;
          }
        }
      }
      client.onreadystatechange = handleReady;
      client.open('POST', '$reportPath/${browserId}?id=' + current_id);
      client.setRequestHeader('Content-type',
                              'application/x-www-form-urlencoded');
      client.send(msg);
      // TODO(ricow) add error handling to somehow report the fact that
      // we could not send back a result.
    }

    function messageHandler(e) {
      var msg = e.data;
      if (typeof msg != 'string') return;
      reportMessage(msg);
    }

    window.addEventListener('message', messageHandler, false);
    waitForDone = false;

    getNextTask();

  </script>
</head>
  <body>
    Dart test driver, number of tests: <div id="number"></div>
  </body>
</html>
""";
    return driverContent;
  }
}
