import 'package:flutter/material.dart';
import 'category_assistant_screen.dart';

class HealthcareScreen extends StatelessWidget {
  const HealthcareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoryAssistantScreen(
      categoryTitle: "Healthcare",
      categoryIcon: Icons.local_hospital,
      categoryColor: Color(0xFFE11D48),
      suggestions: [
        CategorySuggestion(
          id: "hc_1",
          title: "Ayushman Bharat Card (PM-JAY)",
          description: "How to apply for ₹5 Lakh health insurance card?",
          answer:
              "To apply for Ayushman Bharat Card (PM-JAY):\n\n1. Visit your nearest CSC (Common Service Center) or empaneled government hospital.\n2. Carry your Aadhaar Card and Ration Card for eligibility check.\n3. Verify your name in the SECC list at pmjay.gov.in.\n4. Provides up to ₹5 Lakh free medical coverage per family per year.",
        ),
        CategorySuggestion(
          id: "hc_2",
          title: "Free Doctor Teleconsultation (eSanjeevani)",
          description: "How to consult doctors online for free?",
          answer:
              "To access free doctor teleconsultations:\n\n1. Visit esanjeevaniopd.in or download the eSanjeevani app.\n2. Register with your mobile number and state.\n3. Connect live with government medical officers and receive digital prescriptions instantly.",
        ),
        CategorySuggestion(
          id: "hc_3",
          title: "Maternal & Child Care (PMMVY Scheme)",
          description: "₹6,000 assistance for pregnant women",
          answer:
              "Under Pradhan Mantri Matru Vandana Yojana (PMMVY):\n\n1. Pregnant mothers receive ₹6,000 financial support directly into their bank account.\n2. Register at your local Anganwadi Center or health sub-center with Aadhaar & Mother Child Protection Card.",
        ),
      ],
    );
  }
}