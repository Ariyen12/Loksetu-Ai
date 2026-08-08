import 'package:flutter/material.dart';
import 'category_assistant_screen.dart';

class GovernanceScreen extends StatelessWidget {
  const GovernanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoryAssistantScreen(
      categoryTitle: "Governance",
      categoryIcon: Icons.account_balance,
      categoryColor: Color(0xFF2563EB),
      suggestions: [
        CategorySuggestion(
          id: "gov_1",
          title: "Apply Income / Caste / Residence Certificate",
          description: "Required documents and application process",
          answer:
              "To apply for official certificates:\n\n1. Log on to your state e-District portal or visit your nearest CSC Center.\n2. Submit Aadhaar Card, Address Proof, and Income Details.\n3. Application fee is ₹15–₹30. Download certified PDF using application status number.",
        ),
        CategorySuggestion(
          id: "gov_2",
          title: "Ration Card e-KYC & Status Check",
          description: "Link Aadhaar & check ration distribution",
          answer:
              "To complete Ration Card e-KYC & status:\n\n1. Download the 'Mera Ration' mobile app or visit state food portal.\n2. Complete Aadhaar fingerprint biometric link at your local Fair Price Shop (FPS) dealer.",
        ),
        CategorySuggestion(
          id: "gov_3",
          title: "Government Scheme Bank Linkage (DBT)",
          description: "Enable Direct Benefit Transfer in bank account",
          answer:
              "To enable Direct Benefit Transfer (DBT):\n\n1. Visit your bank branch or Post Office (IPPB).\n2. Request Aadhaar seeding with NPCI mapper for your savings account.\n3. Ensures all government scheme funds reach your account without delays.",
        ),
      ],
    );
  }
}