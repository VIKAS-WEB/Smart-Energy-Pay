import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_energy_pay/Screens/DashboardScreen/Dashboard/AccountsList/accountsListApi.dart';
import 'package:smart_energy_pay/Screens/DashboardScreen/Dashboard/AccountsList/accountsListModel.dart';
import 'package:smart_energy_pay/Screens/DashboardScreen/SendMoneyScreen/PayRecipientsScree/exchangeCurrencyModel/exchangeCurrencyApi.dart';
import 'package:smart_energy_pay/Screens/DashboardScreen/SendMoneyScreen/PayRecipientsScree/makePaymentModel/makePaymentApi.dart';
import 'package:smart_energy_pay/Screens/DashboardScreen/SendMoneyScreen/PayRecipientsScree/makePaymentModel/makePaymentModel.dart';
import 'package:smart_energy_pay/constants.dart';
import 'package:smart_energy_pay/util/currency_utils.dart';

import '../../../../util/auth_manager.dart';
import '../../../../util/customSnackBar.dart';
import '../../../HomeScreen/home_screen.dart';
import 'exchangeCurrencyModel/exchangeCurrencyModel.dart';

class PayRecipientsScreen extends StatefulWidget {
  const PayRecipientsScreen({super.key});

  @override
  State<PayRecipientsScreen> createState() => _PayRecipientsScreen();
}

class _PayRecipientsScreen extends State<PayRecipientsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ExchangeCurrencyApi _exchangeCurrencyApi = ExchangeCurrencyApi();
  final RecipientMakePaymentApi _recipientMakePaymentApi =
      RecipientMakePaymentApi();

  final TextEditingController mSendAmountController = TextEditingController();
  final TextEditingController mReceiveAmountController =
      TextEditingController();

  final TextEditingController mFullName = TextEditingController();
  final TextEditingController mEmail = TextEditingController();
  final TextEditingController mMobileNo = TextEditingController();
  final TextEditingController mBankName = TextEditingController();
  final TextEditingController mIban = TextEditingController();
  final TextEditingController mBicCode = TextEditingController();
  final TextEditingController mAddress = TextEditingController();

  String? selectedSendCurrency;
  String? selectedReceiveCurrency;
  bool isLoading = false;
  bool isAddLoading = false;

  // Send Currency -----
  String? mSendCountry = '';
  String? mSendCurrency = 'Select Currency';
  double? mSendCurrencyAmount = 0.0;
  String? mSendCurrencySymbol = '';
  double? mTotalCharge = 0.0;
  String? mTotalPayable = '0.0';

  // Receive Currency
  String? mReceiveCountry = '';
  String? mReceiveCurrency = 'Select Currency';
  double? mReceiveCurrencyAmount = 0.0;
  String? mReceiveCurrencySymbol = '';

  // Send Currency Set
  Future<void> mSelectedSendCurrency(mSelectedSendCountry,
      mSelectedSendCurrency, mSelectedSendCurrencyAmount) async {
    setState(() {
      mSendCountry = mSelectedSendCountry;
      mSendCurrency = mSelectedSendCurrency;
      mSendCurrencyAmount = mSelectedSendCurrencyAmount;
      mSendCurrencySymbol = getCurrencySymbol(mSendCurrency!);
    });
  }

  // Receive Currency Set
  Future<void> mSelectedReceiveCurrency(mSelectedReceiveCountry,
      mSelectedReceiveCurrency, mSelectedReceiveCurrencyAmount) async {
    setState(() {
      mReceiveCountry = mSelectedReceiveCountry;
      mReceiveCurrency = mSelectedReceiveCurrency;
      mReceiveCurrencyAmount = mSelectedReceiveCurrencyAmount;
      mReceiveCurrencySymbol = getCurrencySymbol(mReceiveCurrency!);
    });
  }

  String getCurrencySymbol(String currencyCode) {
    var format = NumberFormat.simpleCurrency(name: currencyCode);
    return format.currencySymbol;
  }

  // Exchange Money Api **************
  Future<void> mExchangeMoneyApi() async {
    setState(() {
      isLoading = true;
    });

    try {
      final request = ExchangeCurrencyRequest(
          userId: AuthManager.getUserId(),
          amount: mSendAmountController.text,
          fromCurrency: mSendCurrency!,
          toCurrency: mReceiveCurrency!);
      final response = await _exchangeCurrencyApi.exchangeCurrencyApi(request);

      if (response.message == "Success") {
        setState(() {
          isLoading = false;
          mTotalCharge = response.data.totalFees;
          mTotalPayable = response.data.totalCharge.toString();
          mReceiveAmountController.text =
              response.data.convertedAmount.toStringAsFixed(2);
        });
      } else {
        setState(() {
          isLoading = false;
          CustomSnackBar.showSnackBar(
              context: context,
              message: "We are facing some issue!",
              color: kPrimaryColor);
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> mMakePayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isAddLoading = true;
      });

      try {
        String amountText =
            '$mSendCurrencySymbol ${mSendAmountController.text}';
        String conversionAmountText =
            '$mReceiveCurrencySymbol ${mReceiveAmountController.text}';

        final request = RecipientMakePaymentRequest(
            userId: AuthManager.getUserId(),
            iban: mIban.text,
            bicCode: mBicCode.text,
            fee: mTotalCharge.toString(),
            amount: mSendAmountController.text,
            conversionAmount: mReceiveAmountController.text,
            conversionAmountText: conversionAmountText,
            amountText: amountText,
            fromCurrency: mSendCurrency!,
            toCurrency: mReceiveCurrency!,
            status: "pending",
            name: mFullName.text,
            email: mEmail.text,
            address: mAddress.text,
            mobile: mMobileNo.text,
            bankName: mBankName.text);
        final response = await _recipientMakePaymentApi.makePaymentApi(request);

        if (response.message == "Receipient is added Successfully!!!") {
          setState(() {
            isAddLoading = false;
            CustomSnackBar.showSnackBar(
                context: context,
                message: "Recipient is added Successfully ",
                color: kPrimaryColor);
            Navigator.of(context).pop();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
            );
          });
        } else {
          setState(() {
            isAddLoading = false;
            CustomSnackBar.showSnackBar(
                context: context,
                message: "We are facing some issue",
                color: kPrimaryColor);
          });
        }
      } catch (error) {
        setState(() {
          isAddLoading = false;
          CustomSnackBar.showSnackBar(
              context: context,
              message: "Something went wrong!",
              color: kPrimaryColor);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Recipients",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: defaultPadding),
                Card(
                  elevation: 4.0,
                  color: Colors.white,
                  margin:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                  child: Padding(
                    padding: const EdgeInsets.all(defaultPadding),
                    child: Column(
                      children: [
                        const Center(
                          child: Text(
                            "Payment Information",
                            style: TextStyle(
                                color: kPrimaryColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const Divider(),
                        const SizedBox(height: defaultPadding),
                        Card(
                          elevation: 4.0,
                          color: Colors.white,
                          margin: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 0),
                          child: Padding(
                            padding: const EdgeInsets.all(defaultPadding),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    mSendCurrencyBottomSheet(context);
                                  },
                                  child: Card(
                                    elevation: 1.0,
                                    color: kPrimaryLightColor,
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 0, horizontal: 0),
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.all(defaultPadding),
                                      child: Row(
                                        children: [
                                          // Use EU flag for EUR, country flag for others
                                          if (mSendCurrency?.toUpperCase() ==
                                              'EUR')
                                            getEuFlagWidget()
                                          else
                                            CountryFlag.fromCountryCode(
                                              width: 35,
                                              height: 35,
                                              mSendCountry!,
                                              shape: const Circle(),
                                            ),
                                          const SizedBox(width: defaultPadding),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '$mSendCurrency',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: kPrimaryColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.arrow_drop_down,
                                              color: kPrimaryColor),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: smallPadding,
                                ),
                                Row(
                                  children: [
                                    const Text(
                                      'Send Avg Balance = ',
                                      style: TextStyle(color: kPrimaryColor),
                                    ),
                                    Text(
                                      '${getCurrencySymbol(mSendCurrency!)}${mSendCurrencyAmount?.toStringAsFixed(2) ?? '0.00'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: kPrimaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: largePadding,
                                ),
                                TextFormField(
                                  controller: mSendAmountController,
                                  decoration: InputDecoration(
                                    prefix: Text(
                                      '${getCurrencySymbol(mSendCurrency!)} ',
                                      style:
                                          const TextStyle(color: kPrimaryColor),
                                    ),
                                    labelText: 'Send',
                                    labelStyle:
                                        const TextStyle(color: kPrimaryColor),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(),
                                    ),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                  ),
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  cursorColor: kPrimaryColor,
                                  style: const TextStyle(color: kPrimaryColor),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter sender amount';
                                    }
                                    return null;
                                  },
                                  maxLines: 3,
                                  minLines: 1,
                                  onChanged: (value) {
                                    if (mSendCurrency != "Select Currency") {
                                      if (mReceiveCurrency !=
                                          "Select Currency") {
                                        if (mSendAmountController
                                            .text.isNotEmpty) {
                                          if (mSendAmountController.text ==
                                                  mSendCurrencyAmount
                                                      .toString() ||
                                              double.parse(mSendAmountController
                                                      .text) <=
                                                  mSendCurrencyAmount!) {
                                            setState(() {
                                              mExchangeMoneyApi();
                                            });
                                          } else {
                                            setState(() {
                                              CustomSnackBar.showSnackBar(
                                                  context: context,
                                                  message:
                                                      "Please enter a valid amount",
                                                  color: kPrimaryColor);
                                            });
                                          }
                                        } else {
                                          mReceiveAmountController.clear();
                                          CustomSnackBar.showSnackBar(
                                              context: context,
                                              message:
                                                  "Please enter sender amount",
                                              color: kPrimaryColor);
                                        }
                                      } else {
                                        CustomSnackBar.showSnackBar(
                                            context: context,
                                            message:
                                                "Please select Recipient will receive currency",
                                            color: kPrimaryColor);
                                      }
                                    } else {
                                      CustomSnackBar.showSnackBar(
                                          context: context,
                                          message:
                                              "Please select send currency",
                                          color: kPrimaryColor);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Divider line
                              Container(
                                height: 1,
                                width: double.maxFinite,
                                color: kPrimaryLightColor,
                              ),
                              // Circular button
                              Material(
                                elevation: 6.0,
                                shape: const CircleBorder(),
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            color: kPrimaryColor,
                                          ),
                                        )
                                      : const Center(
                                          child: Icon(
                                            Icons.arrow_downward,
                                            size: 30,
                                            color: kPrimaryColor,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          elevation: 4.0,
                          color: Colors.white,
                          margin: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 0),
                          child: Padding(
                            padding: const EdgeInsets.all(defaultPadding),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    mReceiveCurrencyBottomSheet(context);
                                  },
                                  child: Card(
                                    elevation: 1.0,
                                    color: kPrimaryLightColor,
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 0, horizontal: 0),
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.all(defaultPadding),
                                      child: Row(
                                        children: [
                                          // Use EU flag for EUR, country flag for others (corrected for mReceiveCurrency)
                                          if (mReceiveCurrency?.toUpperCase() ==
                                              'EUR')
                                            getEuFlagWidget()
                                          else
                                            CountryFlag.fromCountryCode(
                                              width: 35,
                                              height: 35,
                                              mReceiveCountry!,
                                              shape: const Circle(),
                                            ),
                                          const SizedBox(width: defaultPadding),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '$mReceiveCurrency',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: kPrimaryColor,
                                                  ),
                                                ),
                                                // Text(
                                                //   '${mReceiveCurrencyAmount?.toStringAsFixed(2)}',
                                                //   style: const TextStyle(
                                                //     fontWeight: FontWeight.bold,
                                                //     fontSize: 14,
                                                //     color: kPrimaryColor,
                                                //   ),
                                                // ),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.arrow_drop_down,
                                              color: kPrimaryColor),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: largePadding,
                                ),
                                TextFormField(
                                  controller: mReceiveAmountController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    prefix: Text(
                                      '${getCurrencySymbol(mReceiveCurrency!)} ',
                                      style:
                                          const TextStyle(color: kPrimaryColor),
                                    ),
                                    labelText: 'Recipient will receive',
                                    labelStyle:
                                        const TextStyle(color: kPrimaryColor),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(),
                                    ),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter recipient will receive amount';
                                    }
                                    return null;
                                  },
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  cursorColor: kPrimaryColor,
                                  style: const TextStyle(color: kPrimaryColor),
                                  maxLines: 2,
                                  minLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: defaultPadding),
                        const SizedBox(height: 30),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Charge',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: kPrimaryColor)),
                            Text('$mSendCurrencySymbol $mTotalCharge',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: kPrimaryColor)),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Payable',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.bold)),
                            Text('$mSendCurrencySymbol $mTotalPayable',
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: defaultPadding)
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: defaultPadding),
                Card(
                  elevation: 4.0,
                  color: Colors.white,
                  margin:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                  child: Padding(
                    padding: const EdgeInsets.all(defaultPadding),
                    child: Column(
                      children: [
                        const SizedBox(height: defaultPadding),
                        TextFormField(
                          controller: mFullName,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          cursorColor: kPrimaryColor,
                          style: const TextStyle(color: kPrimaryColor),
                          decoration: InputDecoration(
                            labelText: "Full Name",
                            labelStyle: const TextStyle(color: kPrimaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(),
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your full name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: defaultPadding),
                        TextFormField(
                          controller: mEmail,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          cursorColor: kPrimaryColor,
                          style: const TextStyle(color: kPrimaryColor),
                          decoration: InputDecoration(
                            labelText: "Your Email",
                            labelStyle: const TextStyle(color: kPrimaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(),
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: defaultPadding),
                        TextFormField(
                          controller: mMobileNo,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          cursorColor: kPrimaryColor,
                          style: const TextStyle(color: kPrimaryColor),
                          decoration: InputDecoration(
                            labelText: "Mobile Number",
                            labelStyle: const TextStyle(color: kPrimaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(),
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your mobile number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: defaultPadding),
                        TextFormField(
                          controller: mBankName,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          cursorColor: kPrimaryColor,
                          style: const TextStyle(color: kPrimaryColor),
                          decoration: InputDecoration(
                            labelText: "Bank Name",
                            labelStyle: const TextStyle(color: kPrimaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(),
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your bank name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: defaultPadding),
                        TextFormField(
                          controller: mIban,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          cursorColor: kPrimaryColor,
                          style: const TextStyle(color: kPrimaryColor),
                          decoration: InputDecoration(
                            labelText: "IBAN / AC",
                            labelStyle: const TextStyle(color: kPrimaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(),
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your IBAN or account number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: defaultPadding),
                        TextFormField(
                          controller: mBicCode,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          cursorColor: kPrimaryColor,
                          style: const TextStyle(color: kPrimaryColor),
                          decoration: InputDecoration(
                            labelText: "Routing/IFSC/BIC/SwiftCode",
                            labelStyle: const TextStyle(color: kPrimaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(),
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the routing number or equivalent';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: defaultPadding),
                        TextFormField(
                          controller: mAddress,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          cursorColor: kPrimaryColor,
                          style: const TextStyle(color: kPrimaryColor),
                          decoration: InputDecoration(
                            labelText: "Recipient Address",
                            labelStyle: const TextStyle(color: kPrimaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(),
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the recipient address';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(
                          height: largePadding,
                        ),
                        if (isAddLoading)
                          const Center(
                            child: CircularProgressIndicator(
                              color: kPrimaryColor,
                            ),
                          ), // Show loading indicator

                        const SizedBox(height: 35),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 50),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: isAddLoading ? null : mMakePayment,
                            child: const Text('Make Payment',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: defaultPadding),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Send Currency Bottom Sheet
  void mSendCurrencyBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            Container(
              height: 600,
              padding: const EdgeInsets.all(defaultPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SendCurrencyBottomSheet(
                onSendCurrencySelected: (
                  String country,
                  String currency,
                  double amount,
                ) async {
                  await mSelectedSendCurrency(
                    country,
                    currency,
                    amount,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // Receive Currency Bottom Sheet
  void mReceiveCurrencyBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            Container(
              height: 600,
              padding: const EdgeInsets.all(defaultPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ReceiveCurrencyBottomSheet(
                onReceiveCurrencySelected: (
                  String country,
                  String currency,
                  double amount,
                ) async {
                  await mSelectedReceiveCurrency(
                    country,
                    currency,
                    amount,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// Send Currency Code
class SendCurrencyBottomSheet extends StatefulWidget {
  final Function(String, String, double) onSendCurrencySelected;

  const SendCurrencyBottomSheet(
      {super.key, required this.onSendCurrencySelected});

  @override
  State<SendCurrencyBottomSheet> createState() =>
      _SendCurrencyBottomSheetState();
}

class _SendCurrencyBottomSheetState extends State<SendCurrencyBottomSheet> {
  final AccountsListApi _accountsListApi = AccountsListApi();
  List<AccountsListsData> accountsListData = [];
  bool isLoading = false;
  String? errorMessage;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    mAccounts();
  }

  // Accounts List Api ---------------
  Future<void> mAccounts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await _accountsListApi.accountsListApi();

      if (response.accountsList != null && response.accountsList!.isNotEmpty) {
        setState(() {
          accountsListData = response.accountsList!;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'No Account Found';
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select Currency',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: kPrimaryColor),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
        const SizedBox(
          height: defaultPadding,
        ),
        Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: kPrimaryColor,
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height,
                          child: isLoading
                              ? const Center(
                                  child:
                                      CircularProgressIndicator(), // Show loading indicator
                                )
                              : ListView.builder(
                                  itemCount: accountsListData.length,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    final accountsData =
                                        accountsListData[index];
                                    final isSelected = index == _selectedIndex;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5,
                                          horizontal: smallPadding),
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedIndex = index;

                                            widget.onSendCurrencySelected(
                                              accountsData.country ?? '',
                                              accountsData.currency ?? '',
                                              accountsData.amount ?? 0.0,
                                            );
                                            Navigator.pop(context);
                                          });
                                        },
                                        child: Card(
                                          elevation: 5,
                                          color: isSelected
                                              ? kPrimaryColor
                                              : Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                defaultPadding),
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(
                                                defaultPadding),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    // Use EU flag for EUR, country flag for others
                                                    if (accountsData.currency
                                                            ?.toUpperCase() ==
                                                        'EUR')
                                                      getEuFlagWidget()
                                                    else
                                                      CountryFlag
                                                          .fromCountryCode(
                                                        width: 35,
                                                        height: 35,
                                                        accountsData.country!,
                                                        shape: const Circle(),
                                                      ),
                                                    Text(
                                                      "${accountsData.currency}",
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isSelected
                                                            ? Colors.white
                                                            : kPrimaryColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(
                                                    height: defaultPadding),
                                                // ignore: prefer_const_constructors
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    // Text(
                                                    //   "Balance",
                                                    //   style: TextStyle(
                                                    //     fontSize: 16,
                                                    //     fontWeight:
                                                    //         FontWeight.bold,
                                                    //     color: isSelected
                                                    //         ? Colors.white
                                                    //         : kPrimaryColor,
                                                    //   ),
                                                    // ),
                                                    // Text(
                                                    //   "${accountsData.amount?.toStringAsFixed(2)}",
                                                    //   style: TextStyle(
                                                    //     fontSize: 16,
                                                    //     fontWeight:
                                                    //         FontWeight.bold,
                                                    //     color: isSelected
                                                    //         ? Colors.white
                                                    //         : kPrimaryColor,
                                                    //   ),
                                                    // ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  )),
      ],
    ));
  }
}

// Receive Currency Code
class ReceiveCurrencyBottomSheet extends StatefulWidget {
  final Function(String, String, double) onReceiveCurrencySelected;

  const ReceiveCurrencyBottomSheet(
      {super.key, required this.onReceiveCurrencySelected});

  @override
  State<ReceiveCurrencyBottomSheet> createState() =>
      _ReceiveCurrencyBottomSheetState();
}

class _ReceiveCurrencyBottomSheetState
    extends State<ReceiveCurrencyBottomSheet> {
  final AccountsListApi _accountsListApi = AccountsListApi();
  List<AccountsListsData> accountsListData = [];
  bool isLoading = false;
  String? errorMessage;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    mAccounts();
  }

  // Accounts List Api ---------------
  Future<void> mAccounts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await _accountsListApi.accountsListApi();

      if (response.accountsList != null && response.accountsList!.isNotEmpty) {
        setState(() {
          accountsListData = response.accountsList!;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'No Account Found';
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select Currency',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: kPrimaryColor),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
        const SizedBox(
          height: defaultPadding,
        ),
        Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: kPrimaryColor,
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height,
                          child: isLoading
                              ? const Center(
                                  child:
                                      CircularProgressIndicator(), // Show loading indicator
                                )
                              : ListView.builder(
                                  itemCount: accountsListData.length,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    final accountsData =
                                        accountsListData[index];
                                    final isSelected = index == _selectedIndex;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5,
                                          horizontal: smallPadding),
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedIndex = index;

                                            widget.onReceiveCurrencySelected(
                                              accountsData.country ?? '',
                                              accountsData.currency ?? '',
                                              accountsData.amount ?? 0.0,
                                            );
                                            Navigator.pop(context);
                                          });
                                        },
                                        child: Card(
                                          elevation: 5,
                                          color: isSelected
                                              ? kPrimaryColor
                                              : Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                defaultPadding),
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(
                                                defaultPadding),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    // Use EU flag for EUR, country flag for others
                                                    if (accountsData.currency
                                                            ?.toUpperCase() ==
                                                        'EUR')
                                                      getEuFlagWidget()
                                                    else
                                                      CountryFlag
                                                          .fromCountryCode(
                                                        width: 35,
                                                        height: 35,
                                                        accountsData.country!,
                                                        shape: const Circle(),
                                                      ),
                                                    Text(
                                                      "${accountsData.currency}",
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isSelected
                                                            ? Colors.white
                                                            : kPrimaryColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(
                                                    height: defaultPadding),
                                                const Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    // Text(
                                                    //   "Balance",
                                                    //   style: TextStyle(
                                                    //     fontSize: 16,
                                                    //     fontWeight:
                                                    //         FontWeight.bold,
                                                    //     color: isSelected
                                                    //         ? Colors.white
                                                    //         : kPrimaryColor,
                                                    //   ),
                                                    // ),
                                                    // Text(
                                                    //   "${getCurrencySymbol(accountsData.currency)}${accountsData.amount?.toStringAsFixed(2) ?? '0.00'}",
                                                    //   style: TextStyle(
                                                    //     fontSize: 16,
                                                    //     fontWeight:
                                                    //         FontWeight.bold,
                                                    //     color: isSelected
                                                    //         ? Colors.white
                                                    //         : kPrimaryColor,
                                                    //   ),
                                                    // ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  )),
      ],
    ));
  }
}
