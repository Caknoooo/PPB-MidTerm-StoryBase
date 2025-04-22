// screens/story_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/story.dart';
import '../providers/story_provider.dart';
import '../utils/app_constants.dart';

class StoryFormScreen extends StatefulWidget {
  final Story? story;

  const StoryFormScreen({super.key, this.story});

  @override
  _StoryFormScreenState createState() => _StoryFormScreenState();
}

class _StoryFormScreenState extends State<StoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _imageUrlController;

  bool _isLoading = false;
  late StoryProvider _storyProvider;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.story?.title ?? '');
    _contentController = TextEditingController(text: widget.story?.content ?? '');
    _imageUrlController = TextEditingController(text: widget.story?.imageUrl ?? '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store provider reference safely
    _storyProvider = Provider.of<StoryProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  String? _validateImageUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      return 'URL gambar harus dimulai dengan http:// atau https://';
    }
    
    return null;
  }

  Future<void> _saveStory() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String? imageUrl;
      if (_imageUrlController.text.isNotEmpty) {
        if (_validateImageUrl(_imageUrlController.text) == null) {
          imageUrl = _imageUrlController.text;
        }
      }

      final story = Story(
        id: widget.story?.id,
        title: _titleController.text,
        content: _contentController.text,
        imageUrl: imageUrl,
        createdAt: widget.story?.createdAt,
        updatedAt: DateTime.now(),
      );

      try {
        final success = await _storyProvider.saveStory(story);

        setState(() {
          _isLoading = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppConstants.storySaved)),
          );
          
          Navigator.pop(context, true);
        } else {
          _showErrorDialog(_storyProvider.errorMessage ?? AppConstants.errorSavingStory);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Error saving story: $e');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      setState(() {
        _contentController.text = data.text!;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content pasted from clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.story == null ? 'Add Story' : 'Edit Story'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 32,
                      ),
                      child: IntrinsicHeight(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Title',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              TextFormField(
                                controller: _titleController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter story title',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a title';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24.0),

                              const Text(
                                'Story',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              TextFormField(
                                controller: _contentController,
                                decoration: InputDecoration(
                                  hintText: 'Write your story here...',
                                  border: const OutlineInputBorder(),
                                  alignLabelWithHint: true,
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.paste),
                                    onPressed: _pasteFromClipboard,
                                    tooltip: 'Paste from clipboard',
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter story content';
                                  }
                                  return null;
                                },
                                maxLines: 10,
                              ),
                              const SizedBox(height: 24.0),

                              const Text(
                                'Image URL',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              TextFormField(
                                controller: _imageUrlController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter image URL (optional)',
                                  border: OutlineInputBorder(),
                                  helperText: 'Must start with http:// or https://',
                                ),
                                validator: _validateImageUrl,
                              ),
                              const SizedBox(height: 32.0),

                              ElevatedButton(
                                onPressed: _saveStory,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                ),
                                child: Text(
                                  widget.story == null ? 'Create' : 'Save Changes',
                                  style: const TextStyle(fontSize: 16.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      resizeToAvoidBottomInset: true,
    );
  }
}