import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BugSenderPage extends StatefulWidget {
  final String sessionKey;
  final String username;
  final String role;

  const BugSenderPage({
    super.key,
    required this.sessionKey,
    required this.username,
    required this.role,
  });

  @override
  State<BugSenderPage> createState() => _BugSenderPageState();
}

class _BugSenderPageState extends State<BugSenderPage> {
  List<dynamic> senderList = [];
  bool isLoading = false;
  bool isRefreshing = false;
  String? errorMessage;

  // --- TEMA WARNA UNGU ---
  final Color bgDark = const Color(0xFF070317);
  final Color primaryPurple = const Color(0xFF7A5CFF);
  final Color accentPurple = const Color(0xFF4DA3FF);
  final Color lightPurple = const Color(0xFF9CB7FF);
  final Color primaryWhite = Colors.white;
  final Color cardGlass = Colors.white.withOpacity(0.05);
  final Color borderGlass = Colors.white.withOpacity(0.1);

  // All roles can access sender feature.
  bool get canAccessSenderFeature => true;

  @override
  void initState() {
    super.initState();
    _fetchSenders();
  }

  Future<void> _fetchSenders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Use the new /mySenders endpoint for all users
      final response = await http.get(
        Uri.parse(
          "http://tirz.panel.jserver.web.id:2001/mySenders?key=${widget.sessionKey}",
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["valid"] == true) {
          setState(() {
            senderList = data["senders"] ?? [];
          });
        } else {
          setState(() {
            errorMessage = data["message"] ?? "Failed to fetch senders";
          });
        }
      } else {
        setState(() {
          errorMessage = "Server error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Connection failed: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
        isRefreshing = false;
      });
    }
  }

  Future<void> _refreshSenders() async {
    setState(() => isRefreshing = true);
    await _fetchSenders();
  }

  String? _extractPairingCode(dynamic data) {
    if (data is Map) {
      final candidates = [
        data['pairingCode'],
        data['pairing_code'],
        data['code'],
        data['pairCode'],
      ];

      for (final candidate in candidates) {
        if (candidate == null) continue;
        final trimmed = candidate.toString().trim();
        if (trimmed.isNotEmpty) return trimmed;
      }

      final nested = data['pairing'];
      if (nested is Map && nested['code'] != null) {
        final trimmed = nested['code'].toString().trim();
        if (trimmed.isNotEmpty) return trimmed;
      }

      final nestedData = data['data'];
      if (nestedData is Map) {
        final nestedCode = _extractPairingCode(nestedData);
        if (nestedCode != null) return nestedCode;
      }
    }
    return null;
  }

  Future<String?> _requestPairingCode(
    String number, {
    bool showErrors = true,
  }) async {
    try {
      final uri = Uri.parse(
        "http://tirz.panel.jserver.web.id:2001/getPairing",
      ).replace(queryParameters: {"key": widget.sessionKey, "number": number});

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["valid"] == true) {
          final code = _extractPairingCode(data);
          if (code != null) return code;
          if (showErrors) {
            _showSnackBar(
              data["message"] ?? "Pairing code not available",
              isError: true,
            );
          }
          return null;
        }
        if (showErrors) {
          _showSnackBar(
            data["message"] ?? "Failed to get pairing code",
            isError: true,
          );
        }
        return null;
      }

      if (showErrors) {
        _showSnackBar("Server error: ${response.statusCode}", isError: true);
      }
    } catch (e) {
      if (showErrors) {
        _showSnackBar("Connection failed: $e", isError: true);
      }
    }
    return null;
  }

  void _showAddSenderDialog() {
    if (!canAccessSenderFeature) {
      _showSnackBar(
        "You don't have permission to access sender feature!",
        isError: true,
      );
      return;
    }

    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        scrollable: true,
        title: Row(
          children: [
            Icon(Icons.add_circle, color: accentPurple),
            const SizedBox(width: 12),
            Text(
              "Add New Sender",
              style: TextStyle(
                color: primaryWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Enter WhatsApp number for PRIVATE sender (only your account)",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: primaryWhite),
              decoration: InputDecoration(
                labelText: "Phone Number",
                labelStyle: TextStyle(color: accentPurple),
                hintText: "628xxx",
                hintStyle: TextStyle(color: Colors.white54),
                prefixIcon: Icon(Icons.phone, color: accentPurple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryPurple),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accentPurple),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primaryPurple.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: accentPurple, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Private Sender (Only You)",
                      style: TextStyle(color: accentPurple, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "If pairing code doesn't show, open the sender list and tap GET CODE.",
              style: TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: TextStyle(color: Colors.white54)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primaryPurple, accentPurple]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final number = phoneController.text.trim();

                if (number.isEmpty) {
                  _showSnackBar("Please enter phone number", isError: true);
                  return;
                }

                Navigator.pop(context);
                await _addSender(number);
              },
              child: Text("ADD SENDER", style: TextStyle(color: primaryWhite)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addSender(String number) async {
    setState(() => isLoading = true);

    try {
      final endpoint = "addSender";
      final response = await http.post(
        Uri.parse("http://tirz.panel.jserver.web.id:2001/$endpoint"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"key": widget.sessionKey, "number": number}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["valid"] == true) {
          final pairingCode = _extractPairingCode(data);
          String? codeToShow = pairingCode;

          if (codeToShow == null) {
            codeToShow = await _requestPairingCode(number, showErrors: false);
          }

          if (codeToShow != null) {
            _showPairingCodeDialog(number, codeToShow);
            _showSnackBar(
              data['message'] ?? "Sender added successfully!",
              isError: false,
            );
          } else {
            final message = data['message'] ?? "Sender added successfully!";
            _showSnackBar(
              "$message Pairing code not available. Tap GET CODE on the list.",
              isError: false,
            );
          }
        } else {
          // Check if it's a permission issue
          if (data['message']?.contains("Only VIP") == true) {
            _showSnackBar(
              "⚠️ This feature is restricted by role.",
              isError: true,
            );
          } else {
            _showSnackBar(
              data['message'] ?? "Failed to add sender",
              isError: true,
            );
          }
        }
      } else if (response.statusCode == 403) {
        _showSnackBar("⚠️ This feature is restricted by role.", isError: true);
      } else {
        _showSnackBar("Server error: ${response.statusCode}", isError: true);
      }
    } catch (e) {
      _showSnackBar("Connection failed: $e", isError: true);
    } finally {
      setState(() => isLoading = false);
      _fetchSenders();
    }
  }

  void _showPairingCodeDialog(String number, String code) {
    const int maxSeconds = 50;
    int secondsLeft = maxSeconds;
    Timer? countdownTimer;
    bool dialogActive = true;

    void stopTimer() {
      dialogActive = false;
      countdownTimer?.cancel();
      countdownTimer = null;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            final media = MediaQuery.of(context);
            final isCompact = media.size.width < 360;
            final codeFontSize = isCompact
                ? 24.0
                : (media.size.width < 420 ? 28.0 : 32.0);
            final codeLetterSpacing = isCompact ? 2.5 : 4.0;

            countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (
              timer,
            ) {
              if (!dialogActive) {
                timer.cancel();
                return;
              }
              if (secondsLeft <= 1) {
                timer.cancel();
                dialogSetState(() => secondsLeft = 0);
                return;
              }
              dialogSetState(() => secondsLeft--);
            });

            return WillPopScope(
              onWillPop: () async {
                stopTimer();
                return true;
              },
              child: AlertDialog(
                backgroundColor: bgDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                insetPadding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 16 : 24,
                  vertical: 20,
                ),
                title: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isCompact ? 8 : 10),
                      decoration: BoxDecoration(
                        color: primaryPurple.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.qr_code_2,
                        color: accentPurple,
                        size: isCompact ? 34 : 40,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "Pairing Required",
                      style: TextStyle(
                        color: primaryWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: isCompact ? 16 : 18,
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      padding: EdgeInsets.all(isCompact ? 14 : 20),
                      decoration: BoxDecoration(
                        color: cardGlass,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: accentPurple.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Number: $number",
                            style: TextStyle(color: primaryWhite),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            secondsLeft > 0
                                ? "Time left: ${secondsLeft}s"
                                : "Time expired. Request a new code.",
                            style: TextStyle(
                              color: secondsLeft > 0
                                  ? accentPurple.withOpacity(0.9)
                                  : Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: EdgeInsets.all(isCompact ? 16 : 20),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: accentPurple, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: accentPurple.withOpacity(0.4),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                code,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: accentPurple,
                                  fontSize: codeFontSize,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: codeLetterSpacing,
                                  fontFamily: 'Courier',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: primaryPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: primaryPurple),
                            ),
                            child: OutlinedButton.icon(
                              icon: Icon(Icons.copy, color: accentPurple),
                              label: Text(
                                "COPY CODE",
                                style: TextStyle(
                                  color: accentPurple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: code),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Code copied to clipboard!",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: accentPurple,
                                    behavior: SnackBarBehavior.floating,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      stopTimer();
                      Navigator.pop(dialogContext);
                    },
                    child: Text("CLOSE", style: TextStyle(color: primaryWhite)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryPurple, accentPurple],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        stopTimer();
                        Navigator.pop(dialogContext);
                        _fetchSenders();
                      },
                      child: Text(
                        "REFRESH LIST",
                        style: TextStyle(color: primaryWhite),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      stopTimer();
    });
  }

  Future<void> _deleteSender(String senderNumber) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: const Color(0xFF4DA3FF)),
            const SizedBox(width: 12),
            Text("Confirm Delete", style: TextStyle(color: primaryWhite)),
          ],
        ),
        content: Text(
          "Are you sure you want to delete sender $senderNumber? This action cannot be undone.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("CANCEL", style: TextStyle(color: primaryWhite)),
          ),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF5B4CFF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF5B4CFF)),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "DELETE",
                style: TextStyle(color: const Color(0xFF5B4CFF)),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => isLoading = true);

      try {
        // Use the new DELETE /deleteSender endpoint
        final response = await http.delete(
          Uri.parse(
            "http://tirz.panel.jserver.web.id:2001/deleteSender",
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({"key": widget.sessionKey, "number": senderNumber}),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data["valid"] == true) {
            _showSnackBar("Sender deleted successfully!", isError: false);
            _fetchSenders();
          } else {
            _showSnackBar(
              data["message"] ?? "Failed to delete sender",
              isError: true,
            );
          }
        } else {
          _showSnackBar("Server error: ${response.statusCode}", isError: true);
        }
      } catch (e) {
        _showSnackBar("Connection failed: $e", isError: true);
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? const Color(0xFF5B4CFF) : primaryPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSenderCard(Map<String, dynamic> sender, int index) {
    final number = sender['number'] ?? sender['sessionName'] ?? 'Unknown';
    final status = (sender['status'] ?? 'disconnected')
        .toString()
        .toLowerCase();
    final isConnected = status == 'connected';
    final numberText = number.toString();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardGlass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderGlass),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? primaryPurple.withOpacity(0.2)
                        : Color(0xFF6B8CFF).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.phone_android,
                    color: isConnected ? accentPurple : const Color(0xFF6B8CFF),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        numberText,
                        style: TextStyle(
                          color: primaryWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (sender['addedAt'] != null)
                        Text(
                          "Added: ${sender['addedAt'].toString().substring(0, 10)}",
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? Color(0xFF7A5CFF).withOpacity(0.15)
                        : Color(0xFF6B8CFF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isConnected
                          ? Color(0xFF7A5CFF).withOpacity(0.3)
                          : Color(0xFF6B8CFF).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    isConnected ? "CONNECTED" : "OFFLINE",
                    style: TextStyle(
                      color: isConnected
                          ? Color(0xFF7A5CFF)
                          : const Color(0xFF6B8CFF),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.refresh, size: 16, color: primaryWhite),
                    label: Text("REFRESH"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryWhite,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      side: BorderSide(color: borderGlass),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _refreshSenders(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: const Color(0xFF5B4CFF),
                    ),
                    label: Text("DELETE"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF5B4CFF).withOpacity(0.1),
                      foregroundColor: const Color(0xFF5B4CFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _deleteSender(numberText),
                  ),
                ),
              ],
            ),
            if (!isConnected) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: Icon(Icons.qr_code_2, size: 16, color: accentPurple),
                label: Text("GET PAIRING CODE"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accentPurple,
                  backgroundColor: Colors.white.withOpacity(0.05),
                  side: BorderSide(color: borderGlass),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final code = await _requestPairingCode(numberText);
                  if (code != null) {
                    _showPairingCodeDialog(numberText, code);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: primaryPurple.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: primaryPurple.withOpacity(0.3)),
              ),
              child: Icon(Icons.phone_iphone, color: accentPurple, size: 80),
            ),
            const SizedBox(height: 24),
            Text(
              "No Senders Found",
              style: TextStyle(
                color: primaryWhite,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              canAccessSenderFeature
                  ? "Add your first WhatsApp sender to get started"
                  : "This feature is not available for your role.",
              style: TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            if (canAccessSenderFeature)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryPurple, accentPurple],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryPurple.withOpacity(0.4),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text("ADD FIRST SENDER"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _showAddSenderDialog,
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF6B8CFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Color(0xFF6B8CFF).withOpacity(0.3),
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, color: const Color(0xFF6B8CFF), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "No Access",
                      style: TextStyle(
                        color: const Color(0xFF6B8CFF),
                        fontWeight: FontWeight.bold,
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

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: const Color(0xFF5B4CFF), size: 80),
            const SizedBox(height: 24),
            Text(
              "Failed to Load",
              style: TextStyle(
                color: primaryWhite,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? "Unknown error occurred",
              style: TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primaryPurple, accentPurple]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton.icon(
                icon: Icon(Icons.refresh),
                label: Text("TRY AGAIN"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _fetchSenders,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Manage Senders",
              style: TextStyle(
                color: primaryWhite,
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(color: primaryPurple.withOpacity(0.8), blurRadius: 10),
                ],
              ),
            ),
            if (!canAccessSenderFeature) ...[
              const SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(0xFF6B8CFF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Color(0xFF6B8CFF).withOpacity(0.5),
                  ),
                ),
                child: Text(
                  "VIP",
                  style: TextStyle(
                    color: const Color(0xFF6B8CFF),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: accentPurple),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: accentPurple),
            onPressed: isLoading ? null : _refreshSenders,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgDark, primaryPurple.withOpacity(0.1), bgDark],
          ),
        ),
        child: isLoading && senderList.isEmpty
            ? Center(child: CircularProgressIndicator(color: accentPurple))
            : errorMessage != null && senderList.isEmpty
            ? _buildErrorState()
            : senderList.isEmpty
            ? _buildEmptyState()
            : RefreshIndicator(
                color: accentPurple,
                backgroundColor: cardGlass,
                onRefresh: _refreshSenders,
                child: ListView.builder(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(top: 16, bottom: 100),
                  itemCount: senderList.length,
                  itemBuilder: (context, index) => _buildSenderCard(
                    Map<String, dynamic>.from(senderList[index]),
                    index,
                  ),
                ),
              ),
      ),
      floatingActionButton: canAccessSenderFeature
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primaryPurple, accentPurple]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryPurple.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: _showAddSenderDialog,
                backgroundColor: Colors.transparent,
                child: Icon(Icons.add, color: primaryWhite),
              ),
            )
          : null,
    );
  }
}
