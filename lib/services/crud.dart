import 'dart:async';
import 'package:bk_app/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bk_app/models/item.dart';
import 'package:bk_app/models/transaction.dart';
import 'package:bk_app/services/auth.dart';

class CrudHelper {
  AuthService auth = AuthService();
  final userData;
  CrudHelper({this.userData});

  // Item
  Future<int> addItem(Item item) async {
    String targetEmail = this.userData.targetEmail;
    if (targetEmail == this.userData.email) {
      await FirebaseFirestore.instance
          .collection('$targetEmail-items')
          .add(item.toMap())
          .catchError((e) {
        print(e);
        return 0;
      });
      return 1;
    } else {
      return 0;
    }
  }

  Future<int> updateItem(Item newItem) async {
    String targetEmail = this.userData.targetEmail;
    if (targetEmail == this.userData.email) {
      await FirebaseFirestore.instance
          .collection('$targetEmail-items')
          .doc(newItem.id)
          .update(newItem.toMap())
          .catchError((e) {
        print(e);
        return 0;
      });
      return 1;
    } else {
      return 0;
    }
  }

  Future<int> deleteItem(String itemId) async {
    String targetEmail = this.userData.targetEmail;
    if (targetEmail == this.userData.email) {
      await FirebaseFirestore.instance
          .collection('$targetEmail-items')
          .doc(itemId)
          .delete()
          .catchError((e) {
        print(e);
        return 0;
      });
      return 1;
    } else {
      return 0;
    }
  }

  Stream<List<Item>> getItemStream() {
    String email = this.userData.targetEmail;
    print("Stream current target email $email");
    return FirebaseFirestore.instance
        .collection('$email-items')
        .orderBy('used', descending: true)
        .snapshots()
        .map(Item.fromQuerySnapshot);
  }

  Future<Item> getItem(String field, String value) async {
    String email = this.userData.targetEmail;
    QuerySnapshot itemSnapshots = await FirebaseFirestore.instance
        .collection('$email-items')
        .where(field, isEqualTo: value)
        .get()
        .catchError((e) {
      return null;
    });

    if (itemSnapshots.docs.isEmpty) {
      return null;
    }
    DocumentSnapshot itemSnapshot = itemSnapshots.docs.first;

    if (itemSnapshot.data()) {
      Item item = Item.fromMapObject(itemSnapshot.data());
      item.id = itemSnapshot.id;
      return item;
    } else {
      return null;
    }
  }

  Future<Item> getItemById(String id) async {
    String email = this.userData.targetEmail;
    DocumentSnapshot itemSnapshot = await FirebaseFirestore.instance
        .doc('$email-items/$id')
        .get()
        .catchError((e) {
      return null;
    });
    if (itemSnapshot.data() ?? false) {
      Item item = Item.fromMapObject(itemSnapshot.data());
      item.id = itemSnapshot.id;
      return item;
    } else {
      return null;
    }
  }

  Future<List<Item>> getItems() async {
    String email = this.userData.targetEmail;
    QuerySnapshot snapshots = await FirebaseFirestore.instance
        .collection('$email-items')
        .orderBy('used', descending: true)
        .get();
    List<Item> items = List<Item>();
    snapshots.docs.forEach((DocumentSnapshot snapshot) {
      Item item = Item.fromMapObject(snapshot.data());
      item.id = snapshot.id;
      items.add(item);
    });
    return items;
  }

  // Item Transactions
  Stream<List<ItemTransaction>> getItemTransactionStream() {
    String email = this.userData.targetEmail;
    return FirebaseFirestore.instance
        .collection('$email-transactions')
        .where('signature', isEqualTo: email)
        .snapshots()
        .map(ItemTransaction.fromQuerySnapshot);
  }

  Future<List<ItemTransaction>> getItemTransactions() async {
    String email = this.userData.targetEmail;
    QuerySnapshot snapshots = await FirebaseFirestore.instance
        .collection('$email-transactions')
        .where('signature', isEqualTo: email)
        .get();
    return ItemTransaction.fromQuerySnapshot(snapshots);
  }

  Future<List<ItemTransaction>> getPendingTransactions() async {
    String email = this.userData.targetEmail;
    UserData user = await this.getUserData('email', email);
    List roles = user.roles?.keys?.toList() ?? List();
    print("roles $roles");
    if (roles.isEmpty) return List<ItemTransaction>();
    QuerySnapshot snapshots = await FirebaseFirestore.instance
        .collection('$email-transactions')
        .where('signature', whereIn: roles)
        .get();
    return ItemTransaction.fromQuerySnapshot(snapshots);
  }

  Future<List<ItemTransaction>> getDueTransactions() async {
    String email = this.userData.targetEmail;
    QuerySnapshot snapshots = await FirebaseFirestore.instance
        .collection('$email-transactions')
        .where('due_amount', isGreaterThan: 0.0)
        .get();
    return ItemTransaction.fromQuerySnapshot(snapshots);
  }

  // Users
  Future<UserData> getUserData(String field, String value) async {
    QuerySnapshot userDataSnapshots = await FirebaseFirestore.instance
        .collection('users')
        .where(field, isEqualTo: value)
        .get()
        .catchError((e) {
      return null;
    });
    if (userDataSnapshots.docs.isEmpty) {
      return null;
    }
    DocumentSnapshot userDataSnapshot = userDataSnapshots.docs.first;
    if (userDataSnapshot.data()) {
      UserData userData = UserData.fromMapObject(userDataSnapshot.data());
      userData.uid = userDataSnapshot.id;
      return userData;
    } else {
      return null;
    }
  }

  Future<UserData> getUserDataByUid(String uid) async {
    DocumentSnapshot _userData =
        await FirebaseFirestore.instance.doc('users/$uid').get().catchError((e) {
      print("error getting userdata $e");
      return null;
    });

    if (_userData.data == null) {
      print("error getting userdata is $uid");
      return null;
    }

    UserData userData = UserData.fromMapObject(_userData.data());
    print("here we go $userData & roles ${userData.roles}");
    return userData;
  }

  Future<int> updateUserData(UserData userData) async {
    print("got userData and roles ${userData.toMap}");
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userData.uid)
        .set(userData.toMap())
        .catchError((e) {
      print(e);
      return 0;
    });
    return 1;
  }
}
