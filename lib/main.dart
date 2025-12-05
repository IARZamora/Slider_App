import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const SliderF1App());
}

class SliderF1App extends StatelessWidget {
  const SliderF1App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slider F1',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark),
      home: const ScenarioSelectScreen(),
    );
  }
}

/* ==========================
   SELECTOR DE ESCENARIO
   ========================== */

class ScenarioSelectScreen extends StatelessWidget {
  const ScenarioSelectScreen({super.key});

  final List<Map<String, String>> scenarios = const [
    {"name": "México", "img": "assets/images/mex.png"},
    {"name": "Mónaco", "img": "assets/images/mon.png"},
    {"name": "Baréin", "img": "assets/images/bar.jpeg"},
    {"name": "Azerbaiyán", "img": "assets/images/aze.jpeg"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Seleccionar escenario"), backgroundColor: Colors.red),
      body: GridView.builder(
        padding: const EdgeInsets.all(18),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1),
        itemCount: scenarios.length,
        itemBuilder: (context, index) {
          final s = scenarios[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => GameScreen(backgroundPath: s["img"]!, scenarioName: s["name"]!),
              ));
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                image: DecorationImage(image: AssetImage(s["img"]!), fit: BoxFit.cover),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 8)],
              ),
              child: Container(
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.6), Colors.transparent]),
                ),
                child: Text(s["name"]!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
          );
        },
      ),
    );
  }
}

/* ==========================
   PANTALLA DE JUEGO (UN SOLO ARCHIVO)
   ========================== */

class GameScreen extends StatefulWidget {
  final String backgroundPath;
  final String scenarioName;
  const GameScreen({super.key, required this.backgroundPath, required this.scenarioName});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // player lane position (0..1)
  double carPosition = 0.5;

  // game objects
  List<Obstacle> obstacles = [];
  List<Coin> coins = [];
  List<FuelCan> fuelCans = [];

  // state
  bool gameOver = false;
  int score = 0;
  int coinsCollected = 0;

  // fuel
  double fuel = 100.0;
  final double fuelConsumePerTick = 0.045; // per game tick ~30ms

  // timers
  Timer? gameTimer;
  Timer? spawnTimer;
  Timer? fuelSpawnTimer;

  // visual
  double roadOffset = 0.0;
  double obstacleSpeed = 0.012;

  final Random rng = Random();

  late AnimationController explosionController;

  @override
  void initState() {
    super.initState();
    explosionController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    startGame();
  }

  void startGame() {
    setState(() {
      gameOver = false;
      score = 0;
      coinsCollected = 0;
      fuel = 100.0;
      carPosition = 0.5;
      obstacles.clear();
      coins.clear();
      fuelCans.clear();
      roadOffset = 0.0;
      obstacleSpeed = 0.012;
    });

    gameTimer?.cancel();
    spawnTimer?.cancel();
    fuelSpawnTimer?.cancel();

    gameTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      updateGame();
    });

    spawnTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      addObstacle();
      if (rng.nextBool()) addCoin();
    });

    // schedule fuel can rarer than coins
    scheduleNextFuelCan();
  }

  void scheduleNextFuelCan() {
    fuelSpawnTimer?.cancel();
    final seconds = 10 + rng.nextInt(8); // 10..17 s
    fuelSpawnTimer = Timer(Duration(seconds: seconds), () {
      addFuelCan();
      scheduleNextFuelCan();
    });
  }

  void addObstacle() {
    final lanes = [0.2, 0.5, 0.8];
    obstacles.add(Obstacle(position: lanes[rng.nextInt(lanes.length)], top: -0.18, type: rng.nextInt(2)));
  }

  void addCoin() {
    final lanes = [0.2, 0.5, 0.8];
    coins.add(Coin(position: lanes[rng.nextInt(lanes.length)], top: -0.18));
  }

  void addFuelCan() {
    final lanes = [0.2, 0.5, 0.8];
    fuelCans.add(FuelCan(position: lanes[rng.nextInt(lanes.length)], top: -0.18));
  }

  void updateGame() {
    if (gameOver) return;

    setState(() {
      // fuel consumption
      fuel -= fuelConsumePerTick;
      if (fuel <= 0) {
        fuel = 0;
        endGame();
        return;
      }

      // road animation
      roadOffset += obstacleSpeed * 100;
      if (roadOffset > 100000) roadOffset = roadOffset % 100000;

      // update obstacles
      for (int i = obstacles.length - 1; i >= 0; i--) {
        obstacles[i].top += obstacleSpeed;
        if (obstacles[i].top > 1.25) {
          obstacles.removeAt(i);
          score += 10;
        } else if (_checkCollision(obstacles[i].position, obstacles[i].top)) {
          endGame();
          return;
        }
      }

      // update coins
      for (int i = coins.length - 1; i >= 0; i--) {
        coins[i].top += obstacleSpeed;
        if (coins[i].top > 1.25) {
          coins.removeAt(i);
        } else if (_checkCollision(coins[i].position, coins[i].top)) {
          coinsCollected++;
          score += 25;
          coins.removeAt(i);
        }
      }

      // update fuel cans
      for (int i = fuelCans.length - 1; i >= 0; i--) {
        fuelCans[i].top += obstacleSpeed;
        if (fuelCans[i].top > 1.25) {
          fuelCans.removeAt(i);
        } else if (_checkCollision(fuelCans[i].position, fuelCans[i].top)) {
          fuel = min(100, fuel + 30); // refill amount
          fuelCans.removeAt(i);
        }
      }
    });
  }

  bool _checkCollision(double objPosition, double objTop) {
    return objTop > 0.65 && objTop < 0.9 && (objPosition - carPosition).abs() < 0.12;
  }

  void endGame() {
    gameTimer?.cancel();
    spawnTimer?.cancel();
    fuelSpawnTimer?.cancel();
    setState(() => gameOver = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      showDialog(context: context, barrierDismissible: false, builder: (_) {
        return AlertDialog(
          title: Text(fuel <= 0 ? '¡Sin gasolina!' : '¡Choque!'),
          content: Text('Puntos: $score\nMonedas: $coinsCollected'),
          actions: [
            TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('Menú')),
            ElevatedButton(onPressed: () { Navigator.pop(context); startGame(); }, child: const Text('Reintentar')),
          ],
        );
      });
    });
  }

  // player controls
  void moveLeft() {
    setState(() {
      carPosition -= 0.25;
      if (carPosition < 0.1) carPosition = 0.1;
    });
  }

  void moveRight() {
    setState(() {
      carPosition += 0.25;
      if (carPosition > 0.9) carPosition = 0.9;
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    spawnTimer?.cancel();
    fuelSpawnTimer?.cancel();
    explosionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    // used for lane stripes wrap
    final cycle = screenH + 160.0;

    return Scaffold(
      body: Stack(children: [
        // background (slightly darkened so HUD and lanes stand out)
        Positioned.fill(
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.25), BlendMode.darken),
            child: Image.asset(widget.backgroundPath, fit: BoxFit.cover, errorBuilder: (c,e,s) {
              return Container(color: Colors.grey.shade900);
            }),
          ),
        ),

        // LANE STRIPES (draw ON TOP of background)
        ...List.generate(20, (i) {
          double raw = i * 120.0 - roadOffset;
          double top = raw % cycle;
          if (top < -140) top += cycle;
          return Positioned(
            left: screenW * 0.5 - 6,
            top: top,
            child: Container(
              width: 12,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 6)],
              ),
            ),
          );
        }),

        // Side lane markings (to visually frame the road)
        Positioned(
          left: screenW * 0.12,
          top: 0,
          bottom: 0,
          child: Container(width: 8, decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.red, Colors.white, Colors.red], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          )),
        ),
        Positioned(
          right: screenW * 0.12,
          top: 0,
          bottom: 0,
          child: Container(width: 8, decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.red, Colors.white, Colors.red], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          )),
        ),

        // Coins
        ...coins.map((c) {
          return Positioned(
            left: screenW * c.position - 20,
            top: screenH * c.top,
            child: const Icon(Icons.monetization_on, color: Colors.amber, size: 42),
          );
        }),

        // Fuel cans (use your asset path)
        ...fuelCans.map((f) {
          return Positioned(
            left: screenW * f.position - 22,
            top: screenH * f.top,
            child: Image.asset('assets/images/fuel.png', width: 46, height: 56, errorBuilder: (c,e,s) {
              return Container(width:46, height:56, decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.local_gas_station, color: Colors.white));
            }),
          );
        }),

        // Obstacles (enemy cars) - Williams image
        ...obstacles.map((o) {
          return Positioned(
            left: screenW * o.position - 32,
            top: screenH * o.top,
            child: SizedBox(
              width: 64,
              height: 110,
              child: Image.asset('assets/images/william_f1.jpg', fit: BoxFit.cover, errorBuilder: (c,e,s) {
                return Container(width:64, height:110, color: Colors.redAccent);
              }),
            ),
          );
        }),

        // Player car (Cadillac)
        Positioned(
          left: screenW * carPosition - 35,
          bottom: 110,
          child: SizedBox(
            width: 70,
            height: 120,
            child: Image.asset('assets/images/cadillac_f1.jpeg', fit: BoxFit.cover, errorBuilder: (c,e,s) {
              return Container(width:70, height:120, color: Colors.blue);
            }),
          ),
        ),

        // HUD top
        Positioned(
          top: 36,
          left: 16,
          right: 16,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _hudBox(Icons.stars, Colors.amber, score.toString()),
            _fuelHUD(),
            _hudBox(Icons.monetization_on, Colors.yellow, coinsCollected.toString())
          ]),
        ),

        // Controls bottom
        Positioned(
          bottom: 14,
          left: 18,
          right: 18,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _controlButton(Icons.arrow_back_ios_new, moveLeft),
            _controlButton(Icons.arrow_forward_ios, moveRight),
          ]),
        ),
      ]),
    );
  }

  Widget _controlButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 38,
        backgroundColor: Colors.black.withOpacity(0.55),
        child: Icon(icon, color: Colors.white, size: 36),
      ),
    );
  }

  Widget _hudBox(IconData icon, Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12), border: Border.all(color: color, width: 1.5)),
      child: Row(children: [Icon(icon, color: color), const SizedBox(width: 6), Text(text, style: const TextStyle(fontWeight: FontWeight.bold))]),
    );
  }

  Widget _fuelHUD() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green, width: 1.5)),
      child: Row(children: [
        Image.asset('assets/images/fuel.png', width: 30, height: 36, errorBuilder: (c,e,s) => const Icon(Icons.local_gas_station)),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          height: 18,
          child: Stack(children: [
            Container(decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10))),
            FractionallySizedBox(widthFactor: (fuel / 100).clamp(0.0, 1.0), child: Container(decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.green, Colors.yellow, Colors.red]), borderRadius: BorderRadius.circular(10)))),
            Center(child: Text('${fuel.toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))
          ]),
        )
      ]),
    );
  }
}

/* ==========================
   MODELOS
   ========================== */

class Obstacle {
  double position;
  double top;
  int type;
  Obstacle({required this.position, required this.top, this.type = 0});
}

class Coin {
  double position;
  double top;
  Coin({required this.position, required this.top});
}

class FuelCan {
  double position;
  double top;
  FuelCan({required this.position, required this.top});
}