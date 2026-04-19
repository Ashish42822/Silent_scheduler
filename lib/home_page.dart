import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'storage_service.dart';
import 'notification_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime? selectedDateTime;
  String selectedMode = "Silent";
  String meetingTitle = "";
  bool isEnglish = true;

  final StorageService storageService = StorageService();
  final NotificationService notificationService = NotificationService();

  late Timer timer;
  DateTime currentUtcTime = DateTime.now().toUtc();
  bool hasShownMeetingAlert = false;

  @override
  void initState() {
    super.initState();
    notificationService.init();
    loadSavedData();

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        currentUtcTime = DateTime.now().toUtc();
      });
      checkMeetingAlert();
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  Future<void> loadSavedData() async {
    final data = await storageService.getData();
    if (data != null) {
      setState(() {
        selectedDateTime = data['dateTime'];
        selectedMode = data['mode'];
        meetingTitle = data['title'] ?? "";
      });
    }
  }

  Future<void> pickMeetingTime() async {
    final controller = TextEditingController(text: meetingTitle);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            isEnglish ? "Enter Meeting Title" : "मिटिङ शीर्षक लेख्नुहोस्",
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: isEnglish
                  ? "e.g. Class / Work / Exam"
                  : "जस्तै: कक्षा / काम / परीक्षा",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isEnglish ? "Cancel" : "रद्द गर्नुहोस्"),
            ),
            TextButton(
              onPressed: () {
                meetingTitle = controller.text.trim();
                Navigator.pop(context);
              },
              child: Text(isEnglish ? "Next" : "अर्को"),
            ),
          ],
        );
      },
    );

    if (meetingTitle.isEmpty) return;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedDateTime != null
          ? TimeOfDay.fromDateTime(selectedDateTime!)
          : TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    final finalDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    await storageService.saveData(finalDateTime, selectedMode, meetingTitle);
    await notificationService.showNotification();

    setState(() {
      selectedDateTime = finalDateTime;
      hasShownMeetingAlert = false;
    });
  }

  Future<void> deleteMeeting() async {
    await storageService.deleteData();

    setState(() {
      selectedDateTime = null;
      meetingTitle = "";
      hasShownMeetingAlert = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEnglish
              ? "Meeting deleted successfully"
              : "मिटिङ सफलतापूर्वक हटाइयो",
        ),
      ),
    );
  }

  Future<void> checkMeetingAlert() async {
    if (selectedDateTime == null || hasShownMeetingAlert) return;

    final now = DateTime.now();

    if (now.year == selectedDateTime!.year &&
        now.month == selectedDateTime!.month &&
        now.day == selectedDateTime!.day &&
        now.hour == selectedDateTime!.hour &&
        now.minute == selectedDateTime!.minute) {
      hasShownMeetingAlert = true;

      await notificationService.applyPhoneMode(selectedMode);
      showMeetingDialog();
    }
  }

  void showMeetingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEnglish ? "Meeting Alert" : "मिटिङ सूचना"),
          content: Text(
            isEnglish
                ? "$meetingTitle has started. Phone switched to $selectedMode mode."
                : "$meetingTitle सुरु भयो। फोन $selectedMode मोडमा परिवर्तन गरिएको छ।",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isEnglish ? "OK" : "ठिक छ"),
            )
          ],
        );
      },
    );
  }

  String formatUtcTime() {
    return DateFormat('HH:mm:ss').format(currentUtcTime);
  }

  String formatCityTime(int offset) {
    final time = currentUtcTime.add(Duration(hours: offset));
    return DateFormat('HH:mm:ss').format(time);
  }

  String formatMeetingDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd hh:mm a').format(dateTime);
  }

  Widget buildCity(String flag, String name, int offset) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 22)),
      title: Text(name),
      trailing: Text(formatCityTime(offset)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sydney = isEnglish ? "Sydney" : "सिड्नी";
    final kathmandu = isEnglish ? "Kathmandu" : "काठमाडौं";
    final london = isEnglish ? "London" : "लन्डन";
    final newYork = isEnglish ? "New York" : "न्युयोर्क";
    final tokyo = isEnglish ? "Tokyo" : "टोकियो";

    return Scaffold(
      backgroundColor: const Color(0xFF0B0A18),
      appBar: AppBar(
        title: const Text("Silent Scheduler"),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              setState(() {
                isEnglish = !isEnglish;
              });
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: pickMeetingTime,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    isEnglish ? "Global Time (UTC)" : "विश्व समय",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    formatUtcTime(),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              selectedDateTime == null
                  ? (isEnglish
                      ? "No meeting set"
                      : "मिटिङ सेट गरिएको छैन")
                  : (isEnglish
                      ? "$meetingTitle at ${formatMeetingDateTime(selectedDateTime!)}"
                      : "$meetingTitle - ${formatMeetingDateTime(selectedDateTime!)}"),
            ),
            const SizedBox(height: 10),
            if (selectedDateTime != null)
              ElevatedButton.icon(
                onPressed: deleteMeeting,
                icon: const Icon(Icons.delete),
                label:
                    Text(isEnglish ? "Delete Meeting" : "मिटिङ हटाउनुहोस्"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: pickMeetingTime,
              child: Text(
                isEnglish
                    ? "Set Meeting Date & Time"
                    : "मिटिङ मिति र समय सेट गर्नुहोस्",
              ),
            ),
            const SizedBox(height: 20),
            Text(isEnglish ? "Mode" : "मोड"),
            RadioListTile(
              value: "Silent",
              groupValue: selectedMode,
              onChanged: (value) async {
                setState(() => selectedMode = value!);
                if (selectedDateTime != null && meetingTitle.isNotEmpty) {
                  await storageService.saveData(
                    selectedDateTime!,
                    selectedMode,
                    meetingTitle,
                  );
                }
              },
              title: Text(isEnglish ? "Silent" : "साइलेंट"),
            ),
            RadioListTile(
              value: "Vibrate",
              groupValue: selectedMode,
              onChanged: (value) async {
                setState(() => selectedMode = value!);
                if (selectedDateTime != null && meetingTitle.isNotEmpty) {
                  await storageService.saveData(
                    selectedDateTime!,
                    selectedMode,
                    meetingTitle,
                  );
                }
              },
              title: Text(isEnglish ? "Vibrate" : "भाइब्रेट"),
            ),
            const SizedBox(height: 20),
            Text(
              isEnglish ? "Major World Cities" : "मुख्य शहरहरू",
              style: const TextStyle(fontSize: 18),
            ),
            buildCity("🇦🇺", sydney, 10),
            buildCity("🇳🇵", kathmandu, 5),
            buildCity("🇬🇧", london, 0),
            buildCity("🇺🇸", newYork, -4),
            buildCity("🇯🇵", tokyo, 9),
          ],
        ),
      ),
    );
  }
}