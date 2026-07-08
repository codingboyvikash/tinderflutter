import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class VerifyOTPScreen extends ConsumerStatefulWidget {
  final String email;
  const VerifyOTPScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyOTPScreen> createState() => _VerifyOTPScreenState();
}

class _VerifyOTPScreenState extends ConsumerState<VerifyOTPScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onKeyInput(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _submit();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  void _submit() {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == 6) {
      ref.read(authNotifierProvider.notifier).verifyOTP(widget.email, otp);
    }
  }

  void _resendOTP() {
    ref.read(authNotifierProvider.notifier).resendOTP(widget.email);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A new OTP has been sent to your email.'), backgroundColor: AppTheme.primaryPink),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authNotifierProvider);

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        if (next.user['hasProfile'] == true) {
          context.go('/home');
        } else {
          context.go('/profile-setup');
        }
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: Colors.redAccent),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verify your email',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit OTP code sent to:\n${widget.email}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
              const SizedBox(height: 48),

              // OTP Inputs Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (index) => SizedBox(
                    width: 48,
                    height: 56,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: Alignment.center.y == 0 ? TextAlign.center : TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(1),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF334155), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primaryPink, width: 2),
                        ),
                      ),
                      onChanged: (value) => _onKeyInput(index, value),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Verify Button
              ElevatedButton(
                onPressed: state is AuthLoading ? null : _submit,
                child: state is AuthLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Verify Code'),
              ),
              const SizedBox(height: 24),

              // Resend Action
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Didn\'t receive code? ', style: Theme.of(context).textTheme.bodyMedium),
                  GestureDetector(
                    onTap: _resendOTP,
                    child: const Text(
                      'Resend OTP',
                      style: TextStyle(color: AppTheme.primaryPink, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
