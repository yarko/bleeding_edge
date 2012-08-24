// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

#import("dart:isolate");
#import("dart:io");

class TestServerMain {
  TestServerMain()
      : _statusPort = new ReceivePort(),
        _serverPort = null {
    _serverPort = spawnFunction(startTestServer);
  }

  void setServerStartedHandler(void startedCallback(int port)) {
    _startedCallback = startedCallback;
  }

  void start() {
    // Handle status messages from the server.
    _statusPort.receive((var status, SendPort replyTo) {
      if (status.isStarted) {
        _startedCallback(status.port);
      }
    });

    // Send server start message to the server.
    var command = new TestServerCommand.start();
    _serverPort.send(command, _statusPort.toSendPort());
  }

  void shutdown() {
    // Send server stop message to the server.
    _serverPort.send(new TestServerCommand.stop(), _statusPort.toSendPort());
    _statusPort.close();
  }

  void chunkedEncoding() {
    // Send chunked encoding message to the server.
    _serverPort.send(
        new TestServerCommand.chunkedEncoding(), _statusPort.toSendPort());
  }

  ReceivePort _statusPort;  // Port for receiving messages from the server.
  SendPort _serverPort;  // Port for sending messages to the server.
  var _startedCallback;
}


class TestServerCommand {
  static const START = 0;
  static const STOP = 1;
  static const CHUNKED_ENCODING = 2;

  TestServerCommand.start() : _command = START;
  TestServerCommand.stop() : _command = STOP;
  TestServerCommand.chunkedEncoding() : _command = CHUNKED_ENCODING;

  bool get isStart() => _command == START;
  bool get isStop() => _command == STOP;
  bool get isChunkedEncoding() => _command == CHUNKED_ENCODING;

  int _command;
}


class TestServerStatus {
  static const STARTED = 0;
  static const STOPPED = 1;
  static const ERROR = 2;

  TestServerStatus.started(this._port) : _state = STARTED;
  TestServerStatus.stopped() : _state = STOPPED;
  TestServerStatus.error() : _state = ERROR;

  bool get isStarted() => _state == STARTED;
  bool get isStopped() => _state == STOPPED;
  bool get isError() => _state == ERROR;

  int get port() => _port;

  int _state;
  int _port;
}


void startTestServer() {
  var server = new TestServer();
  server.init();
  port.receive(server.dispatch);
}


class TestServer {
  // Echo the request content back to the response.
  void _echoHandler(HttpRequest request, HttpResponse response) {
    Expect.equals("POST", request.method);
    response.contentLength = request.contentLength;
    request.inputStream.pipe(response.outputStream);
  }

  // Echo the request content back to the response.
  void _zeroToTenHandler(HttpRequest request, HttpResponse response) {
    Expect.equals("GET", request.method);
    request.inputStream.onData = () {};
    request.inputStream.onClosed = () {
      response.outputStream.writeString("01234567890");
      response.outputStream.close();
    };
  }

  // Return a 404.
  void _notFoundHandler(HttpRequest request, HttpResponse response) {
    response.statusCode = HttpStatus.NOT_FOUND;
    response.headers.set("Content-Type", "text/html; charset=UTF-8");
    response.outputStream.writeString("Page not found");
    response.outputStream.close();
  }

  // Return a 301 with a custom reason phrase.
  void _reasonForMovingHandler(HttpRequest request, HttpResponse response) {
    response.statusCode = HttpStatus.MOVED_PERMANENTLY;
    response.reasonPhrase = "Don't come looking here any more";
    response.outputStream.close();
  }

  // Check the "Host" header.
  void _hostHandler(HttpRequest request, HttpResponse response) {
    Expect.equals(1, request.headers["Host"].length);
    Expect.equals("www.dartlang.org:1234", request.headers["Host"][0]);
    Expect.equals("www.dartlang.org", request.headers.host);
    Expect.equals(1234, request.headers.port);
    response.statusCode = HttpStatus.OK;
    response.outputStream.close();
  }

  void init() {
    // Setup request handlers.
    _requestHandlers = new Map();
    _requestHandlers["/echo"] = (HttpRequest request, HttpResponse response) {
      _echoHandler(request, response);
    };
    _requestHandlers["/0123456789"] =
        (HttpRequest request, HttpResponse response) {
          _zeroToTenHandler(request, response);
        };
    _requestHandlers["/reasonformoving"] =
        (HttpRequest request, HttpResponse response) {
          _reasonForMovingHandler(request, response);
        };
    _requestHandlers["/host"] =
        (HttpRequest request, HttpResponse response) {
          _hostHandler(request, response);
        };
  }

  void dispatch(var message, SendPort replyTo) {
    if (message.isStart) {
      _server = new HttpServer();
      try {
        _server.listen("127.0.0.1", 0);
        _server.defaultRequestHandler = (HttpRequest req, HttpResponse rsp) {
          _requestReceivedHandler(req, rsp);
        };
        replyTo.send(new TestServerStatus.started(_server.port), null);
      } catch (var e) {
        replyTo.send(new TestServerStatus.error(), null);
      }
    } else if (message.isStop) {
      _server.close();
      port.close();
      replyTo.send(new TestServerStatus.stopped(), null);
    } else if (message.isChunkedEncoding) {
      _chunkedEncoding = true;
    }
  }

  void _requestReceivedHandler(HttpRequest request, HttpResponse response) {
    var requestHandler =_requestHandlers[request.path];
    if (requestHandler != null) {
      requestHandler(request, response);
    } else {
      _notFoundHandler(request, response);
    }
  }

  HttpServer _server;  // HTTP server instance.
  Map _requestHandlers;
  bool _chunkedEncoding = false;
}

void testStartStop() {
  TestServerMain testServerMain = new TestServerMain();
  testServerMain.setServerStartedHandler((int port) {
    testServerMain.shutdown();
  });
  testServerMain.start();
}

void testGET() {
  TestServerMain testServerMain = new TestServerMain();
  testServerMain.setServerStartedHandler((int port) {
    HttpClient httpClient = new HttpClient();
    HttpClientConnection conn =
        httpClient.get("127.0.0.1", port, "/0123456789");
    conn.onResponse = (HttpClientResponse response) {
      Expect.equals(HttpStatus.OK, response.statusCode);
      StringInputStream stream = new StringInputStream(response.inputStream);
      StringBuffer body = new StringBuffer();
      stream.onData = () => body.add(stream.read());
      stream.onClosed = () {
        Expect.equals("01234567890", body.toString());
        httpClient.shutdown();
        testServerMain.shutdown();
      };
    };
  });
  testServerMain.start();
}

void testPOST(bool chunkedEncoding) {
  String data = "ABCDEFGHIJKLMONPQRSTUVWXYZ";
  final int kMessageCount = 10;

  TestServerMain testServerMain = new TestServerMain();

  void runTest(int port) {
    int count = 0;
    HttpClient httpClient = new HttpClient();
    void sendRequest() {
      HttpClientConnection conn =
          httpClient.post("127.0.0.1", port, "/echo");
      conn.onRequest = (HttpClientRequest request) {
        if (chunkedEncoding) {
          request.outputStream.writeString(data.substring(0, 10));
          request.outputStream.writeString(data.substring(10, data.length));
        } else {
          request.contentLength = data.length;
          request.outputStream.write(data.charCodes());
        }
        request.outputStream.close();
      };
      conn.onResponse = (HttpClientResponse response) {
        Expect.equals(HttpStatus.OK, response.statusCode);
        StringInputStream stream = new StringInputStream(response.inputStream);
        StringBuffer body = new StringBuffer();
        stream.onData = () => body.add(stream.read());
        stream.onClosed = () {
          Expect.equals(data, body.toString());
          count++;
          if (count < kMessageCount) {
            sendRequest();
          } else {
            httpClient.shutdown();
            testServerMain.shutdown();
          }
        };
      };
    }

    sendRequest();
  }

  testServerMain.setServerStartedHandler(runTest);
  if (chunkedEncoding) {
    testServerMain.chunkedEncoding();
  }
  testServerMain.start();
}

void test404() {
  TestServerMain testServerMain = new TestServerMain();
  testServerMain.setServerStartedHandler((int port) {
    HttpClient httpClient = new HttpClient();
    HttpClientConnection conn =
        httpClient.get("127.0.0.1", port, "/thisisnotfound");
    conn.onResponse = (HttpClientResponse response) {
      Expect.equals(HttpStatus.NOT_FOUND, response.statusCode);
      httpClient.shutdown();
      testServerMain.shutdown();
    };
  });
  testServerMain.start();
}

void testReasonPhrase() {
  TestServerMain testServerMain = new TestServerMain();
  testServerMain.setServerStartedHandler((int port) {
    HttpClient httpClient = new HttpClient();
    HttpClientConnection conn =
        httpClient.get("127.0.0.1", port, "/reasonformoving");
    conn.followRedirects = false;
    conn.onResponse = (HttpClientResponse response) {
      Expect.equals(HttpStatus.MOVED_PERMANENTLY, response.statusCode);
      Expect.equals("Don't come looking here any more", response.reasonPhrase);
      httpClient.shutdown();
      testServerMain.shutdown();
    };
  });
  testServerMain.start();
}

void main() {
  testStartStop();
  testGET();
  testPOST(true);
  testPOST(false);
  test404();
  testReasonPhrase();
}
