import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NavegacionPaciente extends StatefulWidget {
  const NavegacionPaciente({super.key});
  @override
  State<NavegacionPaciente> createState() => _NavegacionPacienteState();
}

class _NavegacionPacienteState extends State<NavegacionPaciente> {
  int state = 0;
  final TextEditingController _codigoController = TextEditingController(); // Controlador para el código
  bool _vinculando = false;

  // Lógica de Computer Science: Transacción en la base de datos
  Future<void> _vincularFisio() async {
    if (_codigoController.text.isEmpty) return;
    setState(() => _vinculando = true);

    try {
      final String codigoIngresado = _codigoController.text.trim().toUpperCase();
      final pacienteUid = FirebaseAuth.instance.currentUser!.uid;

      // 1. Buscamos al fisio que tenga ese código
      final query = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('rol', isEqualTo: 'fisio')
          .where('codigoInvitacion', isEqualTo: codigoIngresado)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código inválido')));
        return;
      }

      final fisioDoc = query.docs.first;
      final fisioUid = fisioDoc.id;

      // 2. Actualizamos ambas cuentas (Batch write / Transacción simple)
      await FirebaseFirestore.instance.collection('usuarios').doc(pacienteUid).update({
        'fisioId': fisioUid,
      });

      await FirebaseFirestore.instance.collection('usuarios').doc(fisioUid).update({
        'pacientesVinculados': FieldValue.arrayUnion([pacienteUid])
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Vinculación exitosa!')));
      _codigoController.clear();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _vinculando = false);
    }
  }

  late final List<Widget> _pages = [
    const Center(child: Text('Mi Plan de Ejercicios')),
    const Center(child: Text('Mis Citas')),
    const Center(child: Text('Mi Progreso')),
    
    // NUEVA PESTAÑA DE PERFIL PARA EL PACIENTE
    Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Vincular con mi Fisioterapeuta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: _codigoController,
            decoration: const InputDecoration(
              labelText: 'Ingresa el código de 6 letras',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 15),
          _vinculando 
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _vincularFisio,
                child: const Text('Vincular Cuenta'),
              ),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Recuperación'), backgroundColor: Colors.teal),
      body: _pages[state],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: state,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => state = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Mi Plan'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Citas'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Progreso'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}