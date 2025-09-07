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
        const SnackBar(content: Text('Por favor, preencha todos os campos.')),
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
                  Text(
                    'Criar Nova Vaga/Disponibilidade',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Descrição',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedInstrument,
                    decoration: InputDecoration(
                      labelText: 'Instrumento/Função',
                      border: OutlineInputBorder(),
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
                  SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _createVaga,
                    child: Text('Publicar Vaga'),
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
                  Text(
                    'Filtros',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _filterUserType,
                          decoration: InputDecoration(
                            labelText: 'Tipo de Usuário',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Todos')),
                            DropdownMenuItem(value: 'musician', child: Text('Músico')),
                            DropdownMenuItem(value: 'band', child: Text('Banda')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filterUserType = value;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _filterInstrument,
                          decoration: InputDecoration(
                            labelText: 'Instrumento',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Todos')),
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
                  SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _applyFilters,
                    child: Text('Aplicar Filtros'),
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
                return Center(
                  child: Text('Nenhuma vaga/disponibilidade encontrada.'),
                );
              }

              return ListView.builder(
                itemCount: vagaProvider.vagas.length,
                itemBuilder: (ctx, index) {
                  final vaga = vagaProvider.vagas[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vaga.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text('Por: ${vaga.username} (${vaga.userType})'),
                          SizedBox(height: 4),
                          Text('Instrumento: ${vaga.instrument}'),
                          SizedBox(height: 4),
                          Text(vaga.description),
                          SizedBox(height: 4),
                          Text(
                            vaga.timestamp.toDate().toString(),
                            style: TextStyle(color: Colors.grey, fontSize: 12),
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