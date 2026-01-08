import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_localizations.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  File? _imageFile;
  String? _currentProfileIcon;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('username, profile_icon')
          .eq('id', user.id)
          .single();

      setState(() {
        _usernameController.text = response['username'] ?? '';
        _currentProfileIcon = response['profile_icon'];
      });
    }
  }

  Future<void> _pickImage() async {
    // Request permissions based on platform
    PermissionStatus status;

    if (Platform.isAndroid) {
      // For Android, try photos first, then fallback to storage
      status = await Permission.photos.request();
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
    } else {
      // For iOS and other platforms
      status = await Permission.photos.request();
    }

    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.permissionDeniedPhotos),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
      return;
    }

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.failedToPickImage}: $e')),
      );
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.png';
    final filePath = 'movie_icons/$fileName';

    try {
      await Supabase.instance.client.storage
          .from('movie_icons')
          .upload(filePath, imageFile);

      final publicUrl = Supabase.instance.client.storage
          .from('movie_icons')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.failedToUploadImage}: $e')),
      );
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      String? imageUrl = _currentProfileIcon;

      // Upload new image if selected
      if (_imageFile != null) {
        imageUrl = await _uploadImage(_imageFile!);
        if (imageUrl == null) {
          setState(() => _loading = false);
          return; // Upload failed
        }
      }

      // Update profile
      await Supabase.instance.client
          .from('profiles')
          .update({
            'username': _usernameController.text.trim(),
            'profile_icon': imageUrl,
          })
          .eq('id', user.id);

      // Update user metadata
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {'username': _usernameController.text.trim()},
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.profileUpdatedSuccessfully)),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.failedToUpdateProfile}: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.editProfile),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Picture
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(60),
                      image: _imageFile != null
                          ? DecorationImage(
                              image: FileImage(_imageFile!),
                              fit: BoxFit.cover,
                            )
                          : _currentProfileIcon != null
                              ? DecorationImage(
                                  image: NetworkImage(_currentProfileIcon!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                      color: Colors.grey[800],
                    ),
                    child: (_imageFile == null && _currentProfileIcon == null)
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _pickImage,
                  child: Text(AppLocalizations.of(context)!.changeProfilePicture),
                ),
                const SizedBox(height: 30),

                // Username Field
                TextFormField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF00FF7F)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Username is required';
                    }
                    if (value.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // Save Button
                ElevatedButton(
                  onPressed: _loading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(AppLocalizations.of(context)!.saveChanges),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}