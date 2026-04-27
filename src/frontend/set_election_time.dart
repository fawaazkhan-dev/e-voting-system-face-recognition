import 'package:flutter/material.dart';
import 'api_service.dart';

class SetElectionTimeScreen extends StatefulWidget {
  @override
  _SetElectionTimeScreenState createState() => _SetElectionTimeScreenState();
}

class _SetElectionTimeScreenState extends State<SetElectionTimeScreen> {
  bool _isEnabled = false;
  DateTime? _startTime;
  DateTime? _endTime;
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  // Callback for when the enable checkbox is changed
  void _onEnableChanged(bool? value) {
    setState(() {
      _isEnabled = value ?? false;
    });
  }

  // Submit election time settings
  Future<void> _submitElectionTime() async {
    if (_startTime != null && _endTime != null) {
      final success = await ApiService.setElectionTime(
        _startTime!,
        _endTime!,
        _isEnabled,
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Election time settings updated.'),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update election time settings.'),
        ));
      }
    }
  }

  // Disable election time
  Future<void> _disableElectionTime() async {
    final success = await ApiService.disableElectionTime();
    if (success) {
      setState(() {
        _isEnabled = false;
        _startTime = null;
        _endTime = null;
        _startTimeController.clear();
        _endTimeController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Election time disabled.'),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to disable election time.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Set Election Time')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              title: Text('Enable Election Time'),
              value: _isEnabled,
              onChanged: _onEnableChanged,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _startTimeController,
              decoration: InputDecoration(
                labelText: 'Start Time (YYYY-MM-DD HH:MM:SS)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _startTime = DateTime.tryParse(value);
                });
              },
            ),
            SizedBox(height: 16),
            TextField(
              controller: _endTimeController,
              decoration: InputDecoration(
                labelText: 'End Time (YYYY-MM-DD HH:MM:SS)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _endTime = DateTime.tryParse(value);
                });
              },
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitElectionTime,
              child: Text('Save Election Time'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _disableElectionTime,
              child: Text('Disable Election Time'),
              style: ElevatedButton.styleFrom(
                // backgroundColor: Colors.red, // Change color to indicate disable action
              ),
            ),
          ],
        ),
      ),
    );
  }
}
