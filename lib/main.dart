import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final authStateProvider = StreamProvider<User?>((ref){
  return FirebaseAuth.instance.authStateChanges();
});

void main() async{

WidgetsFlutterBinding.ensureInitialized();

  // 6. Inicializamos Firebase apuntando a las opciones de tu proyecto
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 7. Envolvemos tu MyApp en un ProviderScope para poder usar Riverpod más adelante
  runApp(const ProviderScope(child: MyApp()));
}


class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 2. Escuchamos el estado de autenticación
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // 3. .when() maneja los 3 posibles estados de un Stream (cargando, error, o datos listos)
      home: authState.when(
        data: (user) {
          if (user != null) {
            return const NavegacionPrincipal(); // ¡El usuario está logueado! Mostramos tu menú.
          } else {
            return const PantallaLogin(); // No hay usuario, mostramos el Login.
          }
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, trace) => Scaffold(body: Center(child: Text('Error: $e'))),
      ),
    );
  }
}

class NavegacionPrincipal extends StatefulWidget {
  const NavegacionPrincipal({super.key});

  @override
  State<NavegacionPrincipal> createState() => _NavegacionPrincipalState();
}

class _NavegacionPrincipalState extends State<NavegacionPrincipal> {
  int state = 0;
  
  final List<Widget> _pages = [
    Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Home Screen'),
        ElevatedButton(
          onPressed: () {
            // Ejemplo de cómo CERRAR SESIÓN
            FirebaseAuth.instance.signOut();
          }, 
          child: const Text('Cerrar Sesión')
        )
      ],
    ),
    const Center(child: Text('Routines Page')),
    const Center(child: Text('Patients Page')),
    const Center(child: Text('Profile Page')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('FisioApp'),
      ),
      body: _pages[state],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: state,
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.blueAccent, // Color cuando está seleccionado
        unselectedItemColor: Colors.grey, // Color de las pestañas inactivas
        onTap: (index) {
          setState(() {
            state = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Routines'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: 'Patients'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  // Controladores para atrapar lo que el usuario escribe
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false; // Para mostrar un circulito de carga mientras verifica

  // Función para iniciar sesión
  Future<void> _iniciarSesion() async {
    setState(() { _isLoading = true; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Si el código llega aquí, Firebase autenticó al usuario.
      // Riverpod detectará el cambio y nos mandará automáticamente a NavegacionPrincipal.
    } on FirebaseAuthException catch (e) {
      // Si hay error (contraseña mal, correo no existe), mostramos un aviso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  void dispose() {
    // Es buena práctica de CS liberar memoria destruyendo los controladores
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medical_services, size: 100, color: Colors.blueAccent),
            const SizedBox(height: 30),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Correo Electrónico',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
              obscureText: true, // Oculta los caracteres
            ),
            const SizedBox(height: 30),
            _isLoading 
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _iniciarSesion,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50), // Botón ancho
                  ),
                  child: const Text('Iniciar Sesión', style: TextStyle(fontSize: 18)),
                ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PantallaRegistro()),
                );
              },
              child: const Text('¿No tienes cuenta? Registrate aquí'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> registrarUsuario(String email, String password, String nombre, String rol) async{
  try{
    //Esto crea la cuenta en firebase auth
    UserCredential credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password
    );
    //obtiene el uid que le asigno firebase a la cuenta
    String uid = credential.user!.uid;
    
    await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'fechaRegistro': FieldValue.serverTimestamp(),// esto guarda la hora exacta del servidor
    });

    print("Usuario registrado y guardado en Firestore exitosamente");
  }catch (e){
    print("Hubo un error al registrar: $e");
  }
}

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro>{
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  //variable para guardar el rol seleccionado por defecto
  String _rolSeleccionado = 'paciente';
  bool _isLoading = false;

  Future<void> _registrar() async{
    //validar que los campos no esten vacios
    if(_nombreController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor llena todos los campos')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try{
      //Crear usuario en firebase auth
      UserCredential credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = credential.user!.uid;

      //Guardar perfil en Cloud Firestore
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'nombre': _nombreController.text.trim(),
        'email': _emailController.text.trim(),
        'rol': _rolSeleccionado,
        'fechaRegistro': FieldValue.serverTimestamp(),
      });

      //regresar a la pantalla anterior
      if(mounted){
        Navigator.pop(context);
      }

    }on FirebaseAuthException catch (e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    }finally{
      if(mounted){
        setState(() {_isLoading = false; });
      }
    }
  }

  @override
  void dispose(){
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Cuenta')),
      body: SingleChildScrollView( // Permite hacer scroll si el teclado tapa la pantalla
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre Completo', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Correo Electrónico', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña (mínimo 6 caracteres)', border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            
            // Menú desplegable para elegir el rol
            DropdownButtonFormField<String>(
              initialValue: _rolSeleccionado,
              decoration: const InputDecoration(labelText: '¿Qué tipo de usuario eres?', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'paciente', child: Text('Soy Paciente')),
                DropdownMenuItem(value: 'fisio', child: Text('Soy Fisioterapeuta')),
              ],
              onChanged: (String? nuevoValor) {
                setState(() {
                  _rolSeleccionado = nuevoValor!;
                });
              },
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