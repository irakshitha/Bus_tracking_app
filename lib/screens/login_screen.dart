import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'route_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  String selectedRole = 'Student';
  bool isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _snack('Please enter email and password');
      return;
    }

    if (!isLogin && (name.isEmpty || phone.isEmpty)) {
      _snack('Please fill in your name and phone number');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (isLogin) {
        // ── LOGIN ──
        final user = await _authService.login(email, password);
        if (user == null) return;

        final role = await _firestoreService.getUserRole(user.uid);

        // Validate that the selected role matches the stored role
        if (role != selectedRole) {
          _snack('Selected role does not match your registered role');
          await _authService.logout();
          return;
        }

        _goToRouteSelection(role ?? selectedRole, user.uid);
      } else {
        // ── REGISTER ──
        final user =
            await _authService.register(email, password, selectedRole);
        if (user == null) return;

        // Save full profile to Firestore
        await _firestoreService.saveUserProfile(
          uid: user.uid,
          name: name,
          phone: phone,
          email: email,
          role: selectedRole,
        );

        _goToRouteSelection(selectedRole, user.uid);
      }
    } catch (e) {
      _snack('${isLogin ? 'Login' : 'Registration'} failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToRouteSelection(String role, String uid) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RouteSelectionScreen(role: role, uid: uid),
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF42A5F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
            child: Column(
              children: [
                const Icon(Icons.directions_bus,
                    size: 85, color: Colors.white),
                const SizedBox(height: 10),
                const Text(
                  'Smart Bus Tracking',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isLogin ? 'Welcome back!' : 'Create your account',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 35),

                // Name + Phone fields shown only during registration
                if (!isLogin) ...[
                  _inputField(_nameCtrl, 'Full Name', Icons.person),
                  const SizedBox(height: 16),
                  _inputField(_phoneCtrl, 'Phone Number', Icons.phone,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                ],

                _inputField(_emailCtrl, 'Email', Icons.email,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _inputField(_passwordCtrl, 'Password', Icons.lock,
                    isPassword: true),
                const SizedBox(height: 24),

                // Role selection
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select Role',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _roleCard('Student', Icons.school)),
                    const SizedBox(width: 15),
                    Expanded(child: _roleCard('Driver', Icons.person)),
                  ],
                ),

                const SizedBox(height: 30),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Color(0xFF0D47A1))
                        : Text(
                            isLogin ? 'Login' : 'Register',
                            style: const TextStyle(
                              color: Color(0xFF0D47A1),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  child: Text(
                    isLogin
                        ? "Don't have an account? Register"
                        : 'Already have an account? Login',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon),
        hintText: hint,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }

  Widget _roleCard(String role, IconData icon) {
    final isSelected = selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected
                    ? const Color(0xFF0D47A1)
                    : Colors.white),
            const SizedBox(height: 5),
            Text(
              role,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF0D47A1)
                    : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
