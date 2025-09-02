import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  final DatabaseReference _diaryRef = FirebaseDatabase.instance.ref("diaries");
  List<DiaryEntry> diaryList = [];

  @override
  void initState() {
    super.initState();
    _loadDiaries();
  }

  void _loadDiaries() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? loggedInClass = prefs.getString('class');

  _diaryRef.onValue.listen((event) {
    final data = event.snapshot.value as Map<dynamic, dynamic>?;
    if (data == null) return;

    List<DiaryEntry> tempList = [];
    data.forEach((key, value) {
      // Only add if matches the student's class
      if (value['ClassName'] == loggedInClass) {
        final diary = DiaryEntry(
          className: value['ClassName'] ?? '',
          date: value['Date'] ?? '',
          text: value['Text'] ?? '',
          images: List<String>.from(value['Images'] ?? []),
        );
        tempList.add(diary);
      }
    });

    setState(() {
      diaryList = tempList;
    });
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Diary"),
        backgroundColor: Colors.blueAccent,
      ),
      body: diaryList.isEmpty
          ? const Center(child: Text("No diary entries yet"))
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: diaryList.length,
              itemBuilder: (context, index) {
                final diary = diaryList[index];
                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${diary.className} - ${diary.date}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(diary.text),
                        if (diary.images.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 150,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: diary.images.length,
                              itemBuilder: (context, i) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Image.network(diary.images[i],
                                    width: 150, fit: BoxFit.cover),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class DiaryEntry {
  final String className;
  final String date;
  final String text;
  final List<String> images;

  DiaryEntry(
      {required this.className,
      required this.date,
      required this.text,
      required this.images});
}
