import 'package:flutter/material.dart';
import 'category_assistant_screen.dart';

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoryAssistantScreen(
      categoryTitle: "Education",
      categoryIcon: Icons.school,
      categoryColor: Color(0xFF059669),
      suggestions: [
        CategorySuggestion(
          id: "edu_1",
          title: "National & State Post-Matric Scholarships",
          description: "Stipends for Pre-Matric and Post-Matric students",
          answer:
              "To apply for scholarships:\n\n1. Register on the National Scholarship Portal (scholarships.gov.in).\n2. Upload student Aadhaar, bank passbook, fee receipt, and caste/income certificate.\n3. Funds are directly transferred to the student's bank account upon verification.",
        ),
        CategorySuggestion(
          id: "edu_2",
          title: "Free Skill Training & Certification (PMKVY)",
          description: "Pradhan Mantri Kaushal Vikas Yojana courses",
          answer:
              "For free industry skill training:\n\n1. Visit pmkvyofficial.org to search training centers near you.\n2. Choose from technical courses like electronics, solar installation, healthcare assist, or IT.\n3. Free training, government certification, and placement assistance provided.",
        ),
        CategorySuggestion(
          id: "edu_3",
          title: "RTE Act Free School Admission (25% Quota)",
          description: "Free private school seats for underprivileged children",
          answer:
              "Under Right to Education (RTE) Act:\n\n1. 25% of seats in private non-aided schools are reserved for disadvantaged groups.\n2. Apply online on your state RTE portal with birth proof & income certificate.",
        ),
      ],
    );
  }
}