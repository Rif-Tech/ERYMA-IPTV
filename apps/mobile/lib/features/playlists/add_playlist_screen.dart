import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/portal_api.dart';
import '../../core/db/database.dart';
import '../../core/device/device_identity.dart';
import '../../core/settings/settings.dart';
import '../../core/xtream/xtream_client.dart';
import '../../l10n/generated/app_localizations.dart';
import 'playlists_provider.dart';

/// Creates a playlist, or edits an existing local one when [editId] is set.
class AddPlaylistScreen extends ConsumerStatefulWidget {
  const AddPlaylistScreen({super.key, required this.xtream, this.editId});
  final bool xtream;
  final String? editId;

  @override
  ConsumerState<AddPlaylistScreen> createState() => _AddPlaylistScreenState();
}

class _AddPlaylistScreenState extends ConsumerState<AddPlaylistScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _url = TextEditingController();
  final _epg = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _pin = TextEditingController();
  bool _protect = false;
  bool _busy = false;
  bool _obscure = true;
  late bool _xtream = _xtream;
  Playlist? _editing;

  bool get _isEdit => widget.editId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _load();
  }

  Future<void> _load() async {
    final p = await ref.read(databaseProvider).getPlaylist(widget.editId!);
    if (p == null || !mounted) return;
    setState(() {
      _editing = p;
      _xtream = p.type == PlaylistType.xtream;
      _name.text = p.name;
      _url.text = p.url;
      _epg.text = p.epgUrl ?? '';
      _user.text = p.username ?? '';
      _pass.text = p.password ?? '';
      _protect = p.isProtected;
      _pin.text = p.pinCode ?? '';
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _url, _epg, _user, _pass, _pin]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    final path = result?.files.single.path;
    if (path == null) return;
    setState(() {
      _url.text = Uri.file(path).toString();
      if (_name.text.isEmpty) _name.text = result!.files.single.name;
    });
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    final local = ref.read(localPlaylistsProvider);
    final pin = _protect ? _pin.text.trim() : null;
    try {
      final Playlist playlist;
      if (_editing != null && _editing!.source == PlaylistSource.portal) {
        playlist = await _updatePortal(_editing!, pin);
      } else if (_editing != null) {
        playlist = await local.update(
          _editing!,
          name: _name.text.trim(),
          url: _xtream ? normalizeXtreamBaseUrl(_url.text) : _url.text.trim(),
          username: _xtream ? _user.text.trim() : null,
          password: _xtream ? _pass.text : null,
          epgUrl: _xtream ? null : _epg.text.trim(),
          pin: pin,
        );
      } else {
        playlist = _xtream
            ? await local.addXtream(
                name: _name.text.trim(),
                serverUrl: normalizeXtreamBaseUrl(_url.text),
                username: _user.text.trim(),
                password: _pass.text,
                pin: pin,
              )
            : await _addM3u(local, pin);
      }
      await ref.read(settingsProvider.notifier).setActivePlaylistId(playlist.id);
      if (!mounted) return;
      context.go(Routes.import(playlist.id));
    } on PortalApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Portal playlists are the source of truth on the server: update there, then mirror locally.
  Future<Playlist> _updatePortal(Playlist p, String? pin) async {
    final device = await ref.read(deviceIdentityProvider.future);
    await ref.read(portalApiProvider).updatePlaylist(device, p.id.replaceFirst('portal-', ''), {
      'name': _name.text.trim(),
      'type': _xtream ? 'xtream' : 'm3u',
      'url': _xtream ? normalizeXtreamBaseUrl(_url.text) : _url.text.trim(),
      'username': _xtream ? _user.text.trim() : null,
      'password': _xtream ? _pass.text : null,
      'epg_url': _xtream ? null : (_epg.text.trim().isEmpty ? null : _epg.text.trim()),
      'is_protected': pin != null && pin.isNotEmpty,
      'pin_code': pin,
    });
    await ref.read(deviceSessionProvider.notifier).refresh();
    return (await ref.read(databaseProvider).getPlaylist(p.id)) ?? p;
  }

  Future<Playlist> _addM3u(LocalPlaylists local, String? pin) {
    // A get.php URL is really an Xtream account: store it as such to unlock VOD/series/EPG.
    final creds = credentialsFromM3uUrl(_url.text);
    if (creds != null) {
      return local.addXtream(
        name: _name.text.trim(),
        serverUrl: creds.baseUrl,
        username: creds.username,
        password: creds.password,
        pin: pin,
      );
    }
    return local.addM3u(name: _name.text.trim(), url: _url.text.trim(), epgUrl: _epg.text.trim(), pin: pin);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? l10n.editPlaylist : (_xtream ? l10n.addXtream : l10n.addM3u))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  decoration: InputDecoration(labelText: l10n.playlistName),
                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _url,
                  decoration: InputDecoration(
                    labelText: _xtream ? l10n.serverUrl : l10n.playlistUrl,
                    hintText: _xtream ? l10n.serverUrlHint : 'http://…/playlist.m3u',
                    suffixIcon: _xtream
                        ? null
                        : IconButton(tooltip: l10n.addM3uFile, icon: const Icon(Icons.folder_open), onPressed: _pickFile),
                  ),
                  keyboardType: TextInputType.url,
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return l10n.fieldRequired;
                    if (_xtream) return null;
                    final uri = Uri.tryParse(s);
                    if (uri == null || (!uri.hasScheme)) return l10n.invalidUrl;
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                if (_xtream) ...[
                  TextFormField(
                    controller: _user,
                    decoration: InputDecoration(labelText: l10n.username),
                    validator: (v) => (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pass,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: l10n.password,
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? l10n.fieldRequired : null,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                ] else
                  TextFormField(
                    controller: _epg,
                    decoration: InputDecoration(labelText: l10n.epgUrl),
                    keyboardType: TextInputType.url,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(l10n.protectWithPin),
                  value: _protect,
                  onChanged: (v) => setState(() => _protect = v),
                ),
                if (_protect)
                  TextFormField(
                    controller: _pin,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.pinCode),
                    validator: (v) => _protect && (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
                  ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _busy ? null : _submit,
                  icon: _busy
                      ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check),
                  label: Text(_isEdit ? l10n.save : l10n.addPlaylist),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
