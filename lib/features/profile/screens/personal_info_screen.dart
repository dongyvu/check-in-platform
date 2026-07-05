import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'package:sign/models/app_profile.dart';
import 'package:sign/repositories/sign_repository.dart';
import 'package:sign/shared/ui/responsive_layout.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _repository = SignRepository();
  final _displayNameController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _imageCropper = ImageCropper();

  late Future<AppProfile?> _profileFuture;
  String? _avatarPath;
  String? _avatarUrl;
  Uint8List? _selectedAvatarBytes;
  String _selectedAvatarContentType = 'image/jpeg';
  bool _isSaving = false;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<AppProfile?> _loadProfile() async {
    final profile = await _repository.fetchCurrentProfile();
    if (profile == null) return null;
    _displayNameController.text = profile.displayName;
    _avatarPath = profile.avatarUrl;
    if (_avatarPath != null && _avatarPath!.isNotEmpty) {
      _avatarUrl = await _repository.createAvatarUrl(_avatarPath!);
    }
    return profile;
  }

  Future<void> _pickAvatar() async {
    setState(() => _isUploadingAvatar = true);
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
      );
      if (picked == null) return;
      if (!mounted) return;

      final cropped = await _imageCropper.cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 82,
        maxWidth: 512,
        maxHeight: 512,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '裁剪头像',
            lockAspectRatio: true,
            initAspectRatio: CropAspectRatioPreset.square,
          ),
          IOSUiSettings(
            title: '裁剪头像',
            aspectRatioLockEnabled: true,
            aspectRatioPickerButtonHidden: true,
          ),
          WebUiSettings(context: context),
        ],
      );
      if (cropped == null) return;

      final bytes = await cropped.readAsBytes();

      if (!mounted) return;
      setState(() {
        _selectedAvatarBytes = bytes;
        _selectedAvatarContentType = 'image/jpeg';
        _avatarUrl = null;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('头像处理失败：$error')));
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Future<void> _save() async {
    final displayName = _displayNameController.text.trim();
    if (displayName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('用户名不能为空')));
      return;
    }

    setState(() => _isSaving = true);
    String? uploadedAvatarPath;
    try {
      final oldAvatarPath = _avatarPath;
      final selectedAvatarBytes = _selectedAvatarBytes;
      final nextAvatarPath = selectedAvatarBytes == null
          ? oldAvatarPath
          : await _repository.uploadAvatar(
              avatarBytes: selectedAvatarBytes,
              contentType: _selectedAvatarContentType,
            );
      uploadedAvatarPath = selectedAvatarBytes == null ? null : nextAvatarPath;

      await _repository.updateProfile(
        displayName: displayName,
        avatarUrl: nextAvatarPath,
      );
      if (uploadedAvatarPath != null &&
          oldAvatarPath != null &&
          oldAvatarPath.isNotEmpty &&
          oldAvatarPath != uploadedAvatarPath) {
        await _repository.deleteAvatar(oldAvatarPath).catchError((_) {});
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('个人信息已保存')));
      Navigator.pop(context, true);
    } catch (error) {
      if (uploadedAvatarPath != null) {
        await _repository.deleteAvatar(uploadedAvatarPath).catchError((_) {});
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存失败：$error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('个人信息')),
      body: FutureBuilder<AppProfile?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          }

          return MaxWidthContainer(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 56,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        backgroundImage: _avatarImageProvider(),
                        child: _avatarImageProvider() == null
                            ? Icon(
                                Icons.person,
                                size: 56,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              )
                            : null,
                      ),
                      IconButton.filled(
                        onPressed: _isUploadingAvatar || _isSaving
                            ? null
                            : _pickAvatar,
                        icon: _isUploadingAvatar
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.photo_camera_outlined),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: '用户名',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  snapshot.data?.email ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _isSaving || _isUploadingAvatar ? null : _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(_isSaving ? '保存中...' : '保存'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  ImageProvider? _avatarImageProvider() {
    final bytes = _selectedAvatarBytes;
    if (bytes != null) return MemoryImage(bytes);
    final url = _avatarUrl;
    if (url != null && url.isNotEmpty) return NetworkImage(url);
    return null;
  }
}
