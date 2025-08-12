import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminUserManagement extends StatefulWidget {
  const AdminUserManagement({super.key});

  @override
  State<AdminUserManagement> createState() => _AdminUserManagementState();
}

class _AdminUserManagementState extends State<AdminUserManagement>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  String _selectedRole = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'All Users'),
            Tab(text: 'Providers'),
            Tab(text: 'Regular Users'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddUserDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    underline: Container(), // Remove default underline
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Roles')),
                      DropdownMenuItem(value: 'user', child: Text('Users')),
                      DropdownMenuItem(
                          value: 'provider', child: Text('Pet Sitters')),
                      DropdownMenuItem(value: 'admin', child: Text('Admins')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedRole = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserList('all'),
                _buildUserList('provider'),
                _buildUserList('user'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(String userType) {
    return StreamBuilder<QuerySnapshot>(
      key: ValueKey('user_list_$userType'), // Force refresh when needed
      stream: _getUserStream(userType),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Icon(Icons.error_outline,
                        color: Colors.red.shade700, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading users',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check your permissions or try again later.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading users...'),
              ],
            ),
          );
        }

        final users = snapshot.data?.docs ?? [];
        final filteredUsers = _filterUsers(users);

        if (filteredUsers.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Icon(Icons.people_outline,
                        color: Colors.grey.shade600, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No users found',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try adjusting your search or filters to find users.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddUserDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add New User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredUsers.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final userData =
                filteredUsers[index].data() as Map<String, dynamic>;
            final userId = filteredUsers[index].id;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      _getUserRoleColor(userData['role'] ?? 'user'),
                  child: Icon(
                    _getUserRoleIcon(userData['role'] ?? 'user'),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  userData['name'] ??
                      userData['displayName'] ??
                      userData['email'] ??
                      'Unknown User',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      userData['email'] ?? 'No email',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userData['phoneNumber'] ??
                          userData['phone'] ??
                          'No phone',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getUserRoleColor(userData['role'] ?? 'user')
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getUserRoleColor(userData['role'] ?? 'user')
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        userData['role'] ?? 'user',
                        style: TextStyle(
                          color: _getUserRoleColor(userData['role'] ?? 'user'),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                  onSelected: (value) =>
                      _handleUserAction(value, userId, userData),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 18),
                          SizedBox(width: 8),
                          Text('View Details'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit User'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Delete User',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getUserStream(String userType) {
    if (userType == 'all') {
      return _firestore.collection('users').snapshots();
    } else {
      return _firestore
          .collection('users')
          .where('role', isEqualTo: userType)
          .snapshots();
    }
  }

  List<QueryDocumentSnapshot> _filterUsers(List<QueryDocumentSnapshot> users) {
    return users.where((user) {
      final userData = user.data() as Map<String, dynamic>;
      final email = userData['email']?.toString().toLowerCase() ?? '';
      final name = userData['name']?.toString().toLowerCase() ?? '';
      final displayName =
          userData['displayName']?.toString().toLowerCase() ?? '';
      final phone = userData['phoneNumber']?.toString().toLowerCase() ?? '';
      final phoneAlt = userData['phone']?.toString().toLowerCase() ?? '';
      final role = userData['role']?.toString() ?? '';

      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          email.contains(_searchQuery.toLowerCase()) ||
          name.contains(_searchQuery.toLowerCase()) ||
          displayName.contains(_searchQuery.toLowerCase()) ||
          phone.contains(_searchQuery.toLowerCase()) ||
          phoneAlt.contains(_searchQuery.toLowerCase());

      // Role filter
      final matchesRole = _selectedRole == 'All' || role == _selectedRole;

      return matchesSearch && matchesRole;
    }).toList();
  }

  Color _getUserRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.purple;
      case 'provider':
      case 'petsitter':
        return Colors.green;
      case 'user':
      default:
        return Colors.blue;
    }
  }

  IconData _getUserRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'provider':
      case 'petsitter':
        return Icons.pets;
      case 'user':
      default:
        return Icons.person;
    }
  }

  void _handleUserAction(
      String action, String userId, Map<String, dynamic> userData) {
    switch (action) {
      case 'view':
        _showUserDetails(userId, userData);
        break;
      case 'edit':
        _showEditUserDialog(userId, userData);
        break;
      case 'delete':
        _showDeleteUserDialog(userId, userData);
        break;
    }
  }

  void _showUserDetails(String userId, Map<String, dynamic> userData) {
    // Debug: Show all available fields
    print('=== USER DATA DEBUG ===');
    print('User ID: $userId');
    userData.forEach((key, value) {
      print('$key: $value (${value.runtimeType})');
    });
    print('========================');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.person, color: Colors.purple),
                  const SizedBox(width: 8),
                  const Text(
                    'User Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('User ID', userId),
                      _buildDetailRow('Email', userData['email'] ?? 'N/A'),
                      _buildDetailRow('Name',
                          userData['name'] ?? userData['displayName'] ?? 'N/A'),
                      _buildDetailRow('Role', userData['role'] ?? 'user'),
                      _buildDetailRow(
                          'Phone',
                          userData['phoneNumber'] ??
                              userData['phone'] ??
                              'N/A'),
                      _buildDetailRow('Address', userData['address'] ?? 'N/A'),
                      _buildDetailRow(
                          'Telegram ID', userData['telegramId'] ?? 'N/A'),
                      _buildDetailRow('Last Updated',
                          _formatTimestamp(userData['updatedAt'])),

                      // Provider-specific fields (only show for providers)
                      if (userData['role'] == 'provider' ||
                          userData['isPetSitter'] == true) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.green.withOpacity(0.3)),
                          ),
                          child: const Text(
                            'Provider Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                            'Services', _formatServices(userData['services'])),
                        _buildDetailRow(
                            'Pet Types', _formatPetTypes(userData['petTypes'])),
                        _buildDetailRow(
                            'Experience', userData['experience'] ?? 'N/A'),
                        _buildDetailRow(
                            'Rate',
                            userData['rate'] != null
                                ? '\$${userData['rate']}/hr'
                                : 'N/A'),
                        _buildDetailRow(
                            'Rating',
                            userData['rating'] != null
                                ? '${userData['rating']}/5.0'
                                : 'N/A'),
                        _buildDetailRow('Review Count',
                            userData['reviewCount']?.toString() ?? '0'),
                        _buildDetailRow('Completed Bookings',
                            userData['completedBookings']?.toString() ?? '0'),
                        _buildDetailRow('Verification Status',
                            userData['verificationStatus'] ?? 'N/A'),
                        _buildDetailRow(
                            'Trust Score',
                            userData['trustScore'] != null
                                ? '${userData['trustScore']}/100'
                                : 'N/A'),
                        _buildDetailRow(
                            'Trust Level', userData['trustLevel'] ?? 'N/A'),
                        _buildDetailRow('Setup Completed',
                            userData['setupCompleted']?.toString() ?? 'No'),
                        _buildDetailRow(
                            'Location', _formatLocation(userData['location'])),
                      ],

                      // User Pet Details
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: const Text(
                          'User Pet Details',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<QuerySnapshot>(
                        future: _firestore
                            .collection('users')
                            .doc(userId)
                            .collection('pets')
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Loading pets...'),
                                ],
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Error loading pets: ${snapshot.error}',
                                style: const TextStyle(color: Colors.red),
                              ),
                            );
                          }

                          final pets = snapshot.data?.docs ?? [];

                          if (pets.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'No pets found',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: pets.map((petDoc) {
                              final petData =
                                  petDoc.data() as Map<String, dynamic>;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '🐾 ${petData['name'] ?? 'Unknown Pet'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Type: ${petData['type'] ?? 'N/A'}'),
                                    Text('Breed: ${petData['breed'] ?? 'N/A'}'),
                                    Text(
                                        'Age: ${petData['age']?.toString() ?? 'N/A'} years'),
                                    if (petData['notes'] != null &&
                                        petData['notes'].toString().isNotEmpty)
                                      Text('Notes: ${petData['notes']}'),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom actions
              if (userData['role'] == 'provider' ||
                  userData['isPetSitter'] == true) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Navigate to verification dashboard to check this provider's verification
                          // You can implement this navigation if needed
                        },
                        child: const Text('Check Verification'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(String userId, Map<String, dynamic> userData) {
    // Use the actual name field that's displayed in the list
    final actualName = userData['name'] ?? userData['displayName'] ?? '';
    final displayNameController = TextEditingController(text: actualName);
    final emailController =
        TextEditingController(text: userData['email'] ?? '');
    final phoneController = TextEditingController(
        text: userData['phone'] ?? userData['phoneNumber'] ?? '');

    // Fix the role mapping to ensure it matches dropdown values
    String userRole = userData['role'] ?? 'user';
    String selectedRole = 'user'; // Default value

    // Map the user role to a valid dropdown value
    print('Debug: User role from database: "$userRole"');
    if (userRole == 'provider' || userRole == 'petsitter') {
      selectedRole = 'provider';
    } else if (userRole == 'admin') {
      selectedRole = 'admin';
    } else {
      selectedRole = 'user';
    }
    print('Debug: Mapped to dropdown value: "$selectedRole"');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Edit User'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                enabled: false, // Email cannot be changed
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security),
                ),
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('User')),
                  DropdownMenuItem(
                      value: 'provider', child: Text('Pet Sitter')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) {
                  selectedRole = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _updateUser(userId, {
                'name': displayNameController.text,
                'displayName': displayNameController.text,
                'phone': phoneController.text,
                'phoneNumber': phoneController.text,
                'role': selectedRole,
                'updatedAt': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final displayNameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRole = 'user'; // Default value for new users

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.add, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Add New User'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security),
                ),
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('User')),
                  DropdownMenuItem(
                      value: 'provider', child: Text('Pet Sitter')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) {
                  selectedRole = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _createUser({
                'displayName': displayNameController.text,
                'email': emailController.text,
                'phone': phoneController.text,
                'role': selectedRole,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showDeleteUserDialog(String userId, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete ${userData['displayName'] ?? userData['email']}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _deleteUser(userId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUser(String userId, Map<String, dynamic> data) async {
    try {
      print('Debug: Updating user $userId with data: $data');
      await _firestore.collection('users').doc(userId).update(data);
      print('Debug: User update successful');

      // Force a refresh of the UI
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Debug: Error updating user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createUser(Map<String, dynamic> userData) async {
    try {
      // Create user in Firebase Auth
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: userData['email'],
        password:
            'defaultPassword123', // You might want to generate a random password
      );

      // Add user data to Firestore
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User created successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      // Delete from Firestore
      await _firestore.collection('users').doc(userId).delete();

      // Note: Deleting from Firebase Auth requires admin SDK
      // This is handled server-side for security

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatServices(dynamic services) {
    if (services == null) return 'N/A';
    if (services is List) {
      return services.join(', ');
    }
    return services.toString();
  }

  String _formatPetTypes(dynamic petTypes) {
    if (petTypes == null) return 'N/A';
    if (petTypes is List) {
      return petTypes.join(', ');
    }
    return petTypes.toString();
  }

  String _formatLocation(dynamic location) {
    if (location == null) return 'N/A';
    if (location is Map<String, dynamic>) {
      final lat = location['lat'];
      final lng = location['lng'];
      if (lat != null && lng != null) {
        return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      }
    }
    return location.toString();
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      return timestamp.toDate().toString().substring(0, 19);
    }
    if (timestamp is String) {
      try {
        final date = DateTime.parse(timestamp);
        return date.toString().substring(0, 19);
      } catch (e) {
        return timestamp;
      }
    }
    return timestamp.toString();
  }
}
