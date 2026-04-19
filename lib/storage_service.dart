import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  Future<void> saveData(DateTime dateTime, String mode, String title) async {
    final prefs = await SharedPreferences.getInstance();

    final data = {
      'dateTime': dateTime.toIso8601String(),
      'mode': mode,
      'title': title,
    };

    await prefs.setString('meeting_data', jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('meeting_data');

    if (jsonString == null) {
      return null;
    }

    final data = jsonDecode(jsonString);

    return {
      'dateTime': DateTime.parse(data['dateTime']),
      'mode': data['mode'],
      'title': data['title'] ?? '',
    };
  }

  Future<void> deleteData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('meeting_data');
  }
}