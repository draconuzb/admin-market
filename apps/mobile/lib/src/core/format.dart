import 'package:easy_localization/easy_localization.dart';

/// Formats a UZS amount with thin-space thousands separators, e.g. "1 250 000 so'm".
String formatPrice(num value) {
  final whole = value.round();
  final digits = whole.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' '); // thin space
    buf.write(digits[i]);
  }
  final sign = whole < 0 ? '-' : '';
  return "$sign$buf ${'common.currency'.tr()}";
}

num parseNum(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString()) ?? 0;
}
