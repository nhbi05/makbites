import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colours.dart';
import '../../constants/text_styles.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String _selectedRole = 'Customer';
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _selectedRestaurantId;
  List<Map<String, dynamic>> _restaurants = [];
  bool _showRestaurantField = false;

  final List<Map<String, dynamic>> _roles = [
    {'title': 'Customer', 'icon': Icons.person},
    {'title': 'Vendor', 'icon': Icons.store},
    {'title': 'Delivery', 'icon': Icons.delivery_dining},
  ];

  @override
  void initState() {
    super.initState();
    _fetchRestaurants();
  }

  Future<void> _fetchRestaurants() async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'vendor')  // Changed to match your role naming
        .get();
        
    setState(() {
      _restaurants = snapshot.docs.map((doc) {
        return {
          'id': doc.id,  // This is the user ID of the vendor
          'name': doc.data()['businessName'] ?? doc.data()['name'] ?? 'Unnamed Vendor'
          // Use businessName if available, fall back to name
        };
      }).toList();
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load vendors: ${e.toString()}')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Account', style: AppTextStyles.header),
              const SizedBox(height: 8),
              Text('Join MakBites community', style: AppTextStyles.body),
              const SizedBox(height: 32),
              
              // Role Selection
              Text('I am a:', style: AppTextStyles.subHeader),
              const SizedBox(height: 16),
              _buildRoleSelector(),
              const SizedBox(height: 32),
              
              // Restaurant Selection (only for delivery)
              if (_showRestaurantField) _buildRestaurantDropdown(),
              
              // Form Fields
              _buildTextField('Full Name', _nameController, Icons.person_outline),
              const SizedBox(height: 16),
              _buildEmailField(),
              const SizedBox(height: 16),
              _buildPhoneField(),
              const SizedBox(height: 16),
              _buildPasswordField(),
              const SizedBox(height: 32),
              
              // Sign Up Button
              _buildSignUpButton(),
              const SizedBox(height: 24),
              
              // Sign In Link
              _buildSignInLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _roles.map((role) {
          final isSelected = _selectedRole == role['title'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(role['icon'], size: 20),
                  const SizedBox(width: 8),
                  Text(role['title']),
                ],
              ),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedRole = role['title'];
                  _showRestaurantField = _selectedRole == 'Delivery';
                  if (!_showRestaurantField) {
                    _selectedRestaurantId = null;
                  }
                });
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRestaurantDropdown() {
  if (_restaurants.isEmpty) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text('Loading restaurants...'),
    );
  }

  return Column(
    children: [
      DropdownButtonFormField<String>(
        value: _selectedRestaurantId,
        decoration: InputDecoration(
          labelText: 'Assigned Restaurant',
          prefixIcon: Icon(Icons.restaurant),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary),
          ),
        ),
        items: _restaurants.map<DropdownMenuItem<String>>((restaurant) {
          return DropdownMenuItem<String>(
            value: restaurant['id'],
            child: Text(restaurant['name']),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedRestaurantId = value;
          });
        },
        validator: (value) {
          if (_showRestaurantField && (value == null || value.isEmpty)) {
            return 'Please select a restaurant';
          }
          return null;
        },
      ),
      SizedBox(height: 16),
    ],
  );
}
  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
      validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Email',
        prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
      validator: (value) {
        if (value!.isEmpty) return 'Please enter email';
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: 'Phone',
        prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
      validator: (value) => value!.isEmpty ? 'Please enter phone number' : null,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: Icon(Icons.lock_outlined, color: AppColors.primary),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: AppColors.primary,
          ),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
      validator: (value) {
        if (value!.isEmpty) return 'Please enter password';
        if (value.length < 6) return 'Password must be at least 6 characters';
        return null;
      },
    );
  }

  Widget _buildSignUpButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Text('Sign Up', style: AppTextStyles.button),
      ),
    );
  }

  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Already have an account? ', style: AppTextStyles.body),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/login'),
          child: Text(
            'Sign In',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    // Additional validation for delivery riders
    if (_selectedRole == 'delivery' && 
        (_selectedRestaurantId == null || _selectedRestaurantId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a restaurant')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create auth user
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // 2. Create user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
            'uid': credential.user!.uid,
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'role': _selectedRole.toLowerCase(),
            'emailVerified': false,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // 3. If delivery rider, create rider document with restaurant
      // 3. If delivery rider, create rider document with vendor association
if (_selectedRole == 'Delivery') {
  await FirebaseFirestore.instance
      .collection('delivery_riders')
      .doc('rider_${credential.user!.uid}')
      .set({
        'rider_id': 'rider_${credential.user!.uid}',
        'user_id': credential.user!.uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'vendor_id': _selectedRestaurantId,  // Now this is actually a vendor user ID
        'address': '',
        'current_location': null,
        'is_online': false,
        'total_deliveries': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

        // Update restaurant with rider assignment
        await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(_selectedRestaurantId)
            .update({
              'assigned_riders': FieldValue.arrayUnion(['rider_${credential.user!.uid}']),
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }

      // 4. Navigate to appropriate screen
      if (!mounted) return;
      _navigateToHome(_selectedRole);

    } on FirebaseAuthException catch (e) {
      _showErrorSnackbar(e.code);
    } catch (e) {
      _showErrorSnackbar('Sign-up failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToHome(String role) {
    final route = switch (role.toLowerCase()) {
      'customer' => '/customer-home',
      'vendor' => '/vendor-home',
      'delivery' => '/delivery-home',
      _ => '/',
    };
    Navigator.pushReplacementNamed(context, route);
  }

  void _showErrorSnackbar(String errorCode) {
    final message = switch (errorCode) {
      'email-already-in-use' => 'Email already registered',
      'weak-password' => 'Password too weak',
      'invalid-email' => 'Invalid email address',
      _ => 'Sign-up failed. Please try again.',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}