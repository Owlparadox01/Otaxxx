import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dashboard_page.dart';

class SplashScreen extends StatefulWidget {
  final String username, password, role, expiredDate, sessionKey, telegramId;
  final List<Map<String, dynamic>> listBug, listDoos;
  final List<dynamic> news;

  const SplashScreen({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.sessionKey,
    required this.telegramId,
    required this.listBug,
    required this.listDoos,
    required this.news,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _uiController;
  late AnimationController _swordController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _swordSlashAnim;
  late Animation<double> _glowAnim;
  late Animation<Offset> _slideAnim;

  bool _isNavigating = false;

  final Color primaryDark = const Color(0xFF0A0A1A);
  final Color accentRed = const Color(0xFFFF4081);
  final Color accentGold = const Color(0xFFFFD700);
  final Color accentCyan = const Color(0xFF00E5FF);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupVideo();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _setupAnimations() {
    _uiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _swordController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _uiController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
      ),
    );

    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _uiController, curve: Curves.elasticOut),
    );

    _swordSlashAnim = Tween<double>(begin: -0.5, end: 0.5).animate(
      CurvedAnimation(parent: _swordController, curve: Curves.elasticOut),
    );

    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _uiController, curve: Curves.easeOutBack),
    );

    _uiController.forward();
    _swordController.forward();
  }

  void _setupVideo() {
    _videoController = VideoPlayerController.asset('assets/videos/splash.mp4')
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _videoController.play();
        _videoController.setLooping(false);

        _videoController.addListener(() {
          if (!mounted || _isNavigating) return;

          final value = _videoController.value;
          if (value.isInitialized &&
              value.duration > Duration.zero &&
              value.position >=
                  value.duration - const Duration(milliseconds: 500)) {
            _navigateToDashboard();
          }
        });
      }).catchError((_) {
        if (mounted) {
          _navigateToDashboard();
        }
      });
  }

  void _navigateToDashboard() {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 1200),
        pageBuilder: (context, animation, secondaryAnimation) =>
            FadeTransition(
          opacity: animation,
          child: DashboardPage(
            username: widget.username,
            password: widget.password,
            role: widget.role,
            expiredDate: widget.expiredDate,
            sessionKey: widget.sessionKey,
            telegramId: widget.telegramId,
            listBug: widget.listBug,
            listDoos: widget.listDoos,
            news: widget.news,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    _uiController.dispose();
    _swordController.dispose();
    _glowController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          if (_videoController.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.85),
                  ],
                  stops: const [0.4, 0.7, 1.0],
                  radius: 1.3,
                ),
              ),
            ),
          ),

          Positioned(
            top: 50,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _navigateToDashboard,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      child: const Text(
                        'SKIP',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _uiController,
                _swordController,
                _glowController,
              ]),
              builder: (context, child) {
                return SlideTransition(
                  position: _slideAnim,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scale: _scaleAnim.value,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 300,
                                height: 150,
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [
                                      accentRed.withOpacity(
                                        0.15 * _glowAnim.value,
                                      ),
                                      Colors.transparent,
                                    ],
                                    radius: 0.8,
                                  ),
                                ),
                              ),

                              Transform.translate(
                                offset: Offset(_swordSlashAnim.value * 100, 0),
                                child: Container(
                                  width: 4,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.8),
                                        accentRed.withOpacity(0.5),
                                        Colors.transparent,
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accentRed.withOpacity(0.6),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              Transform.translate(
                                offset:
                                    Offset(-_swordSlashAnim.value * 100, 0),
                                child: Container(
                                  width: 4,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.8),
                                        accentRed.withOpacity(0.5),
                                        Colors.transparent,
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accentRed.withOpacity(0.6),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [
                                    accentGold,
                                    Colors.white,
                                    accentRed,
                                    accentGold,
                                  ],
                                  stops: const [0.0, 0.3, 0.7, 1.0],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds),
                                child: Text(
                                  'OTAX',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 72,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Orbitron',
                                    letterSpacing: 8,
                                    shadows: [
                                      Shadow(
                                        color: accentRed.withOpacity(0.8),
                                        blurRadius: 15,
                                        offset: const Offset(0, 0),
                                      ),
                                      Shadow(
                                        color: accentGold.withOpacity(0.5),
                                        blurRadius: 25,
                                        offset: const Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              Positioned(
                                bottom: 0,
                                child: Container(
                                  width: 150,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        accentRed,
                                        accentGold,
                                        accentRed,
                                        Colors.transparent,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accentRed.withOpacity(0.5),
                                        blurRadius: 5,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        FadeTransition(
                          opacity: _fadeAnim,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: Text(
                                  'SAMURAI CODE',
                                  style: TextStyle(
                                    color: accentCyan.withOpacity(0.8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 3,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '「 侍の一刀 」',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 11,
                                  fontFamily: 'Inter',
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 50),

                        FadeTransition(
                          opacity: _fadeAnim,
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: CustomPaint(
                              painter: _SamuraiSwordPainter(
                                progress: _glowAnim.value,
                                color: accentRed,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SamuraiSwordPainter extends CustomPainter {
  final double progress;
  final Color color;

  _SamuraiSwordPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.5 + (progress * 0.5))
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final angle = progress * 2 * math.pi;

    for (double i = 0; i < angle; i += 0.1) {
      final x = center.dx + radius * (1 - progress) * math.cos(i);
      final y = center.dy + radius * (1 - progress) * math.sin(i);

      if (i > 0) {
        final prevX = center.dx + radius * (1 - progress) * math.cos(i - 0.1);
        final prevY = center.dy + radius * (1 - progress) * math.sin(i - 0.1);
        canvas.drawLine(Offset(prevX, prevY), Offset(x, y), paint);
      }
    }

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 3 * progress, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}