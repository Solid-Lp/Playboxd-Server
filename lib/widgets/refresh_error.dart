import 'package:flutter/material.dart';

// Aviso padrão quando o "puxar para atualizar" não consegue falar com o servidor
void showRefreshError(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
    content: Text('Não foi possível atualizar. Verifique sua conexão.'),
    duration: Duration(seconds: 3),
  ));
}
