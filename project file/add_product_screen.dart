import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tech_borrow/services/database_helper.dart';
import 'package:tech_borrow/services/auth_service.dart';
import 'package:tech_borrow/ui/screens/widgets/background_widget.dart';
import 'package:tech_borrow/ui/screens/utility/app_colors.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _specsController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  File? _image;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register New Item'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
      ),
      body: BackgroundWidget(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 140,
                          width: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
                            ],
                          ),
                          child: _image != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.file(_image!, fit: BoxFit.cover),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, size: 40, color: Appcolors.primary),
                                    SizedBox(height: 8),
                                    Text('Add Photo', style: TextStyle(color: Appcolors.textSecondary, fontSize: 12)),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(hintText: 'Item Title'),
                      validator: (value) => value?.isEmpty ?? true ? 'Enter title' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _specsController,
                      maxLines: 4,
                      decoration: const InputDecoration(hintText: 'Specifications / Condition'),
                    ),
                    const SizedBox(height: 32),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _onTapRegister,
                            child: const Text('List Item for Borrowing'),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onTapRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = await AuthService.getUid();
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? base64Image;
      if (_image != null) {
        final bytes = await _image!.readAsBytes();
        base64Image = base64Encode(bytes);
      }

      final dbHelper = DatabaseHelper();
      final userData = await dbHelper.getUserByUid(uid);

      await dbHelper.insertItem({
        'title': _titleController.text.trim(),
        'specs': _specsController.text.trim(),
        'userId': uid,
        'userEmail': userData?['email'],
        'ownerName': '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}'.trim(),
        'ownerStudentId': userData?['studentId'] ?? 'N/A',
        'image': base64Image,
        'createdAt': DateTime.now().toIso8601String(),
        'isAvailable': 1,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item listed successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _specsController.dispose();
    super.dispose();
  }
}
