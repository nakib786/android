import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/provinces.dart';
import 'vehicle_setup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form states
  CanadaProvince _selectedProvince = CanadaProvince.on;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  if (mounted) {
                    setState(() {
                      _currentPage = index;
                    });
                  }
                },
                children: [
                  _buildWelcomeStep(),
                  _buildProvinceStep(),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/icons/logo.png',
            height: 120,
          ),
          const SizedBox(height: 40),
          const Text(
            "Welcome to KiloDrive",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Text(
            "The easiest way to track your business mileage and maximize your tax deductions.",
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProvinceStep() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Where do you drive?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "CRA rates vary by province and territory.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            DropdownButtonFormField<CanadaProvince>(
              initialValue: _selectedProvince,
              decoration: const InputDecoration(
                labelText: "Select Province/Territory",
                border: OutlineInputBorder(),
              ),
              items: CanadaProvince.values.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(p.name),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null && mounted) {
                  setState(() => _selectedProvince = val);
                }
              },
            ),
            const SizedBox(height: 20),
            if (_selectedProvince.isTerritory)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Territories use separate CRA rates for the first 5,000 km.",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text("Back"),
            )
          else
            const SizedBox(width: 60),
          Row(
            children: List.generate(
              2,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index ? Colors.blue : Colors.grey[300],
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_currentPage < 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                // Save province selection before navigating
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('selected_province', _selectedProvince.code);

                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const VehicleSetupScreen(),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: Text(_currentPage == 1 ? "Get Started" : "Next"),
          ),
        ],
      ),
    );
  }
}
