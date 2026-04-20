import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();

  Map<String, String> _projectsMap = {};
  String? _selectedProjectId;

  bool _isLoadingProjects = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchAvailableProjects();
  }

  void _fetchAvailableProjects() async {
    final ref = FirebaseDatabase.instance.ref('CloudBackup');
    final snap = await ref.get();

    if (snap.exists) {
      final data = snap.value as Map<dynamic, dynamic>;
      Map<String, String> tempMap = {};

      data.forEach((key, value) {
        String projectId = key.toString();
        String projectName = "Project ${projectId.replaceAll(RegExp(r'[^0-9]'), '')}";

        if (value != null && value is Map && value.containsKey('info')) {
          var infoData = value['info'];
          if (infoData is Map && infoData.containsKey('projectName')) {
            projectName = infoData['projectName'].toString();
          }
        }
        tempMap[projectId] = projectName;
      });

      setState(() {
        _projectsMap = tempMap;
        if (_projectsMap.isNotEmpty) {
          _selectedProjectId = _projectsMap.keys.first;
        }
        _isLoadingProjects = false;
      });
    } else {
      setState(() => _isLoadingProjects = false);
    }
  }

  void _saveExpense() async {
    if (_formKey.currentState!.validate() && _selectedProjectId != null) {
      setState(() => _isSaving = true);

      final dbRef = FirebaseDatabase.instance.ref('CloudBackup/$_selectedProjectId/expenses');

      try {
        await dbRef.push().set({
          'claimant': _nameController.text,
          'type': _typeController.text,
          'amount': double.parse(_amountController.text),
          'date': _dateController.text,
          'id': DateTime.now().millisecondsSinceEpoch,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense added successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADD NEW EXPENSE', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingProjects
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // DROPDOWN HIỂN THỊ TÊN THẬT
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Project',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.folder),
                ),
                value: _selectedProjectId,
                items: _projectsMap.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key, // Giá trị ẩn (project_3)
                    child: Text(entry.value), // Tên hiển thị (Dự án Website)
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedProjectId = newValue;
                  });
                },
                validator: (value) => value == null ? 'Please select a project' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Claimant Name', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'Expense Type (e.g. Travel, Food)', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Please enter a type' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (\$)', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Please enter an amount' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: 'Date (DD/MM/YYYY)', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Please enter a date' : null,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isSaving ? null : _saveExpense,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('SAVE EXPENSE', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}