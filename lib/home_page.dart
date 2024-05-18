import 'package:agenda6/login_page.dart';
import 'package:agenda6/services/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _dataNascimentoController =
      TextEditingController();
  final TextEditingController _enderecoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isEditing = false;
  String _editingRecordId = '';

  void _addOrUpdatePessoa() async {
    if (_senhaController.text.length < 6) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Erro"),
            content: Text("A senha deve ter no mínimo 6 caracteres."),
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

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(_emailController.text)) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Erro"),
            content: Text("Por favor, insira um e-mail válido."),
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

    DateTime dataNascimento = _dataNascimentoController.text.isNotEmpty
        ? DateTime.parse(_dataNascimentoController.text).toUtc()
        : DateTime.now().toUtc();

    if (_isEditing) {
      await _firestoreService.updatePessoa(
        _editingRecordId,
        _nomeController.text,
        dataNascimento,
        _enderecoController.text,
        _emailController.text,
        _senhaController.text,
      );

      if (_senhaController.text.isNotEmpty) {
        User? currentUser = _auth.currentUser;
        await currentUser!.updatePassword(_senhaController.text);
      }
    } else {
      String pessoaId = await _firestoreService.addPessoa(
        _nomeController.text,
        dataNascimento,
        _enderecoController.text,
        _emailController.text,
        _senhaController.text,
      );

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _senhaController.text,
      );
    }
    _limparCampos();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dataNascimentoController.text =
            DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _preencherCamposParaEdicao(Map<String, dynamic> data) {
    _isEditing = true;
    _editingRecordId = data.containsKey('id') ? data['id'] : '';
    _nomeController.text = data['nome'];

    DateTime dataNascimento = data['dataNascimento'] != null
        ? (data['dataNascimento'] as Timestamp).toDate()
        : DateTime.now();

    _dataNascimentoController.text =
        DateFormat('yyyy-MM-dd').format(dataNascimento);

    _enderecoController.text = data['endereco'];
    _emailController.text = data['email'];
    _senhaController.text = data['senha'];
  }

  void _limparCampos() {
    _isEditing = false;
    _editingRecordId = '';
    _nomeController.clear();
    _dataNascimentoController.clear();
    _enderecoController.clear();
    _emailController.clear();
    _senhaController.clear();
  }

  void _openAddModal(BuildContext context) {
    _limparCampos();
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              ),
              SizedBox(height: 4),
              Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: ElevatedButton(
                  onPressed: () {
                    if (_nomeController.text.isEmpty ||
                        _dataNascimentoController.text.isEmpty ||
                        _enderecoController.text.isEmpty ||
                        _emailController.text.isEmpty ||
                        _senhaController.text.isEmpty) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Erro"),
                            content: Text(
                                "Por favor, preencha todas as informações."),
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
                    _addOrUpdatePessoa();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: Text(
                    'Adicionar Pessoa',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openEditModal(BuildContext context, {Map<String, dynamic>? data}) {
    _preencherCamposParaEdicao(data!);
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              ),
              SizedBox(height: 4),
              Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: ElevatedButton(
                  onPressed: () {
                    if (_nomeController.text.isEmpty ||
                        _dataNascimentoController.text.isEmpty ||
                        _enderecoController.text.isEmpty ||
                        _emailController.text.isEmpty ||
                        _senhaController.text.isEmpty) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Erro"),
                            content: Text(
                                "Por favor, preencha todas as informações."),
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
                    _addOrUpdatePessoa();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: Text(
                    'Salvar Edição',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Pessoas'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getPessoasStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar dados.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final List<QueryDocumentSnapshot> documents = snapshot.data!.docs;

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> data =
                  documents[index].data()! as Map<String, dynamic>;
              data['id'] = documents[index].id;

              return ListTile(
                title: Text(data['nome']),
                subtitle: Text('Email: ${data['email']}'),
                onTap: () => _openEditModal(context, data: data),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddModal(context),
        tooltip: 'Adicionar Pessoa',
        child: Icon(Icons.add),
      ),
    );
  }
}
