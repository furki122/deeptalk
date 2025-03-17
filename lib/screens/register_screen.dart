import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  File? _profileImage; // Datei für das Profilbild
  bool _isLoading = false;

  // Methode zur Auswahl des Profilbilds
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _profileImage = File(pickedImage.path);
      });
    }
  }

  // Methode zur Validierung der E-Mail-Adresse
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  // Methode zur Validierung des Passworts
  bool _isValidPassword(String password) {
    return password.length >= 6; // Mindestlänge: 6 Zeichen
  }

  // Methode zur Registrierung des Benutzers
  Future<void> _registerUser() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte alle Felder ausfüllen')),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte eine gültige E-Mail-Adresse eingeben')),
      );
      return;
    }

    if (!_isValidPassword(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwort muss mindestens 6 Zeichen lang sein')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Benutzer mit Firebase registrieren
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String? profileImageUrl;

      // Profilbild in Firebase Storage hochladen, falls vorhanden
      if (_profileImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${userCredential.user!.uid}.jpg');
        await storageRef.putFile(_profileImage!);

        // URL des hochgeladenen Bildes abrufen
        profileImageUrl = await storageRef.getDownloadURL();
      } else {
        // Optional: Eine Standard-URL für das Profilbild verwenden
        profileImageUrl = null; // Oder eine Standard-URL wie 'https://example.com/default-profile.jpg'
      }

      // Benutzerinformationen in Firestore speichern
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'username': username,
        'email': email,
        'profileImageUrl': profileImageUrl ?? '', // Speichere die URL oder eine leere Zeichenkette
        'friends': [],
        'requests': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Erfolgreiche Registrierung - Weiterleitung zum HomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyApp()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Fehler bei der Registrierung';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'Diese E-Mail-Adresse wird bereits verwendet.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Das Passwort ist zu schwach.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Bitte eine gültige E-Mail-Adresse eingeben.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ein unerwarteter Fehler ist aufgetreten: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // TextController freigeben
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrieren'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Profilbild hochladen
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage:
                  _profileImage != null ? FileImage(_profileImage!) : null,
                  child: _profileImage == null
                      ? const Icon(
                    Icons.add_a_photo,
                    size: 40,
                    color: Colors.grey,
                  )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              // Namens-Eingabe
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Vollständiger Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Benutzername-Eingabe
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Benutzername',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // E-Mail-Eingabe
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-Mail',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              // Passwort-Eingabe
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Passwort',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              // Ladeanzeige oder Registrierungsbutton
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _registerUser,
                  child: const Text('Registrieren'),
                ),
              const SizedBox(height: 20),
              // Zurück zur Anmeldung
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Zurück zur Anmeldung'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
