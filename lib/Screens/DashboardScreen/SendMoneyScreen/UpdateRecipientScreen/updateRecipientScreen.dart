import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_energy_pay/Screens/DashboardScreen/Dashboard/AccountsList/accountsListApi.dart';
import 'package:smart_energy_pay/Screens/DashboardScreen/Dashboard/AccountsList/accountsListModel.dart';
import 'package:smart_energy_pay/Screens/DashboardScreen/SendMoneyScreen/UpdateRecipientScreen/RecipientDetailsModel/receipientDetailsApi.dart';
import 'package:smart_energy_pay/Screens/DashboardScreen/SendMoneyScreen/UpdateRecipientScreen/RecipientExchangeMoneyModel/recipientExchangeMoneyApi.dart';
import 'package:smart_energy_pay/Screens/DashboardScreen/SendMoneyScreen/UpdateRecipientScreen/RecipientExchangeMoneyModel/recipientExchangeMoneyModel.dart';
import 'package:smart_energy_pay/Screens/DashboardScreen/SendMoneyScreen/UpdateRecipientScreen/UpdateRecipientModel/UpdateRecipientApi.dart';
import 'package:smart_energy_pay/Screens/DashboardScreen/SendMoneyScreen/UpdateRecipientScreen/UpdateRecipientModel/updateRecipientModel.dart';
import 'package:smart_energy_pay/constants.dart';
import 'package:smart_energy_pay/util/currency_utils.dart';

import '../../../../util/auth_manager.dart';
import '../../../../util/customSnackBar.dart';
import '../../../HomeScreen/home_screen.dart';

class UpdateRecipientScreen extends StatefulWidget {
  final String? mRecipientId;

  const UpdateRecipientScreen({super.key, this.mRecipientId});

  @override
  State<UpdateRecipientScreen> createState() => _UpdateRecipientScreenState();
}

class _UpdateRecipientScreenState extends State<UpdateRecipientScreen> {
  final RecipientsDetailsApi _recipientsDetailsApi = RecipientsDetailsApi();
  final RecipientExchangeMoneyApi _recipientExchangeMoneyApi =
      RecipientExchangeMoneyApi();
  final RecipientUpdateApi _recipientUpdateApi = RecipientUpdateApi();

  TextEditingController mIbanController = TextEditingController();
  TextEditingController mBicCodeController = TextEditingController();
  TextEditingController mCurrencyController = TextEditingController();
  TextEditingController mAmountController = TextEditingController();

  bool isLoading = false;
  bool isSubmitLoading = false;
  bool isSubmit = false;

  // From Currency
  String? mFromCurrency;

  // To Currency -----
  String? mToAccountId = '';
  String? mToCountry = '';
  String? mToCurrency = 'Select';
  String? mToIban = '';
  bool? mToStatus;
  double? mToAmount = 0.0;
  String? mToCurrencySymbol = '';
  String? mFromCurrencySymbol = '';
  double? mFromRate;
  double? mFees = 0.0;
  String? mTotalAmount = "0.0";
  double? mGetTotalAmount = 0.0;

  Future<void> mSetSelectedAccountData(
      mSelectedAccountId,
      mSelectedCountry,
      mSelectedCurrency,
      mSelectedIban,
      mSelectedStatus,
      mSelectedAmount) async {
    setState(() {
      mToAccountId = mSelectedAccountId;
      mToCountry = mSelectedCountry;
      mToCurrency = mSelectedCurrency;
      mToIban = mSelectedIban;
      mToStatus = mSelectedStatus;
      mToAmount = mSelectedAmount;

      mToCurrencySymbol = getCurrencySymbol(mToCurrency!);
    });
  }

  @override
  void initState() {
    mShowRecipientDetail();
    super.initState();
  }

  // Recipient Details Get Api *****
  Future<void> mShowRecipientDetail() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await _recipientsDetailsApi
          .recipientsDetailsApi(widget.mRecipientId!);

      if (response.message == "Reciepient list is Successfully fetched") {
        setState(() {
          isLoading = false;
          mIbanController.text = response.recipientDetails!.first.iban!;
          mBicCodeController.text = response.recipientDetails!.first.bicCode!;
          mCurrencyController.text = response.recipientDetails!.first.currency!;
          mFromCurrency = response.recipientDetails!.first.currency!;
          mFromCurrencySymbol = getCurrencySymbol(mFromCurrency!);
        });
      } else {
        setState(() {
          Navigator.of(context).pop();
          CustomSnackBar.showSnackBar(
              context: context,
              message: "We are facing some issue!",
              color: kPrimaryColor);
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        Navigator.of(context).pop();
        CustomSnackBar.showSnackBar(
            context: context,
            message: "Something went wrong!",
            color: kPrimaryColor);
      });
    }
  }

  // Exchange Money Api **************
  Future<void> mExchangeMoneyApi() async {
    setState(() {
      // isLoading = true;
    });

    try {
      final request = RecipientExchangeMoneyRequest(
          userId: AuthManager.getUserId(),
          amount: mAmountController.text,
          fromCurrency: mFromCurrency!,
          toCurrency: mToCurrency!);
      final response =
          await _recipientExchangeMoneyApi.recipientExchangeMoneyApi(request);

      if (response.message == "Success") {
        setState(() {
          isLoading = false;
          isSubmit = true;
          mFees = response.data.totalFees;
          mTotalAmount = response.data.totalCharge.toString();

          double amount = double.parse(mAmountController.text);
          double rate = response.data.rate;
          mGetTotalAmount = amount / rate;
        });
      } else {
        setState(() {
          isLoading = false;
          isSubmit = false;
          CustomSnackBar.showSnackBar(
              context: context,
              message: "We are facing some issue!",
              color: kPrimaryColor);
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        isSubmit = false;
      });
    }
  }

  // Update Recipients Details Api ************
  Future<void> mUpdateRecipient() async {
    setState(() {
      isSubmitLoading = true;
    });

    try {
      String amountText = '$mFromCurrencySymbol ${mAmountController.text}';

      String conversionAmountText = '$mToCurrencySymbol $mGetTotalAmount';

      final request = RecipientUpdateRequest(
          userId: AuthManager.getUserId(),
          fee: mFees.toString(),
          toCurrency: mToCurrency!,
          recipientId: widget.mRecipientId!,
          amount: mAmountController.text,
          amountText: amountText,
          conversionAmount: mGetTotalAmount.toString(),
          conversionAmountText: conversionAmountText);
      final response = await _recipientUpdateApi.recipientUpdateApi(request);

      if (response.message ==
          "Bank Transfer transaction has been submitted Successfully!!!") {
        setState(() {
          isSubmitLoading = false;
          CustomSnackBar.showSnackBar(
              context: context,
              message:
                  "Bank Transfer transaction has been submitted Successfully!",
              color: Colors.green);
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
          isSubmitLoading = false;
          CustomSnackBar.showSnackBar(
              context: context,
              message: "We are facing some issue!",
              color: kRedColor);
        });
      }
    } catch (error) {
      setState(() {
        isSubmitLoading = false;
        isSubmit = false;
      });
    }
  }

  // Currency Symbol *********
  String getCurrencySymbol(String currencyCode) {
    var format = NumberFormat.simpleCurrency(name: currencyCode);
    return format.currencySymbol;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Beneficiary Account Details",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: kPrimaryColor,
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: defaultPadding),
                    TextFormField(
                      controller: mIbanController,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      cursorColor: kPrimaryColor,
                      readOnly: true,
                      style: const TextStyle(color: kPrimaryColor),
                      decoration: InputDecoration(
                        labelText: "IBAN / Account Number",
                        labelStyle: const TextStyle(color: kPrimaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(),
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                    ),
                    const SizedBox(height: defaultPadding),
                    TextFormField(
                      controller: mBicCodeController,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      cursorColor: kPrimaryColor,
                      readOnly: true,
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
                    ),

                    const SizedBox(height: defaultPadding),

                    TextFormField(
                      controller: mCurrencyController,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      cursorColor: kPrimaryColor,
                      style: const TextStyle(color: kPrimaryColor),
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Currency",
                        labelStyle: const TextStyle(color: kPrimaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(),
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                    ),
                    const SizedBox(height: largePadding),

                    GestureDetector(
                      onTap: () {
                        mGetAllAccountBottomSheet(context);
                      },
                      child: Card(
                        elevation: 1.0,
                        color: kPrimaryLightColor,
                        margin: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 0),
                        child: Padding(
                          padding: const EdgeInsets.all(defaultPadding),
                          child: Row(
                            children: [
                              // Use EU flag for EUR, country flag for others
                              if (mToCurrency?.toUpperCase() == 'EUR')
                                getEuFlagWidget()
                              else
                                CountryFlag.fromCountryCode(
                                  width: 55,
                                  height: 55,
                                  mToCountry!,
                                  shape: const RoundedRectangle(smallPadding),
                                ),
                              const SizedBox(width: defaultPadding),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$mToCurrency Account',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: kPrimaryColor,
                                      ),
                                    ),
                                    Text(
                                      '$mToIban',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                        color: kPrimaryColor,
                                      ),
                                    ),
                                    Text(
                                      '${getCurrencySymbol(mToCurrency!)}${mToAmount!.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                        color: kPrimaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.navigate_next_rounded,
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
                      controller: mAmountController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      cursorColor: kPrimaryColor,
                      style: const TextStyle(color: kPrimaryColor),
                      decoration: InputDecoration(
                        labelText: "Enter Amount",
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
                          return 'Please enter amount';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        if (mToCurrency != "Select") {
                          if (mAmountController.text.isNotEmpty) {
                            if (double.parse(mAmountController.text) <=
                                mToAmount!) {
                              mExchangeMoneyApi();
                            } else {
                              CustomSnackBar.showSnackBar(
                                  context: context,
                                  message: "Please enter a valid amount",
                                  color: kPrimaryColor);
                            }
                          } else {
                            CustomSnackBar.showSnackBar(
                                context: context,
                                message: "Please enter an amount",
                                color: kPrimaryColor);
                            setState(() {
                              mFees = 0.0;
                              mTotalAmount = '0.0';
                              mGetTotalAmount = 0.0;
                            });
                          }
                        } else {
                          CustomSnackBar.showSnackBar(
                              context: context,
                              message: "Please select an account",
                              color: kPrimaryColor);
                        }
                      },
                    ),

                    const SizedBox(height: 45),
                    Padding(
                      padding: const EdgeInsets.all(defaultPadding),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Fee:",
                                style: TextStyle(
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "$mToCurrencySymbol ${mFees!.toStringAsFixed(2)}",
                                style: const TextStyle(
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Total Amount:",
                                style: TextStyle(
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "$mToCurrencySymbol $mTotalAmount",
                                style: const TextStyle(
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Get Total Amount:",
                                style: TextStyle(
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                               "$mToCurrencySymbol ${mGetTotalAmount?.toStringAsFixed(2) ?? '0.00'}",
                                style: const TextStyle(
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: largePadding,
                    ),
                    if (isSubmitLoading)
                      const Center(
                        child: CircularProgressIndicator(
                          color: kPrimaryColor,
                        ),
                      ), // Show loading indicator

                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      child: isSubmit == true
                          ? ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed:
                                  isSubmitLoading ? null : mUpdateRecipient,
                              child: const Text(
                                'Submit',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            )
                          : Container(), // Show an empty container (or something else) when isReviewOrder is true
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void mGetAllAccountBottomSheet(BuildContext context) {
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
              child: AllAccountsBottomSheet(
                onAccountSelected: (
                  String accountId,
                  String country,
                  String currency,
                  String iban,
                  bool status,
                  double amount,
                ) async {
                  await mSetSelectedAccountData(
                    accountId,
                    country,
                    currency,
                    iban,
                    status,
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

class AllAccountsBottomSheet extends StatefulWidget {
  final Function(String, String, String, String, bool, double)
      onAccountSelected; // Update with required parameters

  const AllAccountsBottomSheet({super.key, required this.onAccountSelected});

  @override
  State<AllAccountsBottomSheet> createState() => _AllAccountsBottomSheetState();
}

class _AllAccountsBottomSheetState extends State<AllAccountsBottomSheet> {
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
              'Select Account',
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

                                            widget.onAccountSelected(
                                              accountsData.accountId ?? '',
                                              accountsData.country ?? '',
                                              accountsData.currency ?? '',
                                              accountsData.iban ?? '',
                                              accountsData.status ?? false,
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
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      "IBAN",
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isSelected
                                                            ? Colors.white
                                                            : kPrimaryColor,
                                                      ),
                                                    ),
                                                    Text(
                                                      "${accountsData.iban}",
                                                      style: TextStyle(
                                                        fontSize: 16,
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
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      "Balance",
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isSelected
                                                            ? Colors.white
                                                            : kPrimaryColor,
                                                      ),
                                                    ),
                                                    Text(
                                                      "${getCurrencySymbol(accountsData.currency)}${accountsData.amount?.toStringAsFixed(2) ?? '0.00'}",
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isSelected
                                                            ? Colors.white
                                                            : kPrimaryColor,
                                                      ),
                                                    ),
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
