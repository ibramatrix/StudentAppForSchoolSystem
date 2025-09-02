import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  String? className;
  String? studentID;
  Map<String, bool> attendanceData = {}; // date: present/absent
  bool isLoading = true;

  String selectedMonth = DateFormat('MMMM yyyy').format(DateTime.now());
  List<String> monthsList = [];

  @override
  void initState() {
    super.initState();
    loadStudentInfo();
  }

  Future<void> loadStudentInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    className = prefs.getString('class');
    studentID = prefs.getString('studentID');

    if (className != null && studentID != null) {
      await fetchAttendance();
      generateMonthsList();
      filterByMonth(selectedMonth);
    }
  }

  Map<String, bool> filteredData = {};

  Future<void> fetchAttendance() async {
    setState(() => isLoading = true);

    DatabaseReference attRef = _dbRef.child("Attendance").child(className!);
    DataSnapshot snapshot = await attRef.get();

    Map<String, bool> tempData = {};

    if (snapshot.exists) {
      Map<dynamic, dynamic> allDates = snapshot.value as Map<dynamic, dynamic>;

      allDates.forEach((date, students) {
        if (students != null && students[studentID!] != null) {
          tempData[date] = students[studentID!] as bool;
        }
      });
    }

    setState(() {
      attendanceData = Map.fromEntries(
          tempData.entries.toList()..sort((a, b) => b.key.compareTo(a.key)));
      isLoading = false;
    });
  }

  void generateMonthsList() {
    Set<String> monthsSet = attendanceData.keys.map((dateStr) {
      DateTime dt = DateTime.parse(dateStr);
      return DateFormat('MMMM yyyy').format(dt);
    }).toSet();

    monthsList = monthsSet.toList()..sort((a, b) {
      DateTime da = DateFormat('MMMM yyyy').parse(a);
      DateTime db = DateFormat('MMMM yyyy').parse(b);
      return db.compareTo(da); // descending
    });
  }

  void filterByMonth(String monthYear) {
    Map<String, bool> temp = {};
    attendanceData.forEach((date, present) {
      DateTime dt = DateTime.parse(date);
      String monthStr = DateFormat('MMMM yyyy').format(dt);
      if (monthStr == monthYear) {
        temp[date] = present;
      }
    });
    setState(() {
      filteredData = temp;
      selectedMonth = monthYear;
    });
  }

  double getMonthlyPercentage() {
    if (filteredData.isEmpty) return 0;
    int total = filteredData.length;
    int presentCount = filteredData.values.where((v) => v).length;
    return (presentCount / total) * 100;
  }

  @override
  Widget build(BuildContext context) {
    double percentage = getMonthlyPercentage();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance"),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 16),
                // Month selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<String>(
                    value: selectedMonth,
                    items: monthsList
                        .map((month) => DropdownMenuItem(
                              value: month,
                              child: Text(month),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) filterByMonth(val);
                    },
                    decoration: const InputDecoration(
                      labelText: "Select Month",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Summary bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text(
                            "Monthly Attendance: ",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "${percentage.toStringAsFixed(1)}%",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        color: Colors.green,
                        backgroundColor: Colors.redAccent.withOpacity(0.3),
                        minHeight: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Attendance list
                Expanded(
                  child: filteredData.isEmpty
                      ? const Center(child: Text("No records for this month"))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredData.length,
                          itemBuilder: (context, index) {
                            String date = filteredData.keys.elementAt(index);
                            bool present = filteredData[date]!;

                            return Card(
                              elevation: 4,
                              margin:
                                  const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                              child: ListTile(
                                leading: Icon(
                                  present
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: present ? Colors.green : Colors.red,
                                  size: 40,
                                ),
                                title: Text(
                                  "Date: $date",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                trailing: Text(
                                  present ? "Present" : "Absent",
                                  style: TextStyle(
                                      color:
                                          present ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
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
