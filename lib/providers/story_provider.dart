import 'package:flutter/material.dart';
import '../models/story.dart';
import '../repositories/story_repository.dart';

class StoryProvider extends ChangeNotifier {
  final StoryRepository _storyRepository = StoryRepository();
  
  List<Story> _stories = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  List<Story> get stories => _stories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  Future<void> loadStories() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      _stories = await _storyRepository.getAllStories();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error loading stories: $e';
      notifyListeners();
    }
  }
  
  Future<Story?> getStoryById(String id) async {
    try {
      return await _storyRepository.getStoryById(id);
    } catch (e) {
      _errorMessage = 'Error fetching story: $e';
      notifyListeners();
      return null;
    }
  }
  
  Future<bool> saveStory(Story story) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _storyRepository.saveStory(story);
      await loadStories();
      
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error saving story: $e';
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> deleteStory(String id) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _storyRepository.deleteStory(id);
      await loadStories(); 
      
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error deleting story: $e';
      notifyListeners();
      return false;
    }
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
