import 'dart:ui';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../widgets/loksetu_logo_widget.dart';
import 'healthcare_screen.dart';
import 'education_screen.dart';
import 'governance_screen.dart';
import 'agriculture_screen.dart';
import 'chat_screen.dart';

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
              // Ambient Blur Circles
              Positioned(
                top: -60,
                right: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.18),
                  ),
                ),
              ),
              Positioned(
                bottom: 80,
                left: -60,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.cyan.withOpacity(0.14),
                  ),
                ),
              ),

              ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  const SizedBox(height: 6),

                  // TOP HEADER WITH GUARANTEED LOKSETU LOGO
                  Row(
                    children: [
                      const ClipOval(
                        child: LokSetuLogoWidget(
                          width: 48,
                          height: 48,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "LokSetu AI",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const Text(
                            "Connecting Multilingual Citizens & Farmers",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.record_voice_over,
                                color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              "Voice Enabled",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // AI BANNER CARD WITH LOGO
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: const ClipOval(
                            child: LokSetuLogoWidget(
                              width: 50,
                              height: 50,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Smart Citizen & Farmer AI",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "High-accuracy answers, research links & human voice in Northeast Indian languages",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    "Select Category or Pick a Query:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 1. HEALTHCARE
                  _categoryCardWithPresets(
                    context: context,
                    icon: Icons.local_hospital,
                    title: "Healthcare",
                    color: const Color(0xFFE11D48),
                    screen: const HealthcareScreen(),
                    presets: [
                      "Ayushman Bharat Card (PM-JAY)",
                      "Free Doctor Teleconsultation",
                      "Maternal & Child Care (PMMVY)",
                    ],
                  ),

                  // 2. GOVERNANCE
                  _categoryCardWithPresets(
                    context: context,
                    icon: Icons.account_balance,
                    title: "Governance",
                    color: const Color(0xFF2563EB),
                    screen: const GovernanceScreen(),
                    presets: [
                      "Apply Income / Caste Certificate",
                      "Ration Card e-KYC & Status",
                      "Government Scheme Bank Link (DBT)",
                    ],
                  ),

                  // 3. EDUCATION
                  _categoryCardWithPresets(
                    context: context,
                    icon: Icons.school,
                    title: "Education",
                    color: const Color(0xFF059669),
                    screen: const EducationScreen(),
                    presets: [
                      "Post-Matric Scholarships",
                      "Free Skill Training (PMKVY)",
                      "RTE Free School Admission (25%)",
                    ],
                  ),

                  // 4. AGRICULTURE
                  _categoryCardWithPresets(
                    context: context,
                    icon: Icons.agriculture,
                    title: "Agriculture",
                    color: const Color(0xFFD97706),
                    screen: const AgricultureScreen(),
                    presets: [
                      "Pest & Insects Control / PM-Kisan",
                      "Crop Damage Claim (PMFBY)",
                      "Kisan Call Center & Soil Health",
                    ],
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ],
          ),
        ),
      ),

      // GENERAL VOICE TALK BUTTON
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.secondary,
        elevation: 6,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatScreen(),
            ),
          );
        },
        icon: const Icon(Icons.mic, color: Colors.white),
        label: const Text(
          "Voice Chatbot",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _categoryCardWithPresets({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required Widget screen,
    required List<String> presets,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER ROW
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => screen),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, size: 28, color: color),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 19,
                                color: color,
                              ),
                            ),
                            const Text(
                              "Top 3 suggestions + Voice Chat",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 18, color: color),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, thickness: 1, color: Colors.black12),
                const SizedBox(height: 12),

                const Text(
                  "Most Popular Queries:",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // 3 PRESET CHIPS + OTHER
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...presets.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final text = entry.value;
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => screen),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color.withOpacity(0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 9,
                                backgroundColor: color,
                                child: Text(
                                  "$index",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                text,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    // OTHER CHIP
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => screen),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.more_horiz,
                                size: 14, color: Colors.black54),
                            SizedBox(width: 4),
                            Text(
                              "Other...",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}