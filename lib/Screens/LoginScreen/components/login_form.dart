import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:smart_energy_pay/Screens/ForgotScreen/forgot_pasword_screen.dart';
import 'package:smart_energy_pay/Screens/HomeScreen/home_screen.dart';
import 'package:smart_energy_pay/components/check_already_have_an_account.dart';
import 'package:smart_energy_pay/constants.dart';
import 'package:smart_energy_pay/Screens/SignupScreen/signup_screen.dart';
import 'package:smart_energy_pay/util/auth_manager.dart';
import '../models/loginApi.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final LoginApi _loginApi = LoginApi();
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _obsecureText = true;
  bool isLoading = false;
  String? errorMessage;

  bool _isPasswordValid(String password) {
    final regex =
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*[!@#$%&*,.?])(?=.*[0-9]).{8,}$');
    return regex.hasMatch(password);
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      print("Email: ${email.text}");
      print("Password: ${password.text}");

      try {
        final response = await _loginApi.login(email.text, password.text);

        print("Login Response: ${response.toString()}");
        print('User ID: ${response.userId}');
        print('Token: ${response.token}');
        print('Name: ${response.name}');
        print('Email: ${response.email}');
        print('Owner Profile: ${response.ownerProfile}');
        print('KycStatus: ${response.kycStatus}');

        // Save credentials for fingerprint login
        await AuthManager.saveCredentials(email.text, password.text);

        setState(() {
          isLoading = false;
        });

        await AuthManager.login(response.token);
        await AuthManager.saveUserId(response.userId);
        await AuthManager.saveUserName(response.name);
        await AuthManager.saveUserEmail(response.email);
        await AuthManager.saveUserImage(
            response.ownerProfile?.toString() ?? '');
        if (response.kycStatus == false) {
          await AuthManager.saveKycStatus("completed");
        } else {
          await AuthManager.saveKycStatus(response.kycStatus.toString());
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } catch (error) {
        print("Login Error: $error");
        setState(() {
          isLoading = false;
          errorMessage = "Login Error: $error";
        });
      }
    }
  }

  Future<void> _loginWithFingerprint() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Check if biometric authentication is available
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        setState(() {
          isLoading = false;
          errorMessage =
              "Biometric authentication is not available on this device.";
        });
        return;
      }

      // Authenticate using biometrics
      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to log in',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        // Load credentials from secure storage
        final credentials = await AuthManager.getCredentials();
        if (credentials['email'] == null || credentials['password'] == null) {
          setState(() {
            isLoading = false;
            errorMessage =
                "No stored credentials found. Please log in manually first.";
          });
          return;
        }

        // Set credentials in text controllers
        email.text = credentials['email']!;
        password.text = credentials['password']!;
        await _login();
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "Fingerprint authentication failed.";
        }); 
      }
    } catch (error) {
      print("Fingerprint Login Error: $error");
      setState(() {
        isLoading = false;
        errorMessage = "Fingerprint Login Error: $error";
      });
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void _togglePasswordVisibilty() {
    setState(() {
      _obsecureText = !_obsecureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(defaultPadding),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              cursorColor: kPrimaryColor,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                if (!regex.hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
              decoration: const InputDecoration(
                hintText: "Your Email",
                prefixIcon: Padding(
                  padding: EdgeInsets.all(defaultPadding),
                  child: Icon(Icons.email),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: defaultPadding),
              child: TextFormField(
                controller: password,
                textInputAction: TextInputAction.done,
                obscureText: _obsecureText,
                cursorColor: kPrimaryColor,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (!_isPasswordValid(value)) {
                    return 'Password must contain at least one lowercase letter, one uppercase letter, one number, and one special character.';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: "Your Password",
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(defaultPadding),
                    child: Icon(Icons.lock),
                  ),
                  suffixIcon: IconButton(
                    onPressed: _togglePasswordVisibilty,
                    icon: Icon(
                      _obsecureText ? Icons.visibility : Icons.visibility_off,
                      color: kPrimaryColor,
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: defaultPadding),
            if (isLoading)
              const CircularProgressIndicator(
                color: kPrimaryColor,
              ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 35),
            ElevatedButton(
              onPressed: isLoading ? null : _login,
              child: const Text("Sign In"),
            ),
            const SizedBox(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                    width: 120,
                    child: Divider(
                      color: kPrimaryColor,
                      thickness: 1,
                    )),
                SizedBox(
                  width: 10,
                ),
                Text("Or"),
                SizedBox(
                  width: 10,
                ),
                SizedBox(
                    width: 120,
                    child: Divider(
                      color: kPrimaryColor,
                      thickness: 1,
                )),
              ],
            ),
            const SizedBox(height: 10),
            FutureBuilder<bool>(
              future: _localAuth.canCheckBiometrics,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.data == true) {
                  return GestureDetector(
                    onTap: isLoading
                        ? null
                        : () async {
                            await _loginWithFingerprint(); // Properly call the async function
                          },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fingerprint, size: 20),
                        SizedBox(width: 10),
                        Text("Login With FingerPrints"),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 30),
            AlreadyHaveAnAccountCheck(
              press: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SignUpScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
