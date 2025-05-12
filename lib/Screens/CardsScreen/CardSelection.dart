import 'package:flutter/material.dart';
import 'package:smart_energy_pay/Screens/CardsScreen/Add_Card.dart';
import 'package:smart_energy_pay/Screens/CardsScreen/PhysicalCardConfirmation.dart';
import 'package:smart_energy_pay/Screens/CardsScreen/PhysicalCardScreen.dart';
import 'package:smart_energy_pay/Screens/CardsScreen/RequestPhysicalCard.dart';
import 'package:smart_energy_pay/Screens/CardsScreen/card_screen.dart';
import 'package:smart_energy_pay/Screens/DashboardScreen/Dashboard/KycStatusWidgets/KycStatusWidgets.dart';
import 'package:smart_energy_pay/constants.dart';
import 'package:smart_energy_pay/util/AnimatedContainerWidget.dart';
import 'package:smart_energy_pay/util/auth_manager.dart'; // Import AuthManager for KYC status
import 'package:smart_energy_pay/Screens/KYCScreen/kycHomeScreen.dart'; // Import for navigation

class CardSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Fetch KYC status
    String kycStatus = AuthManager.getKycStatus();

    return Scaffold(
      backgroundColor: kWhiteColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildContentBasedOnKycStatus(kycStatus, context),
        ),
      ),
    );
  }

  // Method to determine content based on KYC status
  Widget _buildContentBasedOnKycStatus(String kycStatus, BuildContext context) {
    switch (kycStatus) {
      case "Pending":
        return CheckKycStatus(); // Show KYC pending widget
      case "Processed":
        return _buildProcessedWidget(); // Show processed widget
      case "Declined":
        return _buildDeclinedWidget(context); // Show declined widget
      case "completed":
        return _buildCardSelectionContent(
            context); // Show full card selection UI
      default:
        return CheckKycStatus(); // Default to KYC pending widget
    }
  }

  // Full Card Selection UI for "completed" status
  Widget _buildCardSelectionContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        const AnimatedContainerWidget(
          child: Center(
            child: Text(
              "Pick your Cards",
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const AnimatedContainerWidget(
          slideBegin: Offset(2.0, 1.0),
          child: Divider(color: Colors.black26),
        ),
        const SizedBox(height: 16),
        AnimatedContainerWidget(
          slideBegin: const Offset(1.0, 1.0),
          child: _buildCardSection(
            imagePath: "assets/images/card.png",
            icon: Icons.credit_card,
            title: "Physical card",
            description:
                "Choose your card design or\npersonalise it, and get it delivered",
            buttonText: "Customisable",
            isButton: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => RequestPhysicalCard(onCardAdded: () { Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DeliveryProcessingScreen()),
              );},)),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        AnimatedContainerWidget(
          slideCurve: Curves.linear,
          child: _buildCardSection(
            imagePath: "assets/images/VirtualCard.png",
            icon: Icons.credit_card_outlined,
            title: "Virtual card",
            description:
                "Get free virtual cards instantly, and try disposable for extra security online",
            buttonText: "Extra secure",
            isButton: true,
            onTap: () {
             Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AddCardScreen(onCardAdded: () { Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CardsScreen()),
              );},)),
              );
            },
          ),
        ),
      ],
    );
  }

  // Widget for "Processed" status
  Widget _buildProcessedWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/images/PendingApproval.jpg',
            width: 260, height: 150),
        const SizedBox(height: 20),
        const Text(
          'Your details are submitted, Admin will approve after reviewing your KYC details!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  // Widget for "Declined" status
  Widget _buildDeclinedWidget(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/images/Rejected.jpg', width: 260, height: 150),
        const SizedBox(height: 20),
        const Text(
          'Your KYC was rejected. Please apply for Re-KYC!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 35),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const KycHomeScreen()),
            );
          },
          child: const Text(
            'Apply Again',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ],
    );
  }

  // Helper method to build the card sections
  Widget _buildCardSection({
    required String imagePath,
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required bool isButton,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(
            width: 400,
            height: 120,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kPrimaryColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Image.asset(
                    imagePath,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
