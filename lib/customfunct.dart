import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'dart:ui';

class CustomFunctionPage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>>
  listBug; // Still passed but unused for logic, kept for compatibility
  final String role;
  final String expiredDate;

  const CustomFunctionPage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listBug,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<CustomFunctionPage> createState() => _CustomFunctionPageState();
}

class _CustomFunctionPageState extends State<CustomFunctionPage>
    with TickerProviderStateMixin {
  final targetController = TextEditingController();
  late final TextEditingController _functionNameController;
  late final TextEditingController _functionCodeController;

  // Base URL from CustomFunctionPage logic
  static const String baseUrl = "http://tirz.panel.jserver.web.id:2001";

  // Animation controllers
  late AnimationController _buttonController;
  late Animation<double> _scaleAnimation;

  // Video controllers
  late VideoPlayerController _videoController;
  bool _videoInitialized = false;
  bool _videoError = false;

  // State variables
  String _customFunctionCode = '''
// Contoh fungsi custom WhatsApp bug
async function memek(sock, target) {
  // Kirim pesan teks
  await sock.sendMessage(target, { 
    text: "🔥 kontol memek!" 
  });
  masukin funct lu anj
''';
  String _customFunctionName = 'myCustomBug';
  bool _isSavingFunction = false;
  bool _isExecutingFunction = false;
  bool _isTestingSyntax = false;
  String _customFunctionSyntaxStatus = '';
  bool _hasCustomFunction = false;

  @override
  void initState() {
    super.initState();
    _functionNameController = TextEditingController(text: _customFunctionName);
    _functionCodeController = TextEditingController(text: _customFunctionCode);

    _initializeAnimations();
    _initializeVideoController();
    _checkExistingCustomFunction();
  }

  void _initializeAnimations() {
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
  }

  void _initializeVideoController() {
    // Using login.mp4 as requested for background
    try {
      _videoController = VideoPlayerController.asset('assets/videos/banner.mp4')
        ..initialize()
            .then((_) {
              if (mounted) {
                setState(() {
                  _videoInitialized = true;
                });
                _videoController.setLooping(true);
                _videoController.play();
                _videoController.setVolume(0);
              }
            })
            .catchError((error) {
              print('Video initialization error: $error');
              if (mounted) {
                setState(() {
                  _videoError = true;
                });
              }
            });
    } catch (e) {
      print('Video controller creation error: $e');
      if (mounted) {
        setState(() {
          _videoError = true;
        });
      }
    }
  }

  String? formatPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.startsWith('0') || cleaned.length < 8) return null;
    return cleaned;
  }

  // ====================================================
  // API CALLS
  // ====================================================

  Future<void> _saveCustomFunction() async {
    if (_isSavingFunction || _customFunctionCode.isEmpty) return;

    setState(() {
      _isSavingFunction = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/whatsapp/custom/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': widget.sessionKey,
          'functionCode': _customFunctionCode,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['valid'] == true) {
        _showAlert(
          '✅ Success',
          data['message'] ?? 'Function saved successfully',
        );
        setState(() {
          _hasCustomFunction = true;
        });
      } else {
        _showAlert('❌ Error', data['message'] ?? 'Failed to save function');
      }
    } catch (error) {
      _showAlert('❌ Network Error', 'Failed to connect to server: $error');
    } finally {
      setState(() {
        _isSavingFunction = false;
      });
    }
  }

  Future<void> _executeCustomFunction() async {
    if (_isExecutingFunction) return;

    _buttonController.forward().then((_) {
      _buttonController.reverse();
    });

    final rawInput = targetController.text.trim();
    final target = formatPhoneNumber(rawInput);

    if (target == null || widget.sessionKey.isEmpty) {
      _showAlert(
        "❌ Invalid Number",
        "Gunakan nomor internasional (misal: +62, 1, 44), bukan 08xxx.",
      );
      return;
    }

    setState(() {
      _isExecutingFunction = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/whatsapp/custom/execute?'
          'key=${widget.sessionKey}&'
          'target=$target',
        ),
      );

      final data = jsonDecode(response.body);

      if (data['valid'] == true && data['executed'] == true) {
        if (data['success'] == true) {
          _showSuccessPopup(target);
        } else {
          _showAlert(
            '❌ Execution Failed',
            data['error'] ?? 'Unknown error occurred',
          );
        }
      } else {
        _showAlert('❌ Error', data['message'] ?? 'Failed to execute function');
      }
    } catch (error) {
      _showAlert('❌ Network Error', 'Failed to connect to server: $error');
    } finally {
      setState(() {
        _isExecutingFunction = false;
      });
    }
  }

  Future<void> _testCustomFunctionSyntax() async {
    if (_customFunctionCode.isEmpty) {
      _showAlert('⚠️ Warning', 'Function code is empty');
      return;
    }

    setState(() {
      _isTestingSyntax = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/whatsapp/custom/test'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': widget.sessionKey,
          'functionCode': _customFunctionCode,
        }),
      );

      final data = jsonDecode(response.body);

      setState(() {
        _customFunctionSyntaxStatus = data['syntaxValid'] == true
            ? '✅ Valid'
            : '❌ Error';
      });

      if (data['syntaxValid'] == true) {
        _showAlert('✅ Syntax Test', 'Function syntax is valid! Ready to save.');
      } else {
        _showAlert('❌ Syntax Error', data['message'] ?? 'Invalid syntax');
      }
    } catch (error) {
      _showAlert('❌ Test Failed', 'Failed to test syntax: $error');
    } finally {
      setState(() {
        _isTestingSyntax = false;
      });
    }
  }

  Future<void> _getCustomFunction() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/whatsapp/custom/get?key=${widget.sessionKey}'),
      );

      final data = jsonDecode(response.body);

      if (data['valid'] == true && data['hasFunction'] == true) {
        setState(() {
          _customFunctionCode = data['functionCode'];
          _functionCodeController.text = data['functionCode'];
          _hasCustomFunction = true;
        });
      }
    } catch (error) {
      print('Error getting custom function: $error');
    }
  }

  Future<void> _getExampleFunction() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/whatsapp/custom/example?key=${widget.sessionKey}',
        ),
      );

      final data = jsonDecode(response.body);

      if (data['valid'] == true) {
        setState(() {
          _customFunctionCode = data['exampleCode'];
          _functionCodeController.text = data['exampleCode'];
        });
        _showAlert('📚 Example Loaded', 'Example function loaded successfully');
      }
    } catch (error) {
      _showAlert('❌ Error', 'Failed to load example: $error');
    }
  }

  Future<void> _checkExistingCustomFunction() async {
    await _getCustomFunction();
  }

  // ====================================================
  // UI HELPERS
  // ====================================================

  void _showSuccessPopup(String target) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuccessVideoDialog(
        target: target,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.1).withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.lightBlue.withOpacity(0.3), width: 1),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.lightBlue,
            fontFamily: 'Orbitron',
          ),
        ),
        content: Text(
          msg,
          style: const TextStyle(
            color: Colors.lightBlue,
            fontFamily: 'ShareTechMono',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.lightBlue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white.withOpacity(0.1),
      body: Stack(
        children: [
          // Background Video (login.mp4)
          Container(
            color: Colors.black,
            child: _videoInitialized && !_videoError
                ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController.value.size.width,
                        height: _videoController.value.size.height,
                        child: VideoPlayer(_videoController),
                      ),
                    ),
                  )
                : null,
          ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.85),
                  Colors.black,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // User info header
                    _buildUserInfoHeader(),

                    const SizedBox(height: 24),

                    // Target Input
                    _buildTargetInputCard(),

                    const SizedBox(height: 16),

                    // Function Editor (Replaces Bug Type Dropdown)
                    _buildFunctionEditorCard(),

                    const SizedBox(height: 24),

                    // Status Indicators
                    _buildStatusIndicators(),

                    const SizedBox(height: 24),

                    // Execute Button
                    _buildExecuteButton(),

                    const SizedBox(height: 16),

                    _buildFooterInfo(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.lightBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.lightBlue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.lightBlue.withOpacity(0.2),
            child: Icon(
              widget.role.toLowerCase() == "vip"
                  ? FontAwesomeIcons.crown
                  : FontAwesomeIcons.userShield,
              color: Colors.lightBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.username,
                  style: const TextStyle(
                    color: Colors.lightBlue,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    fontSize: 16,
                  ),
                ),
                Text(
                  widget.role.toUpperCase(),
                  style: TextStyle(
                    color: Colors.lightBlue.withOpacity(0.7),
                    fontSize: 12,
                    fontFamily: 'ShareTechMono',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.lightBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "EXP: ${widget.expiredDate}",
              style: const TextStyle(
                color: Colors.lightBlue,
                fontSize: 12,
                fontFamily: 'ShareTechMono',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetInputCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.lightBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.lightBlue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.lightBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  FontAwesomeIcons.phone,
                  color: Colors.lightBlue,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "Target Number",
                style: TextStyle(
                  color: Colors.lightBlue,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: targetController,
            style: const TextStyle(color: Colors.lightBlue),
            cursorColor: Colors.lightBlue,
            decoration: InputDecoration(
              hintText: "e.g. +62xxxxxxxxx",
              hintStyle: TextStyle(color: Colors.lightBlue.withOpacity(0.5)),
              filled: true,
              fillColor: Colors.lightBlue.withOpacity(0.1),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.lightBlue.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.lightBlue),
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(
                FontAwesomeIcons.globe,
                color: Colors.lightBlue,
                size: 16,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionEditorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.lightBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.lightBlue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.lightBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  FontAwesomeIcons.code,
                  color: Colors.lightBlue,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "Function Code",
                style: TextStyle(
                  color: Colors.lightBlue,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (_hasCustomFunction)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xFFD5DCFF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Color(0xFFD5DCFF).withOpacity(0.3),
                    ),
                  ),
                  child: const Text(
                    "SAVED",
                    style: TextStyle(
                      color: Color(0xFFD5DCFF),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Function Name Input
          TextField(
            controller: _functionNameController,
            onChanged: (value) => _customFunctionName = value,
            style: const TextStyle(color: Colors.lightBlue, fontSize: 12),
            cursorColor: Colors.lightBlue,
            decoration: InputDecoration(
              labelText: "Function Name",
              labelStyle: TextStyle(
                color: Colors.lightBlue.withOpacity(0.7),
                fontSize: 12,
              ),
              hintText: "myCustomBug",
              hintStyle: TextStyle(color: Colors.lightBlue.withOpacity(0.5)),
              filled: true,
              fillColor: Colors.lightBlue.withOpacity(0.05),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.lightBlue.withOpacity(0.2),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.lightBlue),
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Code Editor
          Container(
            constraints: const BoxConstraints(minHeight: 150),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.lightBlue.withOpacity(0.3)),
            ),
            child: TextField(
              controller: _functionCodeController,
              onChanged: (value) => _customFunctionCode = value,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(
                color: Colors.lightBlue,
                fontFamily: 'ShareTechMono',
                fontSize: 12,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "// Enter your custom JavaScript code here...",
                hintStyle: TextStyle(
                  color: Colors.white24,
                  fontFamily: 'ShareTechMono',
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Action Buttons Row
          Row(
            children: [
              // Test Syntax
              Expanded(
                child: _buildSmallActionButton(
                  icon: FontAwesomeIcons.vial,
                  label: "TEST",
                  isLoading: _isTestingSyntax,
                  color: _customFunctionSyntaxStatus.contains('✅')
                      ? Color(0xFFD5DCFF)
                      : Colors.lightBlue,
                  onPressed: _testCustomFunctionSyntax,
                ),
              ),
              const SizedBox(width: 8),
              // Save
              Expanded(
                child: _buildSmallActionButton(
                  icon: FontAwesomeIcons.save,
                  label: "SAVE",
                  isLoading: _isSavingFunction,
                  color: Color(0xFFD5DCFF),
                  onPressed: _saveCustomFunction,
                ),
              ),
              const SizedBox(width: 8),
              // Example
              _buildSmallActionButton(
                icon: FontAwesomeIcons.fileCode,
                label: "EXAMPLE",
                isLoading: false,
                color: const Color(0xFF6B8CFF),
                onPressed: _getExampleFunction,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallActionButton({
    required IconData icon,
    required String label,
    required bool isLoading,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: isLoading
          ? const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon, color: color, size: 12),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
    );
  }

  Widget _buildStatusIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _statusIndicator(
          icon: FontAwesomeIcons.server,
          label: "Server",
          isOnline: true,
        ),
        _statusIndicator(
          icon: FontAwesomeIcons.shieldAlt,
          label: "Security",
          isOnline: true,
        ),
        _statusIndicator(
          icon: FontAwesomeIcons.database,
          label: "Database",
          isOnline: true,
        ),
      ],
    );
  }

  Widget _statusIndicator({
    required IconData icon,
    required String label,
    required bool isOnline,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isOnline
                ? Colors.lightBlue.withOpacity(0.2)
                : Colors.lightBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOnline
                  ? Colors.lightBlue.withOpacity(0.5)
                  : Colors.lightBlue.withOpacity(0.3),
            ),
          ),
          child: Icon(
            icon,
            color: isOnline
                ? Colors.lightBlue
                : Colors.lightBlue.withOpacity(0.7),
            size: 20,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: Colors.lightBlue.withOpacity(0.7),
            fontSize: 12,
            fontFamily: 'ShareTechMono',
          ),
        ),
      ],
    );
  }

  Widget _buildExecuteButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.lightBlue.withOpacity(0.3), width: 1),
      ),
      child: ElevatedButton.icon(
        icon: _isExecutingFunction
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.lightBlue,
                  strokeWidth: 2,
                ),
              )
            : const Icon(
                FontAwesomeIcons.play,
                color: Colors.lightBlue,
                size: 18,
              ),
        label: Text(
          _isExecutingFunction ? "EXECUTING..." : "EXECUTE FUNCTION",
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.4,
            color: Colors.lightBlue,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.lightBlue,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _isExecutingFunction ? null : _executeCustomFunction,
      ),
    );
  }

  Widget _buildFooterInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.lightBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.infoCircle,
            color: Colors.lightBlue.withOpacity(0.5),
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Custom functions are executed server-side. Ensure your code is valid before running.",
              style: TextStyle(
                color: Colors.lightBlue.withOpacity(0.5),
                fontSize: 11,
                fontFamily: 'ShareTechMono',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _videoController.dispose();
    targetController.dispose();
    _functionNameController.dispose();
    _functionCodeController.dispose();
    super.dispose();
  }
}

// ====================================================
// SUCCESS DIALOG (Using splash.mp4)
// ====================================================

class SuccessVideoDialog extends StatefulWidget {
  final String target;
  final VoidCallback onDismiss;

  const SuccessVideoDialog({
    super.key,
    required this.target,
    required this.onDismiss,
  });

  @override
  State<SuccessVideoDialog> createState() => _SuccessVideoDialogState();
}

class _SuccessVideoDialogState extends State<SuccessVideoDialog>
    with TickerProviderStateMixin {
  late VideoPlayerController _successVideoController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _showSuccessInfo = false;
  bool _videoError = false;
  bool _videoInitialized = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _initializeSuccessVideo();
  }

  void _initializeSuccessVideo() {
    try {
      // Using splash.mp4 as requested
      _successVideoController =
          VideoPlayerController.asset('assets/videos/splash.mp4')
            ..initialize()
                .then((_) {
                  if (mounted) {
                    setState(() {
                      _videoInitialized = true;
                    });
                    _successVideoController.play();

                    _successVideoController.addListener(() {
                      if (_successVideoController.value.position >=
                          _successVideoController.value.duration) {
                        _showSuccessMessage();
                      }
                    });
                  }
                })
                .catchError((error) {
                  print('Success video error: $error');
                  if (mounted) {
                    setState(() {
                      _videoError = true;
                    });
                    Future.delayed(const Duration(milliseconds: 500), () {
                      _showSuccessMessage();
                    });
                  }
                });
    } catch (e) {
      print('Video controller error: $e');
      if (mounted) {
        setState(() {
          _videoError = true;
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          _showSuccessMessage();
        });
      }
    }
  }

  void _showSuccessMessage() {
    if (mounted) {
      setState(() {
        _showSuccessInfo = true;
      });
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _successVideoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width * 0.9;
    final dialogHeight = screenSize.height * 0.4;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: Container(
          width: dialogWidth,
          height: dialogHeight,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.lightBlue.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Video or fallback
              if (!_showSuccessInfo)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _videoInitialized && !_videoError
                      ? SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _successVideoController.value.size.width,
                              height: _successVideoController.value.size.height,
                              child: VideoPlayer(_successVideoController),
                            ),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [
                                Colors.black,
                                Colors.lightBlue.withOpacity(0.1),
                                Colors.black,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.lightBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: const Icon(
                                    FontAwesomeIcons.check,
                                    color: Colors.lightBlue,
                                    size: 60,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  "SUCCESS",
                                  style: TextStyle(
                                    color: Colors.lightBlue,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Orbitron',
                                    letterSpacing: 3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),

              // Success info overlay
              if (_showSuccessInfo)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.9),
                          Colors.black.withOpacity(0.95),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.lightBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: Colors.lightBlue.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            FontAwesomeIcons.checkDouble,
                            color: Colors.lightBlue,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Function Executed!",
                          style: TextStyle(
                            color: Colors.lightBlue,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron',
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Target: ${widget.target}",
                          style: TextStyle(
                            color: Colors.lightBlue.withOpacity(0.8),
                            fontSize: 14,
                            fontFamily: 'ShareTechMono',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: widget.onDismiss,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightBlue.withOpacity(0.1),
                            foregroundColor: Colors.lightBlue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                              side: BorderSide(
                                color: Colors.lightBlue.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                          ),
                          child: const Text(
                            "DONE",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Orbitron',
                              letterSpacing: 1,
                            ),
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
    );
  }
}






