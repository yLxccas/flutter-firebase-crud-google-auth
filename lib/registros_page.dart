import 'package:agenda6/services/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RegistrosPage extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();
  final void Function(BuildContext, {Map<String, dynamic>? data})? onEdit;
  final void Function(BuildContext)? onAdd;

  RegistrosPage({Key? key, this.onEdit, this.onAdd}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DocumentSnapshot>>(
      stream: _firestoreService.getPessoas(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        final pessoas = snapshot.data!;
        if (pessoas.isEmpty) {
          return Center(
            child: Text('Não existem registros.'),
          );
        }
        return ListView.builder(
          itemCount: pessoas.length,
          itemBuilder: (context, index) {
            final pessoa = pessoas[index];
            final data = pessoa.data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['nome']),
              subtitle: Text(data['email']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      if (onEdit != null) {
                        onEdit!(context, data: data);
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Excluir Registro"),
                            content: Text(
                              "Você realmente deseja excluir este registro? Depois de excluí-lo, não haverá como voltar atrás.",
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text("Cancelar"),
                              ),
                              TextButton(
                                onPressed: () {
                                  _firestoreService.deletePessoa(pessoa.id);
                                  Navigator.of(context).pop();
                                },
                                child: Text("Excluir"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
