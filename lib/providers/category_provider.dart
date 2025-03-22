import 'package:flutter/foundation.dart';
import '../models/category.dart' as model;
import '../services/database_service.dart';

class CategoryProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<model.Category> _categories = [];

  List<model.Category> get categories => _categories;

  // Initialize the provider by loading categories
  Future<void> init() async {
    await loadCategories();
  }

  // Load categories from the database
  Future<void> loadCategories() async {
    _categories = await _databaseService.getCategories();
    notifyListeners();
  }

  // Add a new category
  Future<void> addCategory(model.Category category) async {
    await _databaseService.insertCategory(category);
    await loadCategories();
  }

  // Update an existing category
  Future<void> updateCategory(model.Category category) async {
    await _databaseService.updateCategory(category);
    await loadCategories();
  }

  // Delete a category
  Future<void> deleteCategory(String id) async {
    await _databaseService.deleteCategory(id);
    await loadCategories();
  }

  // Find a category by ID
  model.Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }
}
