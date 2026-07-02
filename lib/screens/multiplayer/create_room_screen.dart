// lib/screens/multiplayer/create_room_screen.dart
// Écran de création d'une room multijoueur.
//
// Formulaire avec :
//   - Nom du joueur (prenom)
//   - Matière (dropdown parmi 7 matières BEPC/BAC)
//   - Nombre de questions (5 / 10 / 15) — boutons radio
//   - Mode (compétitif / coopératif) — toggle
//   - Visibilité (publique / privée) — toggle
//   - Bouton "Créer la room"
//
// À la validation, on appelle MultiplayerSocketService.createRoom(...)
// puis on navigue vers le lobby.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import 'models/multiplayer_room.dart';
import 'multiplayer_lobby_screen.dart';
import 'services/multiplayer_socket_service.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _matiere = 'maths';
  int _nbQuestions = 10;
  MultiplayerMode _mode = MultiplayerMode.competitive;
  MultiplayerVisibility _visibility = MultiplayerVisibility.public;
  bool _creating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _creating = true);
    final svc = context.read<MultiplayerSocketService>();
    await svc.createRoom(
      matiere: _matiere,
      nbQuestions: _nbQuestions,
      mode: _mode,
      visibility: _visibility,
      playerName: _nameController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _creating = false);

    if (svc.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(svc.errorMessage!),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Navigue vers le lobby (remplace l'écran de création).
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const MultiplayerLobbyScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('Créer une room'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ton prenom
                _SectionLabel(text: 'Ton prénom', icon: Icons.person_outline),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Ex : Kossi',
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Entre ton prénom';
                    }
                    if (v.trim().length < 2) {
                      return 'Au moins 2 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Matière
                _SectionLabel(text: 'Matière', icon: Icons.book_outlined),
                const SizedBox(height: 8),
                _SubjectPicker(
                  selected: _matiere,
                  onChanged: (id) => setState(() => _matiere = id),
                ),
                const SizedBox(height: 20),

                // Nombre de questions
                _SectionLabel(
                    text: 'Nombre de questions',
                    icon: Icons.format_list_numbered),
                const SizedBox(height: 8),
                _NbQuestionsPicker(
                  selected: _nbQuestions,
                  onChanged: (n) => setState(() => _nbQuestions = n),
                ),
                const SizedBox(height: 20),

                // Mode
                _SectionLabel(
                    text: 'Mode de jeu', icon: Icons.sports_esports),
                const SizedBox(height: 8),
                _ModePicker(
                  selected: _mode,
                  onChanged: (m) => setState(() => _mode = m),
                ),
                const SizedBox(height: 20),

                // Visibilité
                _SectionLabel(
                    text: 'Visibilité', icon: Icons.lock_outline),
                const SizedBox(height: 8),
                _VisibilityPicker(
                  selected: _visibility,
                  onChanged: (v) => setState(() => _visibility = v),
                ),
                const SizedBox(height: 28),

                // Bouton créer
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _creating ? null : _create,
                    icon: _creating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add),
                    label: Text(
                      _creating ? 'Création...' : 'Créer la room',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Label de section ───────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  final IconData icon;

  const _SectionLabel({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppTextStyles.label.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// ─── Sélecteur de matière ───────────────────────────────────────────
class _SubjectPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _SubjectPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MultiplayerSubject.all.map((s) {
        final isSelected = s.id == selected;
        return ChoiceChip(
          label: Text(s.label),
          selected: isSelected,
          onSelected: (_) => onChanged(s.id),
          avatar: Icon(_iconData(s.icon), size: 18),
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          backgroundColor: AppColors.surfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        );
      }).toList(),
    );
  }

  IconData _iconData(String name) {
    const map = {
      'calculate': Icons.calculate,
      'menu_book': Icons.menu_book,
      'psychology': Icons.psychology,
      'science': Icons.science,
      'biotech': Icons.biotech,
      'public': Icons.public,
      'translate': Icons.translate,
    };
    return map[name] ?? Icons.book;
  }
}

// ─── Sélecteur nombre de questions ──────────────────────────────────
class _NbQuestionsPicker extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _NbQuestionsPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = [5, 10, 15];
    return Row(
      children: options.map((n) {
        final isSelected = n == selected;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onChanged(n),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.divider,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '$n',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'questions',
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected
                            ? Colors.white70
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Sélecteur de mode ──────────────────────────────────────────────
class _ModePicker extends StatelessWidget {
  final MultiplayerMode selected;
  final ValueChanged<MultiplayerMode> onChanged;

  const _ModePicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeCard(
            icon: Icons.flag,
            title: 'Compétitif',
            subtitle: 'Chacun pour soi',
            color: AppColors.primary,
            isSelected: selected == MultiplayerMode.competitive,
            onTap: () => onChanged(MultiplayerMode.competitive),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ModeCard(
            icon: Icons.handshake,
            title: 'Coopératif',
            subtitle: 'Équipe',
            color: AppColors.accent,
            isSelected: selected == MultiplayerMode.cooperative,
            onTap: () => onChanged(MultiplayerMode.cooperative),
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.10) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isSelected ? color : AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sélecteur de visibilité ────────────────────────────────────────
class _VisibilityPicker extends StatelessWidget {
  final MultiplayerVisibility selected;
  final ValueChanged<MultiplayerVisibility> onChanged;

  const _VisibilityPicker({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _VisTile(
              icon: Icons.public,
              title: 'Publique',
              subtitle: 'Visible par tous',
              isSelected: selected == MultiplayerVisibility.public,
              onTap: () => onChanged(MultiplayerVisibility.public),
            ),
          ),
          Expanded(
            child: _VisTile(
              icon: Icons.lock,
              title: 'Privée',
              subtitle: 'Code uniquement',
              isSelected: selected == MultiplayerVisibility.private,
              onTap: () => onChanged(MultiplayerVisibility.private),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _VisTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
