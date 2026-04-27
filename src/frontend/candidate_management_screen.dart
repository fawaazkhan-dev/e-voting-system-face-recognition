import 'package:flutter/material.dart';
import 'api_service.dart';

class CandidateManagementScreen extends StatefulWidget {
  @override
  _CandidateManagementScreenState createState() => _CandidateManagementScreenState();
}

class _CandidateManagementScreenState extends State<CandidateManagementScreen> {
  final _apiService = ApiService();
  List<String> _candidates = [];
  final _candidateController = TextEditingController();

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

  void _deleteCandidate(String candidate) async {
    final success = await _apiService.deleteCandidate(candidate);
    if (success) {
      _fetchCandidates();
    }
  }

  void _addCandidate() async {
    final candidate = _candidateController.text;
    final success = await _apiService.addCandidate(candidate);
    if (success) {
      _fetchCandidates();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Candidate Management')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _candidateController, decoration: InputDecoration(labelText: 'Candidate Name')),
            ElevatedButton(onPressed: _addCandidate, child: Text('Add Candidate')),
            Expanded(
              child: ListView.builder(
                itemCount: _candidates.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_candidates[index]),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deleteCandidate(_candidates[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
