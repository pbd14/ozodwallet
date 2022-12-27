// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// class LabelButton extends StatefulWidget {
//   const LabelButton({
//     Key? key,
//     required this.color1,
//     required this.color2,
//     required this.size,
//     required this.onTap,
//     required this.onTap2,
//     required this.reverse,
//     required this.containsValue,
//     required this.isC,
//   }) : super(key: key);

//   final Color color1;
//   final Color color2;
//   final double size;
//   final Function onTap, onTap2;
//   final DocumentReference reverse;
//   final String containsValue;
//   final bool isC;

//   @override
//   _LabelButtonState createState() => _LabelButtonState();
// }

// class _LabelButtonState extends State<LabelButton> {
//   bool isColored = false;
//   bool isOne = true;
//   Color? labelColor;
//   // ignore: cancel_subscriptions
//   StreamSubscription<DocumentSnapshot>? subscription;
//   List res = [];

//   @override
//   void initState() {
//     super.initState();
//     subscription = widget.reverse.snapshots().listen((docsnap) {
//       if (docsnap.get('favourites') != null) {
//         if (docsnap.get('favourites').contains(widget.containsValue)) {
//           if (mounted) {
//             setState(() {
//               isColored = true;
//               isOne = false;
//             });
//           }
//         } else if (!docsnap
//             .get('favourites')
//             .contains(widget.containsValue)) {
//           if (mounted) {
//             setState(() {
//               isColored = false;
//               isOne = true;
//             });
//           }
//         }
//       }
//     });
//     if (widget.isC) {
//       setState(() {
//         isOne = false;
//         isColored = true;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     labelColor ??= widget.color2;
//     if (isColored) {
//       labelColor = widget.color1;
//     } else {
//       labelColor = widget.color2;
//     }
//     return TextButton(
//       // highlightColor: darkPrimaryColor,
//       // height: widget.ph,
//       // minWidth: widget.pw,
//       style: ButtonStyle(padding: MaterialStateProperty.all(EdgeInsets.zero)),
//       onPressed: () {
//         setState(() {
//           isColored = !isColored;
//           if (isColored) {
//             labelColor = widget.color1;
//           } else {
//             labelColor = widget.color2;
//           }
//         });
//         isOne ? widget.onTap() : widget.onTap2();
//         isOne = !isOne;
//       },
//       child: Icon(
//         Icons.bookmark,
//         color: labelColor ?? widget.color2,
//         size: widget.size,
//       ),
//     );
//   }
// }
