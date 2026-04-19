import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sound_mode/permission_handler.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';

class NotificationService {
  Future<void> init() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final isGranted = await PermissionHandler.permissionsGranted;
    if (isGranted != true) {
      await PermissionHandler.openDoNotDisturbSetting();
    }
  }

  Future<void> showNotification() async {
    debugPrint("Meeting reminder triggered");
  }

  Future<void> applyPhoneMode(String mode) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final isGranted = await PermissionHandler.permissionsGranted;
    if (isGranted != true) {
      await PermissionHandler.openDoNotDisturbSetting();
      return;
    }

    try {
      if (mode == "Silent") {
        await SoundMode.setSoundMode(RingerModeStatus.silent);
      } else if (mode == "Vibrate") {
        await SoundMode.setSoundMode(RingerModeStatus.vibrate);
      } else {
        await SoundMode.setSoundMode(RingerModeStatus.normal);
      }
    } on PlatformException {
      debugPrint("Error changing sound mode");
    }
  }
}