import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class CrudService {
  User get _user {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw StateError("User is not logged in.");
    }
    return currentUser;
  }

  // create a new contact
  Future<String?> createContact(String name, String phone, String email) async {
    try {
      final data = {
        "name": name,
        "phone": phone,
        "email": email,
      };

      await FirebaseFirestore.instance
          .collection("users")
          .doc(_user.uid)
          .collection("contacts")
          .add(data);

      debugPrint("Contact Added");
      return null;
    } catch (e) {
      debugPrint(e.toString());
      return "Unable to create contact. Please try again.";
    }
  }

  // read documents inside firestore
  Stream<QuerySnapshot> getContacts({String? searchQuery}) async* {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      yield* const Stream.empty();
      return;
    }

    var contactsQuery = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("contacts")
        .orderBy("name");

    // a filter to perform search
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final searchEnd = '$searchQuery\uf8ff';

      contactsQuery = contactsQuery.where(
        "name",
        isGreaterThanOrEqualTo: searchQuery,
        isLessThan: searchEnd,
      );
    }

    final contacts = contactsQuery.snapshots();
    yield* contacts;
  }

  // update a contact
  Future<String?> updateContact(
      String name, String phone, String email, String docID) async {
    try {
      final data = {
        "name": name,
        "phone": phone,
        "email": email,
      };

      await FirebaseFirestore.instance
          .collection("users")
          .doc(_user.uid)
          .collection("contacts")
          .doc(docID)
          .update(data);

      debugPrint("Document Updated");
      return null;
    } catch (e) {
      debugPrint(e.toString());
      return "Unable to update contact. Please try again.";
    }
  }

  // delete contact from firestore
  Future<String?> deleteContact(String docID) async {
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(_user.uid)
          .collection("contacts")
          .doc(docID)
          .delete();

      debugPrint("Contact Deleted");
      return null;
    } catch (e) {
      debugPrint(e.toString());
      return "Unable to delete contact. Please try again.";
    }
  }
}
