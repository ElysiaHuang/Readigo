import 'package:flutter/material.dart';
import '../util/firebase_utils.dart';  // adjust import

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

  final List<String> profilePicOptions = [
    "https://imgcdn.stablediffusionweb.com/2024/4/15/437c2a91-01ea-4d6b-b7c4-d489155207f7.jpg",
    "https://creator.nightcafe.studio/jobs/kWGLUgAwkj1kLLvcqvJD/kWGLUgAwkj1kLLvcqvJD--1--kgpmj.jpg",
    "https://imgcdn.stablediffusionweb.com/2024/2/23/da8fbab2-4c52-469c-8f91-437b89850f61.jpg",
    "https://creator.nightcafe.studio/jobs/UpYqKstniHmSEMYpoRnA/UpYqKstniHmSEMYpoRnA--3--ahniu.jpg"
  ];

  @override
  void initState() {
    super.initState();

    _usernameController.text = widget.userData["username"] ?? "";
    _bioController.text = widget.userData["bio"] ?? "";
    selectedProfilePic = widget.userData["profilePic"] ?? profilePicOptions.first;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final newData = <String, dynamic>{};

    final newUsername = _usernameController.text.trim();
    final newBio = _bioController.text.trim();

    // Only add fields that changed
    if (newUsername != widget.userData["username"]) {
      newData["username"] = newUsername;
    }
    if (newBio != widget.userData["bio"]) {
      newData["bio"] = newBio;
    }
    if (selectedProfilePic != widget.userData["profilePic"]) {
      newData["profilePic"] = selectedProfilePic;
    }

    if (newData.isNotEmpty) {
      await FirebaseUtils.updateUser(widget.friendCode, newData);
    }

    setState(() => _saving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile saved!")),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Username cannot be empty';
                  }
                  if (value.length < 3) return 'Minimum 3 characters';
                  if (value.length > 15) return 'Maximum 15 characters';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _bioController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                "Choose Profile Picture",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: profilePicOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final url = profilePicOptions[index];
                    final isSelected = url == selectedProfilePic;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedProfilePic = url;
                        });
                      },
                      child: Stack(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey,
                                width: isSelected ? 3 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: NetworkImage(url),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),

      // ▶ SAVE BUTTON AT THE BOTTOM
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveProfile,
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Save Changes"),
            ),
          ),
        ),
      ),
    );
  }
}
