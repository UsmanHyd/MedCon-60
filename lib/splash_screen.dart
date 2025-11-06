import 'package:flutter/material.dart';
import 'package:medcon30/services/auth_service.dart';
import 'package:medcon30/patient/profile/patient_dashboard.dart';
import 'package:medcon30/doctor/modules/doctor_dashboard.dart';
import 'role_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideAnimation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  bool _showOnboarding = false;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLastPage = false;
  double _onboardingOpacity = 0.0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to MedCon',
      description:
          'Your personal healthcare companion for better health management',
      icon: Icons.health_and_safety,
      color: const Color(0xFF0288D1),
    ),
    OnboardingPage(
      title: 'Track Your Health',
      description:
          'Monitor vital signs, track medications, and manage appointments all in one place',
      icon: Icons.monitor_heart,
      color: const Color(0xFF4CAF50),
    ),
    OnboardingPage(
      title: 'Connect with Doctors',
      description:
          'Schedule virtual consultations and get medical advice from healthcare professionals',
      icon: Icons.people,
      color: const Color(0xFF9C27B0),
    ),
    OnboardingPage(
      title: 'Emergency Support',
      description:
          'Quick access to emergency services and SOS features when you need them most',
      icon: Icons.emergency,
      color: const Color(0xFFF44336),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(_controller);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -0.4),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
    ));

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _progressController, curve: Curves.easeInOutCubic),
    );

    _controller.forward();
    _progressController.forward();
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkAuthAndNavigate();
      }
    });

    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
          _isLastPage = _currentPage == _pages.length - 1;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndNavigate() async {
    final authService = AuthService();
    final authState = await authService.checkAuthState();

    if (authState != null) {
      // User is authenticated, navigate based on role
      if (mounted) {
        if (authState['role'] == 'doctor') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DoctorDashboard()),
          );
        } else if (authState['role'] == 'patient') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        } else {
          // Unknown role, show onboarding
          _startOnboarding();
        }
      }
    } else {
      // User is not authenticated, show onboarding
      _startOnboarding();
    }
  }

  void _startOnboarding() async {
    _controller.reset();
    _controller.forward();
    setState(() {
      _showOnboarding = true;
      _onboardingOpacity = 0.0;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _onboardingOpacity = 1.0;
    });
  }

  void _navigateToRoleSelection() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: SafeArea(
        child: Column(
          children: [
            if (_showOnboarding)
              // MedCon Header when in onboarding mode
              SlideTransition(
                position: _slideAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_hospital,
                          size: 30, color: Color(0xFF0288D1)),
                      SizedBox(width: 10),
                      Text(
                        'MedCon',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF01579B),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (!_showOnboarding)
              Expanded(
                child: Center(
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_hospital,
                            size: 80, color: Color(0xFF0288D1)),
                        const SizedBox(height: 20),
                        const Text(
                          'MedCon',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF01579B),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Custom Animated Progress Bar
                        AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return Container(
                              width: 180,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0288D1)
                                        .withOpacity(0.18),
                                    blurRadius: 12,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 180 * _progressAnimation.value,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF0288D1),
                                          Color(0xFF4FC3F7),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0288D1)
                                              .withOpacity(0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_showOnboarding) ...[
              // Onboarding Content with Fade-in
              Expanded(
                child: AnimatedOpacity(
                  opacity: _onboardingOpacity,
                  duration: const Duration(milliseconds: 400),
                  child: Column(
                    children: [
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _pages.length,
                          itemBuilder: (context, index) {
                            return _buildPage(_pages[index]);
                          },
                        ),
                      ),
                      // Navigation Buttons
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Skip Button
                            TextButton(
                              onPressed: _navigateToRoleSelection,
                              child: const Text(
                                'Skip',
                                style: TextStyle(
                                  color: Color(0xFF0288D1),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            // Page Indicators
                            Row(
                              children: List.generate(
                                _pages.length,
                                (index) => Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentPage == index
                                        ? const Color(0xFF0288D1)
                                        : Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                              ),
                            ),
                            // Next/Get Started Button
                            ElevatedButton(
                              onPressed: _isLastPage
                                  ? _navigateToRoleSelection
                                  : () {
                                      _pageController.nextPage(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeIn,
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0288D1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                _isLastPage ? 'Get Started' : 'Next',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 80,
              color: page.color,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF01579B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            page.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
