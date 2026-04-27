import 'package:flutter/material.dart';
import 'api_service.dart';
import 'package:intl/intl.dart';

class ElectionTimeScreen extends StatefulWidget {
  @override
  _ElectionTimeScreenState createState() => _ElectionTimeScreenState();
}

class _ElectionTimeScreenState extends State<ElectionTimeScreen> {
  DateTime? startTime;
  DateTime? endTime;

  @override
  void initState() {
    super.initState();
    _fetchElectionTime();
  }

  final DateFormat customFormat = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'");

  Future<void> _fetchElectionTime() async {
    final electionTime = await ApiService.getElectionTime();
    if (electionTime != null) {
      setState(() {
        startTime = customFormat.parse(electionTime['start_time']);
        endTime = customFormat.parse(electionTime['end_time']);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Election Time')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (startTime != null && endTime != null) ...[
              Text('Election Start Time: ${startTime!.toLocal()}'),
              SizedBox(height: 16),
              Text('Election End Time: ${endTime!.toLocal()}'),
            ] else
              ...[
                Text('No election time information available'),
              ],
          ],
        ),
      ),
    );
  }
}