import 'package:flutter/material.dart';

void main(){

  runApp(MyApp()) ;
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  int state = 0;

  final List<Widget> _pages = [
    Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text ('Home Screen'),
        ElevatedButton(
          onPressed: (){}, 
          child: Text('Button Home')
        )
      ],
    ),

    Center(child: Text('Business Page')),
    
    Center(child: Text('School Page'))
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blueAccent,
          title: const Text('App de Gera'),
        ),

        body: _pages[state], //cambia la pantalla

        bottomNavigationBar: BottomNavigationBar(
          currentIndex: state,
          onTap: (index){
            setState(() {
              state = index; // cambia pestaña
            });
          },
          items: const[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home' ,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.business),
              label: 'Business' ,
              backgroundColor: Colors.blueGrey 
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school),
              label: 'School',
              backgroundColor: Colors.teal
            )
          ],
        ),

          
      ),
    );
  }
}