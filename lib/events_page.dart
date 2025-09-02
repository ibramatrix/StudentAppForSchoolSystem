import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final dbRef = FirebaseDatabase.instance.ref().child('EventList/StudentEvents');
  List<Map<dynamic, dynamic>> events = [];

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  void fetchEvents() {
    dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      List<Map<dynamic, dynamic>> temp = [];
      if (data != null) {
        data.forEach((yearKey, months) {
          (months as Map).forEach((monthKey, monthEvents) {
            (monthEvents as Map).forEach((key, value) {
              temp.add(value as Map<dynamic, dynamic>);
            });
          });
        });
      }
      setState(() {
        events = temp;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Events"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: events.isEmpty
          ? const Center(child: Text("No events found!"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final ev = events[index];
                return Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  color: Colors.orangeAccent.withAlpha((0.9 * 255).toInt()),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(ev['Title'] ?? "",
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        "${ev['Date']} | ${ev['Time']} | ${ev['Status']}",
                        style: const TextStyle(color: Colors.white70)),
                    leading: const Icon(Icons.event, color: Colors.white),
                  ),
                );
              },
            ),
    );
  }
}
