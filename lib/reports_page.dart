import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
 final dbRef = FirebaseDatabase.instance.ref().child('TestReports');
  String? className;
  String? studentID; // use studentID instead of name
  String? selectedMonth;
  List<String> months = [];
  List<Map<dynamic, dynamic>> reports = [];

  @override
  void initState() {
    super.initState();
    loadUserInfo();
  }

  Future<void> loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    className = prefs.getString('class');
    studentID = prefs.getString('studentID'); // ✅

    if (className != null) {
      fetchMonths();
    }
  }

  void fetchMonths() {
    dbRef.child(className!).onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          months = data.keys.map((e) => e.toString()).toList();
          if (months.isNotEmpty) selectedMonth = months.first;
          fetchReports();
        });
      }
    });
  }

  void fetchReports() {
    if (className == null || selectedMonth == null) return;

    dbRef.child(className!).child(selectedMonth!).onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      List<Map<dynamic, dynamic>> temp = [];

      if (data != null) {
        data.forEach((testKey, testValue) {
          Map<dynamic, dynamic> testMap = testValue as Map<dynamic, dynamic>;
          Map<dynamic, dynamic>? studentData;

          final students = testMap['Students'] as Map<dynamic, dynamic>?;
          if (students != null && studentID != null) {
            studentData = students[studentID];
          }

          if (studentData != null) {
            temp.add({
              'TestName': testMap['TestName'] ?? '',
              'ReportType': testMap['ReportType'] ?? '',
              'Subject': testMap['Subject'] ?? '',
              'ObtainedMarks': studentData['ObtainedMarks'] ?? 0,
              'TotalMarks': testMap['TotalMarks'] ?? 0,
            });
          }
        });
      }

      setState(() {
        reports = temp;
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          // Month selector dropdown
          if (months.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButton<String>(
                isExpanded: true,
                value: selectedMonth,
                items: months
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedMonth = value;
                    fetchReports();
                  });
                },
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: reports.isEmpty
                ? const Center(child: Text("No reports yet!"))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final r = reports[index];
                      return Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        color: Colors.blueAccent.withAlpha((0.9 * 255).toInt()),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(r['TestName'] ?? "",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              "${r['ReportType'] ?? ''} | ${r['Subject'] ?? ''}\nMarks: ${r['ObtainedMarks']}/${r['TotalMarks']}",
                              style: const TextStyle(color: Colors.white70)),
                          leading:
                              const Icon(Icons.report, color: Colors.white),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
