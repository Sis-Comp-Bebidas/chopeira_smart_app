import 'package:chopeira_smart_app/screens/app_logo.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:chopeira_smart_app/screens/confirm_account_screen.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  CreateAccountScreenState createState() => CreateAccountScreenState();
}

class CreateAccountScreenState extends State<CreateAccountScreen>
    with SingleTickerProviderStateMixin {
  final _firstNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isChecked = false;
  final _formKey = GlobalKey<FormState>();

  late AnimationController _animationController;
  late Animation<Color?> _buttonColorAnimation;
  final Logger logger = Logger();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _buttonColorAnimation = ColorTween(
      begin: Colors.amber[700],
      end: Colors.amber[400],
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _firstNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'O campo Senha é obrigatório';
    }
    String pattern = r'^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#])[A-Za-z\d@$!%*?&#]{8,}$';
    RegExp regex = RegExp(pattern);
    if (!regex.hasMatch(value)) {
      return 'A senha deve ter pelo menos 8 caracteres,\ncom uma letra maiúscula, um número e um símbolo';
    }
    return null;
  }

  String? _validateDob(String? value) {
    if (value == null || value.isEmpty) {
      return 'O campo Data de Nascimento é obrigatório';
    }
    if (value.length != 10) {
      return 'Formato de data inválido';
    }

    final day = int.tryParse(value.substring(0, 2));
    final month = int.tryParse(value.substring(3, 5));
    final year = int.tryParse(value.substring(6, 10));

    if (day == null || day < 1 || day > 31) {
      return 'Dia inválido';
    }
    if (month == null || month < 1 || month > 12) {
      return 'Mês inválido';
    }
    if (year == null || year < 1901 || year > 2005) {
      return 'Ano inválido';
    }
    return null;
  }

  Future<void> _registerUser() async {
    if (_formKey.currentState?.validate() == true && _isChecked) {
      try {
        SignUpResult res = await Amplify.Auth.signUp(
          username: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          options: SignUpOptions(userAttributes: {
            CognitoUserAttributeKey.email: _emailController.text.trim(),
            CognitoUserAttributeKey.phoneNumber: _phoneController.text.trim(),
            CognitoUserAttributeKey.name: _firstNameController.text.trim(),
            CognitoUserAttributeKey.birthdate: _dobController.text.trim(),
          }),
        );
        if (res.isSignUpComplete || !res.isSignUpComplete) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ConfirmAccountScreen(email: _emailController.text.trim()),
            ),
          );
        }
      } catch (e) {
        logger.e('Erro ao registrar: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao cadastrar: $e')),
        );
      }
    } else if (!_isChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Você deve aceitar os Termos de Uso e Políticas de Privacidade.')),
      );
    }
  }

  void _openTermsOfUse() {
    logger.i("Abrir Termos de Uso");
  }

  void _openPrivacyPolicy() {
    logger.i("Abrir Políticas de Privacidade");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Criar Conta')),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/beer2.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  AppLogo(),
                  SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _firstNameController,
                            decoration: InputDecoration(
                              labelText: 'Nome',
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'O campo Nome é obrigatório';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 10),
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
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'O campo Email é obrigatório';
                              } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                return 'Por favor, insira um email válido';
                              }
                              return null;
                            },
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
                            validator: _validatePassword,
                          ),
                          SizedBox(height: 10),
                          TextFormField(
                            controller: _dobController,
                            decoration: InputDecoration(
                              labelText: 'Data de Nascimento',
                              hintText: 'DD/MM/AAAA',
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            keyboardType: TextInputType.datetime,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(8),
                              TextInputFormatter.withFunction((oldValue, newValue) {
                                String text = newValue.text;
                                if (text.length >= 2 && text.length < 5) {
                                  text = '${text.substring(0, 2)}/${text.substring(2)}';
                                } else if (text.length >= 5) {
                                  text = '${text.substring(0, 2)}/${text.substring(2, 4)}/${text.substring(4)}';
                                }
                                return TextEditingValue(
                                  text: text,
                                  selection: TextSelection.collapsed(offset: text.length),
                                );
                              }),
                            ],
                            validator: _validateDob,
                          ),
                          SizedBox(height: 10),
                          TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: 'Telefone',
                              hintText: '11 99999-9999',
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                              TextInputFormatter.withFunction((oldValue, newValue) {
                                String text = newValue.text;
                                if (text.length >= 6) {
                                  text = '${text.substring(0, 2)} ${text.substring(2, 7)}-${text.substring(7)}';
                                } else if (text.length >= 2) {
                                  text = '${text.substring(0, 2)} ${text.substring(2)}';
                                }
                                return TextEditingValue(
                                  text: text,
                                  selection: TextSelection.collapsed(offset: text.length),
                                );
                              }),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'O campo Telefone é obrigatório';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _isChecked,
                                onChanged: (value) {
                                  setState(() {
                                    _isChecked = value ?? false;
                                  });
                                },
                              ),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    text: 'Declaro que tenho mais de 18 anos, li e aceito os ',
                                    style: TextStyle(color: Colors.black),
                                    children: [
                                      TextSpan(
                                        text: 'Termos de Uso',
                                        style: TextStyle(
                                          color: Colors.amber,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()..onTap = _openTermsOfUse,
                                      ),
                                      TextSpan(
                                        text: ' e ',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                      TextSpan(
                                        text: 'Políticas de Privacidade',
                                        style: TextStyle(
                                          color: Colors.amber,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()..onTap = _openPrivacyPolicy,
                                      ),
                                      TextSpan(
                                        text: '.',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          GestureDetector(
                            onTapDown: (_) => _animationController.forward(),
                            onTapUp: (_) {
                              _animationController.reverse();
                              _registerUser();
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
                                  onPressed: _registerUser,
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
