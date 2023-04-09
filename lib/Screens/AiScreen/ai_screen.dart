// import 'package:bip39/bip39.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:ed25519_hd_key/ed25519_hd_key.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:hex/hex.dart';
// import 'package:ozodwallet/Services/notification_service.dart';
// import 'package:ozodwallet/Services/safe_storage_service.dart';
// import 'package:ozodwallet/Widgets/loading_screen.dart';
// import 'package:ozodwallet/Widgets/rounded_button.dart';
// import 'package:ozodwallet/constants.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:web3dart/credentials.dart';

// // ignore: must_be_immutable
// class AIScreen extends StatefulWidget {
//   String error;
//   bool isWelcomeScreen;
//   AIScreen({
//     Key? key,
//     this.error = 'Something Went Wrong',
//     this.isWelcomeScreen = true,
//   }) : super(key: key);

//   @override
//   State<AIScreen> createState() => _AIScreenState();
// }

// class _AIScreenState extends State<AIScreen> {
//   bool loading = true;
//   String error = '';
//   String answer = 'Answer';

//   String? question;
//   final _formKey = GlobalKey<FormState>();
//   Interpreter? interpreter;

//   Future<void> prepare() async {
//     interpreter = await Interpreter.fromAsset('tflite/lite-model_qat_mobilebert_xs_qat_lite_1.tflite'); 
//     setState(() {
//       loading = false;
//     });
//   }

//   @override
//   void initState() {
//     prepare();
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // ignore: unused_local_variable
//     Size size = MediaQuery.of(context).size;
//     if (kIsWeb && size.width >= 600) {
//       size = Size(600, size.height);
//     }
//     return loading
//         ? LoadingScreen()
//         : Scaffold(
//             appBar: AppBar(
//               elevation: 0,
//               automaticallyImplyLeading: true,
//               toolbarHeight: 30,
//               backgroundColor: darkPrimaryColor,
//               foregroundColor: secondaryColor,
//               centerTitle: true,
//               actions: [],
//             ),
//             backgroundColor: darkPrimaryColor,
//             body: SingleChildScrollView(
//               child: Center(
//                 child: Container(
//                   margin: const EdgeInsets.all(20),
//                   constraints:
//                       BoxConstraints(maxWidth: kIsWeb ? 600 : double.infinity),
//                   child: Form(
//                     key: _formKey,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Padding(
//                           padding: const EdgeInsets.all(0.0),
//                           child: Text(
//                             error,
//                             style: GoogleFonts.montserrat(
//                               textStyle: const TextStyle(
//                                 color: Colors.red,
//                                 fontSize: 14,
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(
//                           height: 10,
//                         ),
//                         Text(
//                           "Question",
//                           overflow: TextOverflow.ellipsis,
//                           maxLines: 3,
//                           textAlign: TextAlign.start,
//                           style: GoogleFonts.montserrat(
//                             textStyle: const TextStyle(
//                               color: secondaryColor,
//                               fontSize: 35,
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(
//                           height: 10,
//                         ),
//                         Text(
//                           "Enter question",
//                           overflow: TextOverflow.ellipsis,
//                           maxLines: 1000,
//                           textAlign: TextAlign.start,
//                           style: GoogleFonts.montserrat(
//                             textStyle: const TextStyle(
//                               color: secondaryColor,
//                               fontSize: 20,
//                               fontWeight: FontWeight.w400,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(
//                           height: 20,
//                         ),
//                         TextFormField(
//                           style: const TextStyle(color: secondaryColor),
//                           validator: (val) {
//                             if (val!.isEmpty) {
//                               return 'Enter your question';
//                             } else {
//                               return null;
//                             }
//                           },
//                           keyboardType: TextInputType.visiblePassword,
//                           onChanged: (val) {
//                             setState(() {
//                               question = val;
//                             });
//                           },
//                           decoration: InputDecoration(
//                             errorBorder: OutlineInputBorder(
//                               borderSide:
//                                   BorderSide(color: Colors.red, width: 1.0),
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderSide:
//                                   BorderSide(color: secondaryColor, width: 1.0),
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                             enabledBorder: OutlineInputBorder(
//                               borderSide:
//                                   BorderSide(color: secondaryColor, width: 1.0),
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                             hintStyle: TextStyle(
//                                 color: darkPrimaryColor.withOpacity(0.7)),
//                             hintText: 'Password',
//                             border: OutlineInputBorder(
//                               borderSide:
//                                   BorderSide(color: secondaryColor, width: 1.0),
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(
//                           height: 10,
//                         ),
//                         Text(
//                           "Answer " + answer,
//                           overflow: TextOverflow.ellipsis,
//                           maxLines: 1000,
//                           textAlign: TextAlign.start,
//                           style: GoogleFonts.montserrat(
//                             textStyle: const TextStyle(
//                               color: secondaryColor,
//                               fontSize: 20,
//                               fontWeight: FontWeight.w400,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 40),
//                         Center(
//                           child: RoundedButton(
//                             pw: 250,
//                             ph: 45,
//                             text: 'SEND',
//                             press: () async {
//                               setState(() {
//                                 loading = true;
//                               });
//                               if (_formKey.currentState!.validate()) {
//                                 var output = List<double>.filled(1, 0);
//                                 interpreter!.run(question!, output);
//                                 print("INTER");
//                                 print(output[0]);
//                                 print(output);
//                                 setState(() {
//                                   answer = output[0].toString();
//                                   loading = false;
//                                 });
//                               } else {
//                                 setState(() {
//                                   loading = false;
//                                   error = 'Error';
//                                 });
//                                 showNotification("Failed", 'Error', Colors.red);
//                               }
//                               setState(() {
//                                 loading = false;
//                               });
//                             },
//                             color: secondaryColor,
//                             textColor: darkPrimaryColor,
//                           ),
//                         ),
//                         const SizedBox(height: 300),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           );
//   }
// }
