import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'healthcare_screen.dart';
import 'education_screen.dart';
import 'governance_screen.dart';
import 'agriculture_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEAF4FF),
              Color(0xFFD6E8FF),
              Color(0xFFF8FAFC),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [

              // Floating Circle 1
              Positioned(
                top: -60,
                right: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(.18),
                  ),
                ),
              ),

              // Floating Circle 2
              Positioned(
                bottom: 100,
                left: -60,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.cyan.withOpacity(.12),
                  ),
                ),
              ),

              ListView(
                padding: const EdgeInsets.all(24),
                children: [

                  const SizedBox(height: 20),

                  Text(
                    "Good Evening 👋",
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    "LokSetu AI",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 35),

                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF2563EB),
                            Color(0xFF38BDF8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(.45),
                            blurRadius: 35,
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Center(
                    child: Text(
                      "Breaking Language Barriers",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 35),

                  _glassCard(
  context,
  Icons.local_hospital,
  "Healthcare",
  const HealthcareScreen(),
),

_glassCard(
  context,
  Icons.account_balance,
  "Governance",
  const GovernanceScreen(),
),

_glassCard(
  context,
  Icons.school,
  "Education",
  const EducationScreen(),
),

_glassCard(
  context,
  Icons.agriculture,
  "Agriculture",
  const AgricultureScreen(),
),

                  const SizedBox(height: 100),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.secondary,
        onPressed: () {},
        icon: const Icon(Icons.mic),
        label: const Text("Talk"),
      ),
    );
  }

  Widget _glassCard(
  BuildContext context,
  IconData icon,
  String title,
  Widget screen,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => screen,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 18,
            sigmaY: 18,
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.30),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.45),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}