import 'package:flutter/material.dart';

// Campo no mesmo estilo das telas de login e cadastro
class AuthInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final int? maxLength;

  const AuthInput({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          label,

          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),

            fontSize: 13,

            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: controller,

          obscureText: obscure,

          keyboardType: keyboardType,

          maxLength: maxLength,

          style: const TextStyle(color: Colors.white),

          decoration: InputDecoration(
            hintText: label,

            hintStyle: const TextStyle(color: Colors.white38),

            prefixIcon: Icon(icon, color: Colors.white54),

            counterText: '',

            filled: true,

            fillColor: const Color(0xFF081225),

            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 16,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),

              borderSide: BorderSide.none,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),

              borderSide: const BorderSide(color: Colors.white10),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),

              borderSide: const BorderSide(
                color: Color(0xFF39FF14),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Cartão escuro centralizado usado nas telas de autenticação
class AuthCard extends StatelessWidget {
  final List<Widget> children;
  final VoidCallback onBack;

  const AuthCard({
    super.key,
    required this.children,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020817),

      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),

              child: Container(
                width: 420,

                padding: const EdgeInsets.all(24),

                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.88),

                  borderRadius: BorderRadius.circular(24),

                  border: Border.all(color: Colors.white10),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: children,
                ),
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: IconButton(
                tooltip: 'Voltar para login',
                onPressed: onBack,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.arrow_back),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Botão verde principal das telas de autenticação
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,

      height: 58,

      child: ElevatedButton(
        onPressed: loading ? null : onPressed,

        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF39FF14),

          foregroundColor: Colors.black,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),

        child: loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : Text(
                label,

                style: const TextStyle(
                  fontWeight: FontWeight.bold,

                  fontSize: 15,

                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }
}
