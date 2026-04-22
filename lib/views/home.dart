import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_app/controllers/auth_services.dart';
import 'package:contacts_app/controllers/crud_services.dart';
import 'package:contacts_app/views/add_contact_page.dart';
import 'package:contacts_app/views/update_contact_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, "/login");
  }

  void _confirmDelete(BuildContext context, String docId, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Delete Contact",
            style: GoogleFonts.sora(fontWeight: FontWeight.w700)),
        content: Text("Are you sure you want to delete \"$name\"?",
            style: GoogleFonts.sora(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel",
                style: GoogleFonts.sora(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () async {
              final result = await CrudService().deleteContact(docId);
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result ?? "Contact deleted"),
                  backgroundColor: result == null ? null : Colors.red.shade400,
                ),
              );
            },
            child: Text("Delete",
                style: GoogleFonts.sora(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
        title: Text(
          "Contacts",
          style: GoogleFonts.sora(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2D2D2D),
          ),
        ),
        actions: [
          // User avatar
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _showProfileBottomSheet(context),
              child: CircleAvatar(
                backgroundColor: const Color(0xFFE8896A),
                radius: 18,
                child: Text(
                  _currentUser?.email?.substring(0, 1).toUpperCase() ?? "U",
                  style: GoogleFonts.sora(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
              style: GoogleFonts.sora(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Search",
                hintStyle:
                    GoogleFonts.sora(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.grey, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: Colors.grey, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0D5CF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0D5CF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFE8896A), width: 1.5),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // Contacts list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: CrudService().getContacts(searchQuery: _searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE8896A)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error loading contacts",
                        style: GoogleFonts.sora(color: Colors.red)),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off_outlined,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty
                              ? "No contacts yet\nTap + to add one"
                              : "No contacts found for \"$_searchQuery\"",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.sora(
                              color: Colors.grey.shade400, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 2),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? '';
                    final phone = data['phone'] ?? '';
                    final email = data['email'] ?? '';
                    final docId = doc.id;

                    return _ContactTile(
                      name: name,
                      phone: phone,
                      email: email,
                      docId: docId,
                      onDelete: () => _confirmDelete(context, docId, name),
                      onCall: () async {
                        if (phone.isNotEmpty) {
                          final uri = Uri(scheme: 'tel', path: phone);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        }
                      },
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UpdateContactPage(
                              docId: docId,
                              currentName: name,
                              currentPhone: phone,
                              currentEmail: email,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddContactPage()),
          );
        },
        backgroundColor: const Color(0xFFE8896A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  void _showProfileBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              backgroundColor: const Color(0xFFE8896A),
              radius: 32,
              child: Text(
                _currentUser?.email?.substring(0, 1).toUpperCase() ?? "U",
                style: GoogleFonts.sora(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 28),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _currentUser?.displayName ?? "User",
              style:
                  GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              _currentUser?.email ?? "",
              style:
                  GoogleFonts.sora(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _logout();
                },
                icon: const Icon(Icons.logout, size: 18),
                label: Text("Logout",
                    style: GoogleFonts.sora(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final String name;
  final String phone;
  final String email;
  final String docId;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onCall;

  const _ContactTile({
    required this.name,
    required this.phone,
    required this.email,
    required this.docId,
    required this.onTap,
    required this.onDelete,
    required this.onCall,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color get _avatarColor {
    final colors = [
      const Color(0xFFE8896A),
      const Color(0xFF6A9FE8),
      const Color(0xFF6AE8A0),
      const Color(0xFFB36AE8),
      const Color(0xFFE8C96A),
    ];
    return colors[name.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: _avatarColor,
          radius: 22,
          child: Text(
            _initials,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        title: Text(
          name,
          style: GoogleFonts.sora(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: const Color(0xFF2D2D2D)),
        ),
        subtitle: Text(
          phone.isNotEmpty ? phone : (email.isNotEmpty ? email : 'No info'),
          style: GoogleFonts.sora(fontSize: 12, color: Colors.grey.shade500),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.call, color: Color(0xFFE8896A), size: 20),
              tooltip: "Call",
              onPressed: phone.isNotEmpty ? onCall : null,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: Colors.red.shade300, size: 20),
              tooltip: "Delete",
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
