import 'dart:io';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

const _channel = MethodChannel('cc.picnote.app/gmail');

/// Opens the Gmail app searching for [query], or on its inbox when the app
/// takes no search link. Falls back to Gmail on the web, already searching,
/// when the app is not installed.
Future<void> openGmail(String query) async {
  if (await _openApp(query)) return;
  await launchUrl(
    Uri.parse('https://mail.google.com/mail/u/0/#search/${Uri.encodeComponent(query)}'),
    mode: LaunchMode.externalApplication,
  );
}

Future<bool> _openApp(String query) async {
  try {
    if (Platform.isAndroid) {
      return await _channel.invokeMethod<bool>('open', {'query': query}) ?? false;
    }
    if (Platform.isIOS) {
      // Gmail documents no search link; an unknown path still opens the app.
      final search = Uri.parse('googlegmail:///search?q=${Uri.encodeQueryComponent(query)}');
      return await launchUrl(search, mode: LaunchMode.externalApplication) ||
          await launchUrl(Uri.parse('googlegmail://'), mode: LaunchMode.externalApplication);
    }
  } on PlatformException {
    // Fall through to the web.
  }
  return false;
}
