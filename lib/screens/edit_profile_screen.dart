import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentUsername;
  final String? currentAvatar;

  const EditProfileScreen({
    Key? key,
    required this.currentUsername,
    required this.currentAvatar,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _usernameController = TextEditingController();

  File? _imageFile;
  String? avatarUrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.currentUsername;
    avatarUrl = widget.currentAvatar;
  }

  // 📸 selecionar imagem
  Future<void> pickImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  // ☁️ upload imagem
  Future<String?> uploadImage(File file) async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final filePath = '${user.id}/avatar.jpg';

    await supabase.storage.from('avatars').upload(
          filePath,
          file,
          fileOptions: const FileOptions(upsert: true),
        );

    return supabase.storage.from('avatars').getPublicUrl(filePath);
  }

  // 💾 salvar tudo
  Future<void> saveProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    try {
      String? newAvatar = avatarUrl;

      if (_imageFile != null) {
        newAvatar = await uploadImage(_imageFile!);
      }

      await supabase.from('profiles').update({
        'username': _usernameController.text.trim(),
        'avatar_url': newAvatar,
      }).eq('id', user.id);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('ERRO PROFILE SAVE: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFF39FF14),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : (avatarUrl != null
                        ? NetworkImage(avatarUrl!)
                        : const NetworkImage(
                            'https://i.imgur.com/3fJ1P4b.png')) as ImageProvider,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Toque para alterar foto',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39FF14),
              ),
              onPressed: _loading ? null : saveProfile,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text(
                      'Salvar',
                      style: TextStyle(color: Colors.black),
                    ),
            )
          ],
        ),
      ),
    );
  }
}