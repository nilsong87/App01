import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:musiconnect/models/vaga.dart';

class VagaProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Vaga> _vagas = [];
  List<Vaga> get vagas => _vagas;

  Future<void> createVaga(Vaga vaga) async {
    try {
      await _firestore.collection('vagas').doc(vaga.id).set(vaga.toFirestore());
      _vagas.insert(0, vaga);
      notifyListeners();
      debugPrint('Vaga created successfully!');
    } catch (e) {
      debugPrint('Error creating vaga: $e');
    }
  }

  Future<void> fetchVagas({String? userType, String? instrument}) async {
    try {
      Query query = _firestore.collection('vagas').orderBy('timestamp', descending: true);

      if (userType != null && userType.isNotEmpty) {
        query = query.where('userType', isEqualTo: userType);
      }
      if (instrument != null && instrument.isNotEmpty) {
        query = query.where('instrument', isEqualTo: instrument);
      }

      QuerySnapshot snapshot = await query.get();
      _vagas = snapshot.docs.map((doc) => Vaga.fromFirestore(doc)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching vagas: $e');
    }
  }

  Future<void> updateVaga(Vaga vaga) async {
    try {
      await _firestore.collection('vagas').doc(vaga.id).update(vaga.toFirestore());
      final index = _vagas.indexWhere((v) => v.id == vaga.id);
      if (index != -1) {
        _vagas[index] = vaga;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating vaga: $e');
    }
  }

  Future<void> deleteVaga(String vagaId) async {
    try {
      await _firestore.collection('vagas').doc(vagaId).delete();
      _vagas.removeWhere((v) => v.id == vagaId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting vaga: $e');
    }
  }
}