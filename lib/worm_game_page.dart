import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class WormGamePage extends StatefulWidget {
  const WormGamePage({super.key});

  @override
  State<WormGamePage> createState() => _WormGamePageState();
}

class _WormGamePageState extends State<WormGamePage> {
  static const int gridSize = 18;
  static const Duration tick = Duration(milliseconds: 160);

  final Random _rand = Random();
  late Timer _timer;
  List<Point<int>> _worm = [const Point(8, 9), const Point(8, 10), const Point(8, 11)];
  Point<int> _dir = const Point(0, -1); // up
  Point<int> _food = const Point(5, 5);
  bool _alive = true;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _spawnFood();
    _timer = Timer.periodic(tick, (_) => _step());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _spawnFood() {
    while (true) {
      final p = Point(_rand.nextInt(gridSize), _rand.nextInt(gridSize));
      if (!_worm.contains(p)) {
        _food = p;
        break;
      }
    }
  }

  void _step() {
    if (!_alive) return;
    final head = _worm.first;
    final next = Point(head.x + _dir.x, head.y + _dir.y);

    // wall or self hit
    if (next.x < 0 || next.y < 0 || next.x >= gridSize || next.y >= gridSize || _worm.contains(next)) {
      setState(() => _alive = false);
      return;
    }

    final newWorm = [next, ..._worm];
    if (next == _food) {
      _score += 10;
      _spawnFood();
    } else {
      newWorm.removeLast();
    }

    setState(() {
      _worm = newWorm;
    });
  }

  void _changeDir(Point<int> dir) {
    // prevent reverse
    if (dir.x == -_dir.x && dir.y == -_dir.y) return;
    _dir = dir;
  }

  void _restart() {
    setState(() {
      _alive = true;
      _worm = [const Point(8, 9), const Point(8, 10), const Point(8, 11)];
      _dir = const Point(0, -1);
      _score = 0;
      _spawnFood();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cellSize = MediaQuery.of(context).size.width / (gridSize + 2);
    return Scaffold(
      backgroundColor: const Color(0xFF070317),
      appBar: AppBar(
        title: const Text('Worm Game'),
        backgroundColor: const Color(0xFF070317),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Text('Score: $_score', style: const TextStyle(color: Colors.white70, fontSize: 16)),
          Expanded(
            child: Center(
              child: Container(
                width: cellSize * gridSize,
                height: cellSize * gridSize,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A0F3D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF7A5CFF).withOpacity(0.35)),
                ),
                child: GestureDetector(
                  onVerticalDragUpdate: (d) => _changeDir(d.delta.dy < 0 ? const Point(0, -1) : const Point(0, 1)),
                  onHorizontalDragUpdate: (d) => _changeDir(d.delta.dx < 0 ? const Point(-1, 0) : const Point(1, 0)),
                  child: CustomPaint(
                    painter: _WormPainter(_worm, _food),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _alive ? null : _restart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CFF),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_alive ? 'Alive' : 'Restart'),
                ),
                ElevatedButton(
                  onPressed: () => _changeDir(const Point(0, -1)),
                  child: const Icon(Icons.keyboard_arrow_up),
                ),
                ElevatedButton(
                  onPressed: () => _changeDir(const Point(0, 1)),
                  child: const Icon(Icons.keyboard_arrow_down),
                ),
                ElevatedButton(
                  onPressed: () => _changeDir(const Point(-1, 0)),
                  child: const Icon(Icons.keyboard_arrow_left),
                ),
                ElevatedButton(
                  onPressed: () => _changeDir(const Point(1, 0)),
                  child: const Icon(Icons.keyboard_arrow_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WormPainter extends CustomPainter {
  final List<Point<int>> worm;
  final Point<int> food;
  _WormPainter(this.worm, this.food);

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / _WormGamePageState.gridSize;
    final cellH = size.height / _WormGamePageState.gridSize;

    final wormPaint = Paint()..color = const Color(0xFF7A5CFF);
    final headPaint = Paint()..color = const Color(0xFFB36BFF);
    final foodPaint = Paint()..color = const Color(0xFFD6B3FF);

    for (int i = 0; i < worm.length; i++) {
      final p = worm[i];
      final rect = Rect.fromLTWH(p.x * cellW, p.y * cellH, cellW - 2, cellH - 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        i == 0 ? headPaint : wormPaint,
      );
    }

    final foodRect = Rect.fromLTWH(food.x * cellW, food.y * cellH, cellW - 2, cellH - 2);
    canvas.drawRRect(RRect.fromRectAndRadius(foodRect, const Radius.circular(4)), foodPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}




