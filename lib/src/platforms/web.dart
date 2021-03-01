// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:js';

// import 'package:resource/resource.dart';
import 'dart:html';

import 'package:time_machine/src/time_machine_internal.dart';

import 'platform_io.dart';

class _WebMachineIO implements PlatformIO {
  final dynamic _rootBundle;

  _WebMachineIO(this._rootBundle);

  @override
  Future<ByteData> getBinary(String path, String filename) async {
    if (filename == null) return ByteData(0);

    ByteData byteData =
        await _rootBundle.load('packages/time_machine/data/$path/$filename');
    return byteData;
  }

  @override
  // may return Map<String, dynamic> or List
  Future getJson(String path, String filename) async {
    String text = await _rootBundle
        .loadString('packages/time_machine/data/$path/$filename');
    return json.decode(text);
  }
}

Future initialize(Map args) {
  if (args == null || args['rootBundle'] == null)
    throw Exception(
        "Pass in the rootBundle from 'package:flutter/services.dart';");
  // Map IO functions
  PlatformIO.local = _WebMachineIO(args['rootBundle']);
  return TimeMachine.initialize();
}

class TimeMachine {
  // I'm looking to basically use @internal for protection??? <-- what did I mean by this?
  static Future initialize() async {
    Platform.startWeb();

    // Default provider
    var tzdb = await DateTimeZoneProviders.tzdb;
    IDateTimeZoneProviders.defaultProvider = tzdb;

    _readIntlObject();

    // Default TimeZone
    var local = await tzdb[_timeZoneId];
    // todo: cache local more directly? (this is indirect caching)
    TzdbIndex.localId = local.id;

    // Default Culture
    var cultureId = _locale;
    var culture = await Cultures.getCulture(cultureId);
    ICultures.currentCulture = culture;
    // todo: remove Culture.currentCulture

    // todo: set default calendar from [_calendar]
  }

  static String _timeZoneId;
  static String _locale;
  // ignore: unused_field
  static String _numberingSystem;
  // ignore: unused_field
  static String _calendar;
  // ignore: unused_field
  static String _yearFormat;
  // ignore: unused_field
  static String _monthFormat;
  // ignore: unused_field
  static String _dayFormat;

  // {locale: en-US, numberingSystem: latn, calendar: gregory, timeZone: America/New_York, year: numeric, month: numeric, day: numeric}
  static _readIntlObject() {
    try {
      JsObject options = context['Intl']
          .callMethod('DateTimeFormat')
          .callMethod('resolvedOptions');

      _locale = options['locale'];
      _timeZoneId = options['timeZone'];
      _numberingSystem = options['numberingSystem'];
      _calendar = options['calendar'];
      _yearFormat = options['year'];
      _monthFormat = options['month'];
      _dayFormat = options['day'];
    } catch (e, s) {
      print('Failed to get platform local information.\n$e\n$s');
    }
  }
}
