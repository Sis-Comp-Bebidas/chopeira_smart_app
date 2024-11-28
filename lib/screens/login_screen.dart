// Importa a chave correta para os atributos do usuário
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart'; // Acessa AuthUserAttribute e AuthUserAttributeKey
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:http/http.dart' as http; // Add package to handle HTTP requests
import 'dart:convert';
import 'credit_purchase_screen.dart'; // Tela de compra de créditos
import 'create_account_screen.dart'; // Tela de criar conta
import 'app_logo.dart'; // Logo personalizada
import 'package:logger/logger.dart';

class LoginScreen extends StatefulWidget {
  final bool amplifyConfigured;

  const LoginScreen({super.key, required this.amplifyConfigured});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Função para enviar o token JWT e o JSON com atributos do usuário para o API Gateway
  Future<void> _sendJwtToApiGateway(String jwtToken, String jsonBody) async {
    final apiUrl =
        'https://a28uu538mc.execute-api.us-east-1.amazonaws.com/Dev/api/cliente/cadastro'; // API Gateway URL

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization':
              jwtToken, // Envia o token JWT no cabeçalho Authorization
          'Content-Type': 'application/json',
        },
        body: jsonBody, // Envia o corpo JSON na requisição
      );

      if (response.statusCode == 200) {
        // Sucesso na requisição
        final responseData = jsonDecode(response.body);
        logger.i('Resposta da API: $responseData');
      } else {
        logger.e('Erro ao enviar a requisição: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Erro ao enviar o token JWT e os dados para a API Gateway: $e');
    }
  }

// Função de login usando o Amplify Auth
  Future<void> _loginUser() async {
    if (!widget.amplifyConfigured) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'O sistema está sendo configurado. Tente novamente em breve.')),
        );
      }
      return;
    }

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Por favor, preencha seu e-mail e senha.')),
        );
      }
      return;
    }

    try {
      // Faz o login com o Cognito
      SignInResult result = await Amplify.Auth.signIn(
        username: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (result.isSignedIn) {
        // Obtém a sessão do usuário para acessar o token JWT
        var session =
            await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;

        // ignore: unnecessary_null_comparison
        if (session.userPoolTokensResult.value != null) {
          String jwtToken = session.userPoolTokensResult.value.idToken.raw;

          var userAttributes = await Amplify.Auth.fetchUserAttributes();

          var subAttribute = userAttributes.firstWhere(
            (attr) => attr.userAttributeKey == AuthUserAttributeKey.sub,
            orElse: () => AuthUserAttribute(
                userAttributeKey: AuthUserAttributeKey.sub, value: ''),
          );

          if (subAttribute.value.isNotEmpty) {
            String userId = subAttribute.value;
            String name = userAttributes
                .firstWhere(
                  (attr) => attr.userAttributeKey == AuthUserAttributeKey.name,
                  orElse: () => AuthUserAttribute(
                      userAttributeKey: AuthUserAttributeKey.name, value: ''),
                )
                .value;
            String email = userAttributes
                .firstWhere(
                  (attr) => attr.userAttributeKey == AuthUserAttributeKey.email,
                  orElse: () => AuthUserAttribute(
                      userAttributeKey: AuthUserAttributeKey.email, value: ''),
                )
                .value;
            String birthdate = userAttributes
                .firstWhere(
                  (attr) =>
                      attr.userAttributeKey == AuthUserAttributeKey.birthdate,
                  orElse: () => AuthUserAttribute(
                      userAttributeKey: AuthUserAttributeKey.birthdate,
                      value: ''),
                )
                .value;
            String phoneNumber = userAttributes
                .firstWhere(
                  (attr) =>
                      attr.userAttributeKey == AuthUserAttributeKey.phoneNumber,
                  orElse: () => AuthUserAttribute(
                      userAttributeKey: AuthUserAttributeKey.phoneNumber,
                      value: ''),
                )
                .value;

            Map<String, dynamic> requestBody = {
              "userId": userId,
              "payload": {
                "name": name,
                "email": email,
                "birthdate": birthdate,
                "phone_number": phoneNumber,
              }
            };

            String jsonBody = jsonEncode(requestBody);

            await _sendJwtToApiGateway(jwtToken, jsonBody);

            if (mounted) {
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (context) {
                  return CreditPurchaseScreen(
                    amplifyConfigured: widget.amplifyConfigured,
                  );
                },
              ));
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Não foi possível obter suas informações. Tente novamente.')),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Não foi possível obter o token JWT. Por favor, tente novamente.')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Verifique suas credenciais e tente novamente.')),
          );
        }
      }
    } catch (e) {
      logger.e('Erro ao fazer login: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Não foi possível realizar o login. Por favor, tente novamente.')),
        );
      }
    }
  }

  void _createAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateAccountScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/beer.jpeg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 80), // Espaço maior no topo
                AppLogo(), // Logo da aplicação
                SizedBox(
                    height: 10), // Menor espaço entre a logo e o widget branco
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'LOGIN',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      GestureDetector(
                        onTapDown: (_) => _animationController.forward(),
                        onTapUp: (_) {
                          _animationController.reverse();
                          _loginUser();
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
                              onPressed: _loginUser,
                              child: Text(
                                'ENTRAR',
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
                      SizedBox(height: 20),
                      Text(
                        'AINDA NÃO POSSUI UMA CONTA? CADASTRE-SE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      GestureDetector(
                        onTapDown: (_) => _animationController.forward(),
                        onTapUp: (_) {
                          _animationController.reverse();
                          _createAccount();
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
                              onPressed: _createAccount,
                              child: Text(
                                'CRIAR CONTA',
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
