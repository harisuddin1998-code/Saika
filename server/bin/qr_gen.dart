// Generates scannable QR codes (as SVG) for the rider/driver LAN URLs so
// they can be opened on a phone camera without Expo Go — this is a Flutter
// project, so Expo Go (React Native only) can't run it, but scanning still
// gets you straight into the app in the phone's browser.
//
// Run: dart run bin/qr_gen.dart <url> <out.svg>

import 'dart:io';
import 'package:qr/qr.dart';

String qrSvg(String data, {int moduleSize = 8, int quietZone = 4}) {
  final qrCode = QrCode(payload: QrPayload.fromString(data), errorCorrectLevel: QrErrorCorrectLevel.medium);
  final qrImage = QrImage(qrCode);
  final count = qrImage.moduleCount;
  final size = (count + quietZone * 2) * moduleSize;

  final buffer = StringBuffer()
    ..writeln('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $size $size" width="$size" height="$size" shape-rendering="crispEdges">')
    ..writeln('<rect width="$size" height="$size" fill="#ffffff"/>');

  for (var r = 0; r < count; r++) {
    for (var c = 0; c < count; c++) {
      if (qrImage.isDark(r, c)) {
        final x = (c + quietZone) * moduleSize;
        final y = (r + quietZone) * moduleSize;
        buffer.writeln('<rect x="$x" y="$y" width="$moduleSize" height="$moduleSize" fill="#000000"/>');
      }
    }
  }
  buffer.writeln('</svg>');
  return buffer.toString();
}

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln('Usage: dart run bin/qr_gen.dart <url> <out.svg>');
    exit(1);
  }
  final svg = qrSvg(args[0]);
  File(args[1]).writeAsStringSync(svg);
  stdout.writeln('Wrote ${args[1]} for ${args[0]}');
}
