import 'package:agenda6/services/firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RegistroPage extends StatelessWidget {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _dataNascimentoController =
      TextEditingController();
  final TextEditingController _enderecoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registro'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nomeController,
              decoration: InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: _dataNascimentoController,
              decoration: InputDecoration(labelText: 'Data de Nascimento'),
              readOnly: true,
              onTap: () => _selectDate(context),
            ),
            TextField(
              controller: _enderecoController,
              decoration: InputDecoration(labelText: 'Endereço'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'E-mail'),
            ),
            TextField(
              controller: _senhaController,
              decoration: InputDecoration(labelText: 'Senha'),
              obscureText: true,
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancelar'),
                ),
                SizedBox(width: 16.0),
                ElevatedButton(
                  onPressed: () {
                    _registrar(context);
                  },
                  child: Text('Registrar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _registrar(BuildContext context) async {
    String nome = _nomeController.text;
    String endereco = _enderecoController.text;
    String email = _emailController.text;
    String senha = _senhaController.text;

    if (nome.isEmpty ||
        endereco.isEmpty ||
        email.isEmpty ||
        senha.isEmpty ||
        _dataNascimentoController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Erro"),
            content: Text("Por favor, preencha todos os campos."),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
      return;
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      DateTime dataNascimento = DateTime.parse(_dataNascimentoController.text);

      await _firestoreService.addPessoa(
          nome, dataNascimento, endereco, email, senha);

      _limparCampos();

      Navigator.pop(context);
    } catch (e) {
      print("Erro durante o registro: $e");

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Erro de Registro"),
            content: Text(
                "Ocorreu um erro durante o registro. Verifique suas credenciais e tente novamente.\n\nErro: $e"),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  void _limparCampos() {
    _nomeController.clear();
    _dataNascimentoController.clear();
    _enderecoController.clear();
    _emailController.clear();
    _senhaController.clear();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dataNascimentoController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }
}
