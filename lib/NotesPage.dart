import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  String className = "";
  List<Map<String, dynamic>> notes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClassAndNotes();
  }

 Future<void> _loadClassAndNotes() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  className = prefs.getString('class') ?? "";

  if (className.isNotEmpty) {
    DatabaseReference ref =
        FirebaseDatabase.instance.ref("Notes").child(className);

    // Listen for changes in notes
    ref.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;
      List<Map<String, dynamic>> tempNotes = [];

      if (data != null && data is Map) {
        data.forEach((key, value) {
          tempNotes.add({
            'title': value['Title'] ?? key,
            'fileUrl': value['FileUrl'] ?? "",
          });
        });
      }

      setState(() {
        notes = tempNotes;
        isLoading = false;
      });
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Class Notes"),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notes.isEmpty
              ? const Center(child: Text("No notes available."))
              : ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      elevation: 4,
                      child: ListTile(
                        title: Text(note['title']),
                        trailing: IconButton(
                          icon: const Icon(Icons.open_in_new),
                          color: Colors.deepPurpleAccent,
                          onPressed: () {
                            _openNoteFile(note['fileUrl']);
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  // Open note URL in browser or app
  Future<void> _openNoteFile(String fileUrl) async {
    if (fileUrl.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("File URL is empty")));
      return;
    }

    final Uri url = Uri.parse(fileUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open the note file")));
    }
  }
}
