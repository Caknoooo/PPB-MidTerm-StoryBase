import '../models/story.dart';
import '../services/database_service.dart';

class StoryRepository {
  final DatabaseService _databaseService = DatabaseService();

  Future<List<Story>> getAllStories() async {
    return await _databaseService.getStories();
  }

  Future<Story?> getStoryById(String id) async {
    return await _databaseService.getStory(id);
  }

  Future<void> saveStory(Story story) async {
    if (story.id == null) {
      await _databaseService.insertStory(story);
    } else {
      await _databaseService.updateStory(story);
    }
  }

  Future<void> updateStory(Story story) async {
    await _databaseService.updateStory(story);
  }

  Future<void> deleteStory(String id) async {
    await _databaseService.deleteStory(id);
  }

  Future<void> deleteAllStories() async {
    await _databaseService.deleteAllStories();
  }
}
