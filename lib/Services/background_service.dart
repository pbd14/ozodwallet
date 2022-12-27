// // com.transistorsoft.sendDailyStat

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class BackgroundService {

//   Future<void> updateDailyStats(DateTime startDateTime, DateTime endDateTime, double score) async {
//     DocumentSnapshot userAuth = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(FirebaseAuth.instance.currentUser!.uid)
//         .get();
//     DocumentSnapshot currentUserProfile = await FirebaseFirestore.instance
//         .collection('profiles')
//         .doc(userAuth.get('profile'))
//         .get();
//     bool yearFieldExists = true;
//     try {
//       currentUserProfile.get(DateTime.now().year.toString());
//     } catch (e) {
//       yearFieldExists = false;
//     }
//     if (yearFieldExists) {
//       if (currentUserProfile.get(DateTime.now().year.toString())[
//               DateTime.now().month.toString()] !=
//           null) {
//         List newSessions;
//         if (currentUserProfile.get(DateTime.now().year.toString())[
//                     DateTime.now().month.toString()]
//                 [DateTime.now().day.toString()] !=
//             null) {
//           newSessions = currentUserProfile.get(DateTime.now().year.toString())[
//                   DateTime.now().month.toString()]
//               [DateTime.now().day.toString()]['sessions'];
//           newSessions.add({
//             'start': startDateTime,
//             'end': endDateTime,
//             'score': score,
//           });
//           await FirebaseFirestore.instance
//               .collection('profiles')
//               .doc(userAuth.get('profile'))
//               .update({
//             '${DateTime.now().year}.${DateTime.now().month}.${DateTime.now().day}':
//                 {
//               "dateUpdated": DateTime.now(),
//               "score": currentUserProfile.get(DateTime.now().year.toString())[
//                                   DateTime.now().month.toString()]
//                               [DateTime.now().day.toString()] !=
//                           null &&
//                       currentUserProfile
//                                   .get(DateTime.now().year.toString())[DateTime.now().month.toString()]
//                               [DateTime.now().day.toString()]['score'] !=
//                           null
//                   ? currentUserProfile
//                               .get(DateTime.now().year.toString())[DateTime.now().month.toString()]
//                           [DateTime.now().day.toString()]['score'] +
//                       score
//                   : score,
//               "sessions": newSessions,
//             },
//           });
//         } else {
//           await FirebaseFirestore.instance
//               .collection('profiles')
//               .doc(userAuth.get('profile'))
//               .update({
//             '${DateTime.now().year}.${DateTime.now().month}.${DateTime.now().day}':
//                 {
//               "dateUpdated": DateTime.now(),
//               "score": FieldValue.increment(score),
//               "sessions": FieldValue.arrayUnion([
//                 {
//                   'start': startDateTime,
//                   'end': endDateTime,
//                   'score': score,
//                 }
//               ]),
//             },
//           });
//         }
//       } else {
//         await FirebaseFirestore.instance
//             .collection('profiles')
//             .doc(userAuth.get('profile'))
//             .update(
//           {
//             '${DateTime.now().year}.${DateTime.now().month}': {
//               DateTime.now().day.toString(): {
//                 "dateUpdated": DateTime.now(),
//                 "score": score,
//                 "sessions": [
//                   {
//                     'start': startDateTime,
//                     'end': endDateTime,
//                     'score': score,
//                   }
//                 ],
//               },
//             },
//           },
//         );
//       }
//     } else {
//       await FirebaseFirestore.instance
//           .collection('profiles')
//           .doc(userAuth.get('profile'))
//           .update({
//         DateTime.now().year.toString(): {
//           DateTime.now().month.toString(): {
//             DateTime.now().day.toString(): {
//               "dateUpdated": DateTime.now(),
//               "score": score,
//               "sessions": [
//                 {
//                   'start': startDateTime,
//                   'end': endDateTime,
//                   'score': score,
//                 }
//               ],
//             },
//           },
//         },
//       });
//     }
//   }
  
//   Future<void> updateTasksStats(double score, double initScore) async {
//     DocumentSnapshot userAuth = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(FirebaseAuth.instance.currentUser!.uid)
//         .get();
//     DocumentSnapshot currentUserProfile = await FirebaseFirestore.instance
//         .collection('profiles')
//         .doc(userAuth.get('profile'))
//         .get();
//     for (String networkId in currentUserProfile.get('activeTasks').keys) {
//       for (String taskId in currentUserProfile.get('activeTasks')[networkId]) {
//         DocumentSnapshot currentTask = await FirebaseFirestore.instance
//             .collection('tasks')
//             .doc(taskId)
//             .get();
//         bool yearFieldExists = true;
//         double totalScore = score + initScore;
//         try {
//           currentUserProfile.get(DateTime.now().year.toString());
//         } catch (e) {
//           yearFieldExists = false;
//         }
//         if (currentTask.get('mode') == 'daily') {
//           if (yearFieldExists) {
//             if (currentUserProfile.get(DateTime.now().year.toString())[
//                     DateTime.now().month.toString()] !=
//                 null) {
//               if (currentUserProfile.get(DateTime.now().year.toString())[
//                           DateTime.now().month.toString()]
//                       [DateTime.now().day.toString()] !=
//                   null) {
//                 await FirebaseFirestore.instance
//                     .collection('tasks')
//                     .doc(currentTask.id)
//                     .update({
//                   '${DateTime.now().year}.${DateTime.now().month}.${DateTime.now().day}.${currentUserProfile.id}':
//                       {
//                     'score': totalScore,
//                     'isCompleted':
//                         int.parse(currentTask.get('pointsNeeded')) <= totalScore
//                   },
//                 });
//               } else {
//                 await FirebaseFirestore.instance
//                     .collection('tasks')
//                     .doc(currentTask.id)
//                     .update({
//                   '${DateTime.now().year}.${DateTime.now().month}.${DateTime.now().day}':
//                       {
//                     currentUserProfile.id: {
//                       'score': totalScore,
//                       'isCompleted':
//                           int.parse(currentTask.get('pointsNeeded')) <=
//                               totalScore
//                     },
//                   },
//                 });
//               }
//             } else {
//               await FirebaseFirestore.instance
//                   .collection('tasks')
//                   .doc(currentTask.id)
//                   .update({
//                 '${DateTime.now().year}.${DateTime.now().month}': {
//                   DateTime.now().day.toString(): {
//                     currentUserProfile.id: {
//                       'score': totalScore,
//                       'isCompleted':
//                           int.parse(currentTask.get('pointsNeeded')) <=
//                               totalScore
//                     },
//                   },
//                 },
//               });
//             }
//           } else {
//             await FirebaseFirestore.instance
//                 .collection('tasks')
//                 .doc(currentTask.id)
//                 .update({
//               DateTime.now().year.toString(): {
//                 DateTime.now().month.toString(): {
//                   DateTime.now().day.toString(): {
//                     currentUserProfile.id: {
//                       'score': totalScore,
//                       'isCompleted':
//                           int.parse(currentTask.get('pointsNeeded')) <=
//                               totalScore
//                     },
//                   },
//                 },
//               },
//             });
//           }
//         } else if (currentTask.get('mode') == 'monthly') {
//           if (yearFieldExists) {
//             if (currentUserProfile.get(DateTime.now().year.toString())[
//                     DateTime.now().month.toString()] !=
//                 null) {
//               // UPDATING MONTHLY STUFF
//               if (currentUserProfile.get(DateTime.now().year.toString())[
//                       DateTime.now().month.toString()][currentUserProfile.id] !=
//                   null) {
//                 await FirebaseFirestore.instance
//                     .collection('tasks')
//                     .doc(currentTask.id)
//                     .update({
//                   '${DateTime.now().year}.${DateTime.now().month}.${currentUserProfile.id}':
//                       {
//                     'score': currentUserProfile.get(DateTime.now()
//                                 .year
//                                 .toString())[DateTime.now().month.toString()]
//                             [currentUserProfile.id]['score'] +
//                         score,
//                     'isCompleted': currentUserProfile.get(DateTime.now()
//                                 .year
//                                 .toString())[DateTime.now().month.toString()]
//                             [currentUserProfile.id]['score'] +
//                         score
//                   },
//                 });
//               } else {
//                 await FirebaseFirestore.instance
//                     .collection('tasks')
//                     .doc(currentTask.id)
//                     .update({
//                   '${DateTime.now().year}.${DateTime.now().month}.${currentUserProfile.id}':
//                       {
//                     'score': score,
//                     'isCompleted':
//                         int.parse(currentTask.get('pointsNeeded')) <= score
//                   },
//                 });
//               }
//             } else {
//               await FirebaseFirestore.instance
//                   .collection('tasks')
//                   .doc(currentTask.id)
//                   .update(
//                 {
//                   '${DateTime.now().year}.${DateTime.now().month}': {
//                     currentUserProfile.id: {
//                       'score': score,
//                       'isCompleted':
//                           int.parse(currentTask.get('pointsNeeded')) <= score
//                     },
//                   },
//                 },
//               );
//             }
//           } else {
//             await FirebaseFirestore.instance
//                 .collection('tasks')
//                 .doc(currentTask.id)
//                 .update({
//               DateTime.now().year.toString(): {
//                 DateTime.now().month.toString(): {
//                   currentUserProfile.id: {
//                     'score': score,
//                     'isCompleted':
//                         int.parse(currentTask.get('pointsNeeded')) <= score
//                   },
//                 },
//               },
//             });
//           }
//         }
//       }
//     }
//   }

//   // DocumentSnapshot? userProfile;
//   // DocumentSnapshot? userAuth;
//   // DocumentSnapshot? appDataSocial;
//   // DocumentSnapshot? appDataSystem;
//   // double initScore = 240;
//   // int performanceLevel = 0;
//   // int totalMinutes = 0;
//   // int totalMinutesSocial = 0;
//   // Map<String, int>? usedSocialApps = {};
//   // Map<String, int>? usedTopApps = {};
//   // List<AppUsageInfo>? appUsageInfo;
//   // Map<AppUsageInfo, String>? socialAppsInfo = {};

//   // Future<void> send15MinStat() async {
//   // initScore = 240;
//   // performanceLevel = 0;
//   // totalMinutes = 0;
//   // totalMinutesSocial = 0;
//   // usedSocialApps!.clear();
//   // usedTopApps!.clear();
//   // userAuth = await FirebaseFirestore.instance
//   //     .collection('users')
//   //     .doc(FirebaseAuth.instance.currentUser!.uid)
//   //     .get();
//   // userProfile = await FirebaseFirestore.instance
//   //     .collection('profiles')
//   //     .doc(userAuth!.get('profile'))
//   //     .get();
//   // appDataSocial = await FirebaseFirestore.instance
//   //     .collection('appData')
//   //     .doc('social')
//   //     .get();
//   // appDataSystem = await FirebaseFirestore.instance
//   //     .collection('appData')
//   //     .doc('system')
//   //     .get();
//   // try {
//   //   DateTime startDate =
//   //       // DateTime.now().subtract(Duration(hours: DateTime.now().hour, minutes: DateTime.now().minute));
//   //       DateTime(
//   //           DateTime.now().year, DateTime.now().month, DateTime.now().day);
//   //   DateTime endDate = DateTime.now();
//   //   appUsageInfo = await AppUsage.getAppUsage(startDate, endDate);
//   //   appUsageInfo!.sort(((a, b) => a.usage.compareTo(b.usage)));
//   //   for (AppUsageInfo appInfo in appUsageInfo!.reversed) {
//   //     // print(appInfo.packageName + ": " + appInfo.usage.toString());
//   //     if (appDataSocial!.get('apps').keys.contains(appInfo.packageName)) {
//   //       socialAppsInfo![appInfo] =
//   //           appDataSocial!.get('apps')[appInfo.packageName];
//   //       initScore -= appInfo.usage.inMinutes / 6;
//   //       totalMinutes += appInfo.usage.inMinutes;
//   //       totalMinutesSocial += appInfo.usage.inMinutes;
//   //       usedSocialApps![appInfo.packageName] = appInfo.usage.inMinutes;
//   //       usedTopApps![appInfo.packageName] = appInfo.usage.inMinutes;
//   //     }
//   //   }
//   //   await updateDailyStats();
//   // } on AppUsageException catch (exception) {
//   //   print("Background Task FAILED: AppUsage Info error");
//   //   print(exception);
//   // }
//   // }

//   // Future<void> updateDailyStats() async {
//   //   bool yearFieldExists = true;
//   //   try {
//   //     userProfile!.get(DateTime.now().year.toString());
//   //   } catch (e) {
//   //     yearFieldExists = false;
//   //   }
//   //   if (yearFieldExists) {
//   //     if (userProfile!.get(DateTime.now().year.toString())[
//   //             DateTime.now().month.toString()] !=
//   //         null) {
//   //       Map oldStats = userProfile!.get(DateTime.now().year.toString());
//   //       oldStats[DateTime.now().month.toString()]
//   //           [DateTime.now().day.toString()] = {
//   //         "dateUpdated": DateTime.now(),
//   //         "score": initScore,
//   //         "totalTimeSpentOnSocial": totalMinutesSocial,
//   //         "totalTimeSpent": totalMinutes,
//   //         "usedSocialApps": usedSocialApps,
//   //         "usedTopApps": usedTopApps,
//   //       };
//   //       await FirebaseFirestore.instance
//   //           .collection('profiles')
//   //           .doc(userAuth!.get('profile'))
//   //           .update({
//   //         DateTime.now().year.toString(): oldStats,
//   //       });
//   //     } else {
//   //       Map oldStats = userProfile!.get(DateTime.now().year.toString());
//   //       oldStats[DateTime.now().month.toString()] = {};
//   //       oldStats[DateTime.now().month.toString()]
//   //           [DateTime.now().day.toString()] = {
//   //         "dateUpdated": DateTime.now(),
//   //         "score": initScore,
//   //         "totalTimeSpentOnSocial": totalMinutesSocial,
//   //         "totalTimeSpent": totalMinutes,
//   //         "usedSocialApps": usedSocialApps,
//   //         "usedTopApps": usedTopApps,
//   //       };
//   //       await FirebaseFirestore.instance
//   //           .collection('profiles')
//   //           .doc(userAuth!.get('profile'))
//   //           .update({
//   //         DateTime.now().year.toString(): oldStats,
//   //       });
//   //     }
//   //   } else {
//   //     await FirebaseFirestore.instance
//   //         .collection('profiles')
//   //         .doc(userAuth!.get('profile'))
//   //         .update({
//   //       DateTime.now().year.toString(): {
//   //         DateTime.now().month.toString(): {
//   //           DateTime.now().day.toString(): {
//   //             "dateUpdated": DateTime.now(),
//   //             "score": initScore,
//   //             "totalTimeSpentOnSocial": totalMinutesSocial,
//   //             "totalTimeSpent": totalMinutes,
//   //             "usedSocialApps": usedSocialApps,
//   //             "usedTopApps": usedTopApps,
//   //           },
//   //         },
//   //       },
//   //     });
//   //   }
// }
