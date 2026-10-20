import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordHasher {
  static String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
}