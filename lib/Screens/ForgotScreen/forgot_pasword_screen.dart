import 'package:flutter/material.dart';
import 'package:smart_energy_pay/responsive.dart';

import 'package:smart_energy_pay/components/background.dart';
import 'package:smart_energy_pay/Screens/ForgotScreen/components/forgot_password_form.dart';
import 'package:smart_energy_pay/Screens/ForgotScreen/components/forgot_password_top_image.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Background(
      child: SingleChildScrollView(
        child: Responsive(
          mobile: MobileForgotPasswordScreen(),
          desktop: Row(
            children: [
              Expanded(
                child: ForgotPasswordTopImage(),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 450,
                      child: ForgotPasswordForm(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MobileForgotPasswordScreen extends StatelessWidget {
  const MobileForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        ForgotPasswordTopImage(),
        Row(
          children: [
            Spacer(),
            Expanded(
              flex: 8,
              child: ForgotPasswordForm(),
            ),
            Spacer(),
          ],
        )
      ],
    );
  }
}
