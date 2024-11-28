import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class BeerFillingAnimationScreen extends StatefulWidget {
  const BeerFillingAnimationScreen({super.key});

  @override
  BeerFillingAnimationScreenState createState() => BeerFillingAnimationScreenState();
}

class BeerFillingAnimationScreenState extends State<BeerFillingAnimationScreen> with TickerProviderStateMixin {
  late AnimationController _waveController; // Controlador para o movimento das ondas
  late AnimationController _fillController; // Controlador para o preenchimento suave
  late Animation<double> _fillAnimation; // Animação para o preenchimento suave
  late AnimationController _logoController; // Controlador da animação da logo
  late Animation<double> _logoAnimation; // Animação da opacidade da logo
  late Timer _bubbleTimer; // Timer para criar bolhas

  final List<Bubble> _bubbles = []; // Lista de bolhas

  @override
  void initState() {
    super.initState();

    // Inicializa o controlador para o movimento das ondas
    _waveController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1), // Ciclo mais rápido para ondas mais fluidas
    )..repeat(); // Repetir indefinidamente para simular o movimento das ondas

    // Controlador para o preenchimento suave do chopp
    _fillController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 6), // Duração total para o preenchimento mais suave
    );

    // Animação curva para suavizar o preenchimento
    _fillAnimation = CurvedAnimation(
      parent: _fillController,
      curve: Curves.easeInOut, // Preenchimento mais suave, começa devagar, acelera, e desacelera
    );

    // Inicializa o AnimationController para a animação da logo
    _logoController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    // Configura a animação da opacidade da logo
    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_logoController);

    // Inicia o preenchimento
    _startFillingAnimation();

    // Inicia o timer para criar bolhas
    _bubbleTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      setState(() {
        _bubbles.add(Bubble()); // Adiciona uma nova bolha
      });
    });
  }

  void _startFillingAnimation() {
    // Inicia o controlador de preenchimento suave
    _fillController.forward().whenComplete(() {
      // Quando o nível atingir 50%, começa a animação da logo
      _logoController.forward();
      // Quando o preenchimento atingir o topo, navega para a próxima tela
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      });
    });
  
    // Ajusta o ponto de início da logo para 0,37 (um pouco antes)
    _fillController.addListener(() {
       if (_fillController.value >= 0.42 && !_logoController.isAnimating) {
         _logoController.forward();
       }
    });
  }

  @override
  void dispose() {
    _waveController.dispose(); // Libera o controlador das ondas
    _fillController.dispose(); // Libera o controlador de preenchimento
    _logoController.dispose(); // Libera o controlador da logo
    _bubbleTimer.cancel(); // Cancela o timer de bolhas
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fundo branco
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Animação do preenchimento suave com a onda se mexendo
          AnimatedBuilder(
            animation: _fillAnimation,
            builder: (context, _) {
              return ClipPath(
                clipper: BeerWaveClipper(_fillAnimation.value, _waveController.value), // Clipper para criar a onda em movimento
                child: Container(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  color: Colors.amber.withOpacity(0.7), // Cor do "chopp"
                ),
              );
            },
          ),
          // Bolhas subindo
          ..._bubbles.map((bubble) => AnimatedBubble(bubble: bubble)),
          // Animação da logo aparecendo aos poucos no centro
          FadeTransition(
            opacity: _logoAnimation,
            child: Image.asset(
              'assets/images/logo2.png', // Caminho para a logo fornecida
              width: 400, // Tamanho da logo
              height: 400,
            ),
          ),
        ],
      ),
    );
  }
}

// Clipper personalizado para criar o efeito de onda
class BeerWaveClipper extends CustomClipper<Path> {
  final double fillLevel;
  final double waveShift;

  BeerWaveClipper(this.fillLevel, this.waveShift);

  @override
  Path getClip(Size size) {
    final Path path = Path();
    final double fillHeight = size.height * fillLevel;

    // Desenha a onda de baixo para cima
    path.lineTo(0.0, size.height - fillHeight);

    final double waveHeight = 30.0;
    final double waveFrequency = 2 * math.pi / size.width;

    // Cria uma onda no topo do "chopp" que se mexe com a variável waveShift
    for (double i = 0.0; i <= size.width; i++) {
      path.lineTo(
        i,
        size.height - fillHeight + math.sin((i * waveFrequency) + (waveShift * 2 * math.pi)) * waveHeight,
      );
    }

    // Fecha o caminho até o topo da tela
    path.lineTo(size.width, size.height);
    path.lineTo(0.0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true; // Redesenha sempre que o nível do preenchimento ou o shift da onda mudar
  }
}

// Classe que representa uma bolha
class Bubble {
  final double size = math.Random().nextDouble() * 40 + 10; // Tamanho aleatório da bolha
  final double startX = math.Random().nextDouble(); // Posição inicial aleatória
  final double speed = math.Random().nextDouble() * 2 + 1; // Velocidade aleatória

  Bubble();
}

// Widget que anima a subida da bolha
class AnimatedBubble extends StatefulWidget {
  final Bubble bubble;

  const AnimatedBubble({super.key, required this.bubble});

  @override
  AnimatedBubbleState createState() => AnimatedBubbleState();
}

class AnimatedBubbleState extends State<AnimatedBubble> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animationY;
  late Animation<double> _animationX;

  @override
  void initState() {
    super.initState();

    // Controlador para a animação da bolha
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: (10 / widget.bubble.speed).round()), // A duração depende da velocidade da bolha
    )..repeat(reverse: false); // A bolha sobe e repete

    // Animação vertical da bolha
    _animationY = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    // Animação horizontal para sincronizar o movimento com as ondas
    _animationX = Tween<double>(begin: widget.bubble.startX, end: widget.bubble.startX + 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // Libera o controlador da bolha
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: MediaQuery.of(context).size.width * _animationX.value,
          top: MediaQuery.of(context).size.height * _animationY.value,
          child: Opacity(
            opacity: 0.7, // Opacidade da bolha
            child: Container(
              width: widget.bubble.size,
              height: widget.bubble.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.3), // Bolha branca translúcida
              ),
            ),
          ),
        );
      },
    );
  }
}
