import 'package:flutter/material.dart';

// Widget que exibe a logo do aplicativo
class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Margem superior e inferior ao redor da logo
      margin: EdgeInsets.symmetric(vertical: 40.0),
      // Exibe a imagem da logo a partir dos assets
      child: Image.asset(
        'assets/images/logo2.png',
        height: 500, 
      ),
    );
  }
}
