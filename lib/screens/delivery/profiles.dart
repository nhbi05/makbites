import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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
  Map<String, dynamic>? _riderData;
  bool _isLoading = true;
  bool _isEditing = false;
  
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      _user = _auth.currentUser!;
      
      DocumentSnapshot riderDoc = await _firestore
          .collection('delivery_riders')
          .doc(_user.uid)
          .get();
          
      if (riderDoc.exists) {
        setState(() {
          _riderData = riderDoc.data() as Map<String, dynamic>;
          _nameController.text = _riderData?['name'] ?? '';
          _phoneController.text = _riderData?['phone'] ?? '';
          _emailController.text = _riderData?['email'] ?? _user.email ?? '';
          _isLoading = false;
        });
      } else {
        // Create empty profile if doesn't exist
        setState(() {
          _riderData = {
            'name': '',
            'phone': '',
            'email': _user.email,
            'total_deliveries': 0,
            'created_at': Timestamp.now(),
            'updated_at': Timestamp.now(),
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: ${e.toString()}')),
      );
    }
  }

  Future<void> _saveProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      await _firestore
          .collection('delivery_riders')
          .doc(_user.uid)
          .set({
            'name': _nameController.text,
            'phone': _phoneController.text,
            'email': _emailController.text,
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          
      setState(() {
        _isEditing = false;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
                  // Profile Header
                  _buildProfileHeader(),
                  SizedBox(height: 24),
                  
                  // Stats Cards
                  _buildStatsSection(),
                  SizedBox(height: 24),
                  
                  // Profile Form
                  _buildProfileForm(),
                  
                  // Account Info
                  _buildAccountInfoSection(),
                  
                  // Logout Button
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
          _riderData?['name'] ?? 'No name',
          style: AppTextStyles.header,
        ),
        SizedBox(height: 4),
        Text(
          _riderData?['email'] ?? _user.email ?? '',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Deliveries',
            '${_riderData?['total_deliveries'] ?? '0'}',
            Icons.local_shipping,
            AppColors.success,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Status',
            _riderData?['is_online'] == true ? 'Online' : 'Offline',
            _riderData?['is_online'] == true ? Icons.check_circle : Icons.offline_bolt,
            _riderData?['is_online'] == true ? AppColors.success : Colors.orange,
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
      ],
    );
  }

  Widget _buildAccountInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24),
        Text('Account Information', style: AppTextStyles.subHeader),
        SizedBox(height: 16),
        ListTile(
          leading: Icon(Icons.person_outline, color: Colors.grey),
          title: Text('Rider ID'),
          subtitle: Text(_user.uid),
        ),
        ListTile(
          leading: Icon(Icons.calendar_today, color: Colors.grey),
          title: Text('Member Since'),
          subtitle: Text(
            _riderData?['created_at'] != null 
                ? DateFormat('dd MMM yyyy').format(
                    (_riderData?['created_at'] as Timestamp).toDate())
                : 'Not available',
          ),
        ),
        ListTile(
          leading: Icon(Icons.update, color: Colors.grey),
          title: Text('Last Updated'),
          subtitle: Text(
            _riderData?['updated_at'] != null 
                ? DateFormat('dd MMM yyyy HH:mm').format(
                    (_riderData?['updated_at'] as Timestamp).toDate())
                : 'Not available',
          ),
        ),
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