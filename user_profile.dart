import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tech_borrow/services/database_helper.dart';
import 'package:tech_borrow/services/auth_service.dart';
import 'package:tech_borrow/ui/screens/utility/app_colors.dart';
import 'package:tech_borrow/ui/screens/widgets/background_widget.dart';

class UserProfileScreen extends StatefulWidget {
  final Map<String, String>? item;
  final Map<String, String>? userData;
  final bool isStandalone;

  const UserProfileScreen({super.key, this.item, this.userData, this.isStandalone = false});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _profileData;
  List<Map<String, dynamic>> _myItems = [];
  List<Map<String, dynamic>> _incomingRequests = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    final uid = await AuthService.getUid();
    if (uid != null) {
      final dbHelper = DatabaseHelper();
      final profile = await dbHelper.getUserByUid(uid);
      final items = await dbHelper.getMyItems(uid);
      final requests = await dbHelper.getIncomingRequests(uid);

      if (mounted) {
        setState(() {
          _profileData = profile;
          _myItems = items;
          _incomingRequests = requests;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickAndSaveImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 200,
      maxHeight: 200,
      imageQuality: 30,
    );

    if (image == null) return;

    final uid = await AuthService.getUid();
    if (uid == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final bytes = await image.readAsBytes();
      if (bytes.length > 700000) {
        throw Exception("Image too large");
      }
      final base64String = base64Encode(bytes);

      await DatabaseHelper().updateUserProfile(uid, {
        'profilePic': base64String,
      });

      setState(() {
        _profileData?['profilePic'] = base64String;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isStandalone) {
      return Scaffold(
        body: BackgroundWidget(
          child: SafeArea(
            child: _buildBody(context),
          ),
        ),
      );
    }
    return _buildBody(context);
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          if (widget.isStandalone) _buildTopBar(context),
          const SizedBox(height: 16),
          _buildProfileHeader(),
          const TabBar(
            indicatorColor: Appcolors.primary,
            labelColor: Appcolors.primary,
            unselectedLabelColor: Appcolors.textSecondary,
            labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            tabs: [
              Tab(icon: Icon(Icons.person), text: 'Info'),
              Tab(icon: Icon(Icons.inventory_2), text: 'My Items'),
              Tab(icon: Icon(Icons.notifications), text: 'Requests'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                _buildMyItemsList(),
                _buildRequestsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    if (_incomingRequests.isEmpty) {
      return const Center(child: Text("No incoming requests.", style: TextStyle(color: Appcolors.textSecondary)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _incomingRequests.length,
      itemBuilder: (context, index) {
        final req = _incomingRequests[index];
        final status = req['status'] ?? 'pending';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ListTile(
                  title: Text(req['itemTitle'] ?? 'Item', style: const TextStyle(color: Appcolors.textPrimary, fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('From: ${req['senderEmail'] ?? 'User'}', style: const TextStyle(color: Appcolors.textSecondary)),
                      if (req['deadline'] != null)
                        Text(
                          'Deadline: ${DateTime.parse(req['deadline']).day}/${DateTime.parse(req['deadline']).month}/${DateTime.parse(req['deadline']).year}',
                          style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                        ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _getStatusColor(status)),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(color: _getStatusColor(status), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (status == 'pending')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _handleRequest(req['id'], 'rejected'),
                        icon: const Icon(Icons.close, color: Appcolors.error, size: 18),
                        label: const Text('Reject', style: TextStyle(color: Appcolors.error)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _handleRequest(req['id'], 'approved'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent.withValues(alpha: 0.8),
                          foregroundColor: Appcolors.textPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Approve'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'rejected': return Appcolors.error;
      default: return Colors.orange;
    }
  }

  Future<void> _handleRequest(int id, String newStatus) async {
    try {
      await DatabaseHelper().updateRequestStatus(id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request $newStatus successfully!')),
        );
        _fetchData(); // Refresh data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildMyItemsList() {
    if (_myItems.isEmpty) {
      return const Center(child: Text("You haven't listed any items.", style: TextStyle(color: Appcolors.textSecondary)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myItems.length,
      itemBuilder: (context, index) {
        final item = _myItems[index];
        return Card(
          child: ListTile(
            leading: item['image'] != null && item['image'].toString().isNotEmpty
                ? CircleAvatar(backgroundImage: MemoryImage(base64Decode(item['image'])))
                : const CircleAvatar(child: Icon(Icons.devices)),
            title: Text(item['title'] ?? 'Unknown', style: const TextStyle(color: Appcolors.textPrimary, fontWeight: FontWeight.bold)),
            subtitle: Text(item['specs'] ?? '', style: const TextStyle(color: Appcolors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Appcolors.textSecondary),
                  onPressed: () => _editItem(item['id'], item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Appcolors.error),
                  onPressed: () => _confirmDelete(item['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Item?"),
        content: const Text("Are you sure you want to remove this item from listings?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await DatabaseHelper().deleteItem(id);
              if (context.mounted) {
                Navigator.pop(context);
                _fetchData();
              }
            },
            child: const Text("Delete", style: TextStyle(color: Appcolors.error)),
          ),
        ],
      ),
    );
  }

  void _editItem(int id, Map<String, dynamic> currentData) {
    final TextEditingController titleEdit = TextEditingController(text: currentData['title']);
    final TextEditingController specsEdit = TextEditingController(text: currentData['specs']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Item"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleEdit, decoration: const InputDecoration(labelText: "Title")),
            TextField(controller: specsEdit, decoration: const InputDecoration(labelText: "Specs"), maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await DatabaseHelper().updateItem(id, {
                'title': titleEdit.text.trim(),
                'specs': specsEdit.text.trim(),
              });
              if (context.mounted) {
                Navigator.pop(context);
                _fetchData();
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Appcolors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Profile',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Appcolors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Appcolors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final String? base64Image = _profileData?['profilePic'];

    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[200],
              backgroundImage: base64Image != null && base64Image.isNotEmpty
                  ? MemoryImage(base64Decode(base64Image)) 
                  : null,
              child: base64Image == null || base64Image.isEmpty
                  ? const Icon(Icons.person, size: 80, color: Colors.grey)
                  : null,
            ),
          ),
          InkWell(
            onTap: _isSaving ? null : _pickAndSaveImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt, size: 20, color: Appcolors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInfoRow(Icons.fingerprint, 'User ID', _profileData?['uid'] ?? 'N/A'),
            _divider(),
            _buildInfoRow(Icons.person_outline, 'Name', '${_profileData?['firstName'] ?? ''} ${_profileData?['lastName'] ?? ''}'.trim() == '' ? 'N/A' : '${_profileData?['firstName']} ${_profileData?['lastName']}'),
            _divider(),
            _buildInfoRow(Icons.badge_outlined, 'Student ID', _profileData?['studentId'] ?? 'N/A'),
            _divider(),
            _buildInfoRow(Icons.business_outlined, 'Dept', _profileData?['department'] ?? 'N/A'),
            _divider(),
            _buildInfoRow(Icons.email_outlined, 'Email', _profileData?['email'] ?? 'N/A'),
            _divider(),
            _buildInfoRow(Icons.phone_outlined, 'Phone', _profileData?['mobile'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Appcolors.primary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Appcolors.textSecondary, fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Appcolors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(color: Colors.grey.shade100, height: 1);
  }
}
