import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:smart_energy_pay/Screens/ReferAndEarnScreen/refer_and_earn_screen.dart';
import 'package:smart_energy_pay/util/auth_manager.dart';

class HomeBanner extends StatelessWidget {
  const HomeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ReferAndEarnScreen()),
        );
      },
      child: Container(
        height: MediaQuery.of(context).size.width * 0.45, // Height scales with width (45% of screen width)
        width: double.infinity,
        margin: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.04, // 4% of screen width
          vertical: MediaQuery.of(context).size.height * 0.01, // 1% of screen height
        ),
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/images/referAndEarn.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black26,
              BlendMode.dstATop,
            ),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900.withOpacity(0.9),
              Colors.purple.shade600.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 5,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Padding(
                  padding: EdgeInsets.all(constraints.maxWidth * 0.03), // 3% of container width
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Invite and Earn With Smart Energy Pay!',
                              style: TextStyle(
                                fontSize: constraints.maxWidth * 0.05, // 5% of container width
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: constraints.maxHeight * 0.05), // 5% of container height
                            Text(
                              'Receive interesting incentives and deals as a reward for your recommendation!',
                              style: TextStyle(
                                fontSize: constraints.maxWidth * 0.035, // 3.5% of container width
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: constraints.maxHeight * 0.2), // 20% of container height
                            // Uncomment and adjust the button if needed
                            // SizedBox(
                            //   width: constraints.maxWidth * 0.5, // 50% of container width
                            //   height: constraints.maxHeight * 0.2, // 20% of container height
                            //   child: ElevatedButton(
                            //     onPressed: () {},
                            //     style: ElevatedButton.styleFrom(
                            //       foregroundColor: Colors.blue.shade900,
                            //       backgroundColor: Colors.white,
                            //       shape: RoundedRectangleBorder(
                            //         borderRadius: BorderRadius.circular(20),
                            //       ),
                            //       padding: EdgeInsets.symmetric(
                            //         horizontal: constraints.maxWidth * 0.05,
                            //         vertical: constraints.maxHeight * 0.05,
                            //       ),
                            //     ),
                            //     child: Text(
                            //       'Get Started',
                            //       style: TextStyle(
                            //         fontSize: constraints.maxWidth * 0.04,
                            //         fontWeight: FontWeight.bold,
                            //       ),
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: constraints.maxHeight * 0.25), // 25% of container height
                        child: Container(
                          width: constraints.maxWidth * 0.08, // 8% of container width
                          height: constraints.maxWidth * 0.08, // Square shape, scales with width
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: ClipOval(
                            child: Lottie.asset(
                              'assets/lottie/Arrow.json',
                              fit: BoxFit.contain,
                              repeat: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}