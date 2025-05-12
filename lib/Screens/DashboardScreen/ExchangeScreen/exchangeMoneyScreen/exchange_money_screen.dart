import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:smart_energy_pay/Screens/DashboardScreen/Dashboard/AccountsList/accountsListApi.dart';
import 'package:smart_energy_pay/Screens/DashboardScreen/ExchangeScreen/exchangeMoneyScreen/exchangeMoneyModel/exchangeMoneyApi.dart';
import 'package:smart_energy_pay/Screens/DashboardScreen/ExchangeScreen/exchangeMoneyScreen/exchangeMoneyModel/exchangeMoneyModel.dart';
import 'package:smart_energy_pay/constants.dart';
import 'package:intl/intl.dart';
import 'package:smart_energy_pay/util/auth_manager.dart';
import 'package:smart_energy_pay/util/currency_utils.dart';
import 'package:smart_energy_pay/util/customSnackBar.dart';
import '../../Dashboard/AccountsList/accountsListModel.dart';
import '../reviewExchangeMoneyScreen/review_exchange_money_screen.dart';

class ExchangeMoneyScreen extends StatefulWidget {
  final String? accountId;
  final String? country;
  final String? currency;
  final String? iban;
  final bool? status;
  final double? amount;

  const ExchangeMoneyScreen({
    super.key,
    this.accountId,
    this.country,
    this.currency,
    this.iban,
    this.status,
    this.amount,
  });

  @override
  State<ExchangeMoneyScreen> createState() => _ExchangeMoneyScreen();
}

class _ExchangeMoneyScreen extends State<ExchangeMoneyScreen>
    with SingleTickerProviderStateMixin {
  final ExchangeMoneyApi _exchangeMoneyApi = ExchangeMoneyApi();

  final TextEditingController mFromAmountController = TextEditingController();
  final TextEditingController mToAmountController = TextEditingController();

  bool isLoading = false;
  bool isReviewOrder = false;

  late AnimationController _arrowAnimationController;
  late Animation<Offset> _arrowAnimation;
  // From Account ---
  String? mFromAccountId;
  String? mFromCountry;
  String? mFromCurrency;
  String? mFromIban;
  bool? mFromStatus;
  double? mFromAmount;
  String? mFromCurrencySymbol;
  double? mFromTotalFees = 0.0;

  // To Account ---
  String? mToAccountId = '';
  String? mToCountry = '';
  String? mToCurrency = 'Select';
  String? mToIban = '';
  bool? mToStatus;
  double? mToAmount = 0.0;
  String? mToCurrencySymbol = '';
  double? mFromRate = 0.0;

  @override
  void initState() {
    super.initState();
    mSetDefaultAccountData();

    _arrowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _arrowAnimation = Tween<Offset>(
      begin: Offset(0, 0),
      end: const Offset(0, 0.2),
    ).animate(CurvedAnimation(
      parent: _arrowAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _arrowAnimationController.dispose();
    mFromAmountController.dispose();
    mToAmountController.dispose();
    super.dispose();
  }

  Future<void> mSetDefaultAccountData() async {
    setState(() {
      mFromAccountId = widget.accountId;
      mFromCountry = widget.country;
      mFromCurrency = widget.currency;
      mFromIban = widget.iban;
      mFromStatus = widget.status;
      mFromAmount = widget.amount;
      mFromCurrencySymbol = getCurrencySymbol(mFromCurrency!);
    });
  }

  Future<void> mSetSelectedAccountData(
      String mSelectedAccountId,
      String mSelectedCountry,
      String mSelectedCurrency,
      String mSelectedIban,
      bool mSelectedStatus,
      double mSelectedAmount) async {
    setState(() {
      mToAccountId = mSelectedAccountId;
      mToCountry = mSelectedCountry;
      mToCurrency = mSelectedCurrency;
      mToIban = mSelectedIban;
      mToStatus = mSelectedStatus;
      mToAmount = mSelectedAmount;
      mToCurrencySymbol = getCurrencySymbol(mToCurrency!);
    });

    // Stop animation when an account is selected
    if (mToAccountId != null && mToAccountId!.isNotEmpty) {
      _arrowAnimationController.stop();
    }

    if (mFromAmountController.text.isNotEmpty) {
      mExchangeMoneyApi();
    }
  }

  String getCurrencySymbol(String currencyCode) {
    var format = NumberFormat.simpleCurrency(name: currencyCode);
    return format.currencySymbol;
  }

  Future<void> mExchangeMoneyApi() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (mFromCurrency == null ||
          mToCurrency == null ||
          mToCurrency == "Select") {
        CustomSnackBar.showSnackBar(
            context: context,
            message: "Please select a valid exchange account!",
            color: kPrimaryColor);
        setState(() {
          isLoading = false;
        });
        return;
      }

      final request = ExchangeMoneyRequest(
          userId: AuthManager.getUserId(),
          amount: mFromAmountController.text,
          fromCurrency: mFromCurrency!,
          toCurrency: mToCurrency!);
      final response = await _exchangeMoneyApi.exchangeMoneyApi(request);

      if (response.message == "Success") {
        setState(() {
          isLoading = false;
          isReviewOrder = true;
          mFromRate = response.data.rate;
          mFromTotalFees = response.data.totalFees;
          mToAmountController.text =
              response.data.convertedAmount.toStringAsFixed(2);
        });
      } else {
        setState(() {
          isLoading = false;
          isReviewOrder = false;
          CustomSnackBar.showSnackBar(
              context: context,
              message: "We are facing some issue!",
              color: kPrimaryColor);
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        isReviewOrder = false;
        CustomSnackBar.showSnackBar(
            context: context, message: error.toString(), color: kPrimaryColor);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Exchange Money",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4.0,
                color: Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(defaultPadding),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              // Navigate to PayRecipientsScreen when tapped
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
                                    if (mFromCurrency?.toUpperCase() == 'EUR')
                                      getEuFlagWidget()
                                    else
                                      CountryFlag.fromCountryCode(
                                        width: 35,
                                        height: 35,
                                        mFromCountry!,
                                        shape: const Circle(),
                                      ),
                                    const SizedBox(width: defaultPadding),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$mFromCurrency Account',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: kPrimaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // const Icon(Icons.navigate_next_rounded,
                                    //     color: kPrimaryColor),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: defaultPadding),
                          TextFormField(
                            controller: mFromAmountController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            cursorColor: kPrimaryColor,
                            style: const TextStyle(color: kPrimaryColor),
                            onChanged: (value) {
                              if (mToCurrency != "Select") {
                                if (mFromAmountController.text.isNotEmpty) {
                                  if (double.parse(
                                          mFromAmountController.text) <=
                                      mFromAmount!) {
                                    mExchangeMoneyApi();
                                  } else {
                                    CustomSnackBar.showSnackBar(
                                        context: context,
                                        message:
                                            "You don't have sufficient balance to exchange money",
                                        color: kPrimaryColor);
                                  }
                                } else {
                                  setState(() {
                                    isReviewOrder = false;
                                    mToAmountController.clear();
                                  });
                                  CustomSnackBar.showSnackBar(
                                      context: context,
                                      message: "Please enter an amount",
                                      color: kPrimaryColor);
                                }
                              } else {
                                CustomSnackBar.showSnackBar(
                                    context: context,
                                    message:
                                        "Please select an exchange account",
                                    color: kPrimaryColor);
                              }
                            },
                            decoration: InputDecoration(
                              prefix: Text(
                                '$mFromCurrencySymbol ',
                                style: TextStyle(
                                  color: mToCurrency == "Select"
                                      ? Colors.grey.withOpacity(0.5)
                                      : kPrimaryColor,
                                ),
                              ),
                              labelText: "Amount",
                              labelStyle: TextStyle(
                                color: mToCurrency == "Select"
                                    ? Colors.grey.withOpacity(0.9)
                                    : kPrimaryColor,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(),
                              ),
                              filled: true,
                              fillColor: mToCurrency == "Select"
                                  ? Colors.grey.withOpacity(0.3)
                                  : Colors.transparent, // Visual feedback
                            ),

                            enabled: mToCurrency !=
                                "Select", // Disable until account selected
                            maxLines: 2,
                            minLines: 1,
                          ),
                          const SizedBox(height: 30),
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
                                "$mFromCurrencySymbol $mFromTotalFees",
                                style: const TextStyle(
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Balance:",
                                style: TextStyle(
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "$mFromCurrencySymbol ${mFromAmount?.toStringAsFixed(2)}",
                                style: const TextStyle(
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 1,
                      width: double.maxFinite,
                      color: kPrimaryLightColor,
                    ),
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
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                          child: mToAccountId == null || mToAccountId!.isEmpty
                              ? SlideTransition(
                                  position: _arrowAnimation,
                                  child: const Icon(
                                    Icons.arrow_downward,
                                    key: ValueKey(
                                        "floating_arrow"), // Ensures proper state update
                                    size: 37,
                                    color: kPrimaryColor,
                                  ),
                                )
                              : const Icon(
                                  Icons.arrow_downward,
                                  key: ValueKey("static_arrow"),
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
                margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(defaultPadding),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              mGetAllAccountBottomSheet(context, mFromCurrency);
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
                                    if (mToCurrency?.toUpperCase() == 'EUR')
                                      getEuFlagWidget() // Assuming you have this widget defined
                                    else
                                      CountryFlag.fromCountryCode(
                                        width: 35,
                                        height: 35,
                                        mToCountry!.isEmpty
                                            ? 'US'
                                            : mToCountry!,
                                        shape: const Circle(),
                                      ),
                                    const SizedBox(width: defaultPadding),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$mToCurrency Account',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
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
                          const SizedBox(height: defaultPadding),
                          TextFormField(
                            controller: mToAmountController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            cursorColor: kPrimaryColor,
                            style: const TextStyle(color: kPrimaryColor),
                            decoration: InputDecoration(
                              prefixText: '$mToCurrencySymbol ',
                              prefixStyle:
                                  const TextStyle(color: kPrimaryColor),
                              labelText: "Converted Amount",
                              labelStyle: const TextStyle(color: kPrimaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(),
                              ),
                              filled: true,
                              fillColor: Colors.grey.withOpacity(0.1),
                            ),
                            enabled: false,
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Balance:",
                                style: TextStyle(
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "$mToCurrencySymbol ${mToAmount?.toStringAsFixed(2)}",
                                style: const TextStyle(
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: isReviewOrder
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          print(
                              "Navigating to ReviewExchangeMoneyScreen with:");
                          print("From Account ID: $mFromAccountId");
                          print("From Country: $mFromCountry");
                          print("From Currency: $mFromCurrency");
                          print("From IBAN: $mFromIban");
                          print("From Amount: $mFromAmount");
                          print("From Currency Symbol: $mFromCurrencySymbol");
                          print("From Total Fees: $mFromTotalFees");
                          print("From Rate: $mFromRate");
                          print(
                              "From Exchange Amount: ${mFromAmountController.text}");
                          print("To Account ID: $mToAccountId");
                          print("To Country: $mToCountry");
                          print("To Currency: $mToCurrency");
                          print("To IBAN: $mToIban");
                          print("To Amount: $mToAmount");
                          print("To Currency Symbol: $mToCurrencySymbol");
                          print(
                              "To Exchanged Amount: ${mToAmountController.text}");
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReviewExchangeMoneyScreen(
                                fromAccountId: mFromAccountId,
                                fromCountry: mFromCountry,
                                fromCurrency: mFromCurrency,
                                fromIban: mFromIban,
                                fromAmount: mFromAmount,
                                fromCurrencySymbol: mFromCurrencySymbol,
                                fromTotalFees: mFromTotalFees,
                                fromRate: mFromRate,
                                fromExchangeAmount: mFromAmountController.text,
                                toAccountId: mToAccountId,
                                toCountry: mToCountry,
                                toCurrency: mToCurrency,
                                toIban: mToIban,
                                toAmount: mToAmount,
                                toCurrencySymbol: mToCurrencySymbol,
                                toExchangedAmount: mToAmountController.text,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Review Order',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      )
                    : Container(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void mGetAllAccountBottomSheet(BuildContext context, String? mCurrency) {
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
                currency: mCurrency,
                onAccountSelected: (String accountId,
                    String country,
                    String currency,
                    String iban,
                    bool status,
                    double amount) async {
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

// AllAccountsBottomSheet class remains unchanged as per the previous fix with mounted checks

class AllAccountsBottomSheet extends StatefulWidget {
  final String? currency;
  final Function(String, String, String, String, bool, double)
      onAccountSelected;

  const AllAccountsBottomSheet({
    super.key,
    this.currency,
    required this.onAccountSelected,
  });

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

  Future<void> mAccounts() async {
    if (!mounted) return; // Early exit if not mounted

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await _accountsListApi.accountsListApi();

      if (!mounted) return; // Check again before updating state

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
      if (!mounted) return; // Check before error handling

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
                'Change Account',
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
          const SizedBox(height: defaultPadding),
          const Text(
            "Select your preferred account for currency exchange. Easily switch between different currencies to manage your transactions.",
            style: TextStyle(color: kPrimaryColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: defaultPadding),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: kPrimaryColor),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height,
                          child: ListView.builder(
                            itemCount: accountsListData.length,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final accountsData = accountsListData[index];
                              final isSelected = index == _selectedIndex;

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 5, horizontal: smallPadding),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedIndex = index;
                                      if (widget.currency !=
                                          accountsData.currency) {
                                        widget.onAccountSelected(
                                          accountsData.accountId ?? '',
                                          accountsData.country ?? '',
                                          accountsData.currency ?? '',
                                          accountsData.iban ?? '',
                                          accountsData.status ?? false,
                                          accountsData.amount ?? 0.0,
                                        );
                                        Navigator.pop(context);
                                      } else {
                                        CustomSnackBar.showSnackBar(
                                          context: context,
                                          message:
                                              "Please select another account",
                                          color: kPrimaryColor,
                                        );
                                      }
                                    });
                                  },
                                  child: Card(
                                    elevation: 5,
                                    color: isSelected
                                        ? kPrimaryColor
                                        : Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(defaultPadding),
                                    ),
                                    child: Container(
                                      padding:
                                          const EdgeInsets.all(defaultPadding),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              // Use EU flag for EUR, country flag for others
                                              if (accountsData.currency
                                                      ?.toUpperCase() ==
                                                  'EUR')
                                                getEuFlagWidget()
                                              else
                                                CountryFlag.fromCountryCode(
                                                  width: 35,
                                                  height: 35,
                                                  accountsData.country!,
                                                  shape: const Circle(),
                                                ),
                                              Text(
                                                "${accountsData.currency}",
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
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
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "IBAN",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : kPrimaryColor,
                                                ),
                                              ),
                                              Text(
                                                "${accountsData.iban}",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
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
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Balance",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : kPrimaryColor,
                                                ),
                                              ),
                                              Text(
                                                "${getCurrencySymbol(accountsData.currency)}${accountsData.amount?.toStringAsFixed(1) ?? '0.0'}",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
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
                  ),
          ),
        ],
      ),
    );
  }
}
