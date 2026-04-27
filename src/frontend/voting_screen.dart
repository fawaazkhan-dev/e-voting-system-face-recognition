import 'package:flutter/material.dart';
import 'api_service.dart';

class VotingScreen extends StatefulWidget {
  final String userId; // Add userId as a parameter to VotingScreen

  VotingScreen({required this.userId});

  @override
  _VotingScreenState createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  final _apiService = ApiService();
  List<String> _candidates = [];
  String? _selectedCandidate;

  @override
  void initState() {
    super.initState();
    _fetchCandidates();
  }

  void _fetchCandidates() async {
    final candidates = await _apiService.getCandidates();
    setState(() {
      _candidates = candidates;
    });
  }

  void _vote() async {
    if (_selectedCandidate != null) {
      final success = await _apiService.vote(widget.userId, _selectedCandidate!);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vote cast successfully')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to cast vote')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select a candidate')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Vote')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _selectedCandidate,
              hint: Text('Select Candidate'),
              items: _candidates.map((candidate) {
                return DropdownMenuItem<String>(
                  value: candidate,
                  child: Text(candidate),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCandidate = value;
                });
              },
            ),
            ElevatedButton(onPressed: _vote, child: Text('Vote')),
          ],
        ),
      ),
    );
  }
}
