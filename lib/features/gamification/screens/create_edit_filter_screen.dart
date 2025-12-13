import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sweepfeed/core/models/filter_set_model.dart';

import '../../../core/providers/providers.dart';

class CreateEditFilterScreen extends ConsumerStatefulWidget {
  const CreateEditFilterScreen({super.key, this.filter});

  final FilterSet? filter;

  @override
  _CreateEditFilterScreenState createState() => _CreateEditFilterScreenState();
}

class _CreateEditFilterScreenState extends ConsumerState<CreateEditFilterScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String? _selectedSortBy;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.filter?.name);
    _selectedSortBy = widget.filter?.sortBy;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.filter == null ? 'Create Filter' : 'Edit Filter'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Filter Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedSortBy,
                decoration: const InputDecoration(labelText: 'Sort By'),
                items: ['Default', 'Ending Soon', 'Newest', 'Prize Value (High to Low)', 'Prize Value (Low to High)', 'Trending']
                    .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSortBy = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final userId = ref.read(firebaseAuthProvider).currentUser?.uid;
                    if (userId != null) {
                      final filterSet = FilterSet(
                        id: widget.filter?.id ?? _nameController.text.toLowerCase().replaceAll(' ', '_'),
                        name: _nameController.text,
                        sortBy: _selectedSortBy,
                      );
                      ref.read(profileServiceProvider).saveFilterSet(userId, filterSet);
                      Navigator.of(context).pop();
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
