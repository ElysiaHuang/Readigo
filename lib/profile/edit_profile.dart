import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:testapp3/landing.dart';
import 'package:testapp3/util/constants.dart';
import 'package:testapp3/util/profile_avatar_options.dart';

import '../util/firebase_utils.dart';
import '../util/google_services.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String friendCode;

  const EditProfilePage({
    super.key,
    required this.userData,
    required this.friendCode,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late String selectedProfilePic;
  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.userData["username"] ?? "";
    _bioController.text = widget.userData["bio"] ?? "";
    selectedProfilePic =
        widget.userData["profilePic"]?.toString().isNotEmpty == true
            ? widget.userData["profilePic"].toString()
            : defaultProfileAvatar;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final newData = <String, dynamic>{};
    final newUsername = _usernameController.text.trim();
    final newBio = _bioController.text.trim();

    if (newUsername != widget.userData["username"]) {
      newData["username"] = newUsername;
    }
    if (newBio != widget.userData["bio"]) {
      newData["bio"] = newBio;
    }
    if (selectedProfilePic != widget.userData["profilePic"]) {
      newData["profilePic"] = selectedProfilePic;
    }

    try {
      if (newData.isNotEmpty) {
        await FirebaseUtils.updateUser(widget.friendCode, newData);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved.')));
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  ImageProvider _getProfileImageProvider(String imageValue) {
    if (imageValue.isEmpty) {
      return const AssetImage(defaultProfileAvatar);
    }
    if (imageValue.startsWith('assets/')) {
      return AssetImage(resolvedProfileAvatar(imageValue));
    }
    if (imageValue.startsWith('http')) {
      return NetworkImage(imageValue);
    }
    if (File(imageValue).existsSync()) {
      return FileImage(File(imageValue));
    }
    return const AssetImage(defaultProfileAvatar);
  }

  Future<void> _showDeleteAccountDialog() async {
    if (_deleting) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final useGoogle = user.providerData.any(
      (provider) => provider.providerId == 'google.com',
    );
    String password = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Delete account'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  useGoogle
                      ? 'Confirm with Google to delete your account, library, and conversations.'
                      : 'Enter your password to delete your account, library, and conversations.',
                ),
                if (!useGoogle)
                  TextField(
                    obscureText: true,
                    onChanged: (value) => password = value,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      final credential =
          useGoogle
              ? await GoogleServices.credential()
              : EmailAuthProvider.credential(
                email: user.email!,
                password: password,
              );
      await user.reauthenticateWithCredential(credential);
      await user.getIdToken(true);
      await FirebaseUtils.deleteUser(widget.friendCode);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LandingPage()),
        (_) => false,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deletion did not finish. You can retry. $error'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Widget _buildAvatarPreview(String assetPath, {double size = 96}) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Constants.border, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Image.asset(
        resolvedProfileAvatar(assetPath),
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) => Container(
              color: Constants.sky.withValues(alpha: 0.18),
              alignment: Alignment.center,
              child: const Icon(
                Icons.pets_rounded,
                color: Constants.ink,
                size: 28,
              ),
            ),
      ),
    );
  }

  Widget _buildAvatarChoice(ProfileAvatarOption avatar) {
    final isSelected = selectedProfilePic == avatar.assetPath;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            _saving
                ? null
                : () {
                  setState(() {
                    selectedProfilePic = avatar.assetPath;
                  });
                },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? Constants.sky.withValues(alpha: 0.22)
                    : Constants.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? Constants.ink : Constants.border,
              width: isSelected ? 2 : 1.2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAvatarPreview(avatar.assetPath, size: 54),
              const SizedBox(height: 8),
              Text(
                avatar.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Constants.ink : Constants.mutedInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.background,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 110),
          children: [
            _buildProfileCard(),
            const SizedBox(height: 14),
            _buildDetailsCard(),
            const SizedBox(height: 14),
            _buildDangerCard(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.ink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child:
                  _saving
                      ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text(
                        "Save",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Constants.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Constants.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Avatar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Constants.ink,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 96,
                height: 96,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Constants.border, width: 1.4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Image(
                  image: _getProfileImageProvider(selectedProfilePic),
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Container(
                        color: Constants.sky.withValues(alpha: 0.18),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.pets_rounded,
                          color: Constants.ink,
                          size: 28,
                        ),
                      ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Tap an animal below to change your profile picture.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Constants.mutedInk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 420 ? 4 : 3;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: profileAvatarOptions.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.86,
                ),
                itemBuilder:
                    (context, index) =>
                        _buildAvatarChoice(profileAvatarOptions[index]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Constants.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Constants.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Constants.ink,
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Username cannot be empty';
              }
              if (value.length < 3) return 'Minimum 3 characters';
              if (value.length > 40) return 'Maximum 40 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bioController,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Bio',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Constants.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Delete account',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Constants.ink,
              ),
            ),
          ),
          TextButton(
            onPressed: _deleting ? null : _showDeleteAccountDialog,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
