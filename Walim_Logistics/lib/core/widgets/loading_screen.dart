import 'package:flutter/material.dart';

class AppLoadingScreen extends StatelessWidget {
  final String? message;
  
  const AppLoadingScreen({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).brightness == Brightness.light 
                ? const Color(0xFFFFF3E0) 
                : const Color(0xFF1E293B),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with subtle animation potential (could add TweenAnimationBuilder)
            Hero(
              tag: 'app_logo',
              child: Image.asset(
                'assets/images/logo.png',
                width: 150,
                height: 150,
              ),
            ),
            const SizedBox(height: 48),
            
            // Premium Loading Indicator
            SizedBox(
              width: 200,
              child: Column(
                children: [
                  const LinearProgressIndicator(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    minHeight: 6,
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      message!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
