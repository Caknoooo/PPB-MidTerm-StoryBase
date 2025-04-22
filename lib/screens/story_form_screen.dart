// screens/story_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../models/story.dart';
import '../providers/story_provider.dart';
import '../utils/app_constants.dart';

class StoryFormScreen extends StatefulWidget {
  final Story? story;

  const StoryFormScreen({super.key, this.story});

  @override
  _StoryFormScreenState createState() => _StoryFormScreenState();
}

class _StoryFormScreenState extends State<StoryFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _imageUrlController;
  late FocusNode _titleFocusNode;
  late FocusNode _contentFocusNode;
  late FocusNode _imageUrlFocusNode;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _isTitleFocused = false;
  bool _isContentFocused = false;
  bool _isImageUrlFocused = false;
  bool _isPreviewMode = false;
  String? _previewImageUrl;
  String _contentText = '';
  String _titleText = '';
  int _wordCount = 0;
  int _charCount = 0;
  late StoryProvider _storyProvider;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.story?.title ?? '');
    _contentController = TextEditingController(
      text: widget.story?.content ?? '',
    );
    _imageUrlController = TextEditingController(
      text: widget.story?.imageUrl ?? '',
    );
    _titleFocusNode = FocusNode();
    _contentFocusNode = FocusNode();
    _imageUrlFocusNode = FocusNode();
    _titleText = widget.story?.title ?? '';
    _contentText = widget.story?.content ?? '';

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuint),
    );

    _titleFocusNode.addListener(_onTitleFocusChange);
    _contentFocusNode.addListener(_onContentFocusChange);
    _imageUrlFocusNode.addListener(_onImageUrlFocusChange);

    _contentController.addListener(_updateTextMetrics);
    _titleController.addListener(_onTitleChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });

    _updateTextMetrics();
  }

  void _onTitleFocusChange() {
    setState(() {
      _isTitleFocused = _titleFocusNode.hasFocus;
    });
  }

  void _onContentFocusChange() {
    setState(() {
      _isContentFocused = _contentFocusNode.hasFocus;
    });
  }

  void _onImageUrlFocusChange() {
    setState(() {
      _isImageUrlFocused = _imageUrlFocusNode.hasFocus;
    });
  }

  void _onTitleChanged() {
    setState(() {
      _titleText = _titleController.text;
    });
  }

  void _updateTextMetrics() {
    final text = _contentController.text;
    final wordCount =
        text.isEmpty
            ? 0
            : text
                .split(RegExp(r'\s+'))
                .where((word) => word.isNotEmpty)
                .length;
    final charCount = text.length;

    setState(() {
      _contentText = text;
      _wordCount = wordCount;
      _charCount = charCount;
    });
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
    _titleFocusNode.removeListener(_onTitleFocusChange);
    _contentFocusNode.removeListener(_onContentFocusChange);
    _imageUrlFocusNode.removeListener(_onImageUrlFocusChange);
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    _imageUrlFocusNode.dispose();
    _contentController.removeListener(_updateTextMetrics);
    _titleController.removeListener(_onTitleChanged);
    _animationController.dispose();
    super.dispose();
  }

  bool isValidImageUrl(String? url) {
    return url != null &&
        url.isNotEmpty &&
        (url.startsWith('http://') || url.startsWith('https://'));
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

      // Add haptic feedback for form submission
      HapticFeedback.mediumImpact();

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
        createdAt: widget.story?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        final success = await _storyProvider.saveStory(story);

        setState(() {
          _isLoading = false;
        });

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 16),
                    Text(AppConstants.storySaved),
                  ],
                ),
                backgroundColor: Colors.green[700],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.all(8),
              ),
            );
          }

          Navigator.pop(context, true);
        } else {
          _showErrorDialog(
            _storyProvider.errorMessage ?? AppConstants.errorSavingStory,
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Error saving story: $e');
      }
    } else {
      // If validation fails, provide haptic feedback
      HapticFeedback.vibrate();
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline, color: Colors.red),
              ),
              const SizedBox(width: 16),
              const Text('Error'),
            ],
          ),
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
    HapticFeedback.lightImpact();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      setState(() {
        _contentController.text = data.text!;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.paste, color: Colors.white),
              const SizedBox(width: 16),
              const Text('Content pasted from clipboard'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(8),
        ),
      );
    }
  }

  void _togglePreviewMode() {
    HapticFeedback.lightImpact();
    setState(() {
      _isPreviewMode = !_isPreviewMode;

      if (_isPreviewMode) {
        // Validate and set image URL for preview
        final url = _imageUrlController.text;
        _previewImageUrl = isValidImageUrl(url) ? url : null;
      }
    });
  }

  void _clearContent() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Clear Content?'),
          content: const Text(
            'Are you sure you want to clear all content? This cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Clear'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _contentController.text = '';
                });
                HapticFeedback.mediumImpact();
              },
            ),
          ],
        );
      },
    );
  }

  void _testImageUrl() {
    final url = _imageUrlController.text;
    if (isValidImageUrl(url)) {
      setState(() {
        _previewImageUrl = url;
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Failed to load image',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child: const Text('Close'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white),
              const SizedBox(width: 16),
              const Text('Enter a valid image URL first'),
            ],
          ),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(8),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.white.withOpacity(0.6)),
          ),
        ),
        title: Text(
          widget.story == null ? 'Create New Story' : 'Edit Story',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black87),
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Discard Changes?'),
                  content: const Text(
                    'If you go back now, your changes will be lost.',
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Stay'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: const Text('Discard'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
        actions: [
          // Preview toggle button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: IconButton(
              key: ValueKey<bool>(_isPreviewMode),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      _isPreviewMode
                          ? Colors.purple.withOpacity(0.2)
                          : Colors.black.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPreviewMode ? Icons.edit : Icons.remove_red_eye,
                  color: _isPreviewMode ? Colors.purple : Colors.black87,
                ),
              ),
              tooltip: _isPreviewMode ? 'Edit Mode' : 'Preview Mode',
              onPressed: _togglePreviewMode,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Saving your story...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
              : SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        // Form View
                        AnimatedOpacity(
                          opacity: _isPreviewMode ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: child,
                                ),
                              );
                            },
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                100,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight - 32,
                                ),
                                child: IntrinsicHeight(
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Title Field
                                        AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow:
                                                _isTitleFocused
                                                    ? [
                                                      BoxShadow(
                                                        color: theme
                                                            .primaryColor
                                                            .withOpacity(0.3),
                                                        blurRadius: 8,
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
                                                      ),
                                                    ]
                                                    : [],
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.title,
                                                    size: 18,
                                                    color: Colors.blue,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Text(
                                                    'Story Title',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      border: Border.all(
                                                        color: Colors.red
                                                            .withOpacity(0.3),
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      'Required',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8.0),
                                              TextFormField(
                                                controller: _titleController,
                                                focusNode: _titleFocusNode,
                                                decoration: InputDecoration(
                                                  hintText:
                                                      'Enter a captivating title...',
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    borderSide: BorderSide(
                                                      color: Colors.grey[300]!,
                                                    ),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color:
                                                              Colors.grey[300]!,
                                                        ),
                                                      ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color:
                                                              theme
                                                                  .primaryColor,
                                                          width: 2,
                                                        ),
                                                      ),
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                  contentPadding:
                                                      const EdgeInsets.all(16),
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                textCapitalization:
                                                    TextCapitalization
                                                        .sentences,
                                                textInputAction:
                                                    TextInputAction.next,
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.trim().isEmpty) {
                                                    return 'Please enter a title';
                                                  }
                                                  return null;
                                                },
                                                onFieldSubmitted: (_) {
                                                  _contentFocusNode
                                                      .requestFocus();
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 24.0),

                                        // Content Field
                                        AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow:
                                                _isContentFocused
                                                    ? [
                                                      BoxShadow(
                                                        color: theme
                                                            .primaryColor
                                                            .withOpacity(0.3),
                                                        blurRadius: 8,
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
                                                      ),
                                                    ]
                                                    : [],
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.book,
                                                    size: 18,
                                                    color: Colors.green,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Text(
                                                    'Story Content',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      border: Border.all(
                                                        color: Colors.red
                                                            .withOpacity(0.3),
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      'Required',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  // Word count
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '$_wordCount words',
                                                      style: TextStyle(
                                                        color: Colors.blue[700],
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8.0),
                                              Stack(
                                                children: [
                                                  TextFormField(
                                                    controller:
                                                        _contentController,
                                                    focusNode:
                                                        _contentFocusNode,
                                                    decoration: InputDecoration(
                                                      hintText:
                                                          'Write your story here...',
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color:
                                                              Colors.grey[300]!,
                                                        ),
                                                      ),
                                                      enabledBorder: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color:
                                                              Colors.grey[300]!,
                                                        ),
                                                      ),
                                                      focusedBorder: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color:
                                                              theme
                                                                  .primaryColor,
                                                          width: 2,
                                                        ),
                                                      ),
                                                      filled: true,
                                                      fillColor: Colors.white,
                                                      contentPadding:
                                                          const EdgeInsets.all(
                                                            16,
                                                          ),
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      height: 1.6,
                                                    ),
                                                    validator: (value) {
                                                      if (value == null ||
                                                          value
                                                              .trim()
                                                              .isEmpty) {
                                                        return 'Please enter story content';
                                                      }
                                                      return null;
                                                    },
                                                    maxLines: 15,
                                                    textCapitalization:
                                                        TextCapitalization
                                                            .sentences,
                                                  ),
                                                  // Button overlay
                                                  Positioned(
                                                    bottom: 8,
                                                    right: 8,
                                                    child: Row(
                                                      children: [
                                                        Material(
                                                          color:
                                                              Colors
                                                                  .transparent,
                                                          shape:
                                                              const CircleBorder(),
                                                          clipBehavior:
                                                              Clip.antiAlias,
                                                          child: IconButton(
                                                            icon: Icon(
                                                              Icons.clear_all,
                                                              color:
                                                                  Colors
                                                                      .red[700],
                                                            ),
                                                            tooltip:
                                                                'Clear all',
                                                            onPressed:
                                                                _contentController
                                                                        .text
                                                                        .isNotEmpty
                                                                    ? _clearContent
                                                                    : null,
                                                          ),
                                                        ),
                                                        Material(
                                                          color:
                                                              Colors
                                                                  .transparent,
                                                          shape:
                                                              const CircleBorder(),
                                                          clipBehavior:
                                                              Clip.antiAlias,
                                                          child: IconButton(
                                                            icon: Icon(
                                                              Icons.paste,
                                                              color:
                                                                  Colors
                                                                      .blue[700],
                                                            ),
                                                            tooltip:
                                                                'Paste from clipboard',
                                                            onPressed:
                                                                _pasteFromClipboard,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              // Character count
                                              Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 4,
                                                        right: 8,
                                                      ),
                                                  child: Text(
                                                    '$_charCount characters',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 24.0),

                                        // Image URL Field
                                        AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow:
                                                _isImageUrlFocused
                                                    ? [
                                                      BoxShadow(
                                                        color: theme
                                                            .primaryColor
                                                            .withOpacity(0.3),
                                                        blurRadius: 8,
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
                                                      ),
                                                    ]
                                                    : [],
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.image,
                                                    size: 18,
                                                    color: Colors.purple,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Text(
                                                    'Cover Image URL',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8.0),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: TextFormField(
                                                      controller:
                                                          _imageUrlController,
                                                      focusNode:
                                                          _imageUrlFocusNode,
                                                      decoration: InputDecoration(
                                                        hintText:
                                                            'https://example.com/image.jpg',
                                                        border: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                          borderSide: BorderSide(
                                                            color:
                                                                Colors
                                                                    .grey[300]!,
                                                          ),
                                                        ),
                                                        enabledBorder: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                          borderSide: BorderSide(
                                                            color:
                                                                Colors
                                                                    .grey[300]!,
                                                          ),
                                                        ),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                          borderSide: BorderSide(
                                                            color:
                                                                theme
                                                                    .primaryColor,
                                                            width: 2,
                                                          ),
                                                        ),
                                                        filled: true,
                                                        fillColor: Colors.white,
                                                        contentPadding:
                                                            const EdgeInsets.all(
                                                              16,
                                                            ),
                                                        suffixIcon: IconButton(
                                                          icon: const Icon(
                                                            Icons.clear,
                                                          ),
                                                          onPressed:
                                                              _imageUrlController
                                                                      .text
                                                                      .isNotEmpty
                                                                  ? () {
                                                                    setState(() {
                                                                      _imageUrlController
                                                                          .clear();
                                                                      _previewImageUrl =
                                                                          null;
                                                                    });
                                                                  }
                                                                  : null,
                                                        ),
                                                      ),
                                                      validator:
                                                          _validateImageUrl,
                                                      keyboardType:
                                                          TextInputType.url,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  ElevatedButton(
                                                    onPressed:
                                                        () => _testImageUrl(),
                                                    style: ElevatedButton.styleFrom(
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 16,
                                                            horizontal: 16,
                                                          ),
                                                    ),
                                                    child: const Text(
                                                      'Test URL',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Add a URL to an image for your story cover (optional)',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 40),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Preview Mode
                        AnimatedOpacity(
                          opacity: _isPreviewMode ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Visibility(
                            visible: _isPreviewMode,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                100,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Preview Header
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.purple.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.visibility,
                                          size: 18,
                                          color: Colors.purple,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Preview Mode',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.purple,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          'Tap anywhere to edit',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Cover Image
                                  if (_previewImageUrl != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: AspectRatio(
                                        aspectRatio: 16 / 9,
                                        child: Image.network(
                                          _previewImageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Container(
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.broken_image,
                                                size: 48,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    )
                                  else
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: AspectRatio(
                                        aspectRatio: 16 / 9,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.blue.shade400,
                                                Colors.purple.shade300,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.image,
                                              color: Colors.white,
                                              size: 48,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 24),

                                  // Title
                                  Text(
                                    _titleText.isEmpty
                                        ? 'Untitled Story'
                                        : _titleText,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Content
                                  Text(
                                    _contentText.isEmpty
                                        ? 'No content added yet. Start writing your story...'
                                        : _contentText,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.6,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'save_story_fab',
        onPressed: _saveStory,
        icon: const Icon(Icons.save),
        label: Text(widget.story == null ? 'Create' : 'Save'),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
