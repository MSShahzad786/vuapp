import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vu_mcqs_app/theme/app_theme.dart';
import 'package:vu_mcqs_app/providers/auth_provider.dart';
import 'package:vu_mcqs_app/services/database_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  @override
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray100,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo Section
                _buildLogoSection(),

                const SizedBox(height: 24),

                // Social Login Buttons
                _buildSocialButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          'Vu MCQs',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.w700,
            fontSize: 28,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Welcome back',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.gray600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }


  Widget _buildSocialButtons() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          children: [
            SizedBox(
              width: 280,
              child: ElevatedButton.icon(
                onPressed: authProvider.isLoading ? null : _handleGoogleSignIn,
                icon: authProvider.isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        Icons.g_mobiledata,
                        color: Colors.white,
                        size: 18,
                      ),
                label: Text(
                  authProvider.isLoading ? 'Signing in...' : 'Sign in with Google',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }



  void _handleGoogleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dbService = DatabaseService();

    try {
      await authProvider.signInWithGoogle();

      // Set flag after successful sign-in
      await dbService.setSetting('hasSignedInBefore', 'true');

      if (!mounted) return;
    } catch (e) {
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      if (!mounted) return;
    }
  }
}
