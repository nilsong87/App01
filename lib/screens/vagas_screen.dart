import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:musiconnect/providers/user_profile_provider.dart';
import 'package:musiconnect/providers/vaga_provider.dart';
import 'package:musiconnect/models/vaga.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VagasScreen extends StatefulWidget {
  const VagasScreen({super.key});

  @override
  VagasScreenState createState() => VagasScreenState();
}

class VagasScreenState extends State<VagasScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedInstrument;
  String? _filterUserType;
  String? _filterInstrument;

  final _auth = FirebaseAuth.instance;

  final List<String> _instruments = [
    'Vocal',
    'Backvocal',
    'Guitarra',
    'Violão',
    'Contrabaixo',
    'Bateria',
    'Tecladista',
    'Sopro',
    'Percussão',
    'Outro',
  ];

  @override
  void initState() {
    super.initState();
    Provider.of<VagaProvider>(context, listen: false).fetchVagas();
  }

  void _createVaga() async {
    final user = _auth.currentUser;
    final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
    final vagaProvider = Provider.of<VagaProvider>(context, listen: false);

    final userProfile = userProfileProvider.userProfile;

    if (user == null ||
        userProfile == null ||
        _titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _selectedInstrument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')), // Placeholder for localization
      );
      return;
    }

    final newVaga = Vaga(
      id: FirebaseFirestore.instance.collection('vagas').doc().id,
      userId: user.uid,
      username: userProfile.username,
      userType: userProfile.userType,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      instrument: _selectedInstrument!,
      timestamp: Timestamp.now(),
    );

    await vagaProvider.createVaga(newVaga);

    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedInstrument = null;
    });
    await vagaProvider.fetchVagas();
  }

  void _applyFilters() {
    Provider.of<VagaProvider>(context, listen: false).fetchVagas(
      userType: _filterUserType,
      instrument: _filterInstrument,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create New Vacancy/Availability', // Placeholder for localization
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title', // Placeholder for localization
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0), // Added border radius
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description', // Placeholder for localization
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0), // Added border radius
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedInstrument,
                    decoration: InputDecoration(
                      labelText: 'Instrument/Role', // Placeholder for localization
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0), // Added border radius
                      ),
                    ),
                    items: _instruments.map((instrument) {
                      return DropdownMenuItem(
                        value: instrument,
                        child: Text(instrument),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedInstrument = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _createVaga,
                    child: const Text('Publish Vacancy'), // Placeholder for localization
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filters', // Placeholder for localization
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _filterUserType,
                          decoration: InputDecoration(
                            labelText: 'User Type', // Placeholder for localization
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0), // Added border radius
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('All')), // Placeholder for localization
                            DropdownMenuItem(value: 'musician', child: Text('Musician')), // Placeholder for localization
                            DropdownMenuItem(value: 'band', child: Text('Band')), // Placeholder for localization
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filterUserType = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _filterInstrument,
                          decoration: InputDecoration(
                            labelText: 'Instrument', // Placeholder for localization
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0), // Added border radius
                            ),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All')), // Placeholder for localization
                            ..._instruments.map((instrument) {
                              return DropdownMenuItem(
                                value: instrument,
                                child: Text(instrument),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filterInstrument = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _applyFilters,
                    child: const Text('Apply Filters'), // Placeholder for localization
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Consumer<VagaProvider>(
            builder: (context, vagaProvider, child) {
              if (vagaProvider.vagas.isEmpty) {
                return const Center(
                  child: Text('No vacancies/availabilities found.'), // Placeholder for localization
                );
              }

              return ListView.builder(
                itemCount: vagaProvider.vagas.length,
                itemBuilder: (ctx, index) {
                  final vaga = vagaProvider.vagas[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vaga.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('By: ${vaga.username} (${vaga.userType})'), // Placeholder for localization
                          const SizedBox(height: 4),
                          Text('Instrument: ${vaga.instrument}'), // Placeholder for localization
                          const SizedBox(height: 4),
                          Text(vaga.description),
                          const SizedBox(height: 4),
                          Text(
                            vaga.timestamp.toDate().toString(),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}