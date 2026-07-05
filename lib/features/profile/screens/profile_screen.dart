import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:sign/features/auth/screens/login_screen.dart';
import 'package:sign/features/profile/screens/help_feedback_screen.dart';
import 'package:sign/features/profile/screens/personal_info_screen.dart';
import 'package:sign/features/profile/screens/settings_screen.dart';
import 'package:sign/models/app_profile.dart';
import 'package:sign/repositories/sign_repository.dart';
import 'package:sign/shared/ui/card_style.dart';
import 'package:sign/shared/ui/responsive_layout.dart';

class ProfileScreen extends StatefulWidget {
  final bool isAdmin;

  const ProfileScreen({super.key, this.isAdmin = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _repository = SignRepository();
  late Future<AppProfile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _reloadProfile(preferCache: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshProfile());
  }

  void _reloadProfile({bool preferCache = false}) {
    _profileFuture = _repository.fetchCurrentProfile(preferCache: preferCache);
  }

  Future<void> _refreshProfile() async {
    try {
      final profile = await _repository.fetchCurrentProfile();
      if (!mounted) return;
      setState(() {
        _profileFuture = Future.value(profile);
      });
    } catch (_) {}
  }

  Future<void> _logout(BuildContext context) async {
    await _repository.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('账户'), centerTitle: true),
      body: FutureBuilder<AppProfile?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data;
          final isAdmin = profile?.isAdmin ?? widget.isAdmin;

          return MaxWidthContainer(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: _buildAvatar(context, profile, isAdmin),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile?.displayName ?? (isAdmin ? '管理员' : '普通用户'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile?.email ?? '',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAdmin ? '管理员' : '普通用户',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Card(
                    elevation: 0,
                    color: AppCardStyle.background(context),
                    shape: AppCardStyle.shape(context),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: const Text('个人信息'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openPersonalInfo(context),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.settings_outlined),
                          title: const Text('设置'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.help_outline),
                          title: const Text('帮助与反馈'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const HelpFeedbackScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout),
                      label: const Text('退出登录'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.errorContainer,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openPersonalInfo(BuildContext context) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const PersonalInfoScreen()),
    );
    if (changed == true && mounted) {
      setState(_reloadProfile);
    }
  }

  Widget _buildAvatar(BuildContext context, AppProfile? profile, bool isAdmin) {
    final avatarPath = profile?.avatarUrl;
    if (avatarPath == null || avatarPath.isEmpty) {
      return Icon(
        isAdmin ? Icons.admin_panel_settings : Icons.person,
        size: 50,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      );
    }

    return FutureBuilder<String>(
      future: _repository.createAvatarUrl(avatarPath),
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (url == null || url.isEmpty) {
          return Icon(
            isAdmin ? Icons.admin_panel_settings : Icons.person,
            size: 50,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          );
        }

        return ClipOval(
          child: CachedNetworkImage(
            imageUrl: url,
            cacheKey: avatarPath,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) {
              return Icon(
                isAdmin ? Icons.admin_panel_settings : Icons.person,
                size: 50,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              );
            },
          ),
        );
      },
    );
  }
}
