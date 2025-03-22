import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class User {
  final String username;
  final String email;

  User({required this.username, required this.email});

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
      };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'],
      email: json['email'],
    );
  }
}

class AuthService {
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'currentUser';

  // Hash password using SHA-256
  String _hashPassword(String password) {
    var bytes = utf8.encode(password); // Convert to bytes
    var digest = sha256.convert(bytes); // Apply SHA-256 hash
    return digest.toString();
  }

  // Register a new user
  Future<bool> register(String username, String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing users or create an empty map
      final String? usersJson = prefs.getString(_usersKey);
      Map<String, dynamic> users = usersJson != null 
          ? json.decode(usersJson) as Map<String, dynamic> 
          : {};
      
      // Check if user already exists
      if (users.containsKey(username)) {
        return false; // User already exists
      }
      
      // Hash the password
      final hashedPassword = _hashPassword(password);
      
      // Add new user
      users[username] = {
        'email': email,
        'password': hashedPassword,
      };
      
      // Save updated users
      await prefs.setString(_usersKey, json.encode(users));
      
      // Set as current user
      final currentUser = User(username: username, email: email);
      await prefs.setString(_currentUserKey, json.encode(currentUser.toJson()));
      
      return true;
    } catch (e) {
      print('Error during registration: $e');
      return false;
    }
  }

  // Login user
  Future<bool> login(String username, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing users
      final String? usersJson = prefs.getString(_usersKey);
      if (usersJson == null) {
        return false; // No users exist
      }
      
      Map<String, dynamic> users = json.decode(usersJson) as Map<String, dynamic>;
      
      // Check if user exists
      if (!users.containsKey(username)) {
        return false; // User doesn't exist
      }
      
      // Hash the password and compare
      final hashedPassword = _hashPassword(password);
      if (users[username]['password'] != hashedPassword) {
        return false; // Incorrect password
      }
      
      // Set as current user
      final currentUser = User(
        username: username, 
        email: users[username]['email'],
      );
      await prefs.setString(_currentUserKey, json.encode(currentUser.toJson()));
      
      return true;
    } catch (e) {
      print('Error during login: $e');
      return false;
    }
  }

  // Check if user is logged in
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userJson = prefs.getString(_currentUserKey);
      
      if (userJson == null) {
        return null;
      }
      
      return User.fromJson(json.decode(userJson) as Map<String, dynamic>);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Logout user
  Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserKey);
      return true;
    } catch (e) {
      print('Error during logout: $e');
      return false;
    }
  }
} 