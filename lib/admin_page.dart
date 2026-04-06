import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';

class AdminPage extends StatefulWidget {
  final String sessionKey;

  const AdminPage({super.key, required this.sessionKey});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late String sessionKey;
  List<dynamic> fullUserList = [];
  List<dynamic> filteredList = [];

  // Role Options untuk Admin: member, reseller, vip + tambahan
  final List<String> roleOptions = [
    'member',
    'reseller',
    'vip',
    'moderator',
    'pt',
    'tk',
  ];
  String selectedRole = 'member';

  int currentPage = 1;
  int itemsPerPage = 25;

  final deleteController = TextEditingController();
  final createUsernameController = TextEditingController();
  final createPasswordController = TextEditingController();
  final createDayController = TextEditingController();
  String newUserRole = 'member';
  bool isLoading = false;

  // --- ROLE CREATION VARIABLES ---
  final roleNameController = TextEditingController();
  final roleReviewController = TextEditingController();
  XFile? selectedPhotoFile;
  bool isCreatingRole = false;
  final ImagePicker imagePicker = ImagePicker();

  // --- TEMA WARNA UNGU ---
  final Color bgDark = const Color(0xFF070317);
  final Color primaryPurple = const Color(0xFF7A5CFF);
  final Color accentPurple = const Color(0xFF9B6BFF);
  final Color primaryWhite = Colors.white;
  final Color cardGlass = Colors.white.withOpacity(0.05);
  final Color borderGlass = Colors.white.withOpacity(0.1);

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    _fetchUsers();
  }

  @override
  void dispose() {
    deleteController.dispose();
    createUsernameController.dispose();
    createPasswordController.dispose();
    createDayController.dispose();
    roleNameController.dispose();
    roleReviewController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse(
          'http://tirz.panel.jserver.web.id:2001/listUsers?key=$sessionKey',
        ),
      );
      final data = jsonDecode(res.body);
      if (data['valid'] == true && data['authorized'] == true) {
        fullUserList = data['users'] ?? [];
        _filterAndPaginate();
      } else {
        _alert(
          "⚠️ Error",
          data['message'] ?? 'Tidak diizinkan melihat daftar user.',
        );
      }
    } catch (_) {
      _alert("🌐 Error", "Gagal memuat user list.");
    }
    setState(() => isLoading = false);
  }

  void _filterAndPaginate() {
    setState(() {
      currentPage = 1;
      filteredList = fullUserList
          .where((u) => u['role'] == selectedRole)
          .toList();
    });
  }

  List<dynamic> _getCurrentPageData() {
    final start = (currentPage - 1) * itemsPerPage;
    final end = (start + itemsPerPage);
    return filteredList.sublist(
      start,
      end > filteredList.length ? filteredList.length : end,
    );
  }

  int get totalPages => (filteredList.length / itemsPerPage).ceil();

  Future<void> _deleteUser() async {
    final username = deleteController.text.trim();
    if (username.isEmpty) {
      _alert("⚠️ Error", "Masukkan username yang ingin dihapus.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse(
          'http://tirz.panel.jserver.web.id:2001/deleteUser?key=$sessionKey&username=$username',
        ),
      );
      final data = jsonDecode(res.body);
      if (data['deleted'] == true) {
        _alert(
          "✅ Berhasil",
          "User '${data['user']['username']}' telah dihapus.",
        );
        deleteController.clear();
        _fetchUsers();
      } else {
        _alert("❌ Gagal", data['message'] ?? 'Gagal menghapus user.');
      }
    } catch (_) {
      _alert("🌐 Error", "Tidak dapat menghubungi server.");
    }
    setState(() => isLoading = false);
  }

  Future<void> _createAccount() async {
    final username = createUsernameController.text.trim();
    final password = createPasswordController.text.trim();
    final day = createDayController.text.trim();

    if (username.isEmpty || password.isEmpty || day.isEmpty) {
      _alert("⚠️ Error", "Semua field wajib diisi.");
      return;
    }

    setState(() => isLoading = true);
    try {
      // Menggunakan endpoint userAdd (Admin punya akses penuh)
      final url = Uri.parse(
        'http://tirz.panel.jserver.web.id:2001/userAdd?key=$sessionKey&username=$username&password=$password&day=$day&role=$newUserRole',
      );
      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data['created'] == true) {
        _alert(
          "✅ Sukses",
          "Akun '${data['user']['username']}' berhasil dibuat.",
        );
        createUsernameController.clear();
        createPasswordController.clear();
        createDayController.clear();
        newUserRole = 'member';
        _fetchUsers();
      } else {
        _alert("❌ Gagal", data['message'] ?? 'Gagal membuat akun.');
      }
    } catch (_) {
      _alert("🌐 Error", "Gagal menghubungi server.");
    }
    setState(() => isLoading = false);
  }

  // --- METODE UNTUK CREATE ROLE ---
  Future<void> _pickPhoto() async {
    try {
      final photo = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (photo != null) {
        setState(() => selectedPhotoFile = photo);
        _alert("✅ Sukses", "Foto berhasil dipilih.");
      }
    } catch (e) {
      _alert("❌ Error", "Gagal memilih foto: $e");
    }
  }

  Future<String?> _imageToBase64(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    } catch (e) {
      _alert("❌ Error", "Gagal convert foto ke base64: $e");
      return null;
    }
  }

  Future<void> _createRoleRequest() async {
    final roleName = roleNameController.text.trim();
    final review = roleReviewController.text.trim();

    if (roleName.isEmpty) {
      _alert("⚠️ Error", "Nama role wajib diisi.");
      return;
    }

    if (selectedPhotoFile == null) {
      _alert("⚠️ Error", "Foto bukti transaksi wajib diunggah.");
      return;
    }

    if (review.isEmpty) {
      _alert("⚠️ Error", "Review/Catatan wajib diisi.");
      return;
    }

    setState(() => isCreatingRole = true);
    try {
      final photoBase64 = await _imageToBase64(selectedPhotoFile!);
      if (photoBase64 == null) {
        setState(() => isCreatingRole = false);
        return;
      }

      final response = await http.post(
        Uri.parse('http://tirz.panel.jserver.web.id:2001/createRole'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': sessionKey,
          'roleName': roleName,
          'photoBase64': photoBase64,
          'review': review,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      final data = jsonDecode(response.body);
      if (data['created'] == true) {
        _alert(
          "✅ Sukses",
          "Role '$roleName' berhasil diajukan ke admin.\nFoto dan review sudah dikirim ke bot.",
        );
        roleNameController.clear();
        roleReviewController.clear();
        selectedPhotoFile = null;
      } else {
        _alert("❌ Gagal", data['message'] ?? 'Gagal membuat role request.');
      }
    } catch (e) {
      _alert("🌐 Error", "Gagal menghubungi server: $e");
    }
    setState(() => isCreatingRole = false);
  }

  // --- METODE UNTUK CREATE ROLE ---
  void _alert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: accentPurple.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: accentPurple,
            ), // Icon Info Outline sesuai permintaan
            const SizedBox(width: 10),
            Text(
              "Information",
              style: TextStyle(color: primaryWhite),
            ), // Judul tetap Information
          ],
        ),
        content: Text(message, style: TextStyle(color: Colors.white70)),
        actions: [
          Center(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primaryPurple, accentPurple]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "OK",
                  style: TextStyle(
                    color: primaryWhite,
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

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        keyboardType: type,
        style: TextStyle(color: primaryWhite),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: accentPurple),
          prefixIcon: Icon(icon, color: accentPurple),
          filled: true,
          fillColor: cardGlass,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderGlass),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderGlass),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accentPurple, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 30),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardGlass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderGlass),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentPurple),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: primaryWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildUserItem(Map user) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGlass),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryPurple.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, color: accentPurple),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['username'],
                  style: TextStyle(
                    color: primaryWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "${user['role'].toUpperCase()} | Exp: ${user['expiredDate']}",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                SizedBox(height: 2),
                Text(
                  "Parent: ${user['parent'] ?? 'SYSTEM'}",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),

          // --- TOMBOL DELETE DENGAN STYLE SNIPPET ---
          Container(
            decoration: BoxDecoration(
              color: primaryPurple.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: primaryPurple.withOpacity(0.3)),
            ),
            child: IconButton(
              icon: Icon(Icons.delete_outline, color: primaryPurple),
              onPressed: () async {
                // --- DIALOG KONFIRMASI DELETE (STYLE ALERT) ---
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: bgDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: accentPurple.withOpacity(0.3)),
                    ),
                    title: Row(
                      children: [
                        Icon(Icons.info_outline, color: accentPurple),
                        const SizedBox(width: 10),
                        Text(
                          "Konfirmasi",
                          style: TextStyle(color: primaryWhite),
                        ),
                      ],
                    ),
                    content: Text(
                      "Yakin ingin menghapus user '${user['username']}'?",
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      Container(
                        width: double.infinity, // Full width
                        margin: EdgeInsets.symmetric(
                          horizontal: 24,
                        ), // Side padding
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween, // Push to edges
                          children: [
                            // TOMBOL BATAL
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryPurple, accentPurple],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(
                                  "Batal",
                                  style: TextStyle(
                                    color: primaryWhite,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            // TOMBOL HAPUS (Red Gradient)
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    primaryPurple,
                                    const Color(0xFF7A5CFF),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  "Hapus",
                                  style: TextStyle(
                                    color: primaryWhite,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  deleteController.text = user['username'];
                  _deleteUser();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(totalPages, (index) {
        final page = index + 1;
        return ElevatedButton(
          onPressed: () => setState(() => currentPage = page),
          style: ElevatedButton.styleFrom(
            backgroundColor: currentPage == page
                ? accentPurple
                : Colors.transparent,
            foregroundColor: currentPage == page
                ? primaryWhite
                : Colors.white54,
            padding: EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: borderGlass),
            ),
          ),
          child: Text("$page", style: TextStyle(fontSize: 12)),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgDark, primaryPurple.withOpacity(0.1), bgDark],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header
                Icon(Icons.admin_panel_settings, color: accentPurple, size: 50),
                SizedBox(height: 10),
                Text(
                  "ADMIN DASHBOARD",
                  style: TextStyle(
                    color: primaryWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: primaryPurple.withOpacity(0.8),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40),

                // SECTION 1: CREATE ROLE (BARU)
                _buildGlassCard(
                  title: "CREATE ROLE",
                  icon: FontAwesomeIcons.crown,
                  children: [
                    // Role Name Input
                    _buildInput(
                      label: "Role Name",
                      controller: roleNameController,
                      icon: FontAwesomeIcons.tag,
                    ),

                    // Review/Notes Input
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: TextField(
                        controller: roleReviewController,
                        maxLines: 4,
                        style: TextStyle(color: primaryWhite),
                        decoration: InputDecoration(
                          labelText: "Review / Catatan Transaksi",
                          labelStyle: TextStyle(color: accentPurple),
                          prefixIcon: Icon(
                            FontAwesomeIcons.noteSticky,
                            color: accentPurple,
                          ),
                          filled: true,
                          fillColor: cardGlass,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderGlass),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderGlass),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: accentPurple,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Photo Upload Section
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderGlass),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "📸 Bukti Transaksi",
                            style: TextStyle(
                              color: accentPurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 12),
                          if (selectedPhotoFile != null)
                            Column(
                              children: [
                                Container(
                                  height: 150,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: accentPurple),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(selectedPhotoFile!.path),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  selectedPhotoFile!.name,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 12),
                              ],
                            ),
                          Container(
                            height: 45,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryPurple, accentPurple],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: isCreatingRole ? null : _pickPhoto,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: Icon(FontAwesomeIcons.image, size: 16),
                              label: Text(
                                selectedPhotoFile != null
                                    ? "Ubah Foto"
                                    : "Pilih Foto",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Submit Button
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryPurple, accentPurple],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: primaryPurple.withOpacity(0.4),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: isCreatingRole ? null : _createRoleRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(FontAwesomeIcons.paperPlane, size: 16),
                        label: isCreatingRole
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryWhite,
                                ),
                              )
                            : Text(
                                "SUBMIT ROLE REQUEST",
                                style: TextStyle(
                                  color: primaryWhite,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),

                // SECTION 2: DELETE USER
                _buildGlassCard(
                  title: "DELETE USER",
                  icon: FontAwesomeIcons.userSlash,
                  children: [
                    _buildInput(
                      label: "Username Target",
                      controller: deleteController,
                      icon: FontAwesomeIcons.user,
                    ),
                    SizedBox(height: 10),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryPurple, const Color(0xFF7A5CFF)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF7A5CFF).withOpacity(0.3),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _deleteUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "DELETE ACCOUNT",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // SECTION 2: CREATE ACCOUNT
                _buildGlassCard(
                  title: "CREATE ACCOUNT",
                  icon: FontAwesomeIcons.userPlus,
                  children: [
                    _buildInput(
                      label: "Username",
                      controller: createUsernameController,
                      icon: FontAwesomeIcons.user,
                    ),
                    _buildInput(
                      label: "Password",
                      controller: createPasswordController,
                      icon: FontAwesomeIcons.lock,
                    ),
                    _buildInput(
                      label: "Durasi (Hari)",
                      controller: createDayController,
                      icon: FontAwesomeIcons.calendarDay,
                      type: TextInputType.number,
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderGlass),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: newUserRole,
                          dropdownColor: bgDark,
                          style: TextStyle(color: primaryWhite),
                          items: roleOptions.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(role.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => newUserRole = val ?? 'member'),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryPurple, accentPurple],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: primaryPurple.withOpacity(0.4),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _createAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryWhite,
                                ),
                              )
                            : Text(
                                "CREATE ACCOUNT",
                                style: TextStyle(
                                  color: primaryWhite,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),

                // SECTION 3: USER LIST
                _buildGlassCard(
                  title: "USER MANAGEMENT",
                  icon: FontAwesomeIcons.users,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderGlass),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedRole,
                          dropdownColor: bgDark,
                          style: TextStyle(color: primaryWhite),
                          items: roleOptions.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(role.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              selectedRole = val;
                              _filterAndPaginate();
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: accentPurple,
                            ),
                          )
                        : Column(
                            children: [
                              ..._getCurrentPageData()
                                  .map((u) => _buildUserItem(u))
                                  .toList(),
                              SizedBox(height: 20),
                              _buildPagination(),
                            ],
                          ),
                  ],
                ),

                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
