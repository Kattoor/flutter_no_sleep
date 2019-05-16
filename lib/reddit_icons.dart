/// flutter:
///   fonts:
///    - family:  Reddit
///      fonts:
///       - asset: fonts/Reddit.ttf

import 'package:flutter/widgets.dart';

class Reddit {
  Reddit._();

  static const _kFontFam = 'Reddit';

  static const IconData controversial = const IconData(0xe800, fontFamily: _kFontFam);
  static const IconData hot = const IconData(0xe801, fontFamily: _kFontFam);
  static const IconData new_icon = const IconData(0xe802, fontFamily: _kFontFam);
  static const IconData rising = const IconData(0xe803, fontFamily: _kFontFam);
  static const IconData top = const IconData(0xe804, fontFamily: _kFontFam);
}
