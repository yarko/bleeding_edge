/**
 * An API for storing data in the browser that can be queried with SQL.
 *
 * **Caution:** this specification is no longer actively maintained by the Web
 * Applications Working Group and may be removed at any time.
 * See [the W3C Web SQL Database specification](http://www.w3.org/TR/webdatabase/)
 * for more information.
 *
 * The [dart:indexed_db] APIs is a recommended alternatives.
 */
library dart.dom.web_sql;

import 'dart:async';
import 'dart:collection';
import 'dart:_collection-dev';
import 'dart:html';
import 'dart:html_common';
import 'dart:nativewrappers';
// DO NOT EDIT - unless you are editing documentation as per:
// https://code.google.com/p/dart/wiki/ContributingHTMLDocumentation
// Auto-generated dart:audio library.




// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void SqlStatementCallback(SqlTransaction transaction, SqlResultSet resultSet);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void SqlStatementErrorCallback(SqlTransaction transaction, SqlError error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void SqlTransactionCallback(SqlTransaction transaction);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void SqlTransactionErrorCallback(SqlError error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('Database')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental
class SqlDatabase extends NativeFieldWrapperClass1 {
  SqlDatabase.internal();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('Database.version')
  @DocsEditable
  String get version native "Database_version_Getter";

  /**
   * Atomically update the database version to [newVersion], asynchronously
   * running [callback] on the [SqlTransaction] representing this
   * [changeVersion] transaction.
   *
   * If [callback] runs successfully, then [successCallback] is called.
   * Otherwise, [errorCallback] is called.
   *
   * [oldVersion] should match the database's current [version] exactly.
   *
   * * [Database.changeVersion](http://www.w3.org/TR/webdatabase/#dom-database-changeversion) from W3C.
   */
  @DomName('Database.changeVersion')
  @DocsEditable
  void changeVersion(String oldVersion, String newVersion, [SqlTransactionCallback callback, SqlTransactionErrorCallback errorCallback, VoidCallback successCallback]) native "Database_changeVersion_Callback";

  @DomName('Database.readTransaction')
  @DocsEditable
  void readTransaction(SqlTransactionCallback callback, [SqlTransactionErrorCallback errorCallback, VoidCallback successCallback]) native "Database_readTransaction_Callback";

  @DomName('Database.transaction')
  @DocsEditable
  void transaction(SqlTransactionCallback callback, [SqlTransactionErrorCallback errorCallback, VoidCallback successCallback]) native "Database_transaction_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SQLError')
class SqlError extends NativeFieldWrapperClass1 {
  SqlError.internal();

  @DomName('SQLError.CONSTRAINT_ERR')
  @DocsEditable
  static const int CONSTRAINT_ERR = 6;

  @DomName('SQLError.DATABASE_ERR')
  @DocsEditable
  static const int DATABASE_ERR = 1;

  @DomName('SQLError.QUOTA_ERR')
  @DocsEditable
  static const int QUOTA_ERR = 4;

  @DomName('SQLError.SYNTAX_ERR')
  @DocsEditable
  static const int SYNTAX_ERR = 5;

  @DomName('SQLError.TIMEOUT_ERR')
  @DocsEditable
  static const int TIMEOUT_ERR = 7;

  @DomName('SQLError.TOO_LARGE_ERR')
  @DocsEditable
  static const int TOO_LARGE_ERR = 3;

  @DomName('SQLError.UNKNOWN_ERR')
  @DocsEditable
  static const int UNKNOWN_ERR = 0;

  @DomName('SQLError.VERSION_ERR')
  @DocsEditable
  static const int VERSION_ERR = 2;

  @DomName('SQLError.code')
  @DocsEditable
  int get code native "SQLError_code_Getter";

  @DomName('SQLError.message')
  @DocsEditable
  String get message native "SQLError_message_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SQLException')
class SqlException extends NativeFieldWrapperClass1 {
  SqlException.internal();

  @DomName('SQLException.CONSTRAINT_ERR')
  @DocsEditable
  static const int CONSTRAINT_ERR = 6;

  @DomName('SQLException.DATABASE_ERR')
  @DocsEditable
  static const int DATABASE_ERR = 1;

  @DomName('SQLException.QUOTA_ERR')
  @DocsEditable
  static const int QUOTA_ERR = 4;

  @DomName('SQLException.SYNTAX_ERR')
  @DocsEditable
  static const int SYNTAX_ERR = 5;

  @DomName('SQLException.TIMEOUT_ERR')
  @DocsEditable
  static const int TIMEOUT_ERR = 7;

  @DomName('SQLException.TOO_LARGE_ERR')
  @DocsEditable
  static const int TOO_LARGE_ERR = 3;

  @DomName('SQLException.UNKNOWN_ERR')
  @DocsEditable
  static const int UNKNOWN_ERR = 0;

  @DomName('SQLException.VERSION_ERR')
  @DocsEditable
  static const int VERSION_ERR = 2;

  @DomName('SQLException.code')
  @DocsEditable
  int get code native "SQLException_code_Getter";

  @DomName('SQLException.message')
  @DocsEditable
  String get message native "SQLException_message_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SQLResultSet')
class SqlResultSet extends NativeFieldWrapperClass1 {
  SqlResultSet.internal();

  @DomName('SQLResultSet.insertId')
  @DocsEditable
  int get insertId native "SQLResultSet_insertId_Getter";

  @DomName('SQLResultSet.rows')
  @DocsEditable
  SqlResultSetRowList get rows native "SQLResultSet_rows_Getter";

  @DomName('SQLResultSet.rowsAffected')
  @DocsEditable
  int get rowsAffected native "SQLResultSet_rowsAffected_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SQLResultSetRowList')
class SqlResultSetRowList extends NativeFieldWrapperClass1 with ListMixin<Map>, ImmutableListMixin<Map> implements List<Map> {
  SqlResultSetRowList.internal();

  @DomName('SQLResultSetRowList.length')
  @DocsEditable
  int get length native "SQLResultSetRowList_length_Getter";

  Map operator[](int index) {
    if (index < 0 || index >= length)
      throw new RangeError.range(index, 0, length);
    return _nativeIndexedGetter(index);
  }
  Map _nativeIndexedGetter(int index) native "SQLResultSetRowList_item_Callback";

  void operator[]=(int index, Map value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Map> mixins.
  // Map is the element type.


  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  Map get first {
    if (this.length > 0) {
      return this[0];
    }
    throw new StateError("No elements");
  }

  Map get last {
    int len = this.length;
    if (len > 0) {
      return this[len - 1];
    }
    throw new StateError("No elements");
  }

  Map get single {
    int len = this.length;
    if (len == 1) {
      return this[0];
    }
    if (len == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  Map elementAt(int index) => this[index];
  // -- end List<Map> mixins.

  @DomName('SQLResultSetRowList.item')
  @DocsEditable
  Map item(int index) native "SQLResultSetRowList_item_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SQLTransaction')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental
class SqlTransaction extends NativeFieldWrapperClass1 {
  SqlTransaction.internal();

  @DomName('SQLTransaction.executeSql')
  @DocsEditable
  void executeSql(String sqlStatement, List arguments, [SqlStatementCallback callback, SqlStatementErrorCallback errorCallback]) native "SQLTransaction_executeSql_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SQLTransactionSync')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental
abstract class _SQLTransactionSync extends NativeFieldWrapperClass1 {
  _SQLTransactionSync.internal();

}
