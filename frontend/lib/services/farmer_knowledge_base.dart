class FarmerKnowledgeBase {
  /// Provides accurate, detailed, domain-specific agricultural solutions
  static String getAccurateFarmerAnswer(String query, String category) {
    final text = query.toLowerCase();

    // 1. PESTS, INSECTS & CROP DISEASES
    if (text.contains("pest") ||
        text.contains("insects") ||
        text.contains("keeda") ||
        text.contains("disease") ||
        text.contains("yellow") ||
        text.contains("fungus") ||
        text.contains("blast") ||
        text.contains("worm")) {
      return "Crop Health & Pest Control Guide 🌾\n\n"
          "1. For Yellow Rust or Fungus: Spray Neem Oil (5ml/liter) or Propiconazole 25% EC (1ml/liter water) during early morning.\n"
          "2. For Fall Armyworm / Caterpillar: Apply Emamectin Benzoate 5% SG (0.4g/liter) or Neem Seed Kernel Extract 5%.\n"
          "3. For Soil Pests & Root Rot: Ensure proper field drainage and apply Trichoderma viride bio-fungicide (2.5kg/acre mixed with FYM manure).\n"
          "4. Free Expert Helpline: Call Kisan Call Center toll-free at 1800-180-1551 for free crop doctor consultation.";
    }

    // 2. FERTILIZER & SOIL HEALTH
    if (text.contains("fertilizer") ||
        text.contains("soil") ||
        text.contains("urea") ||
        text.contains("dap") ||
        text.contains("khad") ||
        text.contains("compost") ||
        text.contains("organic")) {
      return "Soil Nutrient & Subsidized Fertilizer Advisory 🧪\n\n"
          "1. Soil Health Card Test: Get your soil sample tested at your local Krishi Vigyan Kendra (KVK) to avoid excess chemical fertilizer usage.\n"
          "2. Subsidized Fertilizer: Buy NPK, Neem Coated Urea, and DAP from authorized Primary Agricultural Credit Societies (PACS) at government subsidized rates.\n"
          "3. Organic Yield Boost: Mix Vermicompost (2 tons/acre) with Bio-fertilizers (Azotobacter & PSB) to increase crop yield by 20% to 30%.";
    }

    // 3. SEEDS, CROPS & SEASONAL SOWING
    if (text.contains("seed") ||
        text.contains("beej") ||
        text.contains("crop") ||
        text.contains("paddy") ||
        text.contains("rice") ||
        text.contains("wheat") ||
        text.contains("maize") ||
        text.contains("mustard") ||
        text.contains("vegetable")) {
      return "High-Yield Certified Seeds & Seasonal Crop Advisory 🌱\n\n"
          "1. Buy Certified Seeds: Procure seeds from National Seeds Corporation (NSC) or State Agriculture Department stores for high germination rate.\n"
          "2. Seed Treatment: Treat seeds with Carbendazim (2g/kg seed) before sowing to prevent seed-borne rot.\n"
          "3. Water-Smart Crops: For low rainfall areas, adopt drought-resistant varieties of Millets (Bajra/Ragi) or Pulses (Arhar/Moong).";
    }

    // 4. PM-KISAN & FINANCIAL SCHEMES
    if (text.contains("pm kisan") ||
        text.contains("installment") ||
        text.contains("money") ||
        text.contains("scheme") ||
        text.contains("paisa") ||
        text.contains("kcc") ||
        text.contains("loan") ||
        text.contains("credit card")) {
      return "PM-Kisan & Kisan Credit Card (KCC) Financial Support 🚜\n\n"
          "1. PM-Kisan ₹6,000 Annual Installment: Check your beneficiary status at pmkisan.gov.in. Ensure land seeding & OTP/biometric e-KYC are linked with Aadhaar.\n"
          "2. Kisan Credit Card (KCC): Get low-interest crop loan up to ₹3 Lakh at only 4% interest rate per annum. Apply at your nearest bank branch with land revenue documents.\n"
          "3. PM Fasal Bima Yojana: Insure Kharif crops at 2% premium & Rabi crops at 1.5% premium to protect against crop failure.";
    }

    // 5. IRRIGATION & WATER SUBSIDY
    if (text.contains("water") ||
        text.contains("irrigation") ||
        text.contains("pump") ||
        text.contains("drip") ||
        text.contains("solar") ||
        text.contains("kusum")) {
      return "Irrigation & Solar Pump Subsidy Scheme (PM-KUSUM) 💧\n\n"
          "1. PM-KUSUM Solar Pump: Get up to 60% government subsidy to install off-grid solar irrigation pumps in your farm.\n"
          "2. Drip & Sprinkler Subsidy: Micro-irrigation under PM Krishi Sinchayee Yojana (PMKSY) offers up to 55% subsidy for small and marginal farmers.";
    }

    // 6. DEFAULT ACCURATE FARMER ADVISORY
    return "Farmer Advisory & Government Support 🌾\n\n"
        "1. For Crop Pests & Diseases: Spray Neem Oil (5ml/L) or contact your District Agriculture Officer.\n"
        "2. For PM-Kisan & Financial Loans: Complete e-KYC at pmkisan.gov.in or apply for Kisan Credit Card (KCC).\n"
        "3. Toll-Free Kisan Helpline: Call 1800-180-1551 (6 AM to 10 PM) in your native language for free guidance.";
  }
}
