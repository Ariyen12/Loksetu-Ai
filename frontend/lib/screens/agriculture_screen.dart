import 'package:flutter/material.dart';
import 'category_assistant_screen.dart';

class AgricultureScreen extends StatelessWidget {
  const AgricultureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoryAssistantScreen(
      categoryTitle: "Agriculture",
      categoryIcon: Icons.agriculture,
      categoryColor: Color(0xFFD97706),
      suggestions: [
        CategorySuggestion(
          id: "ag_1",
          title: "PM-Kisan Installment & e-KYC Status",
          description: "₹6,000 annual farmer support installments",
          answer:
              "To check PM-Kisan status & e-KYC:\n\n1. Visit pmkisan.gov.in and click 'Know Your Status'.\n2. Enter registration number or Aadhaar number.\n3. Ensure land seeding & OTP/biometric e-KYC is completed to receive regular ₹2,000 installments.",
        ),
        CategorySuggestion(
          id: "ag_2",
          title: "Crop Damage Insurance Claim (PMFBY)",
          description: "Report crop loss within 72 hours",
          answer:
              "To claim crop insurance under PM Fasal Bima Yojana:\n\n1. Report crop loss within 72 hours of flood/hailstorm/drought.\n2. Use the Crop Insurance App or call toll-free 1800-200-5142 or notify your local bank/agriculture officer.",
        ),
        CategorySuggestion(
          id: "ag_3",
          title: "Kisan Call Center & Soil Health Card",
          description: "Toll-free farming guidance & fertilizer testing",
          answer:
              "For expert agricultural advice:\n\n1. Call Kisan Call Center toll-free at 1800-180-1551 in your native language (6 AM to 10 PM).\n2. Test soil at Krishi Vigyan Kendra (KVK) to get customized fertilizer dosage and increase crop yield.",
        ),
      ],
    );
  }
}