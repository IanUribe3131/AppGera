import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _rolSeleccionado = 'paciente'; 
  bool _isLoading = false;

  Future<void> _registrar() async {
    if (_nombreController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor llena todos los campos')));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      UserCredential credencial = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = credencial.user!.uid;

      String? codigoInvitacion;
      if (_rolSeleccionado == 'fisio') {
        codigoInvitacion = uid.substring(0, 6).toUpperCase(); 
      }

      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'nombre': _nombreController.text.trim(),
        'email': _emailController.text.trim(),
        'rol': _rolSeleccionado,
        'fechaRegistro': FieldValue.serverTimestamp(),
        if(_rolSeleccionado == 'fisio') 'codigoInvitacion': codigoInvitacion,
        if(_rolSeleccionado == 'paciente') 'fisioId': null,
      });

      if (mounted) Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Cuenta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Nombre Completo', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Correo', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 20),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()), obscureText: true),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _rolSeleccionado,
              decoration: const InputDecoration(labelText: '¿Qué tipo de usuario eres?', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'paciente', child: Text('Soy Paciente')),
                DropdownMenuItem(value: 'fisio', child: Text('Soy Fisioterapeuta')),
              ],
              onChanged: (String? nuevoValor) => setState(() => _rolSeleccionado = nuevoValor!),
            ),
            const SizedBox(height: 30),
            _isLoading 
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _registrar,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  child: const Text('Registrarme', style: TextStyle(fontSize: 18)),
                ),
          ],
        ),
      ),
    );
  }
}