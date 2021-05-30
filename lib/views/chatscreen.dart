import 'dart:convert';

import 'package:authority_chat_app/helperfunctions/sharedpref_helper.dart';
import 'package:authority_chat_app/services/auth.dart';
import 'package:authority_chat_app/services/database.dart';
import 'package:authority_chat_app/views/signin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: must_be_immutable
class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  Text buildTextWithLinks(String textToLink, bool sendByMe) => Text.rich(
        TextSpan(children: linkify(textToLink, sendByMe)),
        style: TextStyle(color: Colors.white),
      );

  Future<void> openUrl(String url) async {
    if (url.startsWith(r'tel')) {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'Could not launch $url';
      }
    } else if (url.startsWith(r'mailto')) {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'Could not launch $url';
      }
    } else if (url.startsWith("http") || url.startsWith("www")) {
      if (url.startsWith("www")) {
        url = "https://$url";
      }
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'Could not launch $url';
      }
    }
  }

  WidgetSpan buildLinkComponent(
          String text, String linkToOpen, bool sendByMe) =>
      WidgetSpan(
          child: InkWell(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.lightBlue.shade300,
            decoration: TextDecoration.underline,
          ),
        ),
        onTap: () => openUrl(linkToOpen),
      ));

  List<InlineSpan> linkify(String text, bool sendByMe) {
    const String urlPattern =
        r"(((https?)://)|www.)([-A-Z0-9.]+)(/[-A-Z0-9+&@#/%=~_|!:,.;]*)?(\?[A-Z0-9+&@#/%=~_|!:‌​,.;]*)?";
    const String emailPattern = r'\S+@\S+';
    const String phonePattern = r'[\d-]{9,}';
    final RegExp linkRegExp = RegExp(
        '($urlPattern)|($phonePattern)|($emailPattern)',
        caseSensitive: false);
    final List<InlineSpan> list = <InlineSpan>[];
    final RegExpMatch match = linkRegExp.firstMatch(text);
    if (match == null) {
      list.add(TextSpan(text: text));
      return list;
    }

    if (match.start > 0) {
      print(match.start);
      list.add(TextSpan(text: text.substring(0, match.start)));
    }

    final String linkText = match.group(0);
    if (linkText.contains(RegExp(urlPattern, caseSensitive: false))) {
      // print(linkText);
      list.add(buildLinkComponent(linkText, linkText, sendByMe));
    } else if (linkText.contains(RegExp(phonePattern, caseSensitive: false))) {
      // print("num");
      // print(linkText);
      list.add(buildLinkComponent(linkText, 'tel:$linkText', sendByMe));
    } else if (linkText.contains(RegExp(emailPattern, caseSensitive: false))) {
      // print("email");

      list.add(buildLinkComponent(linkText, 'mailto:$linkText', sendByMe));
    } else {
      throw 'Unexpected match: $linkText';
    }

    list.addAll(
        linkify(text.substring(match.start + linkText.length), sendByMe));

    return list;
  }

  String chatRoomId, messageId;
  Stream<QuerySnapshot> messageStream;
  String myName, myProfilePic, myUserName, myEmail;
  TextEditingController messageTextEditingController = TextEditingController();
  bool selected = false;
  DocumentSnapshot<Map<String, dynamic>> forwardedReport;

  getMyInfoFromSharedPreferences() async {
    myName = await SharedPreferenceHelper().getDisplayName();
    myProfilePic = await SharedPreferenceHelper().getUserProfileUrl();
    myUserName = await SharedPreferenceHelper().getUserName();
    myEmail = await SharedPreferenceHelper().getUserEmail();

    chatRoomId = getChatRoomIdByUsername(myUserName, myUserName);
  }

  getChatRoomIdByUsername(String a, String b) {
    if (a.compareTo(b) == -1) {
      return "$b\_$a";
    } else if (a.compareTo(b) == 1) {
      return "$a\_$b";
    } else if (a.compareTo(b) == 0) {
      return "$a\_$b";
    }
  }

  void onNo(chatRoomId, messageId, upvoterName, message) async {
    print("Report to 0%");
    print("$chatRoomId $messageId");

    forwardedReport =
        await DatabaseMethods().getForwarded(chatRoomId, messageId);
    List forwardedList = forwardedReport["forwardedTo"];
    List upVoters = forwardedReport["upVoters"];
    print("forwardedList $forwardedList");
    Map<String, String> forwardedListInfoMap = {
      "chatRoomId": chatRoomId,
      "messageId": messageId
    };
    forwardedList.add(forwardedListInfoMap);

    upVoters.add(upvoterName);

    for (var forwardedlistmap in forwardedList) {
      print("forwardedlistmap $forwardedlistmap");
      DatabaseMethods().updateReported(forwardedlistmap, upVoters, 0, 100);
    }

    var bytes = utf8.encode(message);
    messageId = sha256.convert(bytes).toString();

    FirebaseFirestore.instance
        .collection("messages")
        .doc(messageId)
        .update({"confidence": 0});
  }

  void onYes(chatRoomId, messageId, upvoterName, message) async {
    print("Report to 100%");
    print("$chatRoomId $messageId");

    forwardedReport =
        await DatabaseMethods().getForwarded(chatRoomId, messageId);
    List forwardedList = forwardedReport["forwardedTo"];
    List upVoters = forwardedReport["upVoters"];
    print("forwardedList $forwardedList");
    Map<String, String> forwardedListInfoMap = {
      "chatRoomId": chatRoomId,
      "messageId": messageId
    };
    forwardedList.add(forwardedListInfoMap);

    upVoters.add(upvoterName);

    for (var forwardedlistmap in forwardedList) {
      print("forwardedlistmap $forwardedlistmap");
      DatabaseMethods().updateReported(forwardedlistmap, upVoters, 100, 0);
    }

    var bytes = utf8.encode(message);
    messageId = sha256.convert(bytes).toString();

    FirebaseFirestore.instance
        .collection("messages")
        .doc(messageId)
        .update({"confidence": 100});
  }

  Widget chatMessageTile(String messageId, String message, String sendBy,
      Timestamp ts, bool forwarded, String sendByName, List upVoters) {
    bool sendByMe = sendBy == myUserName;
    final DateTime date =
        DateTime.fromMillisecondsSinceEpoch(ts.millisecondsSinceEpoch);
    bool authorityReported = false;
    if (upVoters.contains(myUserName)) {
      authorityReported = true;
    }

    return Card(
      color: Colors.grey.shade50,
      elevation: 0,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: IntrinsicWidth(
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.0),
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                            color: sendByMe ? Colors.blue : Colors.blueGrey,
                            borderRadius:
                                BorderRadius.all(Radius.circular(6.0))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            chatRoomId.contains("Group", 0)
                                ? sendByMe
                                    ? Container()
                                    : Text(sendByName)
                                : Container(),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  constraints: BoxConstraints(maxWidth: 250),
                                  child: buildTextWithLinks(
                                      message.trim(), sendByMe),
                                ),
                                SizedBox(
                                  width: 10.0,
                                ),
                              ],
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 4.0),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('dd MMM hh:mm a').format(date),
                                  style: TextStyle(
                                      fontSize: 10.0, color: Colors.black),
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
            ],
          ),
          authorityReported
              ? Container()
              : Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.red.shade900),
                        ),
                        onPressed: () {
                          showDialog(
                            barrierDismissible: false,
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Confirm"),
                              content: Text(
                                  "Are you sure you want to report this message as fake?"),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    onYes(chatRoomId, messageId, myUserName,
                                        message);
                                  },
                                  child: Text("Yes"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text("No"),
                                )
                              ],
                            ),
                          );
                        },
                        child: Text("Fake"),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.blue),
                        ),
                        onPressed: () {
                          showDialog(
                            barrierDismissible: false,
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Confirm"),
                              content: Text(
                                  "Are you sure you want to report this message as real?"),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    onNo(chatRoomId, messageId, myUserName,
                                        message);
                                  },
                                  child: Text("Yes"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text("No"),
                                )
                              ],
                            ),
                          );
                        },
                        child: Text("Real"),
                      ),
                    ],
                  ),
                )
        ],
      ),
    );
  }

  Widget chatMessages() {
    return StreamBuilder<QuerySnapshot>(
      stream: messageStream,
      builder: (context, snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                padding: EdgeInsets.only(bottom: 70, top: 16),
                itemCount: snapshot.data.docs.length,
                reverse: true,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.docs[index];
                  return chatMessageTile(
                      ds.id,
                      ds["message"],
                      ds["sendBy"],
                      ds["ts"],
                      ds["forwarded"],
                      ds["sendByName"],
                      ds["upVoters"]);
                },
              )
            : Center(child: CircularProgressIndicator());
      },
    );
  }

  getAndSetMessages() async {
    messageStream = await DatabaseMethods().getChatRoomMessages(chatRoomId);
    setState(() {});
  }

  doThisOnLaunch() async {
    await getMyInfoFromSharedPreferences();
    await getAndSetMessages();
    print("dothis launch $chatRoomId");
  }

  @override
  void initState() {
    doThisOnLaunch();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Authority ChatApp"),
        actions: [
          IconButton(
            onPressed: () {
              AuthMethods().signOut().then((value) {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => SignIn()));
              });
            },
            icon: Icon(Icons.exit_to_app),
          )
        ],
      ),
      body: Container(
        child: Stack(
          children: [
            chatMessages(),
          ],
        ),
      ),
    );
  }
}
