import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class ChatPublicPage extends StatefulWidget {
  final String username;
  final String role;
  final String apiKey;
  final double bottomSafeInset;

  const ChatPublicPage({
    super.key,
    required this.username,
    required this.role,
    required this.apiKey,
    this.bottomSafeInset = 0,
  });

  @override
  State<ChatPublicPage> createState() => _ChatPublicPageState();
}

class _ChatPublicPageState extends State<ChatPublicPage> with TickerProviderStateMixin {
  static const String _baseUrl = "http://tirz.panel.jserver.web.id:2001";
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  int _onlineCount = 0;
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _pollTimer;
  late AnimationController _pulseController;

  // Premium Color Palette
  final Color primaryDark = const Color(0xFF0A0A1A);
  final Color primaryNeon = const Color(0xFF00E5FF);
  final Color secondaryNeon = const Color(0xFF7C4DFF);
  final Color accentPink = const Color(0xFFFF4081);
  final Color surfaceColor = const Color(0xFF12122A);
  final Color textPrimary = Colors.white;
  final Color textSecondary = const Color(0xFFB8B8D0);
  final Color cardBg = const Color(0xCC16163A);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _refreshAll();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _refreshAll(silent: true);
    });
  }

  Future<void> _refreshAll({bool silent = false}) async {
    if (!silent && mounted) setState(() => _isLoading = true);
    try {
      await Future.wait([_loadMessages(), _loadUsers()]);
    } finally {
      if (!silent && mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMessages() async {
    final uri = Uri.parse(
      "$_baseUrl/api/chatpublic/messages?key=${Uri.encodeQueryComponent(widget.apiKey)}&limit=150",
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) return;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) return;

    final list = List<Map<String, dynamic>>.from(data['messages'] ?? []);
    list.sort(
      (a, b) => (a['timestamp'] ?? '').toString().compareTo(
        (b['timestamp'] ?? '').toString(),
      ),
    );

    if (!mounted) return;
    setState(() {
      _messages = list;
    });
    _scrollToBottom();
  }

  Future<void> _loadUsers() async {
    final uri = Uri.parse(
      "$_baseUrl/api/chatpublic/users?key=${Uri.encodeQueryComponent(widget.apiKey)}",
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) return;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (!mounted) return;
    setState(() {
      _onlineCount = (data['count'] ?? 0) as int;
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      final uri = Uri.parse("$_baseUrl/api/chatpublic/message");
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "key": widget.apiKey,
          "username": widget.username,
          "role": widget.role,
          "message": text,
        }),
      );
      if (response.statusCode == 200) {
        _messageController.clear();
        HapticFeedback.lightImpact();
        await _refreshAll(silent: true);
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _deleteMessage(String id) async {
    final uri = Uri.parse(
      "$_baseUrl/api/chatpublic/message/$id?key=${Uri.encodeQueryComponent(widget.apiKey)}&username=${Uri.encodeQueryComponent(widget.username)}",
    );
    await http.delete(uri);
    await _refreshAll(silent: true);
    HapticFeedback.mediumImpact();
  }

  Future<void> _addReaction(String id, String emoji) async {
    final uri = Uri.parse("$_baseUrl/api/chatpublic/reaction");
    await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "key": widget.apiKey,
        "messageId": id,
        "emoji": emoji,
        "username": widget.username,
      }),
    );
    await _refreshAll(silent: true);
    HapticFeedback.lightImpact();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case "owner":
        return const Color(0xFFFF4081);
      case "admin":
        return const Color(0xFF7C4DFF);
      case "vip":
        return const Color(0xFF00E5FF);
      case "moderator":
        return const Color(0xFF00E676);
      case "pt":
        return const Color(0xFFFF9800);
      case "tk":
        return const Color(0xFFFF5252);
      case "xceo":
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case "owner":
        return "👑";
      case "admin":
        return "⚡";
      case "vip":
        return "💎";
      case "moderator":
        return "🛡️";
      default:
        return "👤";
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0A0A1A),
              const Color(0xFF12122A),
              const Color(0xFF1A1A3A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildPremiumAppBar(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _messages.isEmpty
                        ? _buildEmptyState()
                        : _buildMessageList(),
              ),
              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            secondaryNeon.withOpacity(0.15),
            primaryNeon.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: primaryNeon.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryNeon, secondaryNeon],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: primaryNeon.withOpacity(0.4),
                  blurRadius: 15,
                ),
              ],
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [primaryNeon, secondaryNeon],
                  ).createShader(bounds),
                  child: const Text(
                    "PUBLIC CHAT",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Global Community Discussion",
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryNeon.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryNeon.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: primaryNeon,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryNeon,
                            blurRadius: 4 * _pulseController.value,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                Text(
                  "$_onlineCount Online",
                  style: TextStyle(
                    color: primaryNeon,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _refreshAll(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.refresh_rounded, color: textSecondary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryNeon, secondaryNeon],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Loading messages...",
            style: TextStyle(
              color: textSecondary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryNeon.withOpacity(0.2), secondaryNeon.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(Icons.chat_bubble_outline_rounded, color: textSecondary, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            "No messages yet",
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Be the first to start the conversation!",
            style: TextStyle(
              color: textSecondary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: 16 + widget.bottomSafeInset,
      ),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final id = (msg['id'] ?? '').toString();
        final author = (msg['username'] ?? 'unknown').toString();
        final role = (msg['role'] ?? 'user').toString();
        final text = (msg['message'] ?? '').toString();
        final mine = author == widget.username;
        final timestamp = (msg['timestamp'] ?? '').toString();
        final reactions = Map<String, dynamic>.from(msg['reactions'] ?? {});

        return _buildMessageCard(
          id: id,
          author: author,
          role: role,
          text: text,
          mine: mine,
          timestamp: timestamp,
          reactions: reactions,
        );
      },
    );
  }

  Widget _buildMessageCard({
    required String id,
    required String author,
    required String role,
    required String text,
    required bool mine,
    required String timestamp,
    required Map<String, dynamic> reactions,
  }) {
    final roleColor = _roleColor(role);
    final timeAgo = _formatTimestamp(timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Message Bubble
          GestureDetector(
            onLongPress: mine
                ? () => _showMessageOptions(id)
                : null,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: mine
                    ? LinearGradient(
                        colors: [secondaryNeon.withOpacity(0.3), primaryNeon.withOpacity(0.2)],
                      )
                    : null,
                color: mine ? null : cardBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: mine ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: mine ? const Radius.circular(4) : const Radius.circular(20),
                ),
                border: Border.all(
                  color: mine ? primaryNeon.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author & Role
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: roleColor.withOpacity(0.2),
                        child: Text(
                          _getRoleIcon(role),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        author,
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: roleColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          role.toUpperCase(),
                          style: TextStyle(
                            color: roleColor,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Message Text
                  Text(
                    text,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      fontFamily: 'Inter',
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Timestamp
                  Row(
                    mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      Text(
                        timeAgo,
                        style: TextStyle(
                          color: textSecondary.withOpacity(0.5),
                          fontSize: 9,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Reactions
          if (reactions.isNotEmpty)
            Wrap(
              spacing: 6,
              children: reactions.entries.map((entry) {
                final emoji = entry.key;
                final users = List<String>.from(entry.value);
                final hasReacted = users.contains(widget.username);
                return GestureDetector(
                  onTap: () => _addReaction(id, emoji),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: hasReacted
                          ? roleColor.withOpacity(0.2)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasReacted ? roleColor.withOpacity(0.3) : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Text(
                      "$emoji ${users.length}",
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    if (timestamp.isEmpty) return "just now";
    try {
      final time = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(time);
      if (diff.inSeconds < 60) return "just now";
      if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
      if (diff.inHours < 24) return "${diff.inHours}h ago";
      if (diff.inDays < 7) return "${diff.inDays}d ago";
      return "${time.day}/${time.month}";
    } catch (_) {
      return "recent";
    }
  }

  void _showMessageOptions(String id) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          border: Border.all(color: primaryNeon.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: primaryNeon.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
              ),
              title: const Text(
                "Delete Message",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(id);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            surfaceColor.withOpacity(0.9),
            primaryDark,
          ],
        ),
        border: Border(
          top: BorderSide(
            color: primaryNeon.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: primaryNeon.withOpacity(0.2)),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Type your message...",
                  hintStyle: TextStyle(color: textSecondary.withOpacity(0.5), fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryNeon, secondaryNeon],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: primaryNeon.withOpacity(0.4 * _pulseController.value),
                      blurRadius: 12 * _pulseController.value,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isSending ? null : _sendMessage,
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: _isSending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}