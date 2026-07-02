// lib/screens/multiplayer/join_room_screen.dart
// Écran pour rejoindre une room multijoueur.
//
// Deux possibilités :
//   1. Entrer un code à 6 chiffres (champ dédié)
//   2. Choisir une room publique parmi une liste mock (démo)
//
// À la validation, on appelle MultiplayerSocketService.joinRoom(...)
// puis on navigue vers le lobby.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import 'models/multiplayer_room.dart';
import 'multiplayer_lobby_screen.dart';
import 'services/multiplayer_socket_service.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _joining = false;

  // Liste de rooms publiques mock pour la démo.
  // En production, viendrait d'un endpoint GET /multiplayer/rooms/public.
  final List<_PublicRoom> _publicRooms = const [
    _PublicRoom(
      code: '482917',
      host: 'Aya',
      matiere: 'maths',
      matiereLabel: 'Mathématiques',
      playersCount: 3,
      maxPlayers: 6,
      mode: MultiplayerMode.competitive,
    ),
    _PublicRoom(
      code: '105832',
      host: 'Komlan',
      matiere: 'francais',
      matiereLabel: 'Français',
      playersCount: 5,
      maxPlayers: 6,
      mode: MultiplayerMode.cooperative,
    ),
    _PublicRoom(
      code: '773041',
      host: 'Délali',
      matiere: 'pc',
      matiereLabel: 'Physique-Chimie',
      playersCount: 2,
      maxPlayers: 6,
      mode: MultiplayerMode.competitive,
    ),
    _PublicRoom(
      code: '318654',
      host: 'Mawuko',
      matiere: 'svt',
      matiereLabel: 'SVT',
      playersCount: 4,
      maxPlayers: 6,
      mode: MultiplayerMode.competitive,
    ),
  ];

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _joinWithCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _joining = true);
    final svc = context.read<MultiplayerSocketService>();
    await svc.joinRoom(
      code: _codeController.text.trim(),
      playerName: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _joining = false);

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

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MultiplayerLobbyScreen()),
    );
  }

  Future<void> _joinPublicRoom(_PublicRoom r) async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entre ton prénom d\'abord'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    setState(() => _joining = true);
    final svc = context.read<MultiplayerSocketService>();
    await svc.joinRoom(
      code: r.code,
      playerName: _nameController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _joining = false);

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

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MultiplayerLobbyScreen()),
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
        title: const Text('Rejoindre une room'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ton prénom
                _SectionLabel(text: 'Ton prénom', icon: Icons.person_outline),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Ex : Aya',
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Entre ton prénom';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // ── Bloc 1 : rejoindre avec un code
                _SectionLabel(
                    text: 'Avec un code', icon: Icons.dialpad_outlined),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    hintText: '123 456',
                    prefixIcon: const Icon(Icons.vpn_key),
                    counterText: '',
                    hintStyle: const TextStyle(
                      letterSpacing: 8,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    letterSpacing: 8,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLength: 6,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Entre un code à 6 chiffres';
                    }
                    if (v.trim().length != 6) {
                      return 'Le code doit faire 6 chiffres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _joining ? null : _joinWithCode,
                    icon: _joining
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.login),
                    label: const Text('Rejoindre'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                const SizedBox(height: 28),
                // Séparateur
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OU',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Bloc 2 : rooms publiques
                _SectionLabel(
                    text: 'Rooms publiques',
                    icon: Icons.public_outlined),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Choisis une room ouverte et rejoins-la directement.',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
                ..._publicRooms.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PublicRoomTile(
                        room: r,
                        onTap: () => _joinPublicRoom(r),
                      ),
                    )),
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

// ─── Modèle interne pour rooms publiques mock ───────────────────────
class _PublicRoom {
  final String code;
  final String host;
  final String matiere;
  final String matiereLabel;
  final int playersCount;
  final int maxPlayers;
  final MultiplayerMode mode;

  const _PublicRoom({
    required this.code,
    required this.host,
    required this.matiere,
    required this.matiereLabel,
    required this.playersCount,
    required this.maxPlayers,
    required this.mode,
  });
}

// ─── Tuile room publique ────────────────────────────────────────────
class _PublicRoomTile extends StatelessWidget {
  final _PublicRoom room;
  final VoidCallback onTap;

  const _PublicRoomTile({required this.room, required this.onTap});

  IconData _subjectIcon(String id) {
    const map = {
      'maths': Icons.calculate,
      'francais': Icons.menu_book,
      'philo': Icons.psychology,
      'pc': Icons.science,
      'svt': Icons.biotech,
      'hg': Icons.public,
      'anglais': Icons.translate,
    };
    return map[id] ?? Icons.book;
  }

  @override
  Widget build(BuildContext context) {
    final isCoop = room.mode == MultiplayerMode.cooperative;
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Icône matière
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _subjectIcon(room.matiere),
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.matiereLabel,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 12,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Hôte : ${room.host}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.group_outlined,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${room.playersCount}/${room.maxPlayers}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Badge mode
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: isCoop
                      ? AppColors.accentSurface
                      : AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isCoop ? 'Coop' : 'Comp',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isCoop ? AppColors.accent : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
