import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Importamos el archivo autogenerado de Firebase
import 'firebase_options.dart';

// Importamos nuestras funcionalidades locales
import 'features/auth/providers/auth_providers.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/fisio/screens/fisio_navigation.dart';
import 'features/paciente/screens/paciente_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: authState.when(
        data: (user) {
          if (user != null) {
            return const NavegacionPrincipal(); 
          } else {
            return const PantallaLogin(); 
          }
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, trace) => Scaffold(body: Center(child: Text('Error: $e'))),
      ),
    );
  }
}

class NavegacionPrincipal extends ConsumerWidget {
  const NavegacionPrincipal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDataAsync = ref.watch(userDataProvider);

    return userDataAsync.when(
      data: (datosDelUsuario) {
        if (datosDelUsuario == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.orange),
                  const SizedBox(height: 20),
                  const Text('Perfil incompleto o no encontrado.'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    child: const Text('Cerrar Sesión para volver a intentar'),
                  )
                ],
              ),
            ),
          );
        }

        final String rol = datosDelUsuario['rol'];

        if (rol == 'fisio') {
          return const NavegacionFisio();
        } else {
          return const NavegacionPaciente();
        }
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, trace) => Scaffold(body: Center(child: Text('Error al cargar perfil: $e'))),
    );
  }
}