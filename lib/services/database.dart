import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  Future addUserInfoToDB(
      String userId, Map<String, dynamic> userInfoMap) async {
    FirebaseFirestore.instance
        .collection("authorities")
        .doc(userId)
        .set(userInfoMap);
    String username = userInfoMap["username"];

    Map<String, dynamic> chatRoomInfoMap = {
      "users": [username]
    };
    String chatRoomId = "$username\_$username";
    Map<String, dynamic> lastMessageInfoMap;
    if (username.contains("Authority")) {
      lastMessageInfoMap = {};
    } else {
      lastMessageInfoMap = {
        "lastMessage": "Hey dude",
        "lastMessageSendTS": DateTime.now(),
        "lastMessageSendBy": " ",
        "lastMessageId": " ",
      };
    }
    createChatRoom(chatRoomId, chatRoomInfoMap, lastMessageInfoMap);
  }

  createChatRoom(
      String chatRoomId, Map chatRoomInfoMap, Map lastMessageInfoMap) async {
    print("Fuckoff this createRoom ");
    FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .get()
        .then((DocumentSnapshot snapShot) {
      if (snapShot.data() != null) {
        print("Hello, createRoom then if is working");
        return null;
      } else {
        print("Hello, createRoom then else is working");
        FirebaseFirestore.instance
            .collection("chatrooms")
            .doc(chatRoomId)
            .set(chatRoomInfoMap);
        return FirebaseFirestore.instance
            .collection("chatrooms")
            .doc(chatRoomId)
            .set(lastMessageInfoMap, SetOptions(merge: true));
      }
    });
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getForwarded(
      String chatRoomId, String messageId) async {
    print("inside getForwarded $messageId");
    print("inside getForwarded $chatRoomId");
    return await FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .collection("chats")
        .doc(messageId)
        .get();
  }

  updateReported(Map forwardedlist, List upVoters, int confidenceFake,
      int confidenceReal) {
    String chatRoomId = forwardedlist["chatRoomId"];
    String messageId = forwardedlist["messageId"];
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .collection("chats")
        .doc(messageId)
        .update({
      "reported": true,
      "upVoters": upVoters,
      "confidenceFake": confidenceFake,
      "confidenceReal": confidenceReal,
      "authorityReported": true
    });
  }

  Future<Stream<QuerySnapshot>> getChatRoomMessages(String chatRoomId) async {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .collection("chats")
        .orderBy("ts", descending: true)
        .snapshots();
  }
}
