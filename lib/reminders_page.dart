import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  String className = "";
  String studentName = "";
  List<Map<dynamic, dynamic>> reminders = [];

  @override
  void initState() {
    super.initState();
    _loadStudentInfo();
  }

  Future<void> _loadStudentInfo() async {
    final prefs = await SharedPreferences.getInstance();
    className = prefs.getString('class') ?? "";
    studentName = prefs.getString('studentName') ?? "";
    fetchReminders();
  }

 void fetchReminders() {
  if (className.isEmpty || studentName.isEmpty) return;

  final dbRef = FirebaseDatabase.instance
      .ref()
      .child('Reminder')
      .child('FeesReminder')
      .child(className);

  dbRef.onValue.listen((event) {
    final data = event.snapshot.value as Map<dynamic, dynamic>?;
    List<Map<dynamic, dynamic>> temp = [];

    if (data != null) {
      final now = DateTime.now();
      final currentYear = now.year;
      final currentMonth = now.month;

      // Map of month names to numbers
      final Map<String, int> monthMap = {
        'January': 1,
        'February': 2,
        'March': 3,
        'April': 4,
        'May': 5,
        'June': 6,
        'July': 7,
        'August': 8,
        'September': 9,
        'October': 10,
        'November': 11,
        'December': 12,
      };

      // Loop through year -> month -> student
      data.forEach((yearKey, yearData) {
        if (yearData is Map) {
          int yearInt = int.tryParse(yearKey.toString()) ?? 0;

          // Only allow reminders from current year
          if (yearInt != currentYear) return;

          yearData.forEach((monthKey, monthData) {
            if (monthData is Map) {
              int monthInt = monthMap[monthKey] ?? 13;

              // Skip future months
              if (monthInt > currentMonth) return;

              monthData.forEach((studentKey, studentData) {
                if (studentData is Map &&
                    studentData['Name'] == studentName) {
                  temp.add({
                    'Title': 'Fee Reminder - $monthKey, $yearKey',
                    'Description': studentData['Message'] ?? '',
                    'StudentName': studentData['Name'] ?? '',
                    'Contact': studentData['Contact'] ?? '',
                  });
                }
              });
            }
          });
        }
      });
    }

    setState(() {
      reminders = temp;
    });
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reminders"),
        backgroundColor: Colors.purpleAccent,
      ),
      body: reminders.isEmpty
          ? const Center(child: Text("No reminders!"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                final r = reminders[index];
                return Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  color: Colors.purpleAccent.withAlpha((0.9 * 255).toInt()),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(
                      r['Title'] ?? "",
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      r['Description'] ?? "",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    leading: const Icon(Icons.alarm, color: Colors.white),
                  ),
                );
              },
            ),
    );
  }
}
