import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

// Tela de cadastro de cartão como um StatefulWidget para gerenciar o estado dos campos de entrada
class CardRegistrationScreen extends StatefulWidget {
  const CardRegistrationScreen({super.key});

  @override
  CardRegistrationScreenState createState() => CardRegistrationScreenState();
}

class CardRegistrationScreenState extends State<CardRegistrationScreen>
    with SingleTickerProviderStateMixin {
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderNameController = TextEditingController();
  final _cardNicknameController = TextEditingController(); // Novo campo para o apelido

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
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardHolderNameController.dispose();
    _cardNicknameController.dispose(); // Dispor do controlador de apelido
    super.dispose();
  }

  void _registerCard() {
    // Lógica para registrar o cartão, armazenar os detalhes do cartão, incluindo o apelido
    final String cardNumber = _cardNumberController.text;
    final String expiryDate = _expiryDateController.text;
    final String cvv = _cvvController.text;
    final String cardHolderName = _cardHolderNameController.text;
    final String cardNickname = _cardNicknameController.text;

    // Salvar os detalhes do cartão no backend ou localmente.

    logger.i("Cartão registrado: Número: $cardNumber, Apelido: $cardNickname, Titular: $cardHolderName, Expiração: $expiryDate, CVV: $cvv");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/beer3.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(height: 60),
              Text(
                'Cadastro de Cartão',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              _buildTextField(_cardNumberController, 'Número do Cartão'),
              _buildTextField(_expiryDateController, 'Data de Expiração (MM/AA)'),
              _buildTextField(_cvvController, 'CVV', obscureText: true),
              _buildTextField(_cardHolderNameController, 'Nome do Titular'),
              _buildTextField(_cardNicknameController, 'Apelido do Cartão'), // Novo campo
              SizedBox(height: 20),
              GestureDetector(
                onTapDown: (_) => _animationController.forward(),
                onTapUp: (_) {
                  _animationController.reverse();
                  _registerCard(); // Chama a função de registrar o cartão
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
                        padding: EdgeInsets.symmetric(vertical: 17, horizontal: 27),
                      ),
                      onPressed: _registerCard,
                      child: Text(
                        'REGISTRAR CARTÃO',
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

  // Função auxiliar para construir TextFields
  Widget _buildTextField(
    TextEditingController controller,
    String labelText, {
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        obscureText: obscureText,
      ),
    );
  }
}
