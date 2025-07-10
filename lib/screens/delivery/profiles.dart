import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colours.dart';
import '../../constants/text_styles.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late User _user;
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;
  bool _isEditing = false;
  
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);
      
      // Fetch from users collection
      final userDoc = await _firestore.collection('users').doc(_user.uid).get();

      if (userDoc.exists) {
        _userData = userDoc.data()!;
        _nameController.text = _userData['name'] ?? '';
        _phoneController.text = _userData['phone'] ?? '';
        _emailController.text = _userData['email'] ?? _user.email ?? '';

      } else {
        // Initialize new rider document if doesn't exist
        _userData = {
          'userType': 'rider',
          'name': '',
          'phoneNumber': '',
          'email': _user.email ?? '',
          'totalDeliveries': 0,
          'isOnline': false,
          'createdAt': Timestamp.now(),
        };
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: ${e.toString()}')),
      );
    }
  }

  Future<void> _saveProfile() async {
    try {
      setState(() => _isLoading = true);
      
      // Update user document
      await _firestore.collection('users').doc(_user.uid).set({
        'userType': 'rider',
        'name': _nameController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Refresh data
      await _loadUserData();
      setState(() => _isEditing = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            TextButton(
              onPressed: _saveProfile,
              child: Text('SAVE', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  SizedBox(height: 24),
                  _buildStatsSection(),
                  SizedBox(height: 24),
                  _buildProfileForm(),
                  SizedBox(height: 32),
                  _buildLogoutButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: AppColors.primary.withOpacity(0.2),
          child: Icon(
            Icons.person,
            size: 50,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 16),
        Text(
          _userData['name']?.isNotEmpty == true 
              ? _userData['name'] 
              : 'No name provided',
          style: AppTextStyles.header,
        ),
        SizedBox(height: 4),
        Text(
          _userData['email'] ?? _user.email ?? '',
          style: TextStyle(color: Colors.grey),
        ),
        if (_userData['userType'] == 'rider')
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Chip(
              label: Text('Delivery Rider', 
                style: TextStyle(color: Colors.white)),
              backgroundColor: AppColors.primary,
            ),
          ),
      ],
    );
  }

  Widget _buildStatsSection() {
    if (_userData['userType'] != 'rider') return SizedBox.shrink();
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Deliveries',
            '${_userData['totalDeliveries'] ?? 0}',
            Icons.local_shipping,
            AppColors.success,
          ),
        ),
       
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Status',
            (_userData['isOnline'] ?? false) ? 'Online' : 'Offline',
            (_userData['isOnline'] ?? false) ? Icons.check_circle : Icons.offline_bolt,
            (_userData['isOnline'] ?? false) ? AppColors.success : Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Profile Information', style: AppTextStyles.subHeader),
        SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          enabled: _isEditing,
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          enabled: _isEditing,
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          enabled: _isEditing,
        ),
        if (_userData['userType'] == 'rider') ...[
        ],
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          await _auth.signOut();
          Navigator.pushNamedAndRemoveUntil(
            context, 
            '/landing', 
            (route) => false,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text('Logout', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}