import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentRegistryManagementScreen extends StatefulWidget {
  const StudentRegistryManagementScreen({super.key});

  @override
  State<StudentRegistryManagementScreen> createState() =>
      _StudentRegistryManagementScreenState();
}

class _StudentRegistryManagementScreenState
    extends State<StudentRegistryManagementScreen> {
  final _registry = FirebaseFirestore.instance.collection('student_registry');
  late Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _load() async {
    final snapshot = await _registry.get();
    final docs = snapshot.docs.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return docs;
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _openEditor({
    QueryDocumentSnapshot<Map<String, dynamic>>? existing,
  }) async {
    final data = existing?.data() ?? const <String, dynamic>{};
    final studentId = TextEditingController(
      text: existing?.id ?? (data['studentId'] ?? '').toString(),
    );
    final name = TextEditingController(text: (data['name'] ?? '').toString());
    final department =
        TextEditingController(text: (data['department'] ?? '').toString());
    final batch = TextEditingController(text: (data['batch'] ?? '').toString());
    final hall = TextEditingController(text: (data['hall'] ?? '').toString());
    var active = data['active'] != false;
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add student' : 'Edit student'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: studentId,
                      enabled: existing == null,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Student ID',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (value) {
                        final id = value?.trim() ?? '';
                        if (!RegExp(r'^[0-9]{7}$').hasMatch(id)) {
                          return 'Enter a 7-digit CUET Student ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Student name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? 'Student name is required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: department,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: batch,
                      decoration: const InputDecoration(
                        labelText: 'Batch',
                        prefixIcon: Icon(Icons.groups_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: hall,
                      decoration: const InputDecoration(
                        labelText: 'Hall',
                        prefixIcon: Icon(Icons.home_work_outlined),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active student'),
                      subtitle: const Text(
                        'Inactive students cannot create a new account.',
                      ),
                      value: active,
                      onChanged: (value) =>
                          setDialogState(() => active = value),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;
                try {
                  final id = studentId.text.trim();
                  await _registry.doc(id).set({
                    'studentId': id,
                    'name': name.text.trim(),
                    'department': department.text.trim(),
                    'batch': batch.text.trim(),
                    'hall': hall.text.trim(),
                    'active': active,
                    'updatedAt': FieldValue.serverTimestamp(),
                    if (existing == null)
                      'createdAt': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));
                  if (context.mounted) Navigator.pop(context, true);
                } on FirebaseException catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        error.code == 'permission-denied'
                            ? 'Permission denied. Deploy the updated Firestore rules and sign in as a DSW Director.'
                            : 'Could not save student: ${error.message ?? error.code}',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    studentId.dispose();
    name.dispose();
    department.dispose();
    batch.dispose();
    hall.dispose();
    if (saved == true) _refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Student Registry Management'),
          actions: [
            IconButton(
              onPressed: _refresh,
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openEditor(),
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Add student'),
        ),
        body: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              final error = snapshot.error.toString();
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    error.contains('permission-denied') ||
                            error.contains('PERMISSION_DENIED')
                        ? 'Student registry management is restricted to the DSW Director. Deploy the updated Firestore rules first, then sign in again.'
                        : 'Could not load student registry: $error',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            final docs = snapshot.data ??
                const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
            if (docs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No students are in the registry yet. Add a student before testing new student registration.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();
                final active = data['active'] != false;
                final studentName = (data['name'] ?? '').toString().trim();
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        studentName.isEmpty
                            ? '?'
                            : studentName[0].toUpperCase(),
                      ),
                    ),
                    title: Text((data['name'] ?? 'Unnamed student').toString()),
                    subtitle: Text(
                      '${doc.id}${(data['department'] ?? '').toString().isEmpty ? '' : ' · ${data['department']}'}${(data['hall'] ?? '').toString().isEmpty ? '' : '\n${data['hall']}'}',
                    ),
                    isThreeLine: (data['hall'] ?? '').toString().isNotEmpty,
                    trailing: Chip(
                      label: Text(active ? 'Active' : 'Inactive'),
                    ),
                    onTap: () => _openEditor(existing: doc),
                  ),
                );
              },
            );
          },
        ),
      );
}
