// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("compiler_helper.dart");

final String CODE = """
var x = 0;
class A {
  A() { x++; }
}

class B extends A {
  B();
}

main() {
  new B();
  new A();
}
""";

main() {
  String generated = compileAll(CODE);
  RegExp regexp = new RegExp(@'A\$0: function');
  Iterator<Match> matches = regexp.allMatches(generated).iterator();
  checkNumberOfMatches(matches, 1);
}
