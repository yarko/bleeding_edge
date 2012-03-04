// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): the native class should be the real JS Date.
// TODO(jimhug): Making the date value non-lazy might be a good path there.
class DateImplementation implements Date {
  final int value;
  final TimeZoneImplementation timeZone;

  factory DateImplementation(int years,
                             int month,
                             int day,
                             int hours,
                             int minutes,
                             int seconds,
                             int milliseconds) {
    return new DateImplementation.withTimeZone(
        years, month, day,
        hours, minutes, seconds, milliseconds,
        new TimeZoneImplementation.local());
  }

  DateImplementation.withTimeZone(int years,
                                  int month,
                                  int day,
                                  int hours,
                                  int minutes,
                                  int seconds,
                                  int milliseconds,
                                  TimeZoneImplementation timeZone)
      : this.timeZone = timeZone,
        value = _valueFromDecomposed(years, month, day,
                                     hours, minutes, seconds, milliseconds,
                                     timeZone.isUtc) {
    if (value === null) throw new IllegalArgumentException();
    _asJs();
  }

  DateImplementation.now()
      : timeZone = new TimeZone.local(),
        value = _now() {
    _asJs();
  }

  factory DateImplementation.fromString(String formattedString) {
    // Read in (a subset of) ISO 8601.
    // Examples:
    //    - "2012-02-27 13:27:00"
    //    - "2012-02-27 13:27:00.423z"
    //    - "20120227 13:27:00"
    //    - "20120227T132700"
    //    - "20120227"
    //    - "2012-02-27T14Z"
    //    - "-123450101 00:00:00 Z"  // In the year -12345.
    final RegExp re = const RegExp(
        @'^([+-]?\d?\d\d\d\d)-?(\d\d)-?(\d\d)' +  // The day part.
        @'(?:[ T](\d\d)(?::?(\d\d)(?::?(\d\d)(?:.(\d{1,5}))?)?)? ?([zZ])?)?$');
    Match match = re.firstMatch(formattedString);
    if (match !== null) {
      int parseIntOrZero(String matched) {
        // TODO(floitsch): we should not need to test against the empty string.
        if (matched === null || matched == "") return 0;
        return Math.parseInt(matched);
      }

      int years = Math.parseInt(match[1]);
      int month = Math.parseInt(match[2]);
      int day = Math.parseInt(match[3]);
      int hours = parseIntOrZero(match[4]);
      int minutes = parseIntOrZero(match[5]);
      int seconds = parseIntOrZero(match[6]);
      bool addOneMillisecond = false;
      int milliseconds = parseIntOrZero(match[7]);
      if (milliseconds != 0) {
        if (match[7].length == 1) {
          milliseconds *= 100;
        } else if (match[7].length == 2) {
          milliseconds *= 10;
        } else if (match[7].length == 3) {
          // Do nothing.
        } else if (match[7].length == 4) {
          addOneMillisecond = ((milliseconds % 10) >= 5);
          milliseconds ~/= 10;
        } else {
          assert(match[7].length == 5);
          addOneMillisecond = ((milliseconds %100) >= 50);
          milliseconds ~/= 100;
        }
        if (addOneMillisecond && milliseconds < 999) {
          addOneMillisecond = false;
          milliseconds++;
        }
      }
      // TODO(floitsch): we should not need to test against the empty string.
      bool isUtc = (match[8] !== null) && (match[8] != "");
      TimeZone timezone = isUtc ? const TimeZone.utc() : new TimeZone.local();
      int epochValue = _valueFromDecomposed(
          years, month, day, hours, minutes, seconds, milliseconds, isUtc);
      if (epochValue === null) {
        throw new IllegalArgumentException(formattedString);
      }
      if (addOneMillisecond) epochValue++;
      return new DateImplementation.fromEpoch(epochValue, timezone);
    } else {
      throw new IllegalArgumentException(formattedString);
    }
  }

  const DateImplementation.fromEpoch(this.value, this.timeZone);

  bool operator ==(other) {
    if (!(other is DateImplementation)) return false;
    return (value == other.value) && (timeZone == other.timeZone);
  }

  int compareTo(Date other) {
    return value.compareTo(other.value);
  }

  Date changeTimeZone(TimeZone targetTimeZone) {
    if (targetTimeZone == null) {
      targetTimeZone = new TimeZoneImplementation.local();
    }
    return new Date.fromEpoch(value, targetTimeZone);
  }

  int get year() native
  '''return this.isUtc() ? this._asJs().getUTCFullYear() :
    this._asJs().getFullYear();''' {
    isUtc();
    _asJs();
  }

  int get month() native
  '''return this.isUtc() ? this._asJs().getUTCMonth() + 1 :
      this._asJs().getMonth() + 1;'''  {
    isUtc();
    _asJs();
  }

  int get day() native
  '''return this.isUtc() ? this._asJs().getUTCDate() :
      this._asJs().getDate();''' {
    isUtc();
    _asJs();
  }

  int get hours() native
  '''return this.isUtc() ? this._asJs().getUTCHours() :
      this._asJs().getHours();''' {
    isUtc();
    _asJs();
  }

  int get minutes() native
  '''return this.isUtc() ? this._asJs().getUTCMinutes() :
      this._asJs().getMinutes();''' {
    isUtc();
    _asJs();
  }

  int get seconds() native
  '''return this.isUtc() ? this._asJs().getUTCSeconds() :
      this._asJs().getSeconds();''' {
    isUtc();
    _asJs();
  }

  int get milliseconds() native
  '''return this.isUtc() ? this._asJs().getUTCMilliseconds() :
    this._asJs().getMilliseconds();''' {
    isUtc();
    _asJs();
  }

  // Adjust by one because JS weeks start on Sunday.
  int get weekday() native '''
    var day = this.isUtc() ? this._asJs().getUTCDay() : this._asJs().getDay();
    return (day + 6) % 7;''';

  // TODO(jimhug): Could this please be getters?
  bool isLocalTime() {
    return !timeZone.isUtc;
  }

  bool isUtc() {
    return timeZone.isUtc;
  }

  String toString() {
    String fourDigits(int n) {
      int absN = n.abs();
      String sign = n < 0 ? "-" : "";
      if (absN >= 1000) return "$n";
      if (absN >= 100) return "${sign}0$absN";
      if (absN >= 10) return "${sign}00$absN";
      if (absN >= 1) return "${sign}000$absN";
    }
    String threeDigits(int n) {
      if (n >= 100) return "${n}";
      if (n > 10) return "0${n}";
      return "00${n}";
    }
    String twoDigits(int n) {
      if (n >= 10) return "${n}";
      return "0${n}";
    }

    String y = fourDigits(year);
    String m = twoDigits(month);
    String d = twoDigits(day);
    String h = twoDigits(hours);
    String min = twoDigits(minutes);
    String sec = twoDigits(seconds);
    String ms = threeDigits(milliseconds);
    if (timeZone.isUtc) {
      return "$y-$m-$d $h:$min:$sec.${ms}Z";
    } else {
      return "$y-$m-$d $h:$min:$sec.$ms";
    }
  }

  // TODO(jimhug): Why not use operators here?
    // Adds the [duration] to this Date instance.
  Date add(Duration duration) {
    return new DateImplementation.fromEpoch(value + duration.inMilliseconds,
                                            timeZone);
  }

  // Subtracts the [duration] from this Date instance.
  Date subtract(Duration duration) {
    return new DateImplementation.fromEpoch(value - duration.inMilliseconds,
                                            timeZone);
  }

  // Returns a [Duration] with the difference of [this] and [other].
  Duration difference(Date other) {
    return new Duration(milliseconds: value - other.value);
  }

  // TODO(floitsch): Use real exception object.
  static int _valueFromDecomposed(int years, int month, int day,
                                  int hours, int minutes, int seconds,
                                  int milliseconds, bool isUtc) native
  '''var jsMonth = month - 1;
  var date = new Date(0);
  if (isUtc) {
    date.setUTCFullYear(years, jsMonth, day);
    date.setUTCHours(hours, minutes, seconds, milliseconds);
  } else {
    date.setFullYear(years, jsMonth, day);
    date.setHours(hours, minutes, seconds, milliseconds);
  }
  var value = date.valueOf();
  if (isNaN(value)) return (void 0);
  return value;''';

  static int _valueFromString(String str) native
  '''var value = Date.parse(str);
  if (isNaN(value)) throw Error("Invalid Date");
  return value;''';

  static int _now() native "return new Date().valueOf();";

  // Lazily keep a JS Date stored in the dart object.
  var _asJs() native '''
  if (!this.date) {
    this.date = new Date(this.value);
  }
  return this.date;''';
}

// Trivial implementation of TimeZone
class TimeZoneImplementation implements TimeZone {
  const TimeZoneImplementation.utc() : this.isUtc = true;
  const TimeZoneImplementation.local() : this.isUtc = false;

  bool operator ==(other) {
    if (!(other is TimeZoneImplementation)) return false;
    return isUtc == other.isUtc;
  }

  String toString() {
    if (isUtc) return "TimeZone (UTC)";
    return "TimeZone (Local)";
  }

  final bool isUtc;
}
