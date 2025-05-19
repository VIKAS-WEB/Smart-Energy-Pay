import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:smart_energy_pay/Screens/InvoicesScreen/ClientsScreen/ClientsScreen/model/clientsApi.dart';
import 'package:smart_energy_pay/Screens/InvoicesScreen/ClientsScreen/ClientsScreen/model/clientsModel.dart';
import 'package:smart_energy_pay/Screens/InvoicesScreen/InvoiceDashboardScreen/AddInvoice/addInvouceModel/addInvoiceApi.dart';
import 'package:smart_energy_pay/Screens/InvoicesScreen/InvoiceDashboardScreen/AddInvoice/addInvouceModel/addInvoiceModel.dart';
import 'package:smart_energy_pay/Screens/InvoicesScreen/InvoiceDashboardScreen/AddInvoice/qrCodeModel/qrCodeApi.dart';
import 'package:smart_energy_pay/Screens/InvoicesScreen/InvoiceDashboardScreen/AddInvoice/qrCodeModel/qrCodeModel.dart';
import 'package:smart_energy_pay/Screens/InvoicesScreen/InvoicesScreen/Invoices/invoiceNumberModel/invoiceNumberApi.dart';
import 'package:smart_energy_pay/Screens/InvoicesScreen/ProductsScreen/ProductScreen/model/productApi.dart';
import 'package:smart_energy_pay/Screens/InvoicesScreen/ProductsScreen/ProductScreen/model/productModel.dart';
import 'package:smart_energy_pay/constants.dart';
import 'package:smart_energy_pay/model/currencyApiModel/Model/currencyModel.dart';
import 'package:smart_energy_pay/model/currencyApiModel/Services/currencyApi.dart';
import 'package:smart_energy_pay/model/taxApi/taxApi.dart';
import 'package:smart_energy_pay/model/taxApi/taxApiModel.dart';
import 'package:smart_energy_pay/util/auth_manager.dart';
import 'package:smart_energy_pay/util/customSnackBar.dart';

import '../../../HomeScreen/home_screen.dart';

class AddInvoiceScreen extends StatefulWidget {
  const AddInvoiceScreen({super.key});

  @override
  State<AddInvoiceScreen> createState() => _AddInvoiceScreenState();
}

class _AddInvoiceScreenState extends State<AddInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final InvoiceNoApi _invoiceNoApi = InvoiceNoApi();
  final CurrencyApi _currencyApi = CurrencyApi();
  final ClientsApi _clientsApi = ClientsApi();
  final ProductApi _productApi = ProductApi();
  final TaxApi _taxApi = TaxApi();
  final QrCodeListApi _qrCodeListApi = QrCodeListApi();
  final AddInvoiceApi _addInvoiceApi = AddInvoiceApi();

  List<ProductData> productLists = [];
  List<TaxData> taxList = [];
  List<String> selectedTaxes = [];
  List<String> selectedTaxesCalculate = [];

  List<ClientsData> clientsData = [];
  List<QrCodeData> qrCodeData = [];

  final TextEditingController invoiceNumber = TextEditingController();
  final TextEditingController receiverName = TextEditingController();
  final TextEditingController receiverEmail = TextEditingController();
  final TextEditingController receiverAddress = TextEditingController();
  final TextEditingController discount = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController termsController = TextEditingController();


  String? selectedType = "other";
  String? selectedRecurring = "yes";
  DateTime? invoiceDate;
  DateTime? dueDate;
  String selectedStatus = 'Select Status';
  String selectedInvoiceTemplate = 'Default';

  //String selectedPaymentQR = 'Payment QR Code';
  String selectedRecurringCycle = 'Day';
  String? selectedCurrency;

  String selectedDiscount = 'Select Discount';
  String selectedTax = 'Select Tax';
  ProductData? selectedProduct;
  String subTotal = "0.00";
  String showDiscount = "0.00";
  String showTaxes = "0.00";
  String showTotalAmount = "0.00";
  double totalTaxValue = 0;
  String? mMemberId;
  String? mQrCodeId;

  String? mCurrencySymbol;
  List<CurrencyListsData> currency = [];
  List<OthersInfo> othersInfo = [];
  String? invoiceDateStr;
  String? dueDateStr;
  ClientsData? selectedMember;
  QrCodeData? selectedPaymentQR;

  // Product list holding the product entries
  List<ProductEntry> productList = [ProductEntry()];


  bool _isAdded = false;
  bool isLoading = false;
  bool isSubmitLoading = false;
  String? errorMessage;

  void _toggleButton() {
    setState(() {
      _isAdded = !_isAdded;
    });
  }

  Future<void> mInvoiceDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: invoiceDate ?? DateTime.now(),
      firstDate: DateTime(1947),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != invoiceDate) {
      setState(() {
        invoiceDate = picked;
        invoiceDateStr = DateFormat('yyyy-MM-dd').format(invoiceDate!);
      });
    }
  }


  Future<void> mDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dueDate ?? DateTime.now(),
      firstDate: DateTime(1947),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != dueDate) {
      setState(() {
        dueDate = picked;
        dueDateStr = DateFormat('yyyy-MM-dd').format(dueDate!);
      });
    }
  }


  @override
  void initState() {
    mInvoiceNo();
    mGetCurrency();
    mClientsApi();
    mQrCodeApi();
    mProduct();
    mTaxes();
    super.initState();
  }

  Future<void> mInvoiceNo() async {
    setState(() {
      // invoiceNumber.text = "Loading";
    });

    try {
      final response = await _invoiceNoApi.invoiceNoApi();

      if (response.message == "Invoice Number is generated and sent") {
        setState(() {
          invoiceNumber.text = response.invoiceNo!;
        });
      } else {
        setState(() {
          CustomSnackBar.showSnackBar(context: context,
              message: "Invoice Number is not generated",
              color: kRedColor);
        });
      }
    } catch (error) {
      setState(() {
        //invoiceNumber.text = "InvoiceNo not fetch";
        CustomSnackBar.showSnackBar(context: context,
            message: "We are facing some issue!",
            color: kRedColor);
      });
    }
  }

  // Currency Api ----
  Future<void> mGetCurrency() async {
    final response = await _currencyApi.currencyApi();
    if (response.currencyList != null && response.currencyList!.isNotEmpty) {
      currency = response.currencyList!;
    }
  }

  // Qr Code List Api *************
  Future<void> mQrCodeApi() async {
    setState(() {
      isLoading = false;
      errorMessage = null;
    });

    try {
      final response = await _qrCodeListApi.qrCodeApi();
      if (response.qrCodeList != null && response.qrCodeList!.isNotEmpty) {
        setState(() {
          qrCodeData = response.qrCodeList!;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'No Qr Code List';
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
    }
  }

  // Clients Api ----
  Future<void> mClientsApi() async {
    setState(() {
      isLoading = false;
      errorMessage = null;
    });

    try {
      final response = await _clientsApi.clientsApi();
      if (response.clientsList != null && response.clientsList!.isNotEmpty) {
        setState(() {
          clientsData = response.clientsList!;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'No Clients List';
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
    }
  }

  Future<void> mProduct() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await _productApi.productApi();

      if (response.productsList != null && response.productsList!.isNotEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = null;
          productLists = response.productsList!;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'No Product List';
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
    }
  }

  Future<void> mTaxes() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await _taxApi.taxesApi();
      if (response.taxesList != null && response.taxesList!.isNotEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = null;
          taxList = response.taxesList!;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'No Tax List';
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
    }
  }

  //  Add Invoice Api ****
  Future<void> mAddInvoice() async {
    setState(() {
      isSubmitLoading = true;
    });


    try {
      String recurringCycleNumber = '';

      if (selectedRecurringCycle.isNotEmpty) {
        switch (selectedRecurringCycle.toLowerCase()) {
          case 'day':
            recurringCycleNumber = '1'; // Send the number as a string
            break;
          case 'weekly':
            recurringCycleNumber = '7';
            break;
          case 'monthly':
            recurringCycleNumber = '31';
            break;
          case 'half yearly':
            recurringCycleNumber = '180';
            break;
          case 'yearly':
            recurringCycleNumber = '365';
            break;
          default:
            throw Exception("Invalid recurring cycle");
        }
      }

      final List<Map<String, dynamic>> productsInfo = productList.map((
          product) => product.toMap()).toList();

      List<String> taxList = selectedTaxes.toList();


      if (selectedType == 'other') {
        // Create the OthersInfo object
        OthersInfo newReceiver = OthersInfo(
          email: receiverEmail.text,
          name: receiverName.text,
          address: receiverAddress.text,
        );
        // Convert the OthersInfo object to a Map
        Map<String, String> receiverMap = newReceiver.toMap();

        final request = AddInvoiceRequest(userId: AuthManager.getUserId(),
            currency: selectedCurrency!,
            currencyText: mCurrencySymbol!,
            discount: discount.text,
            discountType: selectedDiscount.toLowerCase(),
            dueDate: dueDateStr!,
            invoiceCountry: selectedInvoiceTemplate,
            invoiceDate: invoiceDateStr!,
            note: noteController.text,
            invoiceNumber: invoiceNumber.text,
            subTotal: subTotal,
            subDiscount: showDiscount,
            subTax: showTaxes,
            tax: selectedTaxes.toList(),
            terms: termsController.text,
            total: showTotalAmount,
            clientId: '',
            othersInfo: [receiverMap],
            productsInfo: productsInfo,
            paymentQrCode: mQrCodeId!,
            recurring: selectedRecurring!.toLowerCase(),
            recurringCycle: recurringCycleNumber,
            type: 'send',
            status: selectedStatus.toLowerCase());

        final response = await _addInvoiceApi.addInvoiceApi(request);

        if(response.message == "Invoice Data is added Successfully!!!"){
          setState(() {
            isSubmitLoading = false;
            CustomSnackBar.showSnackBar(context: context, message: "Invoice Data is added Successfully!", color: kPrimaryColor);
            Navigator.of(context).pop();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
            );
          });
        }else{
          setState(() {
            isSubmitLoading = false;
            CustomSnackBar.showSnackBar(context: context, message: "We are facing some issue", color: kPrimaryColor);
          });
        }

      } else {
        OthersInfo newReceiver = OthersInfo(
          email: '',
          name: '',
          address: '',
        );
        // Convert the OthersInfo object to a Map
        Map<String, String> receiverMap = newReceiver.toMap();

        final request = AddInvoiceRequest(userId: AuthManager.getUserId(),
            currency: selectedCurrency!,
            currencyText: mCurrencySymbol!,
            discount: discount.text,
            discountType: selectedDiscount.toLowerCase(),
            dueDate: dueDateStr!,
            invoiceCountry: selectedInvoiceTemplate,
            invoiceDate: invoiceDateStr!,
            note: noteController.text,
            invoiceNumber: invoiceNumber.text,
            subTotal: subTotal,
            subDiscount: showDiscount,
            subTax: showTaxes,
            tax: taxList,
            terms: termsController.text,
            total: showTotalAmount,
            clientId: mMemberId!,
            othersInfo: [receiverMap],
            productsInfo: productsInfo,
            paymentQrCode: mQrCodeId!,
            recurring: selectedRecurring!.toLowerCase(),
            recurringCycle: recurringCycleNumber,
            type: 'send',
            status: selectedStatus.toLowerCase());

        final response = await _addInvoiceApi.addInvoiceApi(request);
        if(response.message == "Invoice Data is added Successfully!!!"){
          setState(() {
            isSubmitLoading = false;
            CustomSnackBar.showSnackBar(context: context, message: "Invoice Data is added Successfully!", color: kPrimaryColor);
            Navigator.of(context).pop();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
            );
          });
        }else{
          setState(() {
            isSubmitLoading = false;
            CustomSnackBar.showSnackBar(context: context, message: "We are facing some issue", color: kPrimaryColor);
          });
        }      }
    } catch (error) {
      setState(() {
        isSubmitLoading = false;
        CustomSnackBar.showSnackBar(context: context,
            message: "Something went wrong!",
            color: kPrimaryColor);
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
          "Add Invoice",
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
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: largePadding),
                TextFormField(
                  controller: invoiceNumber,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  cursorColor: kPrimaryColor,
                  onSaved: (value) {},
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter Invoice No.';
                    }
                    return null;
                  },
                  readOnly: true,
                  style: const TextStyle(color: kPrimaryColor),
                  decoration: InputDecoration(
                    labelText: "Invoice #",
                    labelStyle:
                    const TextStyle(color: kPrimaryColor, fontSize: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(),
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                ),
                const SizedBox(height: largePadding),
                const Text(
                  "Select Type",
                  style: TextStyle(
                      color: kPrimaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Radio<String>(
                      value: 'member',
                      groupValue: selectedType,
                      onChanged: (String? value) {
                        setState(() {
                          selectedType = value;
                        });
                      },
                    ),
                    const Text('Member',
                        style: TextStyle(color: kPrimaryColor)),
                    Radio<String>(
                      value: 'other',
                      groupValue: selectedType,
                      onChanged: (String? value) {
                        setState(() {
                          selectedType = value;
                        });
                      },
                    ),
                    const Text('Other', style: TextStyle(color: kPrimaryColor)),
                  ],
                ),

                if (selectedType == "Member" || selectedType == "member") ...[
                  // Selected Member
                  const SizedBox(height: largePadding),
                  DropdownButtonFormField<ClientsData>(
                    value: selectedMember,
                    style: const TextStyle(color: kPrimaryColor),
                    decoration: InputDecoration(
                      labelText: 'Select Member',
                      labelStyle: const TextStyle(color: kPrimaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(),
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                    items: clientsData.map((ClientsData role) {
                      return DropdownMenuItem<ClientsData>(
                        value: role,
                        child: Text(
                          '${role.firstName} ${role.lastName}',
                          style: const TextStyle(
                              color: kPrimaryColor, fontSize: 16),
                        ),
                      );
                    }).toList(),
                    onChanged: (ClientsData? newValue) {
                      setState(() {
                        selectedMember = newValue;
                        if (selectedMember != null) {
                          mMemberId = selectedMember?.id;
                        }
                      });
                    },
                  ),
                ],

                if (selectedType == "Other" || selectedType == "other") ...[
                  const SizedBox(height: largePadding),
                  TextFormField(
                    controller: receiverName,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    cursorColor: kPrimaryColor,
                    onSaved: (value) {},
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter receiver name';
                      }
                      return null;
                    },
                    readOnly: false,
                    style: const TextStyle(color: kPrimaryColor),
                    decoration: InputDecoration(
                      labelText: "Receiver Name",
                      labelStyle:
                      const TextStyle(color: kPrimaryColor, fontSize: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(),
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                  ),
                  const SizedBox(height: largePadding),
                  TextFormField(
                    controller: receiverEmail,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    cursorColor: kPrimaryColor,
                    onSaved: (value) {},
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter receiver email';
                      }
                      return null;
                    },
                    readOnly: false,
                    style: const TextStyle(color: kPrimaryColor),
                    decoration: InputDecoration(
                      labelText: "Receiver Email",
                      labelStyle:
                      const TextStyle(color: kPrimaryColor, fontSize: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(),
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                  ),
                  const SizedBox(height: largePadding),
                  TextFormField(
                    controller: receiverAddress,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    cursorColor: kPrimaryColor,
                    onSaved: (value) {},
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter receiver address';
                      }
                      return null;
                    },
                    readOnly: false,
                    style: const TextStyle(color: kPrimaryColor),
                    decoration: InputDecoration(
                      labelText: "Receiver Address",
                      labelStyle:
                      const TextStyle(color: kPrimaryColor, fontSize: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(),
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                  ),
                ],

                const SizedBox(height: largePadding),
                GestureDetector(
                  onTap: () => mInvoiceDate(context), // Open date picker on tap
                  child: AbsorbPointer(
                    // Prevent keyboard from appearing
                    child: TextFormField(
                      controller: TextEditingController(
                        text: invoiceDate == null
                            ? ''
                            : DateFormat('dd-MM-yyyy').format(invoiceDate!),
                      ),
                      style: const TextStyle(color: kPrimaryColor),
                      decoration: InputDecoration(
                        labelText: "Invoice Date*",
                        labelStyle:
                        const TextStyle(color: kPrimaryColor, fontSize: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(),
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        suffixIcon: const Icon(
                          Icons.calendar_today,
                          color: kPrimaryColor,
                        ), // Add calendar icon here
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: largePadding),
                GestureDetector(
                  onTap: () => mDueDate(context), // Open date picker on tap
                  child: AbsorbPointer(
                    // Prevent keyboard from appearing
                    child: TextFormField(
                      controller: TextEditingController(
                        text: dueDate == null
                            ? ''
                            : DateFormat('dd-MM-yyyy').format(dueDate!),
                      ),
                      style: const TextStyle(color: kPrimaryColor),
                      decoration: InputDecoration(
                        labelText: "Due Date*",
                        labelStyle:
                        const TextStyle(color: kPrimaryColor, fontSize: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(),
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        suffixIcon: const Icon(
                          Icons.calendar_today,
                          color: kPrimaryColor,
                        ), // Add calendar icon here
                      ),
                    ),
                  ),
                ),

                // Status
                const SizedBox(height: largePadding),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  style: const TextStyle(color: kPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Status',
                    labelStyle: const TextStyle(color: kPrimaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(),
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  items: [
                    'Select Status',
                    'Paid',
                    'Unpaid',
                    'Partially',
                    'Overdue',
                    'Processing'
                  ].map((String role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(
                        role,
                        style:
                        const TextStyle(color: kPrimaryColor, fontSize: 16),
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedStatus = newValue!;
                    });
                  },
                ),

                // Invoice Template
                const SizedBox(height: largePadding),
                DropdownButtonFormField<String>(
                  value: selectedInvoiceTemplate,
                  style: const TextStyle(color: kPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Invoice Template',
                    labelStyle: const TextStyle(color: kPrimaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(),
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  items: [
                    'Default',
                    'New York',
                    'Toronto',
                    'Rio',
                    'London',
                    'Istanbul',
                    'Mumbai',
                    'Hong Kong',
                    'Tokyo',
                    'Paris'
                  ].map((String role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(
                        role,
                        style:
                        const TextStyle(color: kPrimaryColor, fontSize: 16),
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedInvoiceTemplate = newValue!;
                    });
                  },
                ),


                // Payment QR Code
                const SizedBox(height: largePadding),
                DropdownButtonFormField<QrCodeData>(
                  value: selectedPaymentQR,
                  style: const TextStyle(color: kPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Payment QR Code',
                    labelStyle: const TextStyle(color: kPrimaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(),
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  items: qrCodeData.map((QrCodeData role) {
                    return DropdownMenuItem<QrCodeData>(
                      value: role,
                      child: Text(
                        '${role.title}',
                        style: const TextStyle(
                            color: kPrimaryColor, fontSize: 16),
                      ),
                    );
                  }).toList(),
                  onChanged: (QrCodeData? newValue) {
                    setState(() {
                      selectedPaymentQR = newValue;
                      if (selectedPaymentQR != null) {
                        mQrCodeId = selectedPaymentQR?.id;
                      }
                    });
                  },
                ),

                // Select Currency
                const SizedBox(height: largePadding),
                GestureDetector(
                  onTap: () {
                    if (currency.isNotEmpty) {
                      RenderBox renderBox = context
                          .findRenderObject() as RenderBox;
                      Offset offset = renderBox.localToGlobal(Offset.zero);

                      showMenu<String>(
                        context: context,
                        position: RelativeRect.fromLTRB(
                          offset.dx,
                          offset.dy + renderBox.size.height,
                          offset.dx + renderBox.size.width,
                          0.0,
                        ),
                        items: currency.map((CurrencyListsData currencyItem) {
                          return PopupMenuItem<String>(
                            value: currencyItem.currencyCode,
                            child: Text(currencyItem.currencyCode!,
                              style: const TextStyle(
                                  color: kPrimaryColor),),
                          );
                        }).toList(),
                      ).then((String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedCurrency = newValue;
                            mCurrencySymbol =
                                getCurrencySymbol(selectedCurrency!);
                          });
                        }
                      });
                    } else {}
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 15.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kPrimaryColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(selectedCurrency ?? "Select Currency",
                              style: const TextStyle(
                                  color: kPrimaryColor, fontSize: 16)),
                          const Icon(Icons.arrow_drop_down,
                              color: kPrimaryColor),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: largePadding),
                const Text(
                  "Recurring",
                  style: TextStyle(
                      color: kPrimaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Radio<String>(
                      value: 'yes',
                      groupValue: selectedRecurring,
                      onChanged: (String? value) {
                        setState(() {
                          selectedRecurring = value;
                        });
                      },
                    ),
                    const Text('Yes', style: TextStyle(color: kPrimaryColor)),
                    Radio<String>(
                      value: 'no',
                      groupValue: selectedRecurring,
                      onChanged: (String? value) {
                        setState(() {
                          selectedRecurring = value;
                        });
                      },
                    ),
                    const Text('No', style: TextStyle(color: kPrimaryColor)),
                  ],
                ),

                // Recurring Cycle
                const SizedBox(height: largePadding),
                DropdownButtonFormField<String>(
                  value: selectedRecurringCycle,
                  style: const TextStyle(color: kPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Recurring Cycle',
                    labelStyle: const TextStyle(color: kPrimaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(),
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  items: ['Day', 'Weekly', 'Monthly', 'Half Yearly', 'Yearly']
                      .map((String role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(
                        role,
                        style:
                        const TextStyle(color: kPrimaryColor, fontSize: 16),
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedRecurringCycle = newValue!;
                    });
                  },
                ),

                const SizedBox(
                  height: largePadding,
                ),

                // Container for product list
                Container(
                  width: double.infinity,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: productList.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: smallPadding),
                            child: Container(
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: largePadding),
                                  // Product Dropdown
                                  DropdownButtonFormField<ProductData?>(
                                    value: productList[index].productId !=
                                        null
                                        ? productLists.firstWhere((product) =>
                                    product.id ==
                                        productList[index].productId)
                                        : null,
                                    style: const TextStyle(
                                        color: kPrimaryColor),
                                    decoration: InputDecoration(
                                      labelText: 'Product',
                                      labelStyle: const TextStyle(
                                          color: kPrimaryColor),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            12),
                                        borderSide: const BorderSide(),
                                      ),
                                    ),
                                    items: productLists.map((
                                        ProductData product) {
                                      return DropdownMenuItem<ProductData?>(
                                        value: product,
                                        child: Text(
                                          product.productName ??
                                              'Unnamed Product',
                                          style: const TextStyle(
                                              color: kPrimaryColor,
                                              fontSize: 16),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (newValue) {
                                      setState(() {
                                        if (newValue != null) {
                                          productList[index].productId =
                                              newValue.id;
                                          productList[index].productName =
                                              newValue.productName ?? '';
                                          productList[index].price =
                                              newValue.unitPrice
                                                  ?.toString() ?? '';
                                          productList[index].quantity =
                                          "1"; // Default quantity
                                          productList[index].amount =
                                              (newValue.unitPrice! * 1)
                                                  .toStringAsFixed(2);

                                          calculateAmount(index);
                                          mDiscount();
                                          mCalculateTax();
                                          mTotalAmount();
                                        } else {
                                          productList[index].productName = "";
                                          productList[index].price = "";
                                          productList[index].quantity = "0";
                                          productList[index].amount = "0.00";

                                          calculateAmount(index);
                                          mDiscount();
                                          mCalculateTax();
                                          mTotalAmount();
                                        }
                                      });
                                    },
                                  ),
                                  const SizedBox(height: largePadding),
                                  // Quantity Field
                                  TextFormField(
                                    controller: TextEditingController(
                                      text: productList[index].quantity,
                                    ),
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                        color: kPrimaryColor),
                                    decoration: InputDecoration(
                                      labelText: "Quantity",
                                      labelStyle: const TextStyle(
                                          color: kPrimaryColor),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            12),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        productList[index].quantity = value;
                                        double price = double.tryParse(
                                            productList[index].price) ?? 0;
                                        int quantity = int.tryParse(value) ??
                                            0;
                                        productList[index].amount =
                                            (price * quantity)
                                                .toStringAsFixed(2);

                                        calculateAmount(index);
                                        mDiscount();
                                        mCalculateTax();
                                        mTotalAmount();
                                      });
                                    },
                                  ),
                                  const SizedBox(height: largePadding),
                                  // Price Field (read-only)
                                  TextFormField(
                                    controller: TextEditingController(
                                      text: productList[index].price,
                                    ),
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                        color: kPrimaryColor),
                                    decoration: InputDecoration(
                                      labelText: "Price",
                                      labelStyle: const TextStyle(
                                          color: kPrimaryColor),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            12),
                                      ),
                                    ),
                                    readOnly: true,
                                    onChanged: (value) {
                                      setState(() {
                                        productList[index].price = value;
                                        calculateAmount(index);
                                        mDiscount();
                                        mCalculateTax();
                                        mTotalAmount();
                                      });
                                    },
                                  ),
                                  const SizedBox(height: largePadding),
                                  // Amount Calculation (Quantity * Price)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment
                                        .spaceBetween,
                                    children: [
                                      const Text("Amount", style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14),
                                        child: Text(
                                          productList[index].amount,
                                          style: const TextStyle(
                                              color: kPrimaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: smallPadding),
                                  // Delete Button
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment
                                        .spaceBetween,
                                    children: [
                                      const Text("Action", style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            removeProduct(index);
                                            calculateAmount(index);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FloatingActionButton(
                            onPressed: () {
                              addProduct();
                            },
                            child: const Icon(
                              Icons.add,
                              color: kPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: defaultPadding,
                      ),
                      const SizedBox(
                        height: largePadding,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [

                          SizedBox(
                            width: 100, // Set your desired fixed width here
                            child: TextFormField(
                              controller: discount,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              cursorColor: kPrimaryColor,
                              style: const TextStyle(color: kPrimaryColor),
                              onChanged: (value) {
                                setState(() {
                                  mDiscount();
                                  mCalculateTax();
                                  mTotalAmount();
                                });
                              },
                              enabled: selectedDiscount != "Select Discount",
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      defaultPadding),
                                  borderSide: const BorderSide(),
                                ),
                                hintText: "0",
                                hintStyle: const TextStyle(
                                    color: kPrimaryColor),
                              ),
                            ),
                          ),

                          const SizedBox(width: defaultPadding,),
                          Expanded(child: DropdownButtonFormField<String>(
                            value: selectedDiscount,
                            style: const TextStyle(color: kPrimaryColor),

                            decoration: InputDecoration(
                              labelText: 'Discount',
                              labelStyle: const TextStyle(
                                  color: kPrimaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(),
                              ),
                            ),

                            items: ['Select Discount', 'Fixed', 'Percentage']
                                .map((String role) {
                              return DropdownMenuItem(
                                value: role,
                                child: Text(role, style: const TextStyle(
                                    color: kPrimaryColor, fontSize: 16),),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                selectedDiscount = newValue!;
                                discount.clear();
                                showDiscount = "0.00";
                              });
                            },
                          ),
                          ),
                        ],
                      ),

                      const SizedBox(height: largePadding),
                      GestureDetector(
                        onTap: _showMultiSelectDialog,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Select Taxes',
                            labelStyle: const TextStyle(color: kPrimaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(),
                            ),
                            suffixIcon: const Icon(
                                Icons.arrow_drop_down, color: kPrimaryColor),
                          ),
                          child: Text(
                            selectedTaxes.isEmpty
                                ? 'Select Taxes'
                                : selectedTaxes.join(', '),
                            style: const TextStyle(color: kPrimaryColor),
                          ),
                        ),
                      ),

                      const SizedBox(height: 35,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Sub Total:", style: TextStyle(
                              color: kPrimaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),),
                          Padding(padding: const EdgeInsets.symmetric(
                              horizontal: defaultPadding),
                            child: Text(subTotal, style: const TextStyle(
                                color: kPrimaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold),),),
                        ],
                      ),

                      const SizedBox(height: defaultPadding,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Discount:", style: TextStyle(
                              color: kPrimaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),),
                          Padding(padding: const EdgeInsets.symmetric(
                              horizontal: defaultPadding),
                            child: Text(showDiscount, style: const TextStyle(
                                color: kPrimaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold),),),
                        ],
                      ),

                      const SizedBox(height: defaultPadding,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Tax:", style: TextStyle(
                              color: kPrimaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),),
                          Padding(padding: const EdgeInsets.symmetric(
                              horizontal: defaultPadding),
                            child: Text(showTaxes, style: const TextStyle(
                                color: kPrimaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold),),),
                        ],
                      ),

                      const SizedBox(height: defaultPadding,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total:", style: TextStyle(
                              color: kPrimaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),),
                          Padding(padding: const EdgeInsets.symmetric(
                              horizontal: defaultPadding),
                            child: Text(
                              showTotalAmount, style: const TextStyle(
                                color: kPrimaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold),),),
                        ],
                      ),


                      const SizedBox(
                        height: largePadding,
                      ),
                      Center(
                        child: SizedBox(
                          width: 220,
                          height: 47.0,
                          child: FloatingActionButton.extended(
                            onPressed: _toggleButton,
                            label: Text(
                              _isAdded
                                  ? 'Remove Note & Terms'
                                  : 'Add Note & Terms',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                            ),
                            icon: Icon(
                              _isAdded ? Icons.remove : Icons.add,
                              color: Colors.white,
                            ),
                            backgroundColor:
                            _isAdded ? Colors.red : kPrimaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: largePadding,
                      ),
                      if (_isAdded) ...[
                        Column(
                          children: [
                            const SizedBox(height: largePadding),
                            TextFormField(
                              controller: noteController,
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.next,
                              cursorColor: kPrimaryColor,
                              onSaved: (value) {},
                              readOnly: false,
                              style: const TextStyle(color: kPrimaryColor),
                              maxLines: 5,
                              minLines: 1,
                              decoration: InputDecoration(
                                labelText: "Note",
                                labelStyle: const TextStyle(
                                    color: kPrimaryColor, fontSize: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(),
                                ),
                                filled: true,
                                fillColor: Colors.transparent,
                              ),
                              onChanged: (value) {
                                setState(() {});
                              },
                            ),
                            const SizedBox(height: defaultPadding),
                            TextFormField(
                              controller: termsController,
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.next,
                              cursorColor: kPrimaryColor,
                              onSaved: (value) {},
                              readOnly: false,
                              maxLines: 5,
                              minLines: 1,
                              style: const TextStyle(color: kPrimaryColor),
                              decoration: InputDecoration(
                                labelText: "Terms",
                                labelStyle: const TextStyle(
                                    color: kPrimaryColor, fontSize: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(),
                                ),
                                filled: true,
                                fillColor: Colors.transparent,
                              ),
                              onChanged: (value) {
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(
                        height: largePadding,
                      ),
                      if (isSubmitLoading)
                        const Center(
                          child: CircularProgressIndicator(
                            color: kPrimaryColor,
                          ),
                        ), // Show loading indicator


                      const SizedBox(
                        height: largePadding,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: largePadding,
                          ),

                          // Draft Button
                          /*SizedBox(
                            width: 145,
                            height: 47.0,
                            child: FloatingActionButton.extended(
                              onPressed: () {},
                              label: const Text(
                                'Save as Draft',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                              backgroundColor: kPrimaryColor,
                            ),
                          ),*/

                          /*const SizedBox(
                            width: defaultPadding,
                          ),*/

                          // Save Button
                          SizedBox(
                            width: 300,
                            height: 47.0,
                            child: FloatingActionButton.extended(
                              onPressed: () {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  mAddInvoice();
                                } else if (selectedType!.isEmpty) {
                                  CustomSnackBar.showSnackBar(context: context,
                                      message: "Please select type",
                                      color: kRedColor);
                                } else if (invoiceDate == null) {
                                  CustomSnackBar.showSnackBar(context: context,
                                      message: "Please select invoice date",
                                      color: kRedColor);
                                } else if (dueDate == null) {
                                  CustomSnackBar.showSnackBar(context: context,
                                      message: "Please select due date",
                                      color: kRedColor);
                                } else if (selectedStatus.isEmpty) {
                                  CustomSnackBar.showSnackBar(context: context,
                                      message: "Please select status",
                                      color: kRedColor);
                                } else if (selectedInvoiceTemplate.isEmpty) {
                                  CustomSnackBar.showSnackBar(context: context,
                                      message: "Please select invoice template",
                                      color: kRedColor);
                                } else if (selectedCurrency!.isEmpty) {
                                  CustomSnackBar.showSnackBar(context: context,
                                      message: "Please select currency",
                                      color: kRedColor);
                                } else {
                                  // CustomSnackBar.showSnackBar(context: context, message: "Save", color: kRedColor);
                                }

                                /**/
                              },
                              label: const Text(
                                'Save & Send',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                              backgroundColor: kPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  String getCurrencySymbol(String currencyCode) {
    var format = NumberFormat.simpleCurrency(name: currencyCode);
    return format.currencySymbol;
  }

  // Function to add a new product entry
  void addProduct() {
    if (productList.length < productLists.length) {
      final selectedProduct = productLists[productList.length];

      if (selectedProduct.productName != null &&
          selectedProduct.unitPrice != null) {
        setState(() {
          productList.add(ProductEntry(productId: selectedProduct.id));
        });
      } else {
        CustomSnackBar.showSnackBar(
          context: context,
          message: 'Selected product is incomplete.',
          color: kPrimaryColor,
        );
      }
    } else {
      CustomSnackBar.showSnackBar(
        context: context,
        message: 'You cannot add more products.',
        color: kPrimaryColor,
      );
    }
  }

  // Function to remove a product from the list
  void removeProduct(int index) {
    if (productList.length > 1) {
      setState(() {
        productList.removeAt(index);
      });

      // Recalculate the subtotal and the totals after product removal
      if (productList.isEmpty) {
        subTotal = "0.00";
        showTotalAmount = "0.00";
        showDiscount = "0.00";
        showTaxes = "0.00";
      } else {
        calculateSubTotalAmount();
      }

      mDiscount();
      mCalculateTax();
      mTotalAmount();
    }
  }

  void _showMultiSelectDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Taxes'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  children: taxList.map((tax) {
                    return CheckboxListTile(
                      title: Text(
                        '${tax.name ?? ''} - ${tax.taxValue ?? ''}',
                        style: const TextStyle(color: kPrimaryColor),
                      ),
                      value: selectedTaxes.contains(
                          '${tax.name ?? ''} - ${tax.taxValue ?? ''}'),
                      onChanged: (bool? isSelected) {
                        setState(() {
                          if (isSelected == true) {
                            selectedTaxes.add(
                                '${tax.name ?? ''} - ${tax.taxValue ?? ''}');
                          } else {
                            selectedTaxes.remove(
                                '${tax.name ?? ''} - ${tax.taxValue ?? ''}');
                          }
                          // Recalculate the total tax value
                          totalTaxValue = _calculateTotalTaxValue();
                          mCalculateTax();
                          mTotalAmount();
                        });
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void mDiscount() {
    double discountAmount = 0;

    if (selectedDiscount == "Fixed") {
      setState(() {
        discountAmount = double.tryParse(discount.text) ?? 0;
        showDiscount = discountAmount.toStringAsFixed(2);
      });
    } else if (selectedDiscount == "Percentage") {
      setState(() {
        double totalPrice = double.tryParse(subTotal.toString()) ?? 0;
        double percentage = double.tryParse(discount.text) ?? 0;

        if (percentage > 0 && totalPrice > 0) {
          discountAmount = (percentage / 100) * totalPrice;
          showDiscount = discountAmount.toStringAsFixed(2);
        } else {
          showDiscount = "0.00";
        }
      });
    }
  }

  void mCalculateTax() {
    double taxAmount = 0;

    setState(() {
      double totalPrice = double.tryParse(subTotal.toString()) ?? 0;
      double? percentage = double.tryParse(totalTaxValue.toStringAsFixed(2)) ??
          0;

      if (percentage > 0 && totalPrice > 0) {
        taxAmount = (percentage / 100) * totalPrice;
        showTaxes = taxAmount.toStringAsFixed(2);
      } else {
        showTaxes = "0.00";
      }
    });
  }

  void mTotalAmount() {
    double totalAmount = 0;

    setState(() {
      double totalPrice = double.tryParse(subTotal.toString()) ?? 0.0;
      double? percentage = double.tryParse(showDiscount.toString()) ?? 0.0;
      double? taxes = double.tryParse(showTaxes.toString()) ?? 0.0;

      if (totalPrice > 0 && percentage > 0 && taxes > 0) {
        totalAmount = totalPrice - percentage + taxes;
        showTotalAmount = totalAmount.toStringAsFixed(2);
      } else if (totalPrice > 0 && percentage > 0) {
        totalAmount = totalPrice - percentage;
        showTotalAmount = totalAmount.toStringAsFixed(2);
      } else if (totalPrice > 0 && taxes > 0) {
        totalAmount = totalPrice + taxes;
        showTotalAmount = totalAmount.toStringAsFixed(2);
      } else if (totalPrice > 0) {
        totalAmount = totalPrice;
        showTotalAmount = totalPrice.toStringAsFixed(2);
      } else {
        showTotalAmount = "0.00";
      }
    });
  }

  void calculateSubTotalAmount() {
    double totalAmount = 0;

    for (var product in productList) {
      final amount = double.tryParse(product.amount) ?? 0;
      totalAmount += amount;
    }

    setState(() {
      subTotal = totalAmount.toStringAsFixed(2);
    });

    // Now update discount, tax, and total amount after recalculating subtotal
    mDiscount();
    mCalculateTax();
    mTotalAmount();
  }

  void calculateAmount(int index) {
    final quantity = double.tryParse(productList[index].quantity) ?? 0;
    final price = double.tryParse(productList[index].price) ?? 0;

    if (quantity != 0) {
      final amount = quantity * price;
      setState(() {
        productList[index].amount = amount.toStringAsFixed(2);
      });
    } else {
      setState(() {
        productList[index].amount = price.toStringAsFixed(2);
      });
    }

    calculateSubTotalAmount(); // Recalculate subtotal after amount change
    mDiscount(); // Recalculate discount
    mCalculateTax(); // Recalculate taxes
    mTotalAmount(); // Recalculate total amount
  }

  double _calculateTotalTaxValue() {
    double total = 0.0;
    for (var selectedTax in selectedTaxes) {
      final tax = taxList.firstWhere(
            (tax) => '${tax.name ?? ''} - ${tax.taxValue ?? ''}' == selectedTax,
        orElse: () => TaxData(name: '', taxValue: 0),
      );
      total += (tax.taxValue ?? 0).toDouble();
    }
    return total;
  }

}

class ProductEntry {
  String? productId;
  String? productName;
  String quantity;
  String price;
  String amount;

  ProductEntry({
    this.productId,
    this.productName,
    this.quantity = "1",
    this.price = "",
    this.amount = "0.00",
  });

  @override
  String toString() {
    return 'ProductEntry{productId: $productId, productName: $productName, quantity: $quantity, price: $price, amount: $amount}';
  }

  // Method to convert ProductEntry to a Map<String, dynamic>
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'qty': quantity,
      'price': price,
      'amount': amount,
    };
  }
}

class OthersInfo {
  String email;
  String name;
  String address;

  OthersInfo({required this.email, required this.name, required this.address});

  // Convert the OthersInfo object to a Map<String, String>
  Map<String, String> toMap() {
    return {
      'email': email,
      'name': name,
      'address': address,
    };
  }
}