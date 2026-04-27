import 'package:flutter/material.dart';
import 'api_service.dart';

class ResultsScreen extends StatefulWidget {
  @override
  _ResultsScreenState createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final _apiService = ApiService();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  void _fetchResults() async {
    try {
      final results = await _apiService.getResults();
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Election Results')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _results.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_results[index]['candidate']),
            subtitle: Text('Votes: ${_results[index]['vote_count']}'),
          );
        },
      ),
    );
  }
}
