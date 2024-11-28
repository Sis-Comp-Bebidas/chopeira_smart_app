import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart'; // Para usar o Amplify Auth
import 'login_screen.dart'; // Tela de login para redirecionar após logout
import 'package:logger/logger.dart'; // Para usar o logger

class AccountScreen extends StatefulWidget {
  final bool amplifyConfigured; // Recebe o estado de configuração do Amplify

  const AccountScreen(
      {super.key,
      required this.amplifyConfigured}); // Construtor para receber amplifyConfigured

  @override
  AccountScreenState createState() => AccountScreenState();
}

class AccountScreenState extends State<AccountScreen>
    with SingleTickerProviderStateMixin {
  final Logger logger =
      Logger(); // Instância do logger para registrar mensagens
  late AnimationController _animationController;
  late Animation<Color?> _buttonColorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200), // Animação rápida
    );
    _buttonColorAnimation = ColorTween(
      begin: Colors.amber[700],
      end: Colors.amber[400],
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Função para realizar o logout usando Amplify Auth e redirecionar para a tela de login
  Future<void> _logout() async {
    try {
      await Amplify.Auth.signOut(); // Desloga o usuário do Cognito

      if (!mounted) return; // Verifica se o widget está montado antes de navegar

      _navigateToLogin(); // Navega para a tela de login
    } catch (e) {
      logger.e('Erro ao deslogar: $e');

      if (!mounted) return; // Verifica se o widget está montado antes de exibir a mensagem

      _showLogoutError(e); // Exibe mensagem de erro
    }
  }

  // Método auxiliar para navegação
  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(amplifyConfigured: widget.amplifyConfigured),
      ),
    );
  }

// Método auxiliar para exibir mensagem de erro
void _showLogoutError(dynamic error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Erro ao deslogar: $error')),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Minha Conta',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Exibir informações de cadastro do usuário (pode ser estático ou dinâmico)
            Text('Nome: João da Silva', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('Email: joao.silva@email.com', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('Data de Nascimento: 10/05/1985',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 40),
            // Botão de logout com animação
            GestureDetector(
              onTapDown: (_) => _animationController.forward(),
              onTapUp: (_) {
                _animationController.reverse();
                _logout(); // Chama a função de logout
              },
              child: AnimatedBuilder(
                animation: _buttonColorAnimation,
                builder: (context, child) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: _buttonColorAnimation.value,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      padding:
                          EdgeInsets.symmetric(vertical: 17, horizontal: 27),
                    ),
                    onPressed: () => _logout(), // Logout com Amplify
                    child: Text(
                      'SAIR',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
