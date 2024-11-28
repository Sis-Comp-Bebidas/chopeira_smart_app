import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'credit_purchase_screen.dart';
import 'package:logger/logger.dart';

class ConfirmAccountScreen extends StatefulWidget {
  final String email; // O email do usuário será passado para a confirmação

  const ConfirmAccountScreen({super.key, required this.email});

  @override
  ConfirmAccountScreenState createState() => ConfirmAccountScreenState();
}

class ConfirmAccountScreenState extends State<ConfirmAccountScreen>
    with SingleTickerProviderStateMixin {
  final _confirmationCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _animationController;
  late Animation<Color?> _buttonColorAnimation;
  final Logger logger = Logger();

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
    _confirmationCodeController.dispose();
    super.dispose();
  }

  Future<void> _confirmSignUp() async {
    if (_formKey.currentState?.validate() == true) {
      try {
        // Chama a função para confirmar o cadastro
        SignUpResult res = await Amplify.Auth.confirmSignUp(
          username: widget.email, // O email que foi registrado
          confirmationCode: _confirmationCodeController.text.trim(),
        );

        if (res.isSignUpComplete) {
          // Navega para a tela de compra de créditos após a confirmação
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CreditPurchaseScreen(amplifyConfigured: true),
            ),
          );
        }
      } catch (e) {
        logger.e('Erro ao confirmar conta: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao confirmar a conta: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Confirmar Conta')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Insira o código enviado para o email: ${widget.email}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _confirmationCodeController,
                decoration: InputDecoration(
                  labelText: 'Código de Confirmação',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'O código de confirmação é obrigatório';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTapDown: (_) => _animationController.forward(),
                onTapUp: (_) {
                  _animationController.reverse();
                  _confirmSignUp();
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
                        padding: EdgeInsets.symmetric(
                            vertical: 17, horizontal: 27),
                      ),
                      onPressed: _confirmSignUp,
                      child: Text(
                        'CONFIRMAR',
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
      ),
    );
  }
}
