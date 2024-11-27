import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'amplifyconfiguration.dart';
import 'screens/login_screen.dart';
import 'screens/credit_purchase_screen.dart';
import 'screens/card_registration_screen.dart';
//import 'screens/qr_code_screen.dart';
import 'screens/beer_animation.dart';
import 'screens/history_screen.dart';
import 'screens/drink_selection_screen.dart';
import 'package:logger/logger.dart';

void main() {
  runApp(ChopeiraSmartApp());
}

class ChopeiraSmartApp extends StatefulWidget {
  const ChopeiraSmartApp({super.key});

  @override
  ChopeiraSmartAppState createState() => ChopeiraSmartAppState();
}

class ChopeiraSmartAppState extends State<ChopeiraSmartApp> with WidgetsBindingObserver {
  final Logger logger = Logger();  // Instância do logger para registrar mensagens
  bool _amplifyConfigured = false;

  @override
  void initState() {
    super.initState();
    _configureAmplify(); // Chama a função para configurar o Amplify
    WidgetsBinding.instance.addObserver(this);  // Adiciona o observer do ciclo de vida do app
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove o observer quando o app for encerrado
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached || state == AppLifecycleState.paused) {
      // O app foi fechado ou minimizado
      _signOutUser();
    }
  }

  Future<void> _signOutUser() async {
    try {
      await Amplify.Auth.signOut();
      logger.i('Usuário deslogado com sucesso');   // Log informativo
    } catch (e) {
      logger.e('Erro ao deslogar usuário: $e');    // Log de erro
    }
  }

  Future<void> _configureAmplify() async {
    try {
      // Adiciona o plugin de autenticação do Cognito
      await Amplify.addPlugin(AmplifyAuthCognito());

      // Configura o Amplify com o arquivo de configuração
      await Amplify.configure(amplifyconfig);

      setState(() {
        _amplifyConfigured = true; // Amplify foi configurado com sucesso
      });
      logger.i('Amplify configurado com sucesso'); // Log informativo
    } catch (e) {
      logger.e('Erro ao configurar o Amplify: $e'); // Log de erro
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chopeira Smart',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        hintColor: Colors.amber,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.yellow[100],
        appBarTheme: AppBarTheme(
          color: Colors.amber[200]
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.amber[100], // Cor de fundo do BottomNavigationBar
          selectedItemColor: Colors.black87, // Cor do item selecionado
          unselectedItemColor: Colors.black54, // Cor dos itens não selecionados
        ),
      ),
      debugShowCheckedModeBanner: false, // Remove o banner de debug
      initialRoute: '/beer_animation',
      routes: {
        '/beer_animation': (context) => Scaffold(appBar: null, body: BeerFillingAnimationScreen()),
        '/login': (context) => Scaffold(appBar: null, body: LoginScreen(amplifyConfigured: _amplifyConfigured)),
        '/home': (context) => Scaffold(appBar: null, body: CreditPurchaseScreen(amplifyConfigured: _amplifyConfigured)),
        '/card_registration': (context) => Scaffold(appBar: null, body: CardRegistrationScreen()),
        '/history_screen': (context) => Scaffold(appBar: null, body: HistoryScreen()),
        '/drink_selection': (context) => Scaffold(appBar: null, body: DrinkSelectionScreen()),
      },
    );
  }
}
