import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'welcome.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentPage = 0;
  final PageController _pageController = PageController();

  // List of onboarding data
  final List<OnboardingData> onboardingPages = [
    OnboardingData(
      image: 'assets/images/shasha_wave.png',
      title: 'Hello',
      description:
          'Welcome to C-Pon! Your personal goal saver that helps you plan and save for your dream purchases!',
    ),
    OnboardingData(
      image: 'assets/images/shasha_plan.png',
      title: 'Plan Ahead',
      description:
          'Enter what you want to buy, the cost, and your weekly savings. We\'ll calculate how many weeks it will take to reach your goal!',
    ),
    OnboardingData(
      image: 'assets/images/shasha_write.png',
      title: 'Track Your Savings',
      description:
          'Include how much you\'ve already saved to get a more accurate timeline. Every peso counts toward your goal!',
    ),
    OnboardingData(
      image: 'assets/images/shasha_rocket.png',
      title: 'Know The Timeline',
      description:
          'See exactly when you can afford your purchase and adjust your savings to reach your goal faster!',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Decorative background circles
          Positioned(
            top: -100.h,
            right: -80.w,
            child: Container(
              width: 300.w,
              height: 300.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primaryContainer.withOpacity(0.3),
              ),
            ),
          ),
          Positioned(
            top: -50.h,
            right: -150.w,
            child: Container(
              width: 280.w,
              height: 280.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.secondaryContainer.withOpacity(0.25),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Skip button (hidden on last page)
                if (currentPage != onboardingPages.length - 1)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.all(16.0.r),
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WelcomeScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Skip',
                          style: TextStyle(color: Colors.grey, fontSize: 16.sp),
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(height: 56.h),

                // PageView for onboarding pages
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        currentPage = index;
                      });
                    },
                    itemCount: onboardingPages.length,
                    itemBuilder: (context, index) {
                      return OnboardingPage(data: onboardingPages[index]);
                    },
                  ),
                ),

                // Page indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    onboardingPages.length,
                    (index) => Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      width: currentPage == index ? 24.w : 8.w,
                      height: 8.h,
                      decoration: BoxDecoration(
                        color: currentPage == index
                            ? Colors.blue
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 32.h),

                // Next/Get Started button
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 24.h,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: () {
                        if (currentPage == onboardingPages.length - 1) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WelcomeScreen(),
                            ),
                          );
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        currentPage == onboardingPages.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Onboarding page widget
class OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),

        // Image/Icon at center
        Image.asset(data.image, height: 300.h, fit: BoxFit.contain),

        const Spacer(),

        // Title and Description at bottom
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            children: [
              Text(
                data.title,
                style: GoogleFonts.manrope(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Text(
                data.description,
                style: TextStyle(fontSize: 14.sp, color: Colors.black45),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        SizedBox(height: 40.h),
      ],
    );
  }
}

// Data model for onboarding
class OnboardingData {
  final String image;
  final String title;
  final String description;

  OnboardingData({
    required this.image,
    required this.title,
    required this.description,
  });
}
