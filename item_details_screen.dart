import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tech_borrow/services/database_helper.dart';
import 'package:tech_borrow/services/auth_service.dart';
import 'package:tech_borrow/ui/screens/widgets/background_widget.dart';
import 'package:tech_borrow/ui/screens/utility/app_colors.dart';

class ItemDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> itemData;

  const ItemDetailsScreen({super.key, required this.itemData});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  DateTime? _selectedReturnDate;
  String? _currentUserUid;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final uid = await AuthService.getUid();
    setState(() {
      _currentUserUid = uid;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Appcolors.primary,
              onPrimary: Colors.white,
              onSurface: Appcolors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedReturnDate) {
      setState(() {
        _selectedReturnDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BackgroundWidget(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  height: 250,
                  width: 250,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: widget.itemData['image'] != null && widget.itemData['image'].toString().isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.memory(
                            base64Decode(widget.itemData['image']),
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.devices, size: 100, color: Appcolors.textSecondary),
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.itemData['title'] ?? 'Unknown Item',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoSection('Specifications', widget.itemData['specs'] ?? 'No specifications provided'),
                    const SizedBox(height: 24),
                    _buildInfoSection('Owner Name', widget.itemData['ownerName'] ?? 'Unknown'),
                    const SizedBox(height: 24),
                    _buildInfoSection('Owner Student ID', widget.itemData['ownerStudentId'] ?? 'N/A'),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.itemData['isAvailable'] == 1 ? Icons.check_circle : Icons.cancel,
                            color: widget.itemData['isAvailable'] == 1 ? Colors.green : Appcolors.error,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.itemData['isAvailable'] == 1 ? 'Available for Borrowing' : 'Currently Borrowed',
                            style: const TextStyle(color: Appcolors.textPrimary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (_currentUserUid != widget.itemData['userId'])
                      Column(
                        children: [
                          InkWell(
                            onTap: () => _selectDate(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Appcolors.primary),
                                  const SizedBox(width: 12),
                                  Text(
                                    _selectedReturnDate == null
                                        ? 'Select Return Deadline'
                                        : 'Return by: ${_selectedReturnDate!.day}/${_selectedReturnDate!.month}/${_selectedReturnDate!.year}',
                                    style: const TextStyle(color: Appcolors.textPrimary, fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.arrow_drop_down, color: Appcolors.textSecondary),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _sendBorrowRequest(context),
                            child: const Text('Send Borrow Request'),
                          ),
                        ],
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: const Center(
                          child: Text(
                            'You own this item',
                            style: TextStyle(color: Appcolors.textSecondary, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendBorrowRequest(BuildContext context) async {
    if (_currentUserUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to send requests')),
      );
      return;
    }

    if (_selectedReturnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a return deadline first!')),
      );
      return;
    }

    try {
      final dbHelper = DatabaseHelper();
      final userEmail = await AuthService.getEmail();

      await dbHelper.insertRequest({
        'itemId': widget.itemData['id'],
        'itemTitle': widget.itemData['title'],
        'ownerId': widget.itemData['userId'],
        'senderId': _currentUserUid,
        'senderEmail': userEmail,
        'deadline': _selectedReturnDate!.toIso8601String(),
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Borrow request sent with deadline!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildInfoSection(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Appcolors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Appcolors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
