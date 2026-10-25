class ProfileAvatarOption {
  final String assetPath;
  final String label;

  const ProfileAvatarOption({required this.assetPath, required this.label});
}

const String legacyBlueCatAvatar = 'assets/images/avatars/cat.png';
const String defaultProfileAvatar = 'assets/images/reading_cat.png';

/// Existing profiles stored the old blue cat path. Keep those profiles valid
/// while showing the new companion everywhere in the app.
String resolvedProfileAvatar(String assetPath) {
  return assetPath == legacyBlueCatAvatar ? defaultProfileAvatar : assetPath;
}

const List<ProfileAvatarOption> profileAvatarOptions = [
  ProfileAvatarOption(assetPath: defaultProfileAvatar, label: 'Reading Cat'),
  ProfileAvatarOption(
    assetPath: 'assets/images/avatars/zebra.png',
    label: 'Zebra',
  ),
  ProfileAvatarOption(
    assetPath: 'assets/images/avatars/lion.png',
    label: 'Lion',
  ),
  ProfileAvatarOption(
    assetPath: 'assets/images/avatars/snake.png',
    label: 'Snake',
  ),
  ProfileAvatarOption(
    assetPath: 'assets/images/avatars/rabbit.png',
    label: 'Rabbit',
  ),
  ProfileAvatarOption(
    assetPath: 'assets/images/avatars/horse.png',
    label: 'Horse',
  ),
  ProfileAvatarOption(assetPath: 'assets/images/avatars/dog.png', label: 'Dog'),
  ProfileAvatarOption(
    assetPath: 'assets/images/avatars/giraffe.png',
    label: 'Giraffe',
  ),
  ProfileAvatarOption(
    assetPath: 'assets/images/avatars/polar-bear.png',
    label: 'Bear',
  ),
];
