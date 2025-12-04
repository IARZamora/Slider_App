import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const F1RacingGame());
}

class F1RacingGame extends StatelessWidget {
  const F1RacingGame({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'F1 Racing',
      theme: ThemeData(
        primarySwatch: Colors.red,
        brightness: Brightness.dark,
        fontFamily: 'RobotoCondensed',
      ),
      home: const MenuScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MenuScreen extends StatelessWidget {
  const MenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.shade900,
              Colors.black,
              Colors.grey.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Logo F1
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Text(
                  'F1',
                  style: TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 10,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'RACING',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 15,
                ),
              ),
              const Spacer(),
              // Botón de jugar
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GameScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 60,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red, Colors.red.shade700],
                    ),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Text(
                    'INICIAR CARRERA',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  double carPosition = 0.5;
  List<Obstacle> obstacles = [];
  List<Coin> coins = [];
  bool gameStarted = false;
  bool gameOver = false;
  int score = 0;
  int coinsCollected = 0;
  int level = 1;
  Timer? gameTimer;
  Timer? obstacleTimer;
  Timer? coinTimer;
  double obstacleSpeed = 0.012;
  double roadOffset = 0;

  late AnimationController _explosionController;
  bool showExplosion = false;
  double explosionX = 0;
  double explosionY = 0;

  @override
  void initState() {
    super.initState();
    _explosionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    startGame();
  }

  void startGame() {
    setState(() {
      gameStarted = true;
      gameOver = false;
      score = 0;
      coinsCollected = 0;
      level = 1;
      obstacles.clear();
      coins.clear();
      obstacleSpeed = 0.012;
    });

    gameTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      updateGame();
    });

    obstacleTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      addObstacle();
    });

    coinTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      addCoin();
    });
  }

  void addObstacle() {
    final random = Random();
    final lanes = [0.25, 0.5, 0.75];
    final type = random.nextInt(3);

    setState(() {
      obstacles.add(Obstacle(
        position: lanes[random.nextInt(lanes.length)],
        top: -0.1,
        type: type,
      ));
    });
  }

  void addCoin() {
    final random = Random();
    final lanes = [0.25, 0.5, 0.75];

    setState(() {
      coins.add(Coin(
        position: lanes[random.nextInt(lanes.length)],
        top: -0.1,
      ));
    });
  }

  void updateGame() {
    if (gameOver) return;

    setState(() {
      roadOffset += obstacleSpeed * 100;
      if (roadOffset > 100) roadOffset = 0;

      // Actualizar obstáculos
      for (var i = obstacles.length - 1; i >= 0; i--) {
        obstacles[i].top += obstacleSpeed;

        if (obstacles[i].top > 1.1) {
          obstacles.removeAt(i);
          score += 15;

          if (score > 0 && score % 100 == 0) {
            level++;
            obstacleSpeed += 0.002;
          }
        } else if (obstacles[i].top > 0.65 &&
            obstacles[i].top < 0.85 &&
            (obstacles[i].position - carPosition).abs() < 0.12) {
          explosionX = carPosition;
          explosionY = 0.75;
          showExplosion = true;
          _explosionController.forward(from: 0);
          endGame();
        }
      }

      // Actualizar monedas
      for (var i = coins.length - 1; i >= 0; i--) {
        coins[i].top += obstacleSpeed;

        if (coins[i].top > 1.1) {
          coins.removeAt(i);
        } else if (coins[i].top > 0.65 &&
            coins[i].top < 0.85 &&
            (coins[i].position - carPosition).abs() < 0.12 &&
            !coins[i].collected) {
          coins[i].collected = true;
          coinsCollected++;
          score += 25;
          coins.removeAt(i);
        }
      }
    });
  }

  void endGame() {
    setState(() {
      gameOver = true;
    });
    gameTimer?.cancel();
    obstacleTimer?.cancel();
    coinTimer?.cancel();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        showGameOverDialog();
      }
    });
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.red.shade900, Colors.black],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '¡CARRERA TERMINADA!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Icon(Icons.stars, color: Colors.amber, size: 40),
                      const SizedBox(height: 10),
                      Text(
                        '$score',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'PUNTOS',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.yellow, size: 40),
                      const SizedBox(height: 10),
                      Text(
                        '$coinsCollected',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'MONEDAS',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('MENÚ'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          showExplosion = false;
                        });
                        startGame();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('REINTENTAR'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void moveLeft() {
    if (!gameStarted || gameOver) return;
    setState(() {
      if (carPosition > 0.25) carPosition -= 0.25;
    });
  }

  void moveRight() {
    if (!gameStarted || gameOver) return;
    setState(() {
      if (carPosition < 0.75) carPosition += 0.25;
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    obstacleTimer?.cancel();
    coinTimer?.cancel();
    _explosionController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              Colors.grey.shade800,
              Colors.grey.shade900,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Carretera con líneas animadas
            ...List.generate(10, (index) {
              return Positioned(
                left: screenWidth / 2 - 3,
                top: (index * 100.0 - roadOffset) % screenHeight,
                child: Container(
                  width: 6,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),

            // Bordes de la carretera
            Positioned(
              left: screenWidth * 0.1,
              top: 0,
              bottom: 0,
              child: Container(
                width: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red, Colors.white, Colors.red],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              right: screenWidth * 0.1,
              top: 0,
              bottom: 0,
              child: Container(
                width: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red, Colors.white, Colors.red],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Monedas
            ...coins.map((coin) {
              return Positioned(
                left: screenWidth * coin.position - 20,
                top: screenHeight * coin.top,
                child: AnimatedOpacity(
                  opacity: coin.collected ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amber,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.monetization_on,
                      color: Colors.yellow,
                      size: 30,
                    ),
                  ),
                ),
              );
            }).toList(),

            // Obstáculos (otros autos F1)
            ...obstacles.map((obstacle) {
              return Positioned(
                left: screenWidth * obstacle.position - 25,
                top: screenHeight * obstacle.top,
                child: F1Car(
                  color: obstacle.type == 0
                      ? Colors.red
                      : obstacle.type == 1
                      ? Colors.green
                      : Colors.orange,
                  isPlayer: false,
                ),
              );
            }).toList(),

            // Explosión
            if (showExplosion)
              Positioned(
                left: screenWidth * explosionX - 50,
                top: screenHeight * explosionY - 50,
                child: AnimatedBuilder(
                  animation: _explosionController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1 + _explosionController.value * 2,
                      child: Opacity(
                        opacity: 1 - _explosionController.value,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.yellow,
                                Colors.orange,
                                Colors.red,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Carro del jugador
            if (gameStarted)
              Positioned(
                left: screenWidth * carPosition - 25,
                bottom: 120,
                child: const F1Car(
                  color: Colors.blue,
                  isPlayer: true,
                ),
              ),

            // HUD Superior
            if (gameStarted && !gameOver)
              Positioned(
                top: 40,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Puntuación
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red, width: 2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.stars, color: Colors.amber, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              '$score',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Nivel
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: Text(
                          'NIVEL $level',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Monedas
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber, width: 2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.monetization_on,
                                color: Colors.yellow, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              '$coinsCollected',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Controles
            if (gameStarted && !gameOver)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: moveLeft,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.red, Colors.red.shade700],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 45,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: moveRight,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.red, Colors.red.shade700],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class F1Car extends StatelessWidget {
  final Color color;
  final bool isPlayer;

  const F1Car({
    Key? key,
    required this.color,
    required this.isPlayer,
  }) : super(key: key);

  String getCarImage() {
    if (isPlayer) {
      return 'assets/images/cadillac_f1.jpeg';
    } else {
      return 'assets/images/william_f1.jpg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 90,
      child: Stack(
        children: [
          // Sombra del auto
          Positioned(
            bottom: 0,
            left: 5,
            right: 5,
            child: Container(
              height: 15,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          // Imagen del auto F1
          Center(
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: isPlayer ? Colors.blue.withOpacity(0.5) : color.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Image.asset(
                getCarImage(),
                width: 70,
                height: 70,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Si falla la carga de imagen, mostrar auto dibujado
                  debugPrint('❌ Error: $error');
                  return Container(
                    width: 50,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          isPlayer ? Colors.blue : color,
                          isPlayer ? Colors.blue.shade700 : color.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: (isPlayer ? Colors.blue : color).withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      color: Colors.white,
                      size: 35,
                    ),
                  );
                },
              ),
            ),
          ),
          // Número del piloto
          if (isPlayer)
            Positioned(
              bottom: 5,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Text(
                    '1',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class Obstacle {
  double position;
  double top;
  int type;

  Obstacle({
    required this.position,
    required this.top,
    required this.type,
  });
}

class Coin {
  double position;
  double top;
  bool collected;

  Coin({
    required this.position,
    required this.top,
    this.collected = false,
  });
}