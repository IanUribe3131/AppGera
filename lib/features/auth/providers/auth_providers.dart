import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Escucha los cambios de sesión (Login/Logout)
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Busca los datos del usuario en tiempo real (Soluciona la condición de carrera)
final userDataProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);

  // En lugar de .get() usamos .snapshots() para escuchar los cambios en vivo
  return FirebaseFirestore.instance
      .collection('usuarios')
      .doc(user.uid)
      .snapshots()
      .map((snapshot) => snapshot.data());
});