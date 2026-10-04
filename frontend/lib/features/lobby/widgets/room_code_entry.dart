import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RoomCodeEntry extends StatefulWidget {
  /// If provided, displays this room code (host mode). Otherwise shows input.
  final String? roomCode;
  final void Function(String code)? onCodeSubmitted;

  const RoomCodeEntry({
    super.key,
    this.roomCode,
    this.onCodeSubmitted,
  });

  @override
  State<RoomCodeEntry> createState() => _RoomCodeEntryState();
}

class _RoomCodeEntryState extends State<RoomCodeEntry> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _copied = false;
  bool _hasError = false;

  static const int _codeLength = 6;

  @override
  void initState() {
    super.initState();
    if (widget.roomCode != null) {
      _controller.text = widget.roomCode!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _isDisplayMode => widget.roomCode != null;

  String get _displayCode =>
      _isDisplayMode ? widget.roomCode! : _controller.text.toUpperCase();

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _displayCode));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _shareCode() async {
    // In production use share_plus package
    await Clipboard.setData(ClipboardData(text: 'Join my WildDeck game! Code: $_displayCode'));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share link copied to clipboard!'),
        backgroundColor: Color(0xFF2E7D32),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleJoin() {
    final code = _controller.text.toUpperCase().trim();
    if (code.length != _codeLength) {
      setState(() => _hasError = true);
      return;
    }
    setState(() => _hasError = false);
    widget.onCodeSubmitted?.call(code);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isDisplayMode) _buildDisplayMode() else _buildInputMode(),
      ],
    );
  }

  Widget _buildDisplayMode() {
    return Column(
      children: [
        const Text(
          'Room Code',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE53935), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _displayCode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _copyToClipboard,
                icon: Icon(
                  _copied ? Icons.check : Icons.copy,
                  size: 18,
                  color: _copied
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFE53935),
                ),
                label: Text(
                  _copied ? 'Copied!' : 'Copy',
                  style: TextStyle(
                    color: _copied
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFE53935),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _copied
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFE53935),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shareCode,
                icon: const Icon(
                  Icons.share,
                  size: 18,
                  color: Colors.white70,
                ),
                label: const Text(
                  'Share',
                  style: TextStyle(color: Colors.white70),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white30),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputMode() {
    return Column(
      children: [
        const Text(
          'Enter Room Code',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          textCapitalization: TextCapitalization.characters,
          maxLength: _codeLength,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 6,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '------',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.15),
              fontSize: 24,
              letterSpacing: 6,
            ),
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _hasError
                    ? const Color(0xFFE53935)
                    : Colors.white24,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFFE53935), width: 1.5),
            ),
            errorText: _hasError ? 'Code must be 6 characters' : null,
            errorStyle: const TextStyle(
              color: Color(0xFFE57373),
              fontSize: 11,
            ),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            TextInputFormatter.withFunction((oldValue, newValue) {
              return newValue.copyWith(
                text: newValue.text.toUpperCase(),
              );
            }),
          ],
          onChanged: (value) {
            if (_hasError && value.length == _codeLength) {
              setState(() => _hasError = false);
            }
          },
          onSubmitted: (_) => _handleJoin(),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleJoin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Join Game',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
