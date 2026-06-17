import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NavegacionFisio extends StatefulWidget {
  const NavegacionFisio({super.key});
  @override
  State<NavegacionFisio> createState() => _NavegacionFisioState();
}

class _NavegacionFisioState extends State<NavegacionFisio> {
  int state = 0;
  final String _fisioUid = FirebaseAuth.instance.currentUser!.uid;

  late final List<Widget> _pages = [
    const Center(child: Text('Lista de Pacientes')),
    const Center(child: Text('Agenda Semanal')),
    const Center(child: Text('Biblioteca de Videos')),

    FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('usuarios').doc(_fisioUid).get(),
      builder: (context, snapshot){
        if(!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final datos =  snapshot.data!.data() as Map<String, dynamic>;
        final codigo = datos['codigoInvitacion']??'No generado';

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Tu codigo de invitacion: ', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                decoration: BoxDecoration(color: Colors.indigo.shade100, borderRadius: BorderRadius.circular(10)),
                child: Text(codigo, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 5)),
                ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text('Cerrar Sesion Fisio'),
              ),
            ],
          ),
        );
      },
    )
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel Fisioterapeuta'), backgroundColor: Colors.indigo),
      body: _pages[state],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: state,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => state = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Pacientes'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Agenda'),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'Biblioteca'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}