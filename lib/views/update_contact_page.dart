import 'package:contacts_app/controllers/crud_services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UpdateContactPage extends StatefulWidget {
  final String docId;
  final String currentName;
  final String currentPhone;
  final String currentEmail;

  const UpdateContactPage({
    super.key,
    required this.docId,
    required this.currentName,
    required this.currentPhone,
    required this.currentEmail,
  });

  @override
  State<UpdateContactPage> createState() => _UpdateContactPageState();
}

class _UpdateContactPageState extends State<UpdateContactPage> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _phoneController = TextEditingController(text: widget.currentPhone);
    _emailController = TextEditingController(text: widget.currentEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _updateContact() async {
    if (formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final result = await CrudService().updateContact(
        _nameController.text.trim(),
        _phoneController.text.trim(),
        _emailController.text.trim(),
        widget.docId,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Contact updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  void _deleteContact() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Delete Contact",
            style: GoogleFonts.sora(fontWeight: FontWeight.w700)),
        content: Text(
            "Are you sure you want to delete \"${widget.currentName}\"?",
            style: GoogleFonts.sora(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel",
                style: GoogleFonts.sora(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Delete",
                style: GoogleFonts.sora(color: Colors.red.shade400)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await CrudService().deleteContact(widget.docId);
      if (!mounted) return;
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Contact deleted")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  String get _initials {
    final parts = widget.currentName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return widget.currentName.isNotEmpty
        ? widget.currentName[0].toUpperCase()
        : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF2D2D2D), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Update Contact",
          style: GoogleFonts.sora(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2D2D2D),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              // Avatar
              Center(
                child: CircleAvatar(
                  backgroundColor: const Color(0xFFE8896A),
                  radius: 40,
                  child: Text(
                    _initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.currentName,
                style: GoogleFonts.sora(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D2D2D)),
              ),
              const SizedBox(height: 28),

              _buildTextField(
                controller: _nameController,
                label: "Name",
                prefixIcon: Icons.person_outline,
                validator: (v) =>
                    v == null || v.isEmpty ? "Name cannot be empty." : null,
              ),
              const SizedBox(height: 14),

              _buildTextField(
                controller: _phoneController,
                label: "Phone",
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v == null || v.isEmpty ? "Phone cannot be empty." : null,
              ),
              const SizedBox(height: 14),

              _buildTextField(
                controller: _emailController,
                label: "Email",
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  if (!v.contains('@')) return "Enter a valid email.";
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Update Button
              SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateContact,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8896A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text("Update",
                          style: GoogleFonts.sora(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),

              // Delete Button
              SizedBox(
                height: 54,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _deleteContact,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    "Delete",
                    style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade400),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.sora(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.sora(color: Colors.grey.shade500, fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFFE8896A), size: 20),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0D5CF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0D5CF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE8896A), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
