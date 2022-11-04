import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdentifier {
  static Future<String> getUUID() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString("DeviceID");
    if (deviceId == null) {
      const charList = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
      Random rnd = Random();
      deviceId = String.fromCharCodes(Iterable.generate(12, (_) => charList.codeUnitAt(rnd.nextInt(charList.length))));
      prefs.setString("DeviceID", deviceId);
    }
    return deviceId;
  }
}
