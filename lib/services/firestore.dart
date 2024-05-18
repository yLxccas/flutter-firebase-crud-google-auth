import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final CollectionReference pessoas =
      FirebaseFirestore.instance.collection('pessoas');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> addPessoa(String nome, DateTime dataNascimento,
      String endereco, String email, String senha) async {
    String id = pessoas.doc().id;
    await pessoas.doc(id).set({
      'id': id,
      'nome': nome,
      'data_nascimento': dataNascimento,
      'endereco': endereco,
      'email': email,
      'senha': senha,
    });
    return id;
  }

  Stream<List<DocumentSnapshot>> getPessoas() {
    return pessoas.snapshots().map((snapshot) => snapshot.docs);
  }

  Stream<QuerySnapshot> getPessoasStream() {
    return pessoas.snapshots();
  }

  Future<void> updatePessoa(String id, String nome, DateTime dataNascimento,
      String endereco, String email, String senha) {
    return pessoas.doc(id).update({
      'nome': nome,
      'data_nascimento': dataNascimento,
      'endereco': endereco,
      'email': email,
      'senha': senha,
    });
  }

  Future<void> deletePessoa(String id) async {
    DocumentSnapshot pessoaSnapshot = await pessoas.doc(id).get();
    Map<String, dynamic> pessoaData =
        pessoaSnapshot.data() as Map<String, dynamic>;

    await pessoas.doc(id).delete();

    String email = pessoaData['email'];
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: pessoaData['senha'],
      );

      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.delete();
      }
    } catch (e) {
      print('Erro ao excluir usuário do Firebase Authentication: $e');
    }
  }
}
