import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_energy_pay/Screens/InvoicesScreen/InvoiceTransactions/model/invoiceTransactionApi.dart';
import 'package:smart_energy_pay/Screens/InvoicesScreen/InvoiceTransactions/model/invoiceTransactionModel.dart';
import 'package:smart_energy_pay/constants.dart';

import '../../../util/customSnackBar.dart';

class InvoiceTransactionsScreen extends StatefulWidget {
  const InvoiceTransactionsScreen({super.key});

  @override
  State<InvoiceTransactionsScreen> createState() => _InvoiceTransactionsScreenState();
}

class _InvoiceTransactionsScreenState extends State<InvoiceTransactionsScreen> {
 final InvoicesTransactionApi _invoicesTransactionApi = InvoicesTransactionApi();
 List<InvoiceTransactionData> invoiceTransactionList = [];

 bool isLoading = true;
 String? errorMessage;

 @override
  void initState() {
    mInvoiceTransaction();
    super.initState();
  }

  Future<void> mInvoiceTransaction() async {
   setState(() {
     isLoading = true;
     errorMessage = null;
   });

   try {
     final response = await _invoicesTransactionApi.invoiceTransactionApi();

     if(response.invoiceTransactionList !=null && response.invoiceTransactionList!.isNotEmpty){
       setState(() {
         isLoading = false;
         errorMessage = null;
         invoiceTransactionList = response.invoiceTransactionList!;
       });
     }else{
       setState(() {
         isLoading = false;
         errorMessage = 'No Invoice Transaction List';
         CustomSnackBar.showSnackBar(context: context, message: "No Invoice Transaction", color: kPrimaryColor);
       });
     }

   }catch (error) {
     setState(() {
       isLoading = false;
       errorMessage = error.toString();
       CustomSnackBar.showSnackBar(context: context, message: errorMessage!, color: kRedColor);
     });
   }
  }

 // Function to format the date
 String formatDate(String? dateTime) {
   if (dateTime == null) {
     return 'Date not available';
   }
   DateTime date = DateTime.parse(dateTime);
   return DateFormat('dd-MM-yyyy').format(date);
 }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.transparent),
        title: const Text(
            "Invoice Transaction",
          style: TextStyle(color: Colors.transparent),
        ),
      ),
      body: isLoading ? const Center(
        child: CircularProgressIndicator(
          color: kPrimaryColor,
        ),
      ) : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: largePadding,),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: invoiceTransactionList.length,
              itemBuilder: (context, index) {
                final invoiceTransaction = invoiceTransactionList[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: defaultPadding), // Add spacing
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(defaultPadding),
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Paid Amount:', style: TextStyle(color: Colors.white, fontSize: 16)),
                            Text(
                              invoiceTransaction.invoiceDetails != null && invoiceTransaction.invoiceDetails!.isNotEmpty
                                  ? '${invoiceTransaction.fromCurrency} ${invoiceTransaction.invoiceDetails![0].total}' // Access the first element
                                  : 'N/A', // Fallback if invoiceDetails is null or empty
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),


                        const SizedBox(height: smallPadding,),
                        const Divider(color: kPrimaryLightColor,),
                        const SizedBox(height: smallPadding,),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Payment Date:',style: TextStyle(color: Colors.white, fontSize: 16),),
                            Text('${invoiceTransaction.dateAdded}',style: const TextStyle(color: Colors.white, fontSize: 16),),
                          ],
                        ),

                        const SizedBox(height: smallPadding,),
                        const Divider(color: kPrimaryLightColor,),
                        const SizedBox(height: smallPadding,),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total:',style: TextStyle(color: Colors.white, fontSize: 16),),
                            Text('${invoiceTransaction.fromCurrency} ${invoiceTransaction.amount}',style: const TextStyle(color: Colors.white, fontSize: 16),),
                          ],
                        ),

                        const SizedBox(height: smallPadding,),
                        const Divider(color: kPrimaryLightColor,),
                        const SizedBox(height: smallPadding,),


                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Paid Amount:',style: TextStyle(color: Colors.white, fontSize: 16),),
                            Text('${invoiceTransaction.fromCurrency} ${invoiceTransaction.invoiceDetails?[0].total}',style: const TextStyle(color: Colors.white, fontSize: 16),),
                          ],
                        ),

                        const SizedBox(height: smallPadding,),
                        const Divider(color: kPrimaryLightColor,),
                        const SizedBox(height: smallPadding,),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Transaction Type:',style: TextStyle(color: Colors.white, fontSize: 16),),
                            Text('${invoiceTransaction.transType}',style: const TextStyle(color: Colors.white, fontSize: 16),),
                          ],
                        ),

                        const SizedBox(height: smallPadding,),
                      ],
                    ),
                  ),
                );
              },
            ),

          ],
        ),
        ),
      ),
    );
  }

}