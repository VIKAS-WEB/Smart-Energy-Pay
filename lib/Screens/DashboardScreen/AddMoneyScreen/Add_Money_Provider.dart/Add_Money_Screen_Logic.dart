import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_energy_pay/Screens/DashboardScreen/AddMoneyScreen/AddPaymentSuccessModel/addPaymentSuccessApi.dart';
import 'package:smart_energy_pay/Screens/DashboardScreen/AddMoneyScreen/AddPaymentSuccessModel/addPaymentSuccessModel.dart';
import 'package:smart_energy_pay/Screens/DashboardScreen/AddMoneyScreen/AddPaymentSuccessScreen/addPaymentSuccessScreen.dart';
import 'package:smart_energy_pay/Screens/DashboardScreen/AddMoneyScreen/Add_Money_Provider.dart/AddMoneyProvider.dart';
import 'package:smart_energy_pay/Screens/DashboardScreen/SendMoneyScreen/PayRecipientsScree/exchangeCurrencyModel/NewCurrencyExchangeAPI.dart';
import 'package:smart_energy_pay/Screens/DashboardScreen/SendMoneyScreen/PayRecipientsScree/exchangeCurrencyModel/exchangeCurrencyModel.dart';
import 'package:smart_energy_pay/constants.dart';
import 'package:smart_energy_pay/model/currencyApiModel/Model/currencyModel.dart';
import 'package:smart_energy_pay/model/currencyApiModel/Services/currencyApi.dart';
import 'package:smart_energy_pay/util/auth_manager.dart';
import 'package:smart_energy_pay/util/customSnackBar.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../SendMoneyScreen/PayRecipientsScree/exchangeCurrencyModel/CurrencyExchangeModel.dart';

class AddMoneyScreenLogic {
  final Razorpay _razorpay = Razorpay();
  final AddPaymentSuccessApi _addPaymentSuccessApi = AddPaymentSuccessApi();
  final CurrencyApi _currencyApi = CurrencyApi();
  final ExchangeCurrencyApiNew _exchangeCurrencyApi = ExchangeCurrencyApiNew();

  final String apiUrl = "https://quickcash.oyefin.com/api/v1/stripe/create-intent";
  final TextEditingController mAmountController = TextEditingController();
  List<CurrencyListsData> currency = [];
  bool isAddLoading = false;

  // From Account
  String? mFromAccountId;
  String? mFromCountry;
  String? mFromCurrency;
  String? mFromAccountName;
  String? mFromIban;
  bool? mFromStatus;
  double? mFromAmount;
  String? mFromCurrencySymbol;

  AddMoneyScreenLogic({
    String? accountId,
    String? accountName,
    String? country,
    String? currency,
    String? iban,
    bool? status,
    double? amount,
  }) {
    mFromAccountId = accountId;
    mFromCountry = country;
    mFromCurrency = currency;
    mFromAccountName = accountName;
    mFromIban = iban;
    mFromStatus = status;
    mFromAmount = amount;
    init();
  }

  void init() {
    mSetDefaultAccountData();
    // mGetCurrency is called in AddMoneyScreenUI's initState
    Stripe.publishableKey = dotenv.env['stripePublishableKey'] ?? 'default_key';;
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void setupPaymentErrorHandler(Function(PaymentFailureResponse) handler) {
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handler);
  }

  void dispose() {
    _razorpay.clear();
    mAmountController.dispose();
  }

  Future<void> mSetDefaultAccountData() async {
    mFromCurrencySymbol = getCurrencySymbol(mFromCurrency ?? 'USD');
  }

  Future<void> mGetCurrency() async {
    try {
      final response = await _currencyApi.currencyApi();
      if (response.currencyList != null && response.currencyList!.isNotEmpty) {
        currency = response.currencyList!;
      } else {
        throw Exception('No currencies returned from API');
      }
    } catch (e) {
      print('Error fetching currencies: $e');
      currency = [];
      throw Exception('Failed to fetch currencies: $e');
    }
  }

  String getCurrencySymbol(String currencyCode) {
    return NumberFormat.simpleCurrency(name: currencyCode).currencySymbol;
  }

  Future<double> getFeeAmount(double transactionAmount) async {
    try {
      final dio = Dio();
      final token = AuthManager.getToken();
      if (token == null) {
        print('getFeeAmount: No auth token available');
        return 23.0;
      }

      final response = await dio.get(
        "https://quickcash.oyefin.com/api/v1/admin/feetype/type?type=Debit",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['status'] == 201 &&
          response.data['data'] != null &&
          response.data['data'].isNotEmpty) {
        final feeData = response.data['data'][0]['feedetails'][0];
        final commissionType = feeData['commissionType'];
        final value = feeData['value'].toDouble();
        final minimumValue = feeData['minimumValue'].toDouble();

        double calculatedFee =
            commissionType == 'percentage' ? transactionAmount * (value / 100) : value;
        double finalFee = calculatedFee > minimumValue ? calculatedFee : minimumValue;

        return finalFee;
      }
      print('getFeeAmount: Unexpected API response: ${response.statusCode}, ${response.data}');
      return 23.0;
    } catch (e) {
      print('getFeeAmount: Error: $e');
      return 23.0;
    }
  }

  Future<void> mExchangeMoneyApi(BuildContext context) async {
    final provider = Provider.of<AddMoneyProvider>(context, listen: false);
    final inputAmount = double.tryParse(mAmountController.text) ?? 0.0;

    if (provider.selectedSendCurrency == null) {
      provider.resetAllFields();
      throw Exception('Please select a currency');
    }

    if (inputAmount <= 0) {
      provider.resetAllFields();
      throw Exception('Please enter a valid amount greater than zero');
    }

    try {
      final exchangeRequest = ExchangeCurrencyRequestnew(
        toCurrency: mFromCurrency ?? 'USD',
        fromCurrency: provider.selectedSendCurrency ?? 'USD',
        amount: inputAmount,
      );
      final response = await _exchangeCurrencyApi.exchangeCurrencyApiNew(exchangeRequest);

      if (response.success && response.result != null) {
        final fee = await getFeeAmount(inputAmount);
        if (fee < 0) {
          throw Exception('Invalid fee amount');
        }
        final totalAmount = inputAmount + fee;
        final convertedAmount = response.result!.convertedAmount;

        if (totalAmount < inputAmount || convertedAmount <= 0) {
          throw Exception('Invalid API response data');
        }

        provider.setDepositFees(fee);
        provider.setAmountCharge(totalAmount.toStringAsFixed(2));
        provider.setConversionAmount(convertedAmount.toStringAsFixed(2));
        provider.setToCurrencySymbol(getCurrencySymbol(provider.selectedSendCurrency ?? 'USD'));
      } else {
        throw Exception('Exchange API failed: ${response.result ?? 'Unknown error'}');
      }
    } catch (error) {
      provider.resetAllFields();
      print('Error in mExchangeMoneyApi: $error');
      throw Exception(error.toString());
    }
  }

  Future<void> handleStripePayment(BuildContext context, GlobalKey<FormState> formKey) async {
    final provider = Provider.of<AddMoneyProvider>(context, listen: false);
    if (!_validatePaymentPrerequisites(context, formKey, provider)) return;

    isAddLoading = true;
    if (context.mounted) {
      (context as Element).markNeedsBuild();
    }
    try {
      final dio = Dio();
      final token = AuthManager.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final amount = double.tryParse(mAmountController.text) ?? 0.0;
      final data = {
        "amount": double.tryParse(provider.amountCharge) ?? 0.0,
        "account": mFromAccountId ?? "",
        "user": AuthManager.getUserId() ?? "",
        "convertedAmount": double.tryParse(provider.conversionAmount) ?? 0.0,
        "fee": provider.depositFees,
        "currency": provider.selectedSendCurrency?.toLowerCase() ?? "",
        "from_currency": provider.selectedSendCurrency ?? "",
        "to_currency": mFromCurrency ?? "USD",
      };

      final response = await dio.post(
        apiUrl,
        data: data,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200 &&
          response.data["status"] == 201 &&
          response.data["data"] != null &&
          context.mounted) {
        final clientSecret = response.data["data"]["client_secret"];
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: "smart_energy_pay",
            style: ThemeMode.light,
          ),
        );
        await Stripe.instance.presentPaymentSheet();

        await _completeStripePayment(
            context, dio, token, response.data["data"]["id"], "succeeded");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: AwesomeSnackbarContent(
                title: 'Success!',
                message: "Payment completed successfully!",
                contentType: ContentType.success,
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          );
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(
              builder: (context) => AddPaymentSuccessScreen(
                transactionId: response.data["data"]["id"],
                amount: '${getCurrencySymbol(provider.selectedSendCurrency ?? "USD")} ${provider.amountCharge}',
              ),
            ),
          );
        }
      } else {
        throw Exception("Failed to create payment intent: ${response.data}");
      }
    } on StripeException catch (e) {
      if (context.mounted) {
        CustomSnackBar.showSnackBar(
            context: context,
            message: "Stripe Error: ${e.error.localizedMessage}",
            color: Colors.red);
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showSnackBar(
            context: context, message: "Payment Failed: $e", color: Colors.red);
      }
    } finally {
      isAddLoading = false;
      if (context.mounted) {
        (context as Element).markNeedsBuild();
      }
    }
  }

  Future<void> _completeStripePayment(
      BuildContext context, Dio dio, String token, String transactionId, String status) async {
    final provider = Provider.of<AddMoneyProvider>(context, listen: false);

    final completeData = {
      "user": AuthManager.getUserId() ?? "",
      "status": status,
      "orderDetails": transactionId,
      "userData": AuthManager.getUserName().toString(),
      "account": mFromAccountId ?? "",
      "amount": double.tryParse(mAmountController.text) ?? 0.0,
      "fee": provider.depositFees,
      "amountText": "$mFromCurrencySymbol${double.tryParse(mAmountController.text) ?? 0.0}",
      "from_currency": mFromCurrency ?? "USD",
      "to_currency": provider.selectedSendCurrency ?? "",
      "convertedAmount": double.tryParse(provider.conversionAmount) ?? 0.0,
      "conversionAmountText": "$mFromCurrencySymbol${provider.conversionAmount}",
    };

    final response = await dio.post(
      "https://quickcash.oyefin.com/api/v1/stripe/complete-addmoney",
      data: completeData,
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );
    if (response.statusCode != 200 || response.data['status'] != 201) {
      throw Exception("Failed to complete add money: ${response.data}");
    }
  }

  Future<void> openRazorpay(BuildContext context) async {
    final provider = Provider.of<AddMoneyProvider>(context, listen: false);
    if (provider.selectedSendCurrency != "INR") {
      if (context.mounted) {
        CustomSnackBar.showSnackBar(
            context: context, message: "Only INR supported for UPI", color: kRedColor);
      }
      return;
    }

    isAddLoading = true;
    if (context.mounted) {
      (context as Element).markNeedsBuild();
    }
    try {
      final amount = (double.tryParse(provider.amountCharge) ?? 0.0) * 100;
      if (amount <= 0) {
        throw Exception('Invalid payment amount');
      }
      final options = {
        'key': 'rzp_test_TR6pZnguGgK8hQ',
        'amount': amount.toInt(),
        'name': 'smart_energy_pay',
        'method': 'upi',
        'theme': {'color': "#6F35A5"},
      };
      _razorpay.open(options);
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showSnackBar(
            context: context, message: "Failed to open Razorpay: $e", color: kRedColor);
      }
    }
    // Note: isAddLoading is reset in payment handlers
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    isAddLoading = false;
    mAddPaymentSuccess(navigatorKey.currentContext, response.paymentId, "Success", "Razorpay");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    isAddLoading = false;
    print('_handleExternalWallet: External wallet used: ${response.walletName}');
  }

  Future<void> mAddPaymentSuccess(
      BuildContext? context, String? paymentId, String status, String paymentGateway) async {
    if (context == null) {
      isAddLoading = false;
      return;
    }
    final provider = Provider.of<AddMoneyProvider>(context, listen: false);
    isAddLoading = true;
    if (context.mounted) {
      (context as Element).markNeedsBuild();
    }

    try {
      final request = AddPaymentSuccessRequest(
        userId: AuthManager.getUserId() ?? "",
        status: status,
        paymentId: paymentId ?? "",
        paymentGateway: paymentGateway,
        amount: mAmountController.text,
        fee: provider.depositFees.toString(),
        amountText: '${provider.toCurrencySymbol}${mAmountController.text}',
        fromCurrency: mFromCurrency ?? "USD",
        toCurrency: provider.selectedSendCurrency ?? "",
        conversionAmount: provider.conversionAmount,
        conversionAmountText: '$mFromCurrencySymbol${provider.conversionAmount}',
      );
      final response = await _addPaymentSuccessApi.addPaymentSuccessApi(request);

      if (response.message == "Payment has been done Successfully !!!" &&
          status == "Success" &&
          context.mounted) {
        provider.resetAllFields();
        mAmountController.clear();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AddPaymentSuccessScreen(
              transactionId: paymentId ?? 'Unknown',
              amount: '${provider.toCurrencySymbol}${provider.amountCharge}',
            ),
          ),
        );
      } else {
        throw Exception('Payment success API failed: ${response.message}');
      }
    } catch (error) {
      if (context.mounted) {
        CustomSnackBar.showSnackBar(
            context: context, message: "Something went wrong: $error", color: kRedColor);
      }
    } finally {
      isAddLoading = false;
      if (context.mounted) {
        (context as Element).markNeedsBuild();
      }
    }
  }

  bool _validatePaymentPrerequisites(
      BuildContext context, GlobalKey<FormState> formKey, AddMoneyProvider provider) {
    if (!formKey.currentState!.validate()) return false;
    if (provider.selectedSendCurrency == null) {
      CustomSnackBar.showSnackBar(
          context: context, message: "Please select a currency", color: kPrimaryColor);
      return false;
    }
    if (provider.selectedTransferType == null) {
      CustomSnackBar.showSnackBar(
          context: context, message: "Please select a transfer type", color: kPrimaryColor);
      return false;
    }
    if (provider.amountCharge == '0.0' || provider.conversionAmount == '0.0') {
      CustomSnackBar.showSnackBar(
          context: context,
          message: "Please enter a valid amount and wait for calculation",
          color: kPrimaryColor);
      return false;
    }
    return true;
  }

  void showPaymentPopupMessage(BuildContext context, bool isPaymentSuccess, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(isPaymentSuccess ? Icons.done : Icons.clear,
                color: isPaymentSuccess ? Colors.green : Colors.red),
            const SizedBox(width: 5),
            Text(isPaymentSuccess ? 'Payment Successful' : 'Payment Failed',
                style: const TextStyle(fontSize: 20)),
          ],
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              const Divider(color: Colors.grey),
              const SizedBox(height: 5),
              Text(message),
              const SizedBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();