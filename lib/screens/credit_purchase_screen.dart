import 'package:chopeira_smart_app/screens/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'card_registration_screen.dart';
import 'account_screen.dart'; // Tela de Conta
import 'drink_selection_screen.dart';
import 'package:logger/logger.dart';

class CreditPurchaseScreen extends StatefulWidget {
  final bool amplifyConfigured;

  const CreditPurchaseScreen({super.key, required this.amplifyConfigured});

  @override
  CreditPurchaseScreenState createState() => CreditPurchaseScreenState();
}

class CreditPurchaseScreenState extends State<CreditPurchaseScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  double userCredits = 0.00;

  late AnimationController _animationController;
  late Animation<Color?> _buttonColorAnimation;
  final Logger logger = Logger();

  // Lista de cartões registrados (exemplo estático)
  final List<String> _registeredCards = ['Cartão Pessoal', 'Cartão Empresarial']; 
  String? _selectedCard; // Cartão selecionado pelo usuário
  String? _paymentMethod; // Método de pagamento selecionado

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _buttonColorAnimation = ColorTween(
      begin: Colors.amber[700],
      end: Colors.amber[400],
    ).animate(_animationController);

    // Adicione todas as telas aqui
    _screens = [
      _buildCreditPurchaseView(), // Tela de compra de créditos
      CardRegistrationScreen(), // Tela de cadastro de cartão
      HistoryScreen(), // Tela de histórico de consumo
      AccountScreen(amplifyConfigured: widget.amplifyConfigured), // Tela de conta
      DrinkSelectionScreen(),
    ];

    // Chama a função para buscar créditos disponíveis
    _fetchCredits();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchCredits() async {
    try {
      final CognitoAuthSession session =
          await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;

      if (session.isSignedIn) {
        final tokens = session.userPoolTokensResult.value;

        // Verifica se os tokens estão disponíveis
        // ignore: unnecessary_null_comparison
        if (tokens != null) {
          String idToken = tokens.idToken.raw;

          final response = await http.get(
            Uri.parse(
                'https://a28uu538mc.execute-api.us-east-1.amazonaws.com/Dev/api/cliente/creditos'),
            headers: {
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
            },
          );

          if (response.statusCode == 200) {
            var data = jsonDecode(response.body);
            setState(() {
              userCredits = data['creditos'];
            });
          } else {
            logger.e('Erro ao buscar créditos: ${response.statusCode}');
          }
        } else {
          logger.i('Tokens não disponíveis.');
        }
      } else {
        logger.i('Usuário não está autenticado.');
      }
    } catch (e) {
      logger.e('Erro ao buscar créditos: $e');
    }
  }

  // Tela de compra de créditos
  Widget _buildCreditPurchaseView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 20),
          Image.asset(
            'assets/images/logo2.png',
            height: 250,
          ),
          SizedBox(height: 20),
          Center(
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Créditos Disponíveis',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'R\$ ${userCredits.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          AnimatedBuilder(
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
                onPressed: _showPaymentOptions, // Chama a função para abrir o modal
                child: Text(
                  'COMPRAR CRÉDITOS',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Modal para selecionar o cartão e o método de pagamento
 void _showPaymentOptions() {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Reduz o tamanho do modal
          children: [
            Text(
              'Escolha o cartão e método de pagamento',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            DropdownButton<String>(
              hint: Text('Selecione um cartão'),
              value: _selectedCard,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCard = newValue!;
                });
              },
              items: _registeredCards.map((String card) {
                return DropdownMenuItem<String>(
                  value: card,
                  child: Text(card),
                );
              }).toList(),
            ),
            SizedBox(height: 10),
            ListTile(
              leading: Radio<String>(
                value: 'Crédito',
                groupValue: _paymentMethod,
                onChanged: (String? value) {
                  setState(() {
                    _paymentMethod = value;
                  });
                },
              ),
              title: Text('Crédito'),
            ),
            ListTile(
              leading: Radio<String>(
                value: 'Débito',
                groupValue: _paymentMethod,
                onChanged: (String? value) {
                  setState(() {
                    _paymentMethod = value;
                  });
                },
              ),
              title: Text('Débito'),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTapDown: (_) => _animationController.forward(),
              onTapUp: (_) {
                _animationController.reverse();
                if (_selectedCard != null && _paymentMethod != null) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pagamento processado com $_selectedCard via $_paymentMethod'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Selecione um cartão e método de pagamento.')),
                  );
                }
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
                    onPressed: () {
                      if (_selectedCard != null && _paymentMethod != null) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Pagamento processado com $_selectedCard via $_paymentMethod'),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Selecione um cartão e método de pagamento.')),
                        );
                      }
                    },
                    child: Text(
                      'Confirmar',
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
      );
    },
  );
}

  // Controla a mudança de página com o BottomNavigationBar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(index, // Faz a transição suave para a página
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _screens, // As telas são definidas aqui
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black87,
        unselectedItemColor: Colors.black54,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: 'Cartão',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Histórico',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Conta',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_drink),
            label: 'Bebidas',
          ),
        ],
      ),
    );
  }
}

