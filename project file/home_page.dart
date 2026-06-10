import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tech_borrow/services/database_helper.dart';
import 'package:tech_borrow/services/auth_service.dart';
import 'package:tech_borrow/ui/screens/add_product_screen.dart';
import 'package:tech_borrow/ui/screens/sign_in_screen.dart';
import 'package:tech_borrow/ui/screens/item_details_screen.dart';
import 'package:tech_borrow/ui/screens/user_profile.dart';
import 'package:tech_borrow/ui/screens/utility/app_colors.dart';
import 'package:tech_borrow/ui/screens/widgets/background_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() {
      _isLoading = true;
    });
    final items = await DatabaseHelper().getAllItems();
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? 'Tech Borrow' : 'Profile',
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                _onLogout();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Appcolors.textSecondary),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: BackgroundWidget(
        child: SafeArea(
          child: _selectedIndex == 0 ? _buildItemsView() : const UserProfileScreen(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Appcolors.primary,
        unselectedItemColor: Appcolors.textSecondary,
        backgroundColor: Appcolors.surface,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Items',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _onTapAddProduct,
              backgroundColor: Appcolors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildItemsView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return const Center(
        child: Text(
          'No items registered yet.\nTap + to add one!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Appcolors.textSecondary, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        return _buildTechItem(_items[index]);
      },
    );
  }

  Widget _buildTechItem(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailsScreen(itemData: item),
            ),
          );
          if (result == true) {
             _fetchItems();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: item['image'] != null && item['image'].toString().isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          base64Decode(item['image']),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image_not_supported, size: 40, color: Appcolors.textSecondary),
                        ),
                      )
                    : const Icon(Icons.devices, size: 40, color: Appcolors.textSecondary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] ?? 'Unknown Item',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Appcolors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item['specs'] != null && item['specs'].toString().isNotEmpty)
                      Text(
                        item['specs'],
                        style: const TextStyle(fontSize: 14, color: Appcolors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Owner: ${item['ownerName'] ?? 'Unknown'}',
                      style: const TextStyle(fontSize: 12, color: Appcolors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Appcolors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onTapAddProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProductScreen()),
    );
    if (result == true) {
      _fetchItems();
    }
  }

  void _onLogout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SignInScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
