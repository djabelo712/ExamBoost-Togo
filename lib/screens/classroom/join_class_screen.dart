// lib/screens/classroom/join_class_screen.dart
// Ecran eleve : saisir le code a 6 chiffres + son prenom pour rejoindre.
//
// Etapes :
//   1. Saisie du code (6 cases style OTP)
//   2. Validation : code a 6 chiffres uniquement
//   3. Saisie du prenom (si pas deja en SharedPreferences)
//   4. Connexion WebSocket -> navigation vers StudentLiveQuizScreen
//
// Si la session est introuvable : snackbar + retour sur la saisie.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/app_logger.dart';
import 'models/classroom_player.dart';
import 'models/classroom_session.dart';
import 'services/classroom_socket_service.dart';
import 'services/classroom_rest_service.dart';
import 'student_live_quiz_screen.dart';

class JoinClassScreen extends StatefulWidget {
  const JoinClassScreen({super.key});

  @override
  State<JoinClassScreen> createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends State<JoinClassScreen> {
  final _codeControllers = List<TextEditingController>.generate(
    6,
    (_) => TextEditingController(),
  );
  final _focusNodes = List<FocusNode>.generate(6, (_) => FocusNode());
  final _nameController = TextEditingController();

  String _playerName = '';
  bool _checking = false;
  bool _showNameStep = false;

  // URL backend par defaut (10.0.2.2 = localhost depuis emulateur Android)
  // En prod, recuperer depuis config / environment.
  static const _defaultBaseUrl = 'http://10.0.2.2:8000';
  static const _defaultWsUrl = 'ws://10.0.2.2:8000';

  @override
  void initState() {
    super.initState();
    _loadSavedName();
  }

  @override
  void dispose() {
    for (final c in _codeControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedName() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('classroom_player_name');
    if (saved != null && saved.isNotEmpty && mounted) {
      setState(() {
        _playerName = saved;
        _nameController.text = saved;
      });
    }
  }

  String get _code => _codeControllers.map((c) => c.text).join();

  bool get _isCodeComplete =>
      _code.length == 6 && _code.every((c) => int.tryParse(c) != null);

  void _onCodeChanged(int index, String value) {
    if (value.length > 1) {
      // Coller plusieurs caractères -> distribuer
      final chars = value.split('');
      for (var i = 0; i < chars.length && (index + i) < 6; i++) {
        _codeControllers[index + i].text = chars[i];
      }
      final nextIndex = (index + chars.length).clamp(0, 5);
      _focusNodes[nextIndex].requestFocus();
      return;
    }
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  void _onCodeBackspace(int index, String value) {
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
      _codeControllers[index - 1].clear();
      setState(() {});
    }
  }

  Future<void> _verifyAndJoin() async {
    if (!_isCodeComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saisis un code a 6 chiffres'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _checking = true);

    try {
      final rest = ClassroomRestService();
      final status = await rest.getStatus(
        baseUrl: _defaultBaseUrl,
        code: _code,
      );

      if (!status.exists || status.status == ClassroomStatus.ended) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                status.status == ClassroomStatus.ended
                    ? 'Session terminee. Demande un nouveau code a ton enseignant.'
                    : 'Session introuvable. Verifie le code saisi.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
        setState(() => _checking = false);
        return;
      }

      // Session valide -> etape nom (si non deja connu)
      if (_playerName.isEmpty) {
        setState(() {
          _showNameStep = true;
          _checking = false;
        });
        _focusNodes.first.unfocus();
      } else {
        setState(() => _checking = false);
        _connectAndNavigate();
      }
    } catch (e) {
      AppLogger.error('Erreur verification session: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connexion impossible : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _checking = false);
    }
  }

  Future<void> _connectAndNavigate() async {
    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : _playerName;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saisis ton prenom'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Sauvegarde le nom pour la prochaine fois
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('classroom_player_name', name);

    setState(() => _checking = true);

    // Cree le service et connecte
    final service = ClassroomSocketService();
    await service.connect(
      baseUrl: _defaultWsUrl,
      sessionCode: _code,
      playerName: name,
      role: PlayerRole.student,
    );

    if (!mounted) {
      service.dispose();
      return;
    }

    // Attend 1.5s pour laisser la WS confirmer la connexion
    await Future.delayed(const Duration(milliseconds: 1500));

    if (service.connectionState == ClassroomConnectionState.error ||
        service.connectionState == ClassroomConnectionState.disconnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              service.errorMessage ?? 'Connexion impossible',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      service.dispose();
      setState(() => _checking = false);
      return;
    }

    if (!mounted) {
      service.dispose();
      return;
    }

    // Fournit le service via Provider pour l'ecran suivant
    setState(() => _checking = false);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: service,
          child: StudentLiveQuizScreen(
            sessionCode: _code,
            playerName: name,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Rejoindre une classe')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _showNameStep ? _buildNameStep() : _buildCodeStep(),
        ),
      ),
    );
  }

  // ─── Etape 1 : saisie du code ──────────────────────────────────
  Widget _buildCodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Icon(Icons.qr_code_scanner,
                  size: 56, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                'Saisis le code a 6 chiffres',
                style: AppTextStyles.h2.copyWith(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Demande le code a ton enseignant.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // 6 cases OTP
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (i) {
            return SizedBox(
              width: 48,
              height: 64,
              child: TextField(
                controller: _codeControllers[i],
                focusNode: _focusNodes[i],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: AppTextStyles.h2.copyWith(fontSize: 26),
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _isCodeComplete
                          ? AppColors.primary
                          : AppColors.divider,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 2),
                  ),
                ),
                onChanged: (v) => _onCodeChanged(i, v),
                onTap: () {
                  if (_codeControllers[i].text.isNotEmpty) {
                    _codeControllers[i].selection =
                        TextSelection.fromPosition(
                      TextPosition(offset: 0),
                    );
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _checking || !_isCodeComplete
                ? null
                : _verifyAndJoin,
            icon: _checking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.login),
            label: Text(_checking ? 'Verification...' : 'Rejoindre'),
          ),
        ),
      ],
    );
  }

  // ─── Etape 2 : saisie du nom ───────────────────────────────────
  Widget _buildNameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Icon(Icons.person_add, size: 56, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                'Comment t\'appelles-tu ?',
                style: AppTextStyles.h2.copyWith(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Code session : $_code',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Prenom (et nom)',
            hintText: 'Ex : Awa Koffi',
            prefixIcon: Icon(Icons.person_outline),
          ),
          onSubmitted: (_) => _connectAndNavigate(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _checking ? null : _connectAndNavigate,
            icon: _checking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.login),
            label: Text(_checking
                ? 'Connexion...'
                : 'Rejoindre la session $_code'),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _showNameStep = false;
              for (final c in _codeControllers) {
                c.clear();
              }
              _focusNodes.first.requestFocus();
            });
          },
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Revenir a la saisie du code'),
        ),
      ],
    );
  }
}
