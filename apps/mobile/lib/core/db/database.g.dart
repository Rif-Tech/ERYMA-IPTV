// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $PlaylistsTable extends Playlists
    with TableInfo<$PlaylistsTable, Playlist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PlaylistType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PlaylistType>($PlaylistsTable.$convertertype);
  @override
  late final GeneratedColumnWithTypeConverter<PlaylistSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PlaylistSource>($PlaylistsTable.$convertersource);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _passwordMeta = const VerificationMeta(
    'password',
  );
  @override
  late final GeneratedColumn<String> password = GeneratedColumn<String>(
    'password',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _epgUrlMeta = const VerificationMeta('epgUrl');
  @override
  late final GeneratedColumn<String> epgUrl = GeneratedColumn<String>(
    'epg_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isProtectedMeta = const VerificationMeta(
    'isProtected',
  );
  @override
  late final GeneratedColumn<bool> isProtected = GeneratedColumn<bool>(
    'is_protected',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_protected" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pinCodeMeta = const VerificationMeta(
    'pinCode',
  );
  @override
  late final GeneratedColumn<String> pinCode = GeneratedColumn<String>(
    'pin_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountInfoMeta = const VerificationMeta(
    'accountInfo',
  );
  @override
  late final GeneratedColumn<String> accountInfo = GeneratedColumn<String>(
    'account_info',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    source,
    url,
    username,
    password,
    epgUrl,
    isProtected,
    pinCode,
    expiresAt,
    position,
    lastSyncedAt,
    accountInfo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<Playlist> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    }
    if (data.containsKey('password')) {
      context.handle(
        _passwordMeta,
        password.isAcceptableOrUnknown(data['password']!, _passwordMeta),
      );
    }
    if (data.containsKey('epg_url')) {
      context.handle(
        _epgUrlMeta,
        epgUrl.isAcceptableOrUnknown(data['epg_url']!, _epgUrlMeta),
      );
    }
    if (data.containsKey('is_protected')) {
      context.handle(
        _isProtectedMeta,
        isProtected.isAcceptableOrUnknown(
          data['is_protected']!,
          _isProtectedMeta,
        ),
      );
    }
    if (data.containsKey('pin_code')) {
      context.handle(
        _pinCodeMeta,
        pinCode.isAcceptableOrUnknown(data['pin_code']!, _pinCodeMeta),
      );
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('account_info')) {
      context.handle(
        _accountInfoMeta,
        accountInfo.isAcceptableOrUnknown(
          data['account_info']!,
          _accountInfoMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Playlist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Playlist(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: $PlaylistsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      source: $PlaylistsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      ),
      password: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password'],
      ),
      epgUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}epg_url'],
      ),
      isProtected: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_protected'],
      )!,
      pinCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pin_code'],
      ),
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      accountInfo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_info'],
      ),
    );
  }

  @override
  $PlaylistsTable createAlias(String alias) {
    return $PlaylistsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PlaylistType, String, String> $convertertype =
      const EnumNameConverter<PlaylistType>(PlaylistType.values);
  static JsonTypeConverter2<PlaylistSource, String, String> $convertersource =
      const EnumNameConverter<PlaylistSource>(PlaylistSource.values);
}

class Playlist extends DataClass implements Insertable<Playlist> {
  final String id;
  final String name;
  final PlaylistType type;
  final PlaylistSource source;

  /// M3U: playlist URL or `file://` path. Xtream: server base URL.
  final String url;
  final String? username;
  final String? password;
  final String? epgUrl;
  final bool isProtected;
  final String? pinCode;
  final DateTime? expiresAt;
  final int position;
  final DateTime? lastSyncedAt;

  /// Xtream `user_info` snapshot (exp_date, max_connections…) as JSON.
  final String? accountInfo;
  const Playlist({
    required this.id,
    required this.name,
    required this.type,
    required this.source,
    required this.url,
    this.username,
    this.password,
    this.epgUrl,
    required this.isProtected,
    this.pinCode,
    this.expiresAt,
    required this.position,
    this.lastSyncedAt,
    this.accountInfo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<String>(
        $PlaylistsTable.$convertertype.toSql(type),
      );
    }
    {
      map['source'] = Variable<String>(
        $PlaylistsTable.$convertersource.toSql(source),
      );
    }
    map['url'] = Variable<String>(url);
    if (!nullToAbsent || username != null) {
      map['username'] = Variable<String>(username);
    }
    if (!nullToAbsent || password != null) {
      map['password'] = Variable<String>(password);
    }
    if (!nullToAbsent || epgUrl != null) {
      map['epg_url'] = Variable<String>(epgUrl);
    }
    map['is_protected'] = Variable<bool>(isProtected);
    if (!nullToAbsent || pinCode != null) {
      map['pin_code'] = Variable<String>(pinCode);
    }
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    if (!nullToAbsent || accountInfo != null) {
      map['account_info'] = Variable<String>(accountInfo);
    }
    return map;
  }

  PlaylistsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      source: Value(source),
      url: Value(url),
      username: username == null && nullToAbsent
          ? const Value.absent()
          : Value(username),
      password: password == null && nullToAbsent
          ? const Value.absent()
          : Value(password),
      epgUrl: epgUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(epgUrl),
      isProtected: Value(isProtected),
      pinCode: pinCode == null && nullToAbsent
          ? const Value.absent()
          : Value(pinCode),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      position: Value(position),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      accountInfo: accountInfo == null && nullToAbsent
          ? const Value.absent()
          : Value(accountInfo),
    );
  }

  factory Playlist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Playlist(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: $PlaylistsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      source: $PlaylistsTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      url: serializer.fromJson<String>(json['url']),
      username: serializer.fromJson<String?>(json['username']),
      password: serializer.fromJson<String?>(json['password']),
      epgUrl: serializer.fromJson<String?>(json['epgUrl']),
      isProtected: serializer.fromJson<bool>(json['isProtected']),
      pinCode: serializer.fromJson<String?>(json['pinCode']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
      position: serializer.fromJson<int>(json['position']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      accountInfo: serializer.fromJson<String?>(json['accountInfo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(
        $PlaylistsTable.$convertertype.toJson(type),
      ),
      'source': serializer.toJson<String>(
        $PlaylistsTable.$convertersource.toJson(source),
      ),
      'url': serializer.toJson<String>(url),
      'username': serializer.toJson<String?>(username),
      'password': serializer.toJson<String?>(password),
      'epgUrl': serializer.toJson<String?>(epgUrl),
      'isProtected': serializer.toJson<bool>(isProtected),
      'pinCode': serializer.toJson<String?>(pinCode),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
      'position': serializer.toJson<int>(position),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'accountInfo': serializer.toJson<String?>(accountInfo),
    };
  }

  Playlist copyWith({
    String? id,
    String? name,
    PlaylistType? type,
    PlaylistSource? source,
    String? url,
    Value<String?> username = const Value.absent(),
    Value<String?> password = const Value.absent(),
    Value<String?> epgUrl = const Value.absent(),
    bool? isProtected,
    Value<String?> pinCode = const Value.absent(),
    Value<DateTime?> expiresAt = const Value.absent(),
    int? position,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    Value<String?> accountInfo = const Value.absent(),
  }) => Playlist(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    source: source ?? this.source,
    url: url ?? this.url,
    username: username.present ? username.value : this.username,
    password: password.present ? password.value : this.password,
    epgUrl: epgUrl.present ? epgUrl.value : this.epgUrl,
    isProtected: isProtected ?? this.isProtected,
    pinCode: pinCode.present ? pinCode.value : this.pinCode,
    expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
    position: position ?? this.position,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    accountInfo: accountInfo.present ? accountInfo.value : this.accountInfo,
  );
  Playlist copyWithCompanion(PlaylistsCompanion data) {
    return Playlist(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      source: data.source.present ? data.source.value : this.source,
      url: data.url.present ? data.url.value : this.url,
      username: data.username.present ? data.username.value : this.username,
      password: data.password.present ? data.password.value : this.password,
      epgUrl: data.epgUrl.present ? data.epgUrl.value : this.epgUrl,
      isProtected: data.isProtected.present
          ? data.isProtected.value
          : this.isProtected,
      pinCode: data.pinCode.present ? data.pinCode.value : this.pinCode,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      position: data.position.present ? data.position.value : this.position,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      accountInfo: data.accountInfo.present
          ? data.accountInfo.value
          : this.accountInfo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Playlist(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('source: $source, ')
          ..write('url: $url, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('epgUrl: $epgUrl, ')
          ..write('isProtected: $isProtected, ')
          ..write('pinCode: $pinCode, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('position: $position, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('accountInfo: $accountInfo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    source,
    url,
    username,
    password,
    epgUrl,
    isProtected,
    pinCode,
    expiresAt,
    position,
    lastSyncedAt,
    accountInfo,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Playlist &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.source == this.source &&
          other.url == this.url &&
          other.username == this.username &&
          other.password == this.password &&
          other.epgUrl == this.epgUrl &&
          other.isProtected == this.isProtected &&
          other.pinCode == this.pinCode &&
          other.expiresAt == this.expiresAt &&
          other.position == this.position &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.accountInfo == this.accountInfo);
}

class PlaylistsCompanion extends UpdateCompanion<Playlist> {
  final Value<String> id;
  final Value<String> name;
  final Value<PlaylistType> type;
  final Value<PlaylistSource> source;
  final Value<String> url;
  final Value<String?> username;
  final Value<String?> password;
  final Value<String?> epgUrl;
  final Value<bool> isProtected;
  final Value<String?> pinCode;
  final Value<DateTime?> expiresAt;
  final Value<int> position;
  final Value<DateTime?> lastSyncedAt;
  final Value<String?> accountInfo;
  final Value<int> rowid;
  const PlaylistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.source = const Value.absent(),
    this.url = const Value.absent(),
    this.username = const Value.absent(),
    this.password = const Value.absent(),
    this.epgUrl = const Value.absent(),
    this.isProtected = const Value.absent(),
    this.pinCode = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.position = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.accountInfo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistsCompanion.insert({
    required String id,
    required String name,
    required PlaylistType type,
    required PlaylistSource source,
    required String url,
    this.username = const Value.absent(),
    this.password = const Value.absent(),
    this.epgUrl = const Value.absent(),
    this.isProtected = const Value.absent(),
    this.pinCode = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.position = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.accountInfo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       type = Value(type),
       source = Value(source),
       url = Value(url);
  static Insertable<Playlist> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? source,
    Expression<String>? url,
    Expression<String>? username,
    Expression<String>? password,
    Expression<String>? epgUrl,
    Expression<bool>? isProtected,
    Expression<String>? pinCode,
    Expression<DateTime>? expiresAt,
    Expression<int>? position,
    Expression<DateTime>? lastSyncedAt,
    Expression<String>? accountInfo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (source != null) 'source': source,
      if (url != null) 'url': url,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      if (epgUrl != null) 'epg_url': epgUrl,
      if (isProtected != null) 'is_protected': isProtected,
      if (pinCode != null) 'pin_code': pinCode,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (position != null) 'position': position,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (accountInfo != null) 'account_info': accountInfo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<PlaylistType>? type,
    Value<PlaylistSource>? source,
    Value<String>? url,
    Value<String?>? username,
    Value<String?>? password,
    Value<String?>? epgUrl,
    Value<bool>? isProtected,
    Value<String?>? pinCode,
    Value<DateTime?>? expiresAt,
    Value<int>? position,
    Value<DateTime?>? lastSyncedAt,
    Value<String?>? accountInfo,
    Value<int>? rowid,
  }) {
    return PlaylistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      source: source ?? this.source,
      url: url ?? this.url,
      username: username ?? this.username,
      password: password ?? this.password,
      epgUrl: epgUrl ?? this.epgUrl,
      isProtected: isProtected ?? this.isProtected,
      pinCode: pinCode ?? this.pinCode,
      expiresAt: expiresAt ?? this.expiresAt,
      position: position ?? this.position,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      accountInfo: accountInfo ?? this.accountInfo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $PlaylistsTable.$convertertype.toSql(type.value),
      );
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $PlaylistsTable.$convertersource.toSql(source.value),
      );
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (password.present) {
      map['password'] = Variable<String>(password.value);
    }
    if (epgUrl.present) {
      map['epg_url'] = Variable<String>(epgUrl.value);
    }
    if (isProtected.present) {
      map['is_protected'] = Variable<bool>(isProtected.value);
    }
    if (pinCode.present) {
      map['pin_code'] = Variable<String>(pinCode.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (accountInfo.present) {
      map['account_info'] = Variable<String>(accountInfo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('source: $source, ')
          ..write('url: $url, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('epgUrl: $epgUrl, ')
          ..write('isProtected: $isProtected, ')
          ..write('pinCode: $pinCode, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('position: $position, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('accountInfo: $accountInfo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, ContentCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES playlists (id) ON DELETE CASCADE',
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ContentKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ContentKind>($CategoriesTable.$converterkind);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    playlistId,
    externalId,
    kind,
    name,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContentCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_externalIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {playlistId, kind, externalId},
  ];
  @override
  ContentCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContentCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_id'],
      )!,
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      )!,
      kind: $CategoriesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ContentKind, String, String> $converterkind =
      const EnumNameConverter<ContentKind>(ContentKind.values);
}

class ContentCategory extends DataClass implements Insertable<ContentCategory> {
  final int id;
  final String playlistId;
  final String externalId;
  final ContentKind kind;
  final String name;
  final int position;
  const ContentCategory({
    required this.id,
    required this.playlistId,
    required this.externalId,
    required this.kind,
    required this.name,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['playlist_id'] = Variable<String>(playlistId);
    map['external_id'] = Variable<String>(externalId);
    {
      map['kind'] = Variable<String>(
        $CategoriesTable.$converterkind.toSql(kind),
      );
    }
    map['name'] = Variable<String>(name);
    map['position'] = Variable<int>(position);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      externalId: Value(externalId),
      kind: Value(kind),
      name: Value(name),
      position: Value(position),
    );
  }

  factory ContentCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContentCategory(
      id: serializer.fromJson<int>(json['id']),
      playlistId: serializer.fromJson<String>(json['playlistId']),
      externalId: serializer.fromJson<String>(json['externalId']),
      kind: $CategoriesTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      name: serializer.fromJson<String>(json['name']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playlistId': serializer.toJson<String>(playlistId),
      'externalId': serializer.toJson<String>(externalId),
      'kind': serializer.toJson<String>(
        $CategoriesTable.$converterkind.toJson(kind),
      ),
      'name': serializer.toJson<String>(name),
      'position': serializer.toJson<int>(position),
    };
  }

  ContentCategory copyWith({
    int? id,
    String? playlistId,
    String? externalId,
    ContentKind? kind,
    String? name,
    int? position,
  }) => ContentCategory(
    id: id ?? this.id,
    playlistId: playlistId ?? this.playlistId,
    externalId: externalId ?? this.externalId,
    kind: kind ?? this.kind,
    name: name ?? this.name,
    position: position ?? this.position,
  );
  ContentCategory copyWithCompanion(CategoriesCompanion data) {
    return ContentCategory(
      id: data.id.present ? data.id.value : this.id,
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      kind: data.kind.present ? data.kind.value : this.kind,
      name: data.name.present ? data.name.value : this.name,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContentCategory(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('externalId: $externalId, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, playlistId, externalId, kind, name, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContentCategory &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.externalId == this.externalId &&
          other.kind == this.kind &&
          other.name == this.name &&
          other.position == this.position);
}

class CategoriesCompanion extends UpdateCompanion<ContentCategory> {
  final Value<int> id;
  final Value<String> playlistId;
  final Value<String> externalId;
  final Value<ContentKind> kind;
  final Value<String> name;
  final Value<int> position;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.externalId = const Value.absent(),
    this.kind = const Value.absent(),
    this.name = const Value.absent(),
    this.position = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String playlistId,
    required String externalId,
    required ContentKind kind,
    required String name,
    this.position = const Value.absent(),
  }) : playlistId = Value(playlistId),
       externalId = Value(externalId),
       kind = Value(kind),
       name = Value(name);
  static Insertable<ContentCategory> custom({
    Expression<int>? id,
    Expression<String>? playlistId,
    Expression<String>? externalId,
    Expression<String>? kind,
    Expression<String>? name,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (externalId != null) 'external_id': externalId,
      if (kind != null) 'kind': kind,
      if (name != null) 'name': name,
      if (position != null) 'position': position,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? playlistId,
    Value<String>? externalId,
    Value<ContentKind>? kind,
    Value<String>? name,
    Value<int>? position,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      externalId: externalId ?? this.externalId,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $CategoriesTable.$converterkind.toSql(kind.value),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('externalId: $externalId, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

class $ChannelsTable extends Channels with TableInfo<$ChannelsTable, Channel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChannelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES playlists (id) ON DELETE CASCADE',
  );
  static const VerificationMeta _streamIdMeta = const VerificationMeta(
    'streamId',
  );
  @override
  late final GeneratedColumn<String> streamId = GeneratedColumn<String>(
    'stream_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _logoMeta = const VerificationMeta('logo');
  @override
  late final GeneratedColumn<String> logo = GeneratedColumn<String>(
    'logo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _epgChannelIdMeta = const VerificationMeta(
    'epgChannelId',
  );
  @override
  late final GeneratedColumn<String> epgChannelId = GeneratedColumn<String>(
    'epg_channel_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _streamUrlMeta = const VerificationMeta(
    'streamUrl',
  );
  @override
  late final GeneratedColumn<String> streamUrl = GeneratedColumn<String>(
    'stream_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tvArchiveMeta = const VerificationMeta(
    'tvArchive',
  );
  @override
  late final GeneratedColumn<bool> tvArchive = GeneratedColumn<bool>(
    'tv_archive',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("tv_archive" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tvArchiveDurationMeta = const VerificationMeta(
    'tvArchiveDuration',
  );
  @override
  late final GeneratedColumn<int> tvArchiveDuration = GeneratedColumn<int>(
    'tv_archive_duration',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    playlistId,
    streamId,
    name,
    logo,
    categoryId,
    epgChannelId,
    streamUrl,
    number,
    tvArchive,
    tvArchiveDuration,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'channels';
  @override
  VerificationContext validateIntegrity(
    Insertable<Channel> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('stream_id')) {
      context.handle(
        _streamIdMeta,
        streamId.isAcceptableOrUnknown(data['stream_id']!, _streamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_streamIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('logo')) {
      context.handle(
        _logoMeta,
        logo.isAcceptableOrUnknown(data['logo']!, _logoMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('epg_channel_id')) {
      context.handle(
        _epgChannelIdMeta,
        epgChannelId.isAcceptableOrUnknown(
          data['epg_channel_id']!,
          _epgChannelIdMeta,
        ),
      );
    }
    if (data.containsKey('stream_url')) {
      context.handle(
        _streamUrlMeta,
        streamUrl.isAcceptableOrUnknown(data['stream_url']!, _streamUrlMeta),
      );
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    }
    if (data.containsKey('tv_archive')) {
      context.handle(
        _tvArchiveMeta,
        tvArchive.isAcceptableOrUnknown(data['tv_archive']!, _tvArchiveMeta),
      );
    }
    if (data.containsKey('tv_archive_duration')) {
      context.handle(
        _tvArchiveDurationMeta,
        tvArchiveDuration.isAcceptableOrUnknown(
          data['tv_archive_duration']!,
          _tvArchiveDurationMeta,
        ),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {playlistId, streamId},
  ];
  @override
  Channel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Channel(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_id'],
      )!,
      streamId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stream_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      logo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logo'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      epgChannelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}epg_channel_id'],
      ),
      streamUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stream_url'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      ),
      tvArchive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}tv_archive'],
      )!,
      tvArchiveDuration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tv_archive_duration'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $ChannelsTable createAlias(String alias) {
    return $ChannelsTable(attachedDatabase, alias);
  }
}

class Channel extends DataClass implements Insertable<Channel> {
  final int id;
  final String playlistId;
  final String streamId;
  final String name;
  final String? logo;
  final String? categoryId;
  final String? epgChannelId;

  /// Full stream URL (M3U). Empty for Xtream: built at play time from the settings.
  final String streamUrl;
  final int? number;
  final bool tvArchive;
  final int tvArchiveDuration;
  final int position;
  const Channel({
    required this.id,
    required this.playlistId,
    required this.streamId,
    required this.name,
    this.logo,
    this.categoryId,
    this.epgChannelId,
    required this.streamUrl,
    this.number,
    required this.tvArchive,
    required this.tvArchiveDuration,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['playlist_id'] = Variable<String>(playlistId);
    map['stream_id'] = Variable<String>(streamId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || logo != null) {
      map['logo'] = Variable<String>(logo);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || epgChannelId != null) {
      map['epg_channel_id'] = Variable<String>(epgChannelId);
    }
    map['stream_url'] = Variable<String>(streamUrl);
    if (!nullToAbsent || number != null) {
      map['number'] = Variable<int>(number);
    }
    map['tv_archive'] = Variable<bool>(tvArchive);
    map['tv_archive_duration'] = Variable<int>(tvArchiveDuration);
    map['position'] = Variable<int>(position);
    return map;
  }

  ChannelsCompanion toCompanion(bool nullToAbsent) {
    return ChannelsCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      streamId: Value(streamId),
      name: Value(name),
      logo: logo == null && nullToAbsent ? const Value.absent() : Value(logo),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      epgChannelId: epgChannelId == null && nullToAbsent
          ? const Value.absent()
          : Value(epgChannelId),
      streamUrl: Value(streamUrl),
      number: number == null && nullToAbsent
          ? const Value.absent()
          : Value(number),
      tvArchive: Value(tvArchive),
      tvArchiveDuration: Value(tvArchiveDuration),
      position: Value(position),
    );
  }

  factory Channel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Channel(
      id: serializer.fromJson<int>(json['id']),
      playlistId: serializer.fromJson<String>(json['playlistId']),
      streamId: serializer.fromJson<String>(json['streamId']),
      name: serializer.fromJson<String>(json['name']),
      logo: serializer.fromJson<String?>(json['logo']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      epgChannelId: serializer.fromJson<String?>(json['epgChannelId']),
      streamUrl: serializer.fromJson<String>(json['streamUrl']),
      number: serializer.fromJson<int?>(json['number']),
      tvArchive: serializer.fromJson<bool>(json['tvArchive']),
      tvArchiveDuration: serializer.fromJson<int>(json['tvArchiveDuration']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playlistId': serializer.toJson<String>(playlistId),
      'streamId': serializer.toJson<String>(streamId),
      'name': serializer.toJson<String>(name),
      'logo': serializer.toJson<String?>(logo),
      'categoryId': serializer.toJson<String?>(categoryId),
      'epgChannelId': serializer.toJson<String?>(epgChannelId),
      'streamUrl': serializer.toJson<String>(streamUrl),
      'number': serializer.toJson<int?>(number),
      'tvArchive': serializer.toJson<bool>(tvArchive),
      'tvArchiveDuration': serializer.toJson<int>(tvArchiveDuration),
      'position': serializer.toJson<int>(position),
    };
  }

  Channel copyWith({
    int? id,
    String? playlistId,
    String? streamId,
    String? name,
    Value<String?> logo = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    Value<String?> epgChannelId = const Value.absent(),
    String? streamUrl,
    Value<int?> number = const Value.absent(),
    bool? tvArchive,
    int? tvArchiveDuration,
    int? position,
  }) => Channel(
    id: id ?? this.id,
    playlistId: playlistId ?? this.playlistId,
    streamId: streamId ?? this.streamId,
    name: name ?? this.name,
    logo: logo.present ? logo.value : this.logo,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    epgChannelId: epgChannelId.present ? epgChannelId.value : this.epgChannelId,
    streamUrl: streamUrl ?? this.streamUrl,
    number: number.present ? number.value : this.number,
    tvArchive: tvArchive ?? this.tvArchive,
    tvArchiveDuration: tvArchiveDuration ?? this.tvArchiveDuration,
    position: position ?? this.position,
  );
  Channel copyWithCompanion(ChannelsCompanion data) {
    return Channel(
      id: data.id.present ? data.id.value : this.id,
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      streamId: data.streamId.present ? data.streamId.value : this.streamId,
      name: data.name.present ? data.name.value : this.name,
      logo: data.logo.present ? data.logo.value : this.logo,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      epgChannelId: data.epgChannelId.present
          ? data.epgChannelId.value
          : this.epgChannelId,
      streamUrl: data.streamUrl.present ? data.streamUrl.value : this.streamUrl,
      number: data.number.present ? data.number.value : this.number,
      tvArchive: data.tvArchive.present ? data.tvArchive.value : this.tvArchive,
      tvArchiveDuration: data.tvArchiveDuration.present
          ? data.tvArchiveDuration.value
          : this.tvArchiveDuration,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Channel(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('streamId: $streamId, ')
          ..write('name: $name, ')
          ..write('logo: $logo, ')
          ..write('categoryId: $categoryId, ')
          ..write('epgChannelId: $epgChannelId, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('number: $number, ')
          ..write('tvArchive: $tvArchive, ')
          ..write('tvArchiveDuration: $tvArchiveDuration, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    playlistId,
    streamId,
    name,
    logo,
    categoryId,
    epgChannelId,
    streamUrl,
    number,
    tvArchive,
    tvArchiveDuration,
    position,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Channel &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.streamId == this.streamId &&
          other.name == this.name &&
          other.logo == this.logo &&
          other.categoryId == this.categoryId &&
          other.epgChannelId == this.epgChannelId &&
          other.streamUrl == this.streamUrl &&
          other.number == this.number &&
          other.tvArchive == this.tvArchive &&
          other.tvArchiveDuration == this.tvArchiveDuration &&
          other.position == this.position);
}

class ChannelsCompanion extends UpdateCompanion<Channel> {
  final Value<int> id;
  final Value<String> playlistId;
  final Value<String> streamId;
  final Value<String> name;
  final Value<String?> logo;
  final Value<String?> categoryId;
  final Value<String?> epgChannelId;
  final Value<String> streamUrl;
  final Value<int?> number;
  final Value<bool> tvArchive;
  final Value<int> tvArchiveDuration;
  final Value<int> position;
  const ChannelsCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.streamId = const Value.absent(),
    this.name = const Value.absent(),
    this.logo = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.epgChannelId = const Value.absent(),
    this.streamUrl = const Value.absent(),
    this.number = const Value.absent(),
    this.tvArchive = const Value.absent(),
    this.tvArchiveDuration = const Value.absent(),
    this.position = const Value.absent(),
  });
  ChannelsCompanion.insert({
    this.id = const Value.absent(),
    required String playlistId,
    required String streamId,
    required String name,
    this.logo = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.epgChannelId = const Value.absent(),
    this.streamUrl = const Value.absent(),
    this.number = const Value.absent(),
    this.tvArchive = const Value.absent(),
    this.tvArchiveDuration = const Value.absent(),
    this.position = const Value.absent(),
  }) : playlistId = Value(playlistId),
       streamId = Value(streamId),
       name = Value(name);
  static Insertable<Channel> custom({
    Expression<int>? id,
    Expression<String>? playlistId,
    Expression<String>? streamId,
    Expression<String>? name,
    Expression<String>? logo,
    Expression<String>? categoryId,
    Expression<String>? epgChannelId,
    Expression<String>? streamUrl,
    Expression<int>? number,
    Expression<bool>? tvArchive,
    Expression<int>? tvArchiveDuration,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (streamId != null) 'stream_id': streamId,
      if (name != null) 'name': name,
      if (logo != null) 'logo': logo,
      if (categoryId != null) 'category_id': categoryId,
      if (epgChannelId != null) 'epg_channel_id': epgChannelId,
      if (streamUrl != null) 'stream_url': streamUrl,
      if (number != null) 'number': number,
      if (tvArchive != null) 'tv_archive': tvArchive,
      if (tvArchiveDuration != null) 'tv_archive_duration': tvArchiveDuration,
      if (position != null) 'position': position,
    });
  }

  ChannelsCompanion copyWith({
    Value<int>? id,
    Value<String>? playlistId,
    Value<String>? streamId,
    Value<String>? name,
    Value<String?>? logo,
    Value<String?>? categoryId,
    Value<String?>? epgChannelId,
    Value<String>? streamUrl,
    Value<int?>? number,
    Value<bool>? tvArchive,
    Value<int>? tvArchiveDuration,
    Value<int>? position,
  }) {
    return ChannelsCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      streamId: streamId ?? this.streamId,
      name: name ?? this.name,
      logo: logo ?? this.logo,
      categoryId: categoryId ?? this.categoryId,
      epgChannelId: epgChannelId ?? this.epgChannelId,
      streamUrl: streamUrl ?? this.streamUrl,
      number: number ?? this.number,
      tvArchive: tvArchive ?? this.tvArchive,
      tvArchiveDuration: tvArchiveDuration ?? this.tvArchiveDuration,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (streamId.present) {
      map['stream_id'] = Variable<String>(streamId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (logo.present) {
      map['logo'] = Variable<String>(logo.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (epgChannelId.present) {
      map['epg_channel_id'] = Variable<String>(epgChannelId.value);
    }
    if (streamUrl.present) {
      map['stream_url'] = Variable<String>(streamUrl.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (tvArchive.present) {
      map['tv_archive'] = Variable<bool>(tvArchive.value);
    }
    if (tvArchiveDuration.present) {
      map['tv_archive_duration'] = Variable<int>(tvArchiveDuration.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChannelsCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('streamId: $streamId, ')
          ..write('name: $name, ')
          ..write('logo: $logo, ')
          ..write('categoryId: $categoryId, ')
          ..write('epgChannelId: $epgChannelId, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('number: $number, ')
          ..write('tvArchive: $tvArchive, ')
          ..write('tvArchiveDuration: $tvArchiveDuration, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

class $MoviesTable extends Movies with TableInfo<$MoviesTable, Movie> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MoviesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES playlists (id) ON DELETE CASCADE',
  );
  static const VerificationMeta _streamIdMeta = const VerificationMeta(
    'streamId',
  );
  @override
  late final GeneratedColumn<String> streamId = GeneratedColumn<String>(
    'stream_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _posterMeta = const VerificationMeta('poster');
  @override
  late final GeneratedColumn<String> poster = GeneratedColumn<String>(
    'poster',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _streamUrlMeta = const VerificationMeta(
    'streamUrl',
  );
  @override
  late final GeneratedColumn<String> streamUrl = GeneratedColumn<String>(
    'stream_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _containerExtensionMeta =
      const VerificationMeta('containerExtension');
  @override
  late final GeneratedColumn<String> containerExtension =
      GeneratedColumn<String>(
        'container_extension',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    playlistId,
    streamId,
    name,
    poster,
    categoryId,
    streamUrl,
    containerExtension,
    rating,
    year,
    addedAt,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'movies';
  @override
  VerificationContext validateIntegrity(
    Insertable<Movie> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('stream_id')) {
      context.handle(
        _streamIdMeta,
        streamId.isAcceptableOrUnknown(data['stream_id']!, _streamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_streamIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('poster')) {
      context.handle(
        _posterMeta,
        poster.isAcceptableOrUnknown(data['poster']!, _posterMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('stream_url')) {
      context.handle(
        _streamUrlMeta,
        streamUrl.isAcceptableOrUnknown(data['stream_url']!, _streamUrlMeta),
      );
    }
    if (data.containsKey('container_extension')) {
      context.handle(
        _containerExtensionMeta,
        containerExtension.isAcceptableOrUnknown(
          data['container_extension']!,
          _containerExtensionMeta,
        ),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {playlistId, streamId},
  ];
  @override
  Movie map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Movie(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_id'],
      )!,
      streamId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stream_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      poster: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poster'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      streamUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stream_url'],
      )!,
      containerExtension: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}container_extension'],
      ),
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $MoviesTable createAlias(String alias) {
    return $MoviesTable(attachedDatabase, alias);
  }
}

class Movie extends DataClass implements Insertable<Movie> {
  final int id;
  final String playlistId;
  final String streamId;
  final String name;
  final String? poster;
  final String? categoryId;
  final String streamUrl;
  final String? containerExtension;
  final double? rating;
  final int? year;
  final DateTime? addedAt;
  final int position;
  const Movie({
    required this.id,
    required this.playlistId,
    required this.streamId,
    required this.name,
    this.poster,
    this.categoryId,
    required this.streamUrl,
    this.containerExtension,
    this.rating,
    this.year,
    this.addedAt,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['playlist_id'] = Variable<String>(playlistId);
    map['stream_id'] = Variable<String>(streamId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || poster != null) {
      map['poster'] = Variable<String>(poster);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['stream_url'] = Variable<String>(streamUrl);
    if (!nullToAbsent || containerExtension != null) {
      map['container_extension'] = Variable<String>(containerExtension);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<double>(rating);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || addedAt != null) {
      map['added_at'] = Variable<DateTime>(addedAt);
    }
    map['position'] = Variable<int>(position);
    return map;
  }

  MoviesCompanion toCompanion(bool nullToAbsent) {
    return MoviesCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      streamId: Value(streamId),
      name: Value(name),
      poster: poster == null && nullToAbsent
          ? const Value.absent()
          : Value(poster),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      streamUrl: Value(streamUrl),
      containerExtension: containerExtension == null && nullToAbsent
          ? const Value.absent()
          : Value(containerExtension),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      addedAt: addedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(addedAt),
      position: Value(position),
    );
  }

  factory Movie.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Movie(
      id: serializer.fromJson<int>(json['id']),
      playlistId: serializer.fromJson<String>(json['playlistId']),
      streamId: serializer.fromJson<String>(json['streamId']),
      name: serializer.fromJson<String>(json['name']),
      poster: serializer.fromJson<String?>(json['poster']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      streamUrl: serializer.fromJson<String>(json['streamUrl']),
      containerExtension: serializer.fromJson<String?>(
        json['containerExtension'],
      ),
      rating: serializer.fromJson<double?>(json['rating']),
      year: serializer.fromJson<int?>(json['year']),
      addedAt: serializer.fromJson<DateTime?>(json['addedAt']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playlistId': serializer.toJson<String>(playlistId),
      'streamId': serializer.toJson<String>(streamId),
      'name': serializer.toJson<String>(name),
      'poster': serializer.toJson<String?>(poster),
      'categoryId': serializer.toJson<String?>(categoryId),
      'streamUrl': serializer.toJson<String>(streamUrl),
      'containerExtension': serializer.toJson<String?>(containerExtension),
      'rating': serializer.toJson<double?>(rating),
      'year': serializer.toJson<int?>(year),
      'addedAt': serializer.toJson<DateTime?>(addedAt),
      'position': serializer.toJson<int>(position),
    };
  }

  Movie copyWith({
    int? id,
    String? playlistId,
    String? streamId,
    String? name,
    Value<String?> poster = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    String? streamUrl,
    Value<String?> containerExtension = const Value.absent(),
    Value<double?> rating = const Value.absent(),
    Value<int?> year = const Value.absent(),
    Value<DateTime?> addedAt = const Value.absent(),
    int? position,
  }) => Movie(
    id: id ?? this.id,
    playlistId: playlistId ?? this.playlistId,
    streamId: streamId ?? this.streamId,
    name: name ?? this.name,
    poster: poster.present ? poster.value : this.poster,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    streamUrl: streamUrl ?? this.streamUrl,
    containerExtension: containerExtension.present
        ? containerExtension.value
        : this.containerExtension,
    rating: rating.present ? rating.value : this.rating,
    year: year.present ? year.value : this.year,
    addedAt: addedAt.present ? addedAt.value : this.addedAt,
    position: position ?? this.position,
  );
  Movie copyWithCompanion(MoviesCompanion data) {
    return Movie(
      id: data.id.present ? data.id.value : this.id,
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      streamId: data.streamId.present ? data.streamId.value : this.streamId,
      name: data.name.present ? data.name.value : this.name,
      poster: data.poster.present ? data.poster.value : this.poster,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      streamUrl: data.streamUrl.present ? data.streamUrl.value : this.streamUrl,
      containerExtension: data.containerExtension.present
          ? data.containerExtension.value
          : this.containerExtension,
      rating: data.rating.present ? data.rating.value : this.rating,
      year: data.year.present ? data.year.value : this.year,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Movie(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('streamId: $streamId, ')
          ..write('name: $name, ')
          ..write('poster: $poster, ')
          ..write('categoryId: $categoryId, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('containerExtension: $containerExtension, ')
          ..write('rating: $rating, ')
          ..write('year: $year, ')
          ..write('addedAt: $addedAt, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    playlistId,
    streamId,
    name,
    poster,
    categoryId,
    streamUrl,
    containerExtension,
    rating,
    year,
    addedAt,
    position,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Movie &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.streamId == this.streamId &&
          other.name == this.name &&
          other.poster == this.poster &&
          other.categoryId == this.categoryId &&
          other.streamUrl == this.streamUrl &&
          other.containerExtension == this.containerExtension &&
          other.rating == this.rating &&
          other.year == this.year &&
          other.addedAt == this.addedAt &&
          other.position == this.position);
}

class MoviesCompanion extends UpdateCompanion<Movie> {
  final Value<int> id;
  final Value<String> playlistId;
  final Value<String> streamId;
  final Value<String> name;
  final Value<String?> poster;
  final Value<String?> categoryId;
  final Value<String> streamUrl;
  final Value<String?> containerExtension;
  final Value<double?> rating;
  final Value<int?> year;
  final Value<DateTime?> addedAt;
  final Value<int> position;
  const MoviesCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.streamId = const Value.absent(),
    this.name = const Value.absent(),
    this.poster = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.streamUrl = const Value.absent(),
    this.containerExtension = const Value.absent(),
    this.rating = const Value.absent(),
    this.year = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.position = const Value.absent(),
  });
  MoviesCompanion.insert({
    this.id = const Value.absent(),
    required String playlistId,
    required String streamId,
    required String name,
    this.poster = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.streamUrl = const Value.absent(),
    this.containerExtension = const Value.absent(),
    this.rating = const Value.absent(),
    this.year = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.position = const Value.absent(),
  }) : playlistId = Value(playlistId),
       streamId = Value(streamId),
       name = Value(name);
  static Insertable<Movie> custom({
    Expression<int>? id,
    Expression<String>? playlistId,
    Expression<String>? streamId,
    Expression<String>? name,
    Expression<String>? poster,
    Expression<String>? categoryId,
    Expression<String>? streamUrl,
    Expression<String>? containerExtension,
    Expression<double>? rating,
    Expression<int>? year,
    Expression<DateTime>? addedAt,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (streamId != null) 'stream_id': streamId,
      if (name != null) 'name': name,
      if (poster != null) 'poster': poster,
      if (categoryId != null) 'category_id': categoryId,
      if (streamUrl != null) 'stream_url': streamUrl,
      if (containerExtension != null) 'container_extension': containerExtension,
      if (rating != null) 'rating': rating,
      if (year != null) 'year': year,
      if (addedAt != null) 'added_at': addedAt,
      if (position != null) 'position': position,
    });
  }

  MoviesCompanion copyWith({
    Value<int>? id,
    Value<String>? playlistId,
    Value<String>? streamId,
    Value<String>? name,
    Value<String?>? poster,
    Value<String?>? categoryId,
    Value<String>? streamUrl,
    Value<String?>? containerExtension,
    Value<double?>? rating,
    Value<int?>? year,
    Value<DateTime?>? addedAt,
    Value<int>? position,
  }) {
    return MoviesCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      streamId: streamId ?? this.streamId,
      name: name ?? this.name,
      poster: poster ?? this.poster,
      categoryId: categoryId ?? this.categoryId,
      streamUrl: streamUrl ?? this.streamUrl,
      containerExtension: containerExtension ?? this.containerExtension,
      rating: rating ?? this.rating,
      year: year ?? this.year,
      addedAt: addedAt ?? this.addedAt,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (streamId.present) {
      map['stream_id'] = Variable<String>(streamId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (poster.present) {
      map['poster'] = Variable<String>(poster.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (streamUrl.present) {
      map['stream_url'] = Variable<String>(streamUrl.value);
    }
    if (containerExtension.present) {
      map['container_extension'] = Variable<String>(containerExtension.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MoviesCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('streamId: $streamId, ')
          ..write('name: $name, ')
          ..write('poster: $poster, ')
          ..write('categoryId: $categoryId, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('containerExtension: $containerExtension, ')
          ..write('rating: $rating, ')
          ..write('year: $year, ')
          ..write('addedAt: $addedAt, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

class $SeriesItemsTable extends SeriesItems
    with TableInfo<$SeriesItemsTable, SeriesItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeriesItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES playlists (id) ON DELETE CASCADE',
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverMeta = const VerificationMeta('cover');
  @override
  late final GeneratedColumn<String> cover = GeneratedColumn<String>(
    'cover',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _plotMeta = const VerificationMeta('plot');
  @override
  late final GeneratedColumn<String> plot = GeneratedColumn<String>(
    'plot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    playlistId,
    seriesId,
    name,
    cover,
    categoryId,
    plot,
    rating,
    year,
    addedAt,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'series_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeriesItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('cover')) {
      context.handle(
        _coverMeta,
        cover.isAcceptableOrUnknown(data['cover']!, _coverMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('plot')) {
      context.handle(
        _plotMeta,
        plot.isAcceptableOrUnknown(data['plot']!, _plotMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {playlistId, seriesId},
  ];
  @override
  SeriesItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeriesItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      cover: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      plot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plot'],
      ),
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $SeriesItemsTable createAlias(String alias) {
    return $SeriesItemsTable(attachedDatabase, alias);
  }
}

class SeriesItem extends DataClass implements Insertable<SeriesItem> {
  final int id;
  final String playlistId;
  final String seriesId;
  final String name;
  final String? cover;
  final String? categoryId;
  final String? plot;
  final double? rating;
  final int? year;
  final DateTime? addedAt;
  final int position;
  const SeriesItem({
    required this.id,
    required this.playlistId,
    required this.seriesId,
    required this.name,
    this.cover,
    this.categoryId,
    this.plot,
    this.rating,
    this.year,
    this.addedAt,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['playlist_id'] = Variable<String>(playlistId);
    map['series_id'] = Variable<String>(seriesId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || cover != null) {
      map['cover'] = Variable<String>(cover);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || plot != null) {
      map['plot'] = Variable<String>(plot);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<double>(rating);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || addedAt != null) {
      map['added_at'] = Variable<DateTime>(addedAt);
    }
    map['position'] = Variable<int>(position);
    return map;
  }

  SeriesItemsCompanion toCompanion(bool nullToAbsent) {
    return SeriesItemsCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      seriesId: Value(seriesId),
      name: Value(name),
      cover: cover == null && nullToAbsent
          ? const Value.absent()
          : Value(cover),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      plot: plot == null && nullToAbsent ? const Value.absent() : Value(plot),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      addedAt: addedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(addedAt),
      position: Value(position),
    );
  }

  factory SeriesItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeriesItem(
      id: serializer.fromJson<int>(json['id']),
      playlistId: serializer.fromJson<String>(json['playlistId']),
      seriesId: serializer.fromJson<String>(json['seriesId']),
      name: serializer.fromJson<String>(json['name']),
      cover: serializer.fromJson<String?>(json['cover']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      plot: serializer.fromJson<String?>(json['plot']),
      rating: serializer.fromJson<double?>(json['rating']),
      year: serializer.fromJson<int?>(json['year']),
      addedAt: serializer.fromJson<DateTime?>(json['addedAt']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playlistId': serializer.toJson<String>(playlistId),
      'seriesId': serializer.toJson<String>(seriesId),
      'name': serializer.toJson<String>(name),
      'cover': serializer.toJson<String?>(cover),
      'categoryId': serializer.toJson<String?>(categoryId),
      'plot': serializer.toJson<String?>(plot),
      'rating': serializer.toJson<double?>(rating),
      'year': serializer.toJson<int?>(year),
      'addedAt': serializer.toJson<DateTime?>(addedAt),
      'position': serializer.toJson<int>(position),
    };
  }

  SeriesItem copyWith({
    int? id,
    String? playlistId,
    String? seriesId,
    String? name,
    Value<String?> cover = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    Value<String?> plot = const Value.absent(),
    Value<double?> rating = const Value.absent(),
    Value<int?> year = const Value.absent(),
    Value<DateTime?> addedAt = const Value.absent(),
    int? position,
  }) => SeriesItem(
    id: id ?? this.id,
    playlistId: playlistId ?? this.playlistId,
    seriesId: seriesId ?? this.seriesId,
    name: name ?? this.name,
    cover: cover.present ? cover.value : this.cover,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    plot: plot.present ? plot.value : this.plot,
    rating: rating.present ? rating.value : this.rating,
    year: year.present ? year.value : this.year,
    addedAt: addedAt.present ? addedAt.value : this.addedAt,
    position: position ?? this.position,
  );
  SeriesItem copyWithCompanion(SeriesItemsCompanion data) {
    return SeriesItem(
      id: data.id.present ? data.id.value : this.id,
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      name: data.name.present ? data.name.value : this.name,
      cover: data.cover.present ? data.cover.value : this.cover,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      plot: data.plot.present ? data.plot.value : this.plot,
      rating: data.rating.present ? data.rating.value : this.rating,
      year: data.year.present ? data.year.value : this.year,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeriesItem(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('seriesId: $seriesId, ')
          ..write('name: $name, ')
          ..write('cover: $cover, ')
          ..write('categoryId: $categoryId, ')
          ..write('plot: $plot, ')
          ..write('rating: $rating, ')
          ..write('year: $year, ')
          ..write('addedAt: $addedAt, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    playlistId,
    seriesId,
    name,
    cover,
    categoryId,
    plot,
    rating,
    year,
    addedAt,
    position,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeriesItem &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.seriesId == this.seriesId &&
          other.name == this.name &&
          other.cover == this.cover &&
          other.categoryId == this.categoryId &&
          other.plot == this.plot &&
          other.rating == this.rating &&
          other.year == this.year &&
          other.addedAt == this.addedAt &&
          other.position == this.position);
}

class SeriesItemsCompanion extends UpdateCompanion<SeriesItem> {
  final Value<int> id;
  final Value<String> playlistId;
  final Value<String> seriesId;
  final Value<String> name;
  final Value<String?> cover;
  final Value<String?> categoryId;
  final Value<String?> plot;
  final Value<double?> rating;
  final Value<int?> year;
  final Value<DateTime?> addedAt;
  final Value<int> position;
  const SeriesItemsCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.name = const Value.absent(),
    this.cover = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.plot = const Value.absent(),
    this.rating = const Value.absent(),
    this.year = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.position = const Value.absent(),
  });
  SeriesItemsCompanion.insert({
    this.id = const Value.absent(),
    required String playlistId,
    required String seriesId,
    required String name,
    this.cover = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.plot = const Value.absent(),
    this.rating = const Value.absent(),
    this.year = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.position = const Value.absent(),
  }) : playlistId = Value(playlistId),
       seriesId = Value(seriesId),
       name = Value(name);
  static Insertable<SeriesItem> custom({
    Expression<int>? id,
    Expression<String>? playlistId,
    Expression<String>? seriesId,
    Expression<String>? name,
    Expression<String>? cover,
    Expression<String>? categoryId,
    Expression<String>? plot,
    Expression<double>? rating,
    Expression<int>? year,
    Expression<DateTime>? addedAt,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (seriesId != null) 'series_id': seriesId,
      if (name != null) 'name': name,
      if (cover != null) 'cover': cover,
      if (categoryId != null) 'category_id': categoryId,
      if (plot != null) 'plot': plot,
      if (rating != null) 'rating': rating,
      if (year != null) 'year': year,
      if (addedAt != null) 'added_at': addedAt,
      if (position != null) 'position': position,
    });
  }

  SeriesItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? playlistId,
    Value<String>? seriesId,
    Value<String>? name,
    Value<String?>? cover,
    Value<String?>? categoryId,
    Value<String?>? plot,
    Value<double?>? rating,
    Value<int?>? year,
    Value<DateTime?>? addedAt,
    Value<int>? position,
  }) {
    return SeriesItemsCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      seriesId: seriesId ?? this.seriesId,
      name: name ?? this.name,
      cover: cover ?? this.cover,
      categoryId: categoryId ?? this.categoryId,
      plot: plot ?? this.plot,
      rating: rating ?? this.rating,
      year: year ?? this.year,
      addedAt: addedAt ?? this.addedAt,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (cover.present) {
      map['cover'] = Variable<String>(cover.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (plot.present) {
      map['plot'] = Variable<String>(plot.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeriesItemsCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('seriesId: $seriesId, ')
          ..write('name: $name, ')
          ..write('cover: $cover, ')
          ..write('categoryId: $categoryId, ')
          ..write('plot: $plot, ')
          ..write('rating: $rating, ')
          ..write('year: $year, ')
          ..write('addedAt: $addedAt, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

class $EpisodesTable extends Episodes with TableInfo<$EpisodesTable, Episode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpisodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES playlists (id) ON DELETE CASCADE',
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _episodeIdMeta = const VerificationMeta(
    'episodeId',
  );
  @override
  late final GeneratedColumn<String> episodeId = GeneratedColumn<String>(
    'episode_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seasonMeta = const VerificationMeta('season');
  @override
  late final GeneratedColumn<int> season = GeneratedColumn<int>(
    'season',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _episodeNumMeta = const VerificationMeta(
    'episodeNum',
  );
  @override
  late final GeneratedColumn<int> episodeNum = GeneratedColumn<int>(
    'episode_num',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _streamUrlMeta = const VerificationMeta(
    'streamUrl',
  );
  @override
  late final GeneratedColumn<String> streamUrl = GeneratedColumn<String>(
    'stream_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _containerExtensionMeta =
      const VerificationMeta('containerExtension');
  @override
  late final GeneratedColumn<String> containerExtension =
      GeneratedColumn<String>(
        'container_extension',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _posterMeta = const VerificationMeta('poster');
  @override
  late final GeneratedColumn<String> poster = GeneratedColumn<String>(
    'poster',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecsMeta = const VerificationMeta(
    'durationSecs',
  );
  @override
  late final GeneratedColumn<int> durationSecs = GeneratedColumn<int>(
    'duration_secs',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _plotMeta = const VerificationMeta('plot');
  @override
  late final GeneratedColumn<String> plot = GeneratedColumn<String>(
    'plot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resolutionMeta = const VerificationMeta(
    'resolution',
  );
  @override
  late final GeneratedColumn<String> resolution = GeneratedColumn<String>(
    'resolution',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    playlistId,
    seriesId,
    episodeId,
    season,
    episodeNum,
    title,
    streamUrl,
    containerExtension,
    poster,
    durationSecs,
    plot,
    resolution,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'episodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Episode> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    if (data.containsKey('episode_id')) {
      context.handle(
        _episodeIdMeta,
        episodeId.isAcceptableOrUnknown(data['episode_id']!, _episodeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_episodeIdMeta);
    }
    if (data.containsKey('season')) {
      context.handle(
        _seasonMeta,
        season.isAcceptableOrUnknown(data['season']!, _seasonMeta),
      );
    } else if (isInserting) {
      context.missing(_seasonMeta);
    }
    if (data.containsKey('episode_num')) {
      context.handle(
        _episodeNumMeta,
        episodeNum.isAcceptableOrUnknown(data['episode_num']!, _episodeNumMeta),
      );
    } else if (isInserting) {
      context.missing(_episodeNumMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('stream_url')) {
      context.handle(
        _streamUrlMeta,
        streamUrl.isAcceptableOrUnknown(data['stream_url']!, _streamUrlMeta),
      );
    }
    if (data.containsKey('container_extension')) {
      context.handle(
        _containerExtensionMeta,
        containerExtension.isAcceptableOrUnknown(
          data['container_extension']!,
          _containerExtensionMeta,
        ),
      );
    }
    if (data.containsKey('poster')) {
      context.handle(
        _posterMeta,
        poster.isAcceptableOrUnknown(data['poster']!, _posterMeta),
      );
    }
    if (data.containsKey('duration_secs')) {
      context.handle(
        _durationSecsMeta,
        durationSecs.isAcceptableOrUnknown(
          data['duration_secs']!,
          _durationSecsMeta,
        ),
      );
    }
    if (data.containsKey('plot')) {
      context.handle(
        _plotMeta,
        plot.isAcceptableOrUnknown(data['plot']!, _plotMeta),
      );
    }
    if (data.containsKey('resolution')) {
      context.handle(
        _resolutionMeta,
        resolution.isAcceptableOrUnknown(data['resolution']!, _resolutionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {playlistId, episodeId},
  ];
  @override
  Episode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Episode(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      )!,
      episodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}episode_id'],
      )!,
      season: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}season'],
      )!,
      episodeNum: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode_num'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      streamUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stream_url'],
      )!,
      containerExtension: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}container_extension'],
      ),
      poster: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poster'],
      ),
      durationSecs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_secs'],
      ),
      plot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plot'],
      ),
      resolution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolution'],
      ),
    );
  }

  @override
  $EpisodesTable createAlias(String alias) {
    return $EpisodesTable(attachedDatabase, alias);
  }
}

class Episode extends DataClass implements Insertable<Episode> {
  final int id;
  final String playlistId;
  final String seriesId;
  final String episodeId;
  final int season;
  final int episodeNum;
  final String title;
  final String streamUrl;
  final String? containerExtension;
  final String? poster;
  final int? durationSecs;
  final String? plot;

  /// e.g. `1920×1080`, when the provider exposes stream info.
  final String? resolution;
  const Episode({
    required this.id,
    required this.playlistId,
    required this.seriesId,
    required this.episodeId,
    required this.season,
    required this.episodeNum,
    required this.title,
    required this.streamUrl,
    this.containerExtension,
    this.poster,
    this.durationSecs,
    this.plot,
    this.resolution,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['playlist_id'] = Variable<String>(playlistId);
    map['series_id'] = Variable<String>(seriesId);
    map['episode_id'] = Variable<String>(episodeId);
    map['season'] = Variable<int>(season);
    map['episode_num'] = Variable<int>(episodeNum);
    map['title'] = Variable<String>(title);
    map['stream_url'] = Variable<String>(streamUrl);
    if (!nullToAbsent || containerExtension != null) {
      map['container_extension'] = Variable<String>(containerExtension);
    }
    if (!nullToAbsent || poster != null) {
      map['poster'] = Variable<String>(poster);
    }
    if (!nullToAbsent || durationSecs != null) {
      map['duration_secs'] = Variable<int>(durationSecs);
    }
    if (!nullToAbsent || plot != null) {
      map['plot'] = Variable<String>(plot);
    }
    if (!nullToAbsent || resolution != null) {
      map['resolution'] = Variable<String>(resolution);
    }
    return map;
  }

  EpisodesCompanion toCompanion(bool nullToAbsent) {
    return EpisodesCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      seriesId: Value(seriesId),
      episodeId: Value(episodeId),
      season: Value(season),
      episodeNum: Value(episodeNum),
      title: Value(title),
      streamUrl: Value(streamUrl),
      containerExtension: containerExtension == null && nullToAbsent
          ? const Value.absent()
          : Value(containerExtension),
      poster: poster == null && nullToAbsent
          ? const Value.absent()
          : Value(poster),
      durationSecs: durationSecs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSecs),
      plot: plot == null && nullToAbsent ? const Value.absent() : Value(plot),
      resolution: resolution == null && nullToAbsent
          ? const Value.absent()
          : Value(resolution),
    );
  }

  factory Episode.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Episode(
      id: serializer.fromJson<int>(json['id']),
      playlistId: serializer.fromJson<String>(json['playlistId']),
      seriesId: serializer.fromJson<String>(json['seriesId']),
      episodeId: serializer.fromJson<String>(json['episodeId']),
      season: serializer.fromJson<int>(json['season']),
      episodeNum: serializer.fromJson<int>(json['episodeNum']),
      title: serializer.fromJson<String>(json['title']),
      streamUrl: serializer.fromJson<String>(json['streamUrl']),
      containerExtension: serializer.fromJson<String?>(
        json['containerExtension'],
      ),
      poster: serializer.fromJson<String?>(json['poster']),
      durationSecs: serializer.fromJson<int?>(json['durationSecs']),
      plot: serializer.fromJson<String?>(json['plot']),
      resolution: serializer.fromJson<String?>(json['resolution']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playlistId': serializer.toJson<String>(playlistId),
      'seriesId': serializer.toJson<String>(seriesId),
      'episodeId': serializer.toJson<String>(episodeId),
      'season': serializer.toJson<int>(season),
      'episodeNum': serializer.toJson<int>(episodeNum),
      'title': serializer.toJson<String>(title),
      'streamUrl': serializer.toJson<String>(streamUrl),
      'containerExtension': serializer.toJson<String?>(containerExtension),
      'poster': serializer.toJson<String?>(poster),
      'durationSecs': serializer.toJson<int?>(durationSecs),
      'plot': serializer.toJson<String?>(plot),
      'resolution': serializer.toJson<String?>(resolution),
    };
  }

  Episode copyWith({
    int? id,
    String? playlistId,
    String? seriesId,
    String? episodeId,
    int? season,
    int? episodeNum,
    String? title,
    String? streamUrl,
    Value<String?> containerExtension = const Value.absent(),
    Value<String?> poster = const Value.absent(),
    Value<int?> durationSecs = const Value.absent(),
    Value<String?> plot = const Value.absent(),
    Value<String?> resolution = const Value.absent(),
  }) => Episode(
    id: id ?? this.id,
    playlistId: playlistId ?? this.playlistId,
    seriesId: seriesId ?? this.seriesId,
    episodeId: episodeId ?? this.episodeId,
    season: season ?? this.season,
    episodeNum: episodeNum ?? this.episodeNum,
    title: title ?? this.title,
    streamUrl: streamUrl ?? this.streamUrl,
    containerExtension: containerExtension.present
        ? containerExtension.value
        : this.containerExtension,
    poster: poster.present ? poster.value : this.poster,
    durationSecs: durationSecs.present ? durationSecs.value : this.durationSecs,
    plot: plot.present ? plot.value : this.plot,
    resolution: resolution.present ? resolution.value : this.resolution,
  );
  Episode copyWithCompanion(EpisodesCompanion data) {
    return Episode(
      id: data.id.present ? data.id.value : this.id,
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      episodeId: data.episodeId.present ? data.episodeId.value : this.episodeId,
      season: data.season.present ? data.season.value : this.season,
      episodeNum: data.episodeNum.present
          ? data.episodeNum.value
          : this.episodeNum,
      title: data.title.present ? data.title.value : this.title,
      streamUrl: data.streamUrl.present ? data.streamUrl.value : this.streamUrl,
      containerExtension: data.containerExtension.present
          ? data.containerExtension.value
          : this.containerExtension,
      poster: data.poster.present ? data.poster.value : this.poster,
      durationSecs: data.durationSecs.present
          ? data.durationSecs.value
          : this.durationSecs,
      plot: data.plot.present ? data.plot.value : this.plot,
      resolution: data.resolution.present
          ? data.resolution.value
          : this.resolution,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Episode(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('seriesId: $seriesId, ')
          ..write('episodeId: $episodeId, ')
          ..write('season: $season, ')
          ..write('episodeNum: $episodeNum, ')
          ..write('title: $title, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('containerExtension: $containerExtension, ')
          ..write('poster: $poster, ')
          ..write('durationSecs: $durationSecs, ')
          ..write('plot: $plot, ')
          ..write('resolution: $resolution')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    playlistId,
    seriesId,
    episodeId,
    season,
    episodeNum,
    title,
    streamUrl,
    containerExtension,
    poster,
    durationSecs,
    plot,
    resolution,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Episode &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.seriesId == this.seriesId &&
          other.episodeId == this.episodeId &&
          other.season == this.season &&
          other.episodeNum == this.episodeNum &&
          other.title == this.title &&
          other.streamUrl == this.streamUrl &&
          other.containerExtension == this.containerExtension &&
          other.poster == this.poster &&
          other.durationSecs == this.durationSecs &&
          other.plot == this.plot &&
          other.resolution == this.resolution);
}

class EpisodesCompanion extends UpdateCompanion<Episode> {
  final Value<int> id;
  final Value<String> playlistId;
  final Value<String> seriesId;
  final Value<String> episodeId;
  final Value<int> season;
  final Value<int> episodeNum;
  final Value<String> title;
  final Value<String> streamUrl;
  final Value<String?> containerExtension;
  final Value<String?> poster;
  final Value<int?> durationSecs;
  final Value<String?> plot;
  final Value<String?> resolution;
  const EpisodesCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.episodeId = const Value.absent(),
    this.season = const Value.absent(),
    this.episodeNum = const Value.absent(),
    this.title = const Value.absent(),
    this.streamUrl = const Value.absent(),
    this.containerExtension = const Value.absent(),
    this.poster = const Value.absent(),
    this.durationSecs = const Value.absent(),
    this.plot = const Value.absent(),
    this.resolution = const Value.absent(),
  });
  EpisodesCompanion.insert({
    this.id = const Value.absent(),
    required String playlistId,
    required String seriesId,
    required String episodeId,
    required int season,
    required int episodeNum,
    required String title,
    this.streamUrl = const Value.absent(),
    this.containerExtension = const Value.absent(),
    this.poster = const Value.absent(),
    this.durationSecs = const Value.absent(),
    this.plot = const Value.absent(),
    this.resolution = const Value.absent(),
  }) : playlistId = Value(playlistId),
       seriesId = Value(seriesId),
       episodeId = Value(episodeId),
       season = Value(season),
       episodeNum = Value(episodeNum),
       title = Value(title);
  static Insertable<Episode> custom({
    Expression<int>? id,
    Expression<String>? playlistId,
    Expression<String>? seriesId,
    Expression<String>? episodeId,
    Expression<int>? season,
    Expression<int>? episodeNum,
    Expression<String>? title,
    Expression<String>? streamUrl,
    Expression<String>? containerExtension,
    Expression<String>? poster,
    Expression<int>? durationSecs,
    Expression<String>? plot,
    Expression<String>? resolution,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (seriesId != null) 'series_id': seriesId,
      if (episodeId != null) 'episode_id': episodeId,
      if (season != null) 'season': season,
      if (episodeNum != null) 'episode_num': episodeNum,
      if (title != null) 'title': title,
      if (streamUrl != null) 'stream_url': streamUrl,
      if (containerExtension != null) 'container_extension': containerExtension,
      if (poster != null) 'poster': poster,
      if (durationSecs != null) 'duration_secs': durationSecs,
      if (plot != null) 'plot': plot,
      if (resolution != null) 'resolution': resolution,
    });
  }

  EpisodesCompanion copyWith({
    Value<int>? id,
    Value<String>? playlistId,
    Value<String>? seriesId,
    Value<String>? episodeId,
    Value<int>? season,
    Value<int>? episodeNum,
    Value<String>? title,
    Value<String>? streamUrl,
    Value<String?>? containerExtension,
    Value<String?>? poster,
    Value<int?>? durationSecs,
    Value<String?>? plot,
    Value<String?>? resolution,
  }) {
    return EpisodesCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      seriesId: seriesId ?? this.seriesId,
      episodeId: episodeId ?? this.episodeId,
      season: season ?? this.season,
      episodeNum: episodeNum ?? this.episodeNum,
      title: title ?? this.title,
      streamUrl: streamUrl ?? this.streamUrl,
      containerExtension: containerExtension ?? this.containerExtension,
      poster: poster ?? this.poster,
      durationSecs: durationSecs ?? this.durationSecs,
      plot: plot ?? this.plot,
      resolution: resolution ?? this.resolution,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (episodeId.present) {
      map['episode_id'] = Variable<String>(episodeId.value);
    }
    if (season.present) {
      map['season'] = Variable<int>(season.value);
    }
    if (episodeNum.present) {
      map['episode_num'] = Variable<int>(episodeNum.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (streamUrl.present) {
      map['stream_url'] = Variable<String>(streamUrl.value);
    }
    if (containerExtension.present) {
      map['container_extension'] = Variable<String>(containerExtension.value);
    }
    if (poster.present) {
      map['poster'] = Variable<String>(poster.value);
    }
    if (durationSecs.present) {
      map['duration_secs'] = Variable<int>(durationSecs.value);
    }
    if (plot.present) {
      map['plot'] = Variable<String>(plot.value);
    }
    if (resolution.present) {
      map['resolution'] = Variable<String>(resolution.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpisodesCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('seriesId: $seriesId, ')
          ..write('episodeId: $episodeId, ')
          ..write('season: $season, ')
          ..write('episodeNum: $episodeNum, ')
          ..write('title: $title, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('containerExtension: $containerExtension, ')
          ..write('poster: $poster, ')
          ..write('durationSecs: $durationSecs, ')
          ..write('plot: $plot, ')
          ..write('resolution: $resolution')
          ..write(')'))
        .toString();
  }
}

class $EpgProgramsTable extends EpgPrograms
    with TableInfo<$EpgProgramsTable, EpgProgram> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpgProgramsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES playlists (id) ON DELETE CASCADE',
  );
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMeta = const VerificationMeta('start');
  @override
  late final GeneratedColumn<DateTime> start = GeneratedColumn<DateTime>(
    'start',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMeta = const VerificationMeta('end');
  @override
  late final GeneratedColumn<DateTime> end = GeneratedColumn<DateTime>(
    'end',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    playlistId,
    channelId,
    start,
    end,
    title,
    description,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'epg_programs';
  @override
  VerificationContext validateIntegrity(
    Insertable<EpgProgram> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('start')) {
      context.handle(
        _startMeta,
        start.isAcceptableOrUnknown(data['start']!, _startMeta),
      );
    } else if (isInserting) {
      context.missing(_startMeta);
    }
    if (data.containsKey('end')) {
      context.handle(
        _endMeta,
        end.isAcceptableOrUnknown(data['end']!, _endMeta),
      );
    } else if (isInserting) {
      context.missing(_endMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EpgProgram map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EpgProgram(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_id'],
      )!,
      channelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel_id'],
      )!,
      start: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start'],
      )!,
      end: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
    );
  }

  @override
  $EpgProgramsTable createAlias(String alias) {
    return $EpgProgramsTable(attachedDatabase, alias);
  }
}

class EpgProgram extends DataClass implements Insertable<EpgProgram> {
  final int id;
  final String playlistId;
  final String channelId;
  final DateTime start;
  final DateTime end;
  final String title;
  final String? description;
  const EpgProgram({
    required this.id,
    required this.playlistId,
    required this.channelId,
    required this.start,
    required this.end,
    required this.title,
    this.description,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['playlist_id'] = Variable<String>(playlistId);
    map['channel_id'] = Variable<String>(channelId);
    map['start'] = Variable<DateTime>(start);
    map['end'] = Variable<DateTime>(end);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    return map;
  }

  EpgProgramsCompanion toCompanion(bool nullToAbsent) {
    return EpgProgramsCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      channelId: Value(channelId),
      start: Value(start),
      end: Value(end),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
    );
  }

  factory EpgProgram.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EpgProgram(
      id: serializer.fromJson<int>(json['id']),
      playlistId: serializer.fromJson<String>(json['playlistId']),
      channelId: serializer.fromJson<String>(json['channelId']),
      start: serializer.fromJson<DateTime>(json['start']),
      end: serializer.fromJson<DateTime>(json['end']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playlistId': serializer.toJson<String>(playlistId),
      'channelId': serializer.toJson<String>(channelId),
      'start': serializer.toJson<DateTime>(start),
      'end': serializer.toJson<DateTime>(end),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
    };
  }

  EpgProgram copyWith({
    int? id,
    String? playlistId,
    String? channelId,
    DateTime? start,
    DateTime? end,
    String? title,
    Value<String?> description = const Value.absent(),
  }) => EpgProgram(
    id: id ?? this.id,
    playlistId: playlistId ?? this.playlistId,
    channelId: channelId ?? this.channelId,
    start: start ?? this.start,
    end: end ?? this.end,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
  );
  EpgProgram copyWithCompanion(EpgProgramsCompanion data) {
    return EpgProgram(
      id: data.id.present ? data.id.value : this.id,
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      start: data.start.present ? data.start.value : this.start,
      end: data.end.present ? data.end.value : this.end,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EpgProgram(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('channelId: $channelId, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('title: $title, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, playlistId, channelId, start, end, title, description);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EpgProgram &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.channelId == this.channelId &&
          other.start == this.start &&
          other.end == this.end &&
          other.title == this.title &&
          other.description == this.description);
}

class EpgProgramsCompanion extends UpdateCompanion<EpgProgram> {
  final Value<int> id;
  final Value<String> playlistId;
  final Value<String> channelId;
  final Value<DateTime> start;
  final Value<DateTime> end;
  final Value<String> title;
  final Value<String?> description;
  const EpgProgramsCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.channelId = const Value.absent(),
    this.start = const Value.absent(),
    this.end = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
  });
  EpgProgramsCompanion.insert({
    this.id = const Value.absent(),
    required String playlistId,
    required String channelId,
    required DateTime start,
    required DateTime end,
    required String title,
    this.description = const Value.absent(),
  }) : playlistId = Value(playlistId),
       channelId = Value(channelId),
       start = Value(start),
       end = Value(end),
       title = Value(title);
  static Insertable<EpgProgram> custom({
    Expression<int>? id,
    Expression<String>? playlistId,
    Expression<String>? channelId,
    Expression<DateTime>? start,
    Expression<DateTime>? end,
    Expression<String>? title,
    Expression<String>? description,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (channelId != null) 'channel_id': channelId,
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
    });
  }

  EpgProgramsCompanion copyWith({
    Value<int>? id,
    Value<String>? playlistId,
    Value<String>? channelId,
    Value<DateTime>? start,
    Value<DateTime>? end,
    Value<String>? title,
    Value<String?>? description,
  }) {
    return EpgProgramsCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      channelId: channelId ?? this.channelId,
      start: start ?? this.start,
      end: end ?? this.end,
      title: title ?? this.title,
      description: description ?? this.description,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (start.present) {
      map['start'] = Variable<DateTime>(start.value);
    }
    if (end.present) {
      map['end'] = Variable<DateTime>(end.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpgProgramsCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('channelId: $channelId, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('title: $title, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }
}

class $FavoritesTable extends Favorites
    with TableInfo<$FavoritesTable, Favorite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES playlists (id) ON DELETE CASCADE',
  );
  @override
  late final GeneratedColumnWithTypeConverter<ContentKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ContentKind>($FavoritesTable.$converterkind);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, playlistId, kind, itemId, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<Favorite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {playlistId, kind, itemId},
  ];
  @override
  Favorite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Favorite(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_id'],
      )!,
      kind: $FavoritesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $FavoritesTable createAlias(String alias) {
    return $FavoritesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ContentKind, String, String> $converterkind =
      const EnumNameConverter<ContentKind>(ContentKind.values);
}

class Favorite extends DataClass implements Insertable<Favorite> {
  final int id;
  final String playlistId;
  final ContentKind kind;
  final String itemId;
  final DateTime addedAt;
  const Favorite({
    required this.id,
    required this.playlistId,
    required this.kind,
    required this.itemId,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['playlist_id'] = Variable<String>(playlistId);
    {
      map['kind'] = Variable<String>(
        $FavoritesTable.$converterkind.toSql(kind),
      );
    }
    map['item_id'] = Variable<String>(itemId);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      kind: Value(kind),
      itemId: Value(itemId),
      addedAt: Value(addedAt),
    );
  }

  factory Favorite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Favorite(
      id: serializer.fromJson<int>(json['id']),
      playlistId: serializer.fromJson<String>(json['playlistId']),
      kind: $FavoritesTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      itemId: serializer.fromJson<String>(json['itemId']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playlistId': serializer.toJson<String>(playlistId),
      'kind': serializer.toJson<String>(
        $FavoritesTable.$converterkind.toJson(kind),
      ),
      'itemId': serializer.toJson<String>(itemId),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  Favorite copyWith({
    int? id,
    String? playlistId,
    ContentKind? kind,
    String? itemId,
    DateTime? addedAt,
  }) => Favorite(
    id: id ?? this.id,
    playlistId: playlistId ?? this.playlistId,
    kind: kind ?? this.kind,
    itemId: itemId ?? this.itemId,
    addedAt: addedAt ?? this.addedAt,
  );
  Favorite copyWithCompanion(FavoritesCompanion data) {
    return Favorite(
      id: data.id.present ? data.id.value : this.id,
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      kind: data.kind.present ? data.kind.value : this.kind,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Favorite(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('kind: $kind, ')
          ..write('itemId: $itemId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, playlistId, kind, itemId, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Favorite &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.kind == this.kind &&
          other.itemId == this.itemId &&
          other.addedAt == this.addedAt);
}

class FavoritesCompanion extends UpdateCompanion<Favorite> {
  final Value<int> id;
  final Value<String> playlistId;
  final Value<ContentKind> kind;
  final Value<String> itemId;
  final Value<DateTime> addedAt;
  const FavoritesCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.kind = const Value.absent(),
    this.itemId = const Value.absent(),
    this.addedAt = const Value.absent(),
  });
  FavoritesCompanion.insert({
    this.id = const Value.absent(),
    required String playlistId,
    required ContentKind kind,
    required String itemId,
    this.addedAt = const Value.absent(),
  }) : playlistId = Value(playlistId),
       kind = Value(kind),
       itemId = Value(itemId);
  static Insertable<Favorite> custom({
    Expression<int>? id,
    Expression<String>? playlistId,
    Expression<String>? kind,
    Expression<String>? itemId,
    Expression<DateTime>? addedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (kind != null) 'kind': kind,
      if (itemId != null) 'item_id': itemId,
      if (addedAt != null) 'added_at': addedAt,
    });
  }

  FavoritesCompanion copyWith({
    Value<int>? id,
    Value<String>? playlistId,
    Value<ContentKind>? kind,
    Value<String>? itemId,
    Value<DateTime>? addedAt,
  }) {
    return FavoritesCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      kind: kind ?? this.kind,
      itemId: itemId ?? this.itemId,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $FavoritesTable.$converterkind.toSql(kind.value),
      );
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('kind: $kind, ')
          ..write('itemId: $itemId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }
}

class $HistoryTable extends History with TableInfo<$HistoryTable, HistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES playlists (id) ON DELETE CASCADE',
  );
  @override
  late final GeneratedColumnWithTypeConverter<ContentKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ContentKind>($HistoryTable.$converterkind);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMsMeta = const VerificationMeta(
    'positionMs',
  );
  @override
  late final GeneratedColumn<int> positionMs = GeneratedColumn<int>(
    'position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _watchedAtMeta = const VerificationMeta(
    'watchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> watchedAt = GeneratedColumn<DateTime>(
    'watched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    playlistId,
    kind,
    itemId,
    parentId,
    positionMs,
    durationMs,
    watchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'history';
  @override
  VerificationContext validateIntegrity(
    Insertable<HistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('position_ms')) {
      context.handle(
        _positionMsMeta,
        positionMs.isAcceptableOrUnknown(data['position_ms']!, _positionMsMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('watched_at')) {
      context.handle(
        _watchedAtMeta,
        watchedAt.isAcceptableOrUnknown(data['watched_at']!, _watchedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {playlistId, kind, itemId},
  ];
  @override
  HistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_id'],
      )!,
      kind: $HistoryTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      positionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_ms'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      watchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}watched_at'],
      )!,
    );
  }

  @override
  $HistoryTable createAlias(String alias) {
    return $HistoryTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ContentKind, String, String> $converterkind =
      const EnumNameConverter<ContentKind>(ContentKind.values);
}

class HistoryData extends DataClass implements Insertable<HistoryData> {
  final int id;
  final String playlistId;
  final ContentKind kind;

  /// Channel streamId, movie streamId or episodeId.
  final String itemId;

  /// For episodes: the parent series id, so "continue watching" can group by series.
  final String? parentId;
  final int positionMs;
  final int durationMs;
  final DateTime watchedAt;
  const HistoryData({
    required this.id,
    required this.playlistId,
    required this.kind,
    required this.itemId,
    this.parentId,
    required this.positionMs,
    required this.durationMs,
    required this.watchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['playlist_id'] = Variable<String>(playlistId);
    {
      map['kind'] = Variable<String>($HistoryTable.$converterkind.toSql(kind));
    }
    map['item_id'] = Variable<String>(itemId);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['position_ms'] = Variable<int>(positionMs);
    map['duration_ms'] = Variable<int>(durationMs);
    map['watched_at'] = Variable<DateTime>(watchedAt);
    return map;
  }

  HistoryCompanion toCompanion(bool nullToAbsent) {
    return HistoryCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      kind: Value(kind),
      itemId: Value(itemId),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      positionMs: Value(positionMs),
      durationMs: Value(durationMs),
      watchedAt: Value(watchedAt),
    );
  }

  factory HistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HistoryData(
      id: serializer.fromJson<int>(json['id']),
      playlistId: serializer.fromJson<String>(json['playlistId']),
      kind: $HistoryTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      itemId: serializer.fromJson<String>(json['itemId']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      positionMs: serializer.fromJson<int>(json['positionMs']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      watchedAt: serializer.fromJson<DateTime>(json['watchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playlistId': serializer.toJson<String>(playlistId),
      'kind': serializer.toJson<String>(
        $HistoryTable.$converterkind.toJson(kind),
      ),
      'itemId': serializer.toJson<String>(itemId),
      'parentId': serializer.toJson<String?>(parentId),
      'positionMs': serializer.toJson<int>(positionMs),
      'durationMs': serializer.toJson<int>(durationMs),
      'watchedAt': serializer.toJson<DateTime>(watchedAt),
    };
  }

  HistoryData copyWith({
    int? id,
    String? playlistId,
    ContentKind? kind,
    String? itemId,
    Value<String?> parentId = const Value.absent(),
    int? positionMs,
    int? durationMs,
    DateTime? watchedAt,
  }) => HistoryData(
    id: id ?? this.id,
    playlistId: playlistId ?? this.playlistId,
    kind: kind ?? this.kind,
    itemId: itemId ?? this.itemId,
    parentId: parentId.present ? parentId.value : this.parentId,
    positionMs: positionMs ?? this.positionMs,
    durationMs: durationMs ?? this.durationMs,
    watchedAt: watchedAt ?? this.watchedAt,
  );
  HistoryData copyWithCompanion(HistoryCompanion data) {
    return HistoryData(
      id: data.id.present ? data.id.value : this.id,
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      kind: data.kind.present ? data.kind.value : this.kind,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      positionMs: data.positionMs.present
          ? data.positionMs.value
          : this.positionMs,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      watchedAt: data.watchedAt.present ? data.watchedAt.value : this.watchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HistoryData(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('kind: $kind, ')
          ..write('itemId: $itemId, ')
          ..write('parentId: $parentId, ')
          ..write('positionMs: $positionMs, ')
          ..write('durationMs: $durationMs, ')
          ..write('watchedAt: $watchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    playlistId,
    kind,
    itemId,
    parentId,
    positionMs,
    durationMs,
    watchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryData &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.kind == this.kind &&
          other.itemId == this.itemId &&
          other.parentId == this.parentId &&
          other.positionMs == this.positionMs &&
          other.durationMs == this.durationMs &&
          other.watchedAt == this.watchedAt);
}

class HistoryCompanion extends UpdateCompanion<HistoryData> {
  final Value<int> id;
  final Value<String> playlistId;
  final Value<ContentKind> kind;
  final Value<String> itemId;
  final Value<String?> parentId;
  final Value<int> positionMs;
  final Value<int> durationMs;
  final Value<DateTime> watchedAt;
  const HistoryCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.kind = const Value.absent(),
    this.itemId = const Value.absent(),
    this.parentId = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.watchedAt = const Value.absent(),
  });
  HistoryCompanion.insert({
    this.id = const Value.absent(),
    required String playlistId,
    required ContentKind kind,
    required String itemId,
    this.parentId = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.watchedAt = const Value.absent(),
  }) : playlistId = Value(playlistId),
       kind = Value(kind),
       itemId = Value(itemId);
  static Insertable<HistoryData> custom({
    Expression<int>? id,
    Expression<String>? playlistId,
    Expression<String>? kind,
    Expression<String>? itemId,
    Expression<String>? parentId,
    Expression<int>? positionMs,
    Expression<int>? durationMs,
    Expression<DateTime>? watchedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (kind != null) 'kind': kind,
      if (itemId != null) 'item_id': itemId,
      if (parentId != null) 'parent_id': parentId,
      if (positionMs != null) 'position_ms': positionMs,
      if (durationMs != null) 'duration_ms': durationMs,
      if (watchedAt != null) 'watched_at': watchedAt,
    });
  }

  HistoryCompanion copyWith({
    Value<int>? id,
    Value<String>? playlistId,
    Value<ContentKind>? kind,
    Value<String>? itemId,
    Value<String?>? parentId,
    Value<int>? positionMs,
    Value<int>? durationMs,
    Value<DateTime>? watchedAt,
  }) {
    return HistoryCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      kind: kind ?? this.kind,
      itemId: itemId ?? this.itemId,
      parentId: parentId ?? this.parentId,
      positionMs: positionMs ?? this.positionMs,
      durationMs: durationMs ?? this.durationMs,
      watchedAt: watchedAt ?? this.watchedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $HistoryTable.$converterkind.toSql(kind.value),
      );
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (positionMs.present) {
      map['position_ms'] = Variable<int>(positionMs.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (watchedAt.present) {
      map['watched_at'] = Variable<DateTime>(watchedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoryCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('kind: $kind, ')
          ..write('itemId: $itemId, ')
          ..write('parentId: $parentId, ')
          ..write('positionMs: $positionMs, ')
          ..write('durationMs: $durationMs, ')
          ..write('watchedAt: $watchedAt')
          ..write(')'))
        .toString();
  }
}

class $ChannelGroupsTable extends ChannelGroups
    with TableInfo<$ChannelGroupsTable, ChannelGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChannelGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES playlists (id) ON DELETE CASCADE',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, playlistId, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'channel_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChannelGroup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChannelGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChannelGroup(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $ChannelGroupsTable createAlias(String alias) {
    return $ChannelGroupsTable(attachedDatabase, alias);
  }
}

class ChannelGroup extends DataClass implements Insertable<ChannelGroup> {
  final int id;
  final String playlistId;
  final String name;
  const ChannelGroup({
    required this.id,
    required this.playlistId,
    required this.name,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['playlist_id'] = Variable<String>(playlistId);
    map['name'] = Variable<String>(name);
    return map;
  }

  ChannelGroupsCompanion toCompanion(bool nullToAbsent) {
    return ChannelGroupsCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      name: Value(name),
    );
  }

  factory ChannelGroup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChannelGroup(
      id: serializer.fromJson<int>(json['id']),
      playlistId: serializer.fromJson<String>(json['playlistId']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playlistId': serializer.toJson<String>(playlistId),
      'name': serializer.toJson<String>(name),
    };
  }

  ChannelGroup copyWith({int? id, String? playlistId, String? name}) =>
      ChannelGroup(
        id: id ?? this.id,
        playlistId: playlistId ?? this.playlistId,
        name: name ?? this.name,
      );
  ChannelGroup copyWithCompanion(ChannelGroupsCompanion data) {
    return ChannelGroup(
      id: data.id.present ? data.id.value : this.id,
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChannelGroup(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, playlistId, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChannelGroup &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.name == this.name);
}

class ChannelGroupsCompanion extends UpdateCompanion<ChannelGroup> {
  final Value<int> id;
  final Value<String> playlistId;
  final Value<String> name;
  const ChannelGroupsCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.name = const Value.absent(),
  });
  ChannelGroupsCompanion.insert({
    this.id = const Value.absent(),
    required String playlistId,
    required String name,
  }) : playlistId = Value(playlistId),
       name = Value(name);
  static Insertable<ChannelGroup> custom({
    Expression<int>? id,
    Expression<String>? playlistId,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (name != null) 'name': name,
    });
  }

  ChannelGroupsCompanion copyWith({
    Value<int>? id,
    Value<String>? playlistId,
    Value<String>? name,
  }) {
    return ChannelGroupsCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChannelGroupsCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $GroupChannelsTable extends GroupChannels
    with TableInfo<$GroupChannelsTable, GroupChannel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupChannelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<int> groupId = GeneratedColumn<int>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES channel_groups (id) ON DELETE CASCADE',
  );
  static const VerificationMeta _streamIdMeta = const VerificationMeta(
    'streamId',
  );
  @override
  late final GeneratedColumn<String> streamId = GeneratedColumn<String>(
    'stream_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [groupId, streamId, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_channels';
  @override
  VerificationContext validateIntegrity(
    Insertable<GroupChannel> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('stream_id')) {
      context.handle(
        _streamIdMeta,
        streamId.isAcceptableOrUnknown(data['stream_id']!, _streamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_streamIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId, streamId};
  @override
  GroupChannel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupChannel(
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_id'],
      )!,
      streamId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stream_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $GroupChannelsTable createAlias(String alias) {
    return $GroupChannelsTable(attachedDatabase, alias);
  }
}

class GroupChannel extends DataClass implements Insertable<GroupChannel> {
  final int groupId;
  final String streamId;
  final int position;
  const GroupChannel({
    required this.groupId,
    required this.streamId,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<int>(groupId);
    map['stream_id'] = Variable<String>(streamId);
    map['position'] = Variable<int>(position);
    return map;
  }

  GroupChannelsCompanion toCompanion(bool nullToAbsent) {
    return GroupChannelsCompanion(
      groupId: Value(groupId),
      streamId: Value(streamId),
      position: Value(position),
    );
  }

  factory GroupChannel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupChannel(
      groupId: serializer.fromJson<int>(json['groupId']),
      streamId: serializer.fromJson<String>(json['streamId']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<int>(groupId),
      'streamId': serializer.toJson<String>(streamId),
      'position': serializer.toJson<int>(position),
    };
  }

  GroupChannel copyWith({int? groupId, String? streamId, int? position}) =>
      GroupChannel(
        groupId: groupId ?? this.groupId,
        streamId: streamId ?? this.streamId,
        position: position ?? this.position,
      );
  GroupChannel copyWithCompanion(GroupChannelsCompanion data) {
    return GroupChannel(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      streamId: data.streamId.present ? data.streamId.value : this.streamId,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupChannel(')
          ..write('groupId: $groupId, ')
          ..write('streamId: $streamId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(groupId, streamId, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupChannel &&
          other.groupId == this.groupId &&
          other.streamId == this.streamId &&
          other.position == this.position);
}

class GroupChannelsCompanion extends UpdateCompanion<GroupChannel> {
  final Value<int> groupId;
  final Value<String> streamId;
  final Value<int> position;
  final Value<int> rowid;
  const GroupChannelsCompanion({
    this.groupId = const Value.absent(),
    this.streamId = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupChannelsCompanion.insert({
    required int groupId,
    required String streamId,
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : groupId = Value(groupId),
       streamId = Value(streamId);
  static Insertable<GroupChannel> custom({
    Expression<int>? groupId,
    Expression<String>? streamId,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (streamId != null) 'stream_id': streamId,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupChannelsCompanion copyWith({
    Value<int>? groupId,
    Value<String>? streamId,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return GroupChannelsCompanion(
      groupId: groupId ?? this.groupId,
      streamId: streamId ?? this.streamId,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<int>(groupId.value);
    }
    if (streamId.present) {
      map['stream_id'] = Variable<String>(streamId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupChannelsCompanion(')
          ..write('groupId: $groupId, ')
          ..write('streamId: $streamId, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LockedChannelsTable extends LockedChannels
    with TableInfo<$LockedChannelsTable, LockedChannel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LockedChannelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES playlists (id) ON DELETE CASCADE',
  );
  static const VerificationMeta _streamIdMeta = const VerificationMeta(
    'streamId',
  );
  @override
  late final GeneratedColumn<String> streamId = GeneratedColumn<String>(
    'stream_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [playlistId, streamId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'locked_channels';
  @override
  VerificationContext validateIntegrity(
    Insertable<LockedChannel> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('stream_id')) {
      context.handle(
        _streamIdMeta,
        streamId.isAcceptableOrUnknown(data['stream_id']!, _streamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_streamIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playlistId, streamId};
  @override
  LockedChannel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LockedChannel(
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_id'],
      )!,
      streamId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stream_id'],
      )!,
    );
  }

  @override
  $LockedChannelsTable createAlias(String alias) {
    return $LockedChannelsTable(attachedDatabase, alias);
  }
}

class LockedChannel extends DataClass implements Insertable<LockedChannel> {
  final String playlistId;
  final String streamId;
  const LockedChannel({required this.playlistId, required this.streamId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['playlist_id'] = Variable<String>(playlistId);
    map['stream_id'] = Variable<String>(streamId);
    return map;
  }

  LockedChannelsCompanion toCompanion(bool nullToAbsent) {
    return LockedChannelsCompanion(
      playlistId: Value(playlistId),
      streamId: Value(streamId),
    );
  }

  factory LockedChannel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LockedChannel(
      playlistId: serializer.fromJson<String>(json['playlistId']),
      streamId: serializer.fromJson<String>(json['streamId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playlistId': serializer.toJson<String>(playlistId),
      'streamId': serializer.toJson<String>(streamId),
    };
  }

  LockedChannel copyWith({String? playlistId, String? streamId}) =>
      LockedChannel(
        playlistId: playlistId ?? this.playlistId,
        streamId: streamId ?? this.streamId,
      );
  LockedChannel copyWithCompanion(LockedChannelsCompanion data) {
    return LockedChannel(
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      streamId: data.streamId.present ? data.streamId.value : this.streamId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LockedChannel(')
          ..write('playlistId: $playlistId, ')
          ..write('streamId: $streamId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(playlistId, streamId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LockedChannel &&
          other.playlistId == this.playlistId &&
          other.streamId == this.streamId);
}

class LockedChannelsCompanion extends UpdateCompanion<LockedChannel> {
  final Value<String> playlistId;
  final Value<String> streamId;
  final Value<int> rowid;
  const LockedChannelsCompanion({
    this.playlistId = const Value.absent(),
    this.streamId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LockedChannelsCompanion.insert({
    required String playlistId,
    required String streamId,
    this.rowid = const Value.absent(),
  }) : playlistId = Value(playlistId),
       streamId = Value(streamId);
  static Insertable<LockedChannel> custom({
    Expression<String>? playlistId,
    Expression<String>? streamId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playlistId != null) 'playlist_id': playlistId,
      if (streamId != null) 'stream_id': streamId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LockedChannelsCompanion copyWith({
    Value<String>? playlistId,
    Value<String>? streamId,
    Value<int>? rowid,
  }) {
    return LockedChannelsCompanion(
      playlistId: playlistId ?? this.playlistId,
      streamId: streamId ?? this.streamId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (streamId.present) {
      map['stream_id'] = Variable<String>(streamId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LockedChannelsCompanion(')
          ..write('playlistId: $playlistId, ')
          ..write('streamId: $streamId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HiddenCategoriesTable extends HiddenCategories
    with TableInfo<$HiddenCategoriesTable, HiddenCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HiddenCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES playlists (id) ON DELETE CASCADE',
  );
  @override
  late final GeneratedColumnWithTypeConverter<ContentKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ContentKind>($HiddenCategoriesTable.$converterkind);
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [playlistId, kind, categoryId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hidden_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<HiddenCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playlistId, kind, categoryId};
  @override
  HiddenCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HiddenCategory(
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_id'],
      )!,
      kind: $HiddenCategoriesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
    );
  }

  @override
  $HiddenCategoriesTable createAlias(String alias) {
    return $HiddenCategoriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ContentKind, String, String> $converterkind =
      const EnumNameConverter<ContentKind>(ContentKind.values);
}

class HiddenCategory extends DataClass implements Insertable<HiddenCategory> {
  final String playlistId;
  final ContentKind kind;
  final String categoryId;
  const HiddenCategory({
    required this.playlistId,
    required this.kind,
    required this.categoryId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['playlist_id'] = Variable<String>(playlistId);
    {
      map['kind'] = Variable<String>(
        $HiddenCategoriesTable.$converterkind.toSql(kind),
      );
    }
    map['category_id'] = Variable<String>(categoryId);
    return map;
  }

  HiddenCategoriesCompanion toCompanion(bool nullToAbsent) {
    return HiddenCategoriesCompanion(
      playlistId: Value(playlistId),
      kind: Value(kind),
      categoryId: Value(categoryId),
    );
  }

  factory HiddenCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HiddenCategory(
      playlistId: serializer.fromJson<String>(json['playlistId']),
      kind: $HiddenCategoriesTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      categoryId: serializer.fromJson<String>(json['categoryId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playlistId': serializer.toJson<String>(playlistId),
      'kind': serializer.toJson<String>(
        $HiddenCategoriesTable.$converterkind.toJson(kind),
      ),
      'categoryId': serializer.toJson<String>(categoryId),
    };
  }

  HiddenCategory copyWith({
    String? playlistId,
    ContentKind? kind,
    String? categoryId,
  }) => HiddenCategory(
    playlistId: playlistId ?? this.playlistId,
    kind: kind ?? this.kind,
    categoryId: categoryId ?? this.categoryId,
  );
  HiddenCategory copyWithCompanion(HiddenCategoriesCompanion data) {
    return HiddenCategory(
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      kind: data.kind.present ? data.kind.value : this.kind,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HiddenCategory(')
          ..write('playlistId: $playlistId, ')
          ..write('kind: $kind, ')
          ..write('categoryId: $categoryId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(playlistId, kind, categoryId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HiddenCategory &&
          other.playlistId == this.playlistId &&
          other.kind == this.kind &&
          other.categoryId == this.categoryId);
}

class HiddenCategoriesCompanion extends UpdateCompanion<HiddenCategory> {
  final Value<String> playlistId;
  final Value<ContentKind> kind;
  final Value<String> categoryId;
  final Value<int> rowid;
  const HiddenCategoriesCompanion({
    this.playlistId = const Value.absent(),
    this.kind = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HiddenCategoriesCompanion.insert({
    required String playlistId,
    required ContentKind kind,
    required String categoryId,
    this.rowid = const Value.absent(),
  }) : playlistId = Value(playlistId),
       kind = Value(kind),
       categoryId = Value(categoryId);
  static Insertable<HiddenCategory> custom({
    Expression<String>? playlistId,
    Expression<String>? kind,
    Expression<String>? categoryId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playlistId != null) 'playlist_id': playlistId,
      if (kind != null) 'kind': kind,
      if (categoryId != null) 'category_id': categoryId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HiddenCategoriesCompanion copyWith({
    Value<String>? playlistId,
    Value<ContentKind>? kind,
    Value<String>? categoryId,
    Value<int>? rowid,
  }) {
    return HiddenCategoriesCompanion(
      playlistId: playlistId ?? this.playlistId,
      kind: kind ?? this.kind,
      categoryId: categoryId ?? this.categoryId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $HiddenCategoriesTable.$converterkind.toSql(kind.value),
      );
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HiddenCategoriesCompanion(')
          ..write('playlistId: $playlistId, ')
          ..write('kind: $kind, ')
          ..write('categoryId: $categoryId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PlaylistsTable playlists = $PlaylistsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $ChannelsTable channels = $ChannelsTable(this);
  late final $MoviesTable movies = $MoviesTable(this);
  late final $SeriesItemsTable seriesItems = $SeriesItemsTable(this);
  late final $EpisodesTable episodes = $EpisodesTable(this);
  late final $EpgProgramsTable epgPrograms = $EpgProgramsTable(this);
  late final $FavoritesTable favorites = $FavoritesTable(this);
  late final $HistoryTable history = $HistoryTable(this);
  late final $ChannelGroupsTable channelGroups = $ChannelGroupsTable(this);
  late final $GroupChannelsTable groupChannels = $GroupChannelsTable(this);
  late final $LockedChannelsTable lockedChannels = $LockedChannelsTable(this);
  late final $HiddenCategoriesTable hiddenCategories = $HiddenCategoriesTable(
    this,
  );
  late final Index epgChannelStart = Index(
    'epg_channel_start',
    'CREATE INDEX epg_channel_start ON epg_programs (playlist_id, channel_id, start)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    playlists,
    categories,
    channels,
    movies,
    seriesItems,
    episodes,
    epgPrograms,
    favorites,
    history,
    channelGroups,
    groupChannels,
    lockedChannels,
    hiddenCategories,
    epgChannelStart,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('categories', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('channels', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('movies', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('series_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('episodes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('epg_programs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('favorites', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('history', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('channel_groups', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'channel_groups',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('group_channels', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('locked_channels', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('hidden_categories', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$PlaylistsTableCreateCompanionBuilder =
    PlaylistsCompanion Function({
      required String id,
      required String name,
      required PlaylistType type,
      required PlaylistSource source,
      required String url,
      Value<String?> username,
      Value<String?> password,
      Value<String?> epgUrl,
      Value<bool> isProtected,
      Value<String?> pinCode,
      Value<DateTime?> expiresAt,
      Value<int> position,
      Value<DateTime?> lastSyncedAt,
      Value<String?> accountInfo,
      Value<int> rowid,
    });
typedef $$PlaylistsTableUpdateCompanionBuilder =
    PlaylistsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<PlaylistType> type,
      Value<PlaylistSource> source,
      Value<String> url,
      Value<String?> username,
      Value<String?> password,
      Value<String?> epgUrl,
      Value<bool> isProtected,
      Value<String?> pinCode,
      Value<DateTime?> expiresAt,
      Value<int> position,
      Value<DateTime?> lastSyncedAt,
      Value<String?> accountInfo,
      Value<int> rowid,
    });

final class $$PlaylistsTableReferences
    extends BaseReferences<_$AppDatabase, $PlaylistsTable, Playlist> {
  $$PlaylistsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CategoriesTable, List<ContentCategory>>
  _categoriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.categories,
    aliasName: $_aliasNameGenerator(db.playlists.id, db.categories.playlistId),
  );

  $$CategoriesTableProcessedTableManager get categoriesRefs {
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_categoriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ChannelsTable, List<Channel>> _channelsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.channels,
    aliasName: $_aliasNameGenerator(db.playlists.id, db.channels.playlistId),
  );

  $$ChannelsTableProcessedTableManager get channelsRefs {
    final manager = $$ChannelsTableTableManager(
      $_db,
      $_db.channels,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_channelsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MoviesTable, List<Movie>> _moviesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.movies,
    aliasName: $_aliasNameGenerator(db.playlists.id, db.movies.playlistId),
  );

  $$MoviesTableProcessedTableManager get moviesRefs {
    final manager = $$MoviesTableTableManager(
      $_db,
      $_db.movies,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_moviesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SeriesItemsTable, List<SeriesItem>>
  _seriesItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.seriesItems,
    aliasName: $_aliasNameGenerator(db.playlists.id, db.seriesItems.playlistId),
  );

  $$SeriesItemsTableProcessedTableManager get seriesItemsRefs {
    final manager = $$SeriesItemsTableTableManager(
      $_db,
      $_db.seriesItems,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_seriesItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EpisodesTable, List<Episode>> _episodesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.episodes,
    aliasName: $_aliasNameGenerator(db.playlists.id, db.episodes.playlistId),
  );

  $$EpisodesTableProcessedTableManager get episodesRefs {
    final manager = $$EpisodesTableTableManager(
      $_db,
      $_db.episodes,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_episodesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EpgProgramsTable, List<EpgProgram>>
  _epgProgramsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.epgPrograms,
    aliasName: $_aliasNameGenerator(db.playlists.id, db.epgPrograms.playlistId),
  );

  $$EpgProgramsTableProcessedTableManager get epgProgramsRefs {
    final manager = $$EpgProgramsTableTableManager(
      $_db,
      $_db.epgPrograms,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_epgProgramsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FavoritesTable, List<Favorite>>
  _favoritesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.favorites,
    aliasName: $_aliasNameGenerator(db.playlists.id, db.favorites.playlistId),
  );

  $$FavoritesTableProcessedTableManager get favoritesRefs {
    final manager = $$FavoritesTableTableManager(
      $_db,
      $_db.favorites,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_favoritesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$HistoryTable, List<HistoryData>>
  _historyRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.history,
    aliasName: $_aliasNameGenerator(db.playlists.id, db.history.playlistId),
  );

  $$HistoryTableProcessedTableManager get historyRefs {
    final manager = $$HistoryTableTableManager(
      $_db,
      $_db.history,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_historyRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ChannelGroupsTable, List<ChannelGroup>>
  _channelGroupsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.channelGroups,
    aliasName: $_aliasNameGenerator(
      db.playlists.id,
      db.channelGroups.playlistId,
    ),
  );

  $$ChannelGroupsTableProcessedTableManager get channelGroupsRefs {
    final manager = $$ChannelGroupsTableTableManager(
      $_db,
      $_db.channelGroups,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_channelGroupsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LockedChannelsTable, List<LockedChannel>>
  _lockedChannelsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.lockedChannels,
    aliasName: $_aliasNameGenerator(
      db.playlists.id,
      db.lockedChannels.playlistId,
    ),
  );

  $$LockedChannelsTableProcessedTableManager get lockedChannelsRefs {
    final manager = $$LockedChannelsTableTableManager(
      $_db,
      $_db.lockedChannels,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_lockedChannelsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$HiddenCategoriesTable, List<HiddenCategory>>
  _hiddenCategoriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.hiddenCategories,
    aliasName: $_aliasNameGenerator(
      db.playlists.id,
      db.hiddenCategories.playlistId,
    ),
  );

  $$HiddenCategoriesTableProcessedTableManager get hiddenCategoriesRefs {
    final manager = $$HiddenCategoriesTableTableManager(
      $_db,
      $_db.hiddenCategories,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _hiddenCategoriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlaylistsTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PlaylistType, PlaylistType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<PlaylistSource, PlaylistSource, String>
  get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get password => $composableBuilder(
    column: $table.password,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get epgUrl => $composableBuilder(
    column: $table.epgUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isProtected => $composableBuilder(
    column: $table.isProtected,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinCode => $composableBuilder(
    column: $table.pinCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountInfo => $composableBuilder(
    column: $table.accountInfo,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> categoriesRefs(
    Expression<bool> Function($$CategoriesTableFilterComposer f) f,
  ) {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> channelsRefs(
    Expression<bool> Function($$ChannelsTableFilterComposer f) f,
  ) {
    final $$ChannelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableFilterComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> moviesRefs(
    Expression<bool> Function($$MoviesTableFilterComposer f) f,
  ) {
    final $$MoviesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movies,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MoviesTableFilterComposer(
            $db: $db,
            $table: $db.movies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> seriesItemsRefs(
    Expression<bool> Function($$SeriesItemsTableFilterComposer f) f,
  ) {
    final $$SeriesItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.seriesItems,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeriesItemsTableFilterComposer(
            $db: $db,
            $table: $db.seriesItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> episodesRefs(
    Expression<bool> Function($$EpisodesTableFilterComposer f) f,
  ) {
    final $$EpisodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.episodes,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpisodesTableFilterComposer(
            $db: $db,
            $table: $db.episodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> epgProgramsRefs(
    Expression<bool> Function($$EpgProgramsTableFilterComposer f) f,
  ) {
    final $$EpgProgramsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.epgPrograms,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpgProgramsTableFilterComposer(
            $db: $db,
            $table: $db.epgPrograms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> favoritesRefs(
    Expression<bool> Function($$FavoritesTableFilterComposer f) f,
  ) {
    final $$FavoritesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.favorites,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoritesTableFilterComposer(
            $db: $db,
            $table: $db.favorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> historyRefs(
    Expression<bool> Function($$HistoryTableFilterComposer f) f,
  ) {
    final $$HistoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.history,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HistoryTableFilterComposer(
            $db: $db,
            $table: $db.history,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> channelGroupsRefs(
    Expression<bool> Function($$ChannelGroupsTableFilterComposer f) f,
  ) {
    final $$ChannelGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.channelGroups,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelGroupsTableFilterComposer(
            $db: $db,
            $table: $db.channelGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> lockedChannelsRefs(
    Expression<bool> Function($$LockedChannelsTableFilterComposer f) f,
  ) {
    final $$LockedChannelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lockedChannels,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LockedChannelsTableFilterComposer(
            $db: $db,
            $table: $db.lockedChannels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> hiddenCategoriesRefs(
    Expression<bool> Function($$HiddenCategoriesTableFilterComposer f) f,
  ) {
    final $$HiddenCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.hiddenCategories,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HiddenCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.hiddenCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get password => $composableBuilder(
    column: $table.password,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get epgUrl => $composableBuilder(
    column: $table.epgUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isProtected => $composableBuilder(
    column: $table.isProtected,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinCode => $composableBuilder(
    column: $table.pinCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountInfo => $composableBuilder(
    column: $table.accountInfo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaylistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PlaylistType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PlaylistSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => column);

  GeneratedColumn<String> get epgUrl =>
      $composableBuilder(column: $table.epgUrl, builder: (column) => column);

  GeneratedColumn<bool> get isProtected => $composableBuilder(
    column: $table.isProtected,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pinCode =>
      $composableBuilder(column: $table.pinCode, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountInfo => $composableBuilder(
    column: $table.accountInfo,
    builder: (column) => column,
  );

  Expression<T> categoriesRefs<T extends Object>(
    Expression<T> Function($$CategoriesTableAnnotationComposer a) f,
  ) {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> channelsRefs<T extends Object>(
    Expression<T> Function($$ChannelsTableAnnotationComposer a) f,
  ) {
    final $$ChannelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableAnnotationComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> moviesRefs<T extends Object>(
    Expression<T> Function($$MoviesTableAnnotationComposer a) f,
  ) {
    final $$MoviesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movies,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MoviesTableAnnotationComposer(
            $db: $db,
            $table: $db.movies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> seriesItemsRefs<T extends Object>(
    Expression<T> Function($$SeriesItemsTableAnnotationComposer a) f,
  ) {
    final $$SeriesItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.seriesItems,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeriesItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.seriesItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> episodesRefs<T extends Object>(
    Expression<T> Function($$EpisodesTableAnnotationComposer a) f,
  ) {
    final $$EpisodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.episodes,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpisodesTableAnnotationComposer(
            $db: $db,
            $table: $db.episodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> epgProgramsRefs<T extends Object>(
    Expression<T> Function($$EpgProgramsTableAnnotationComposer a) f,
  ) {
    final $$EpgProgramsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.epgPrograms,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpgProgramsTableAnnotationComposer(
            $db: $db,
            $table: $db.epgPrograms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> favoritesRefs<T extends Object>(
    Expression<T> Function($$FavoritesTableAnnotationComposer a) f,
  ) {
    final $$FavoritesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.favorites,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoritesTableAnnotationComposer(
            $db: $db,
            $table: $db.favorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> historyRefs<T extends Object>(
    Expression<T> Function($$HistoryTableAnnotationComposer a) f,
  ) {
    final $$HistoryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.history,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HistoryTableAnnotationComposer(
            $db: $db,
            $table: $db.history,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> channelGroupsRefs<T extends Object>(
    Expression<T> Function($$ChannelGroupsTableAnnotationComposer a) f,
  ) {
    final $$ChannelGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.channelGroups,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.channelGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> lockedChannelsRefs<T extends Object>(
    Expression<T> Function($$LockedChannelsTableAnnotationComposer a) f,
  ) {
    final $$LockedChannelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lockedChannels,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LockedChannelsTableAnnotationComposer(
            $db: $db,
            $table: $db.lockedChannels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> hiddenCategoriesRefs<T extends Object>(
    Expression<T> Function($$HiddenCategoriesTableAnnotationComposer a) f,
  ) {
    final $$HiddenCategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.hiddenCategories,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HiddenCategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.hiddenCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaylistsTable,
          Playlist,
          $$PlaylistsTableFilterComposer,
          $$PlaylistsTableOrderingComposer,
          $$PlaylistsTableAnnotationComposer,
          $$PlaylistsTableCreateCompanionBuilder,
          $$PlaylistsTableUpdateCompanionBuilder,
          (Playlist, $$PlaylistsTableReferences),
          Playlist,
          PrefetchHooks Function({
            bool categoriesRefs,
            bool channelsRefs,
            bool moviesRefs,
            bool seriesItemsRefs,
            bool episodesRefs,
            bool epgProgramsRefs,
            bool favoritesRefs,
            bool historyRefs,
            bool channelGroupsRefs,
            bool lockedChannelsRefs,
            bool hiddenCategoriesRefs,
          })
        > {
  $$PlaylistsTableTableManager(_$AppDatabase db, $PlaylistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<PlaylistType> type = const Value.absent(),
                Value<PlaylistSource> source = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String?> username = const Value.absent(),
                Value<String?> password = const Value.absent(),
                Value<String?> epgUrl = const Value.absent(),
                Value<bool> isProtected = const Value.absent(),
                Value<String?> pinCode = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<String?> accountInfo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistsCompanion(
                id: id,
                name: name,
                type: type,
                source: source,
                url: url,
                username: username,
                password: password,
                epgUrl: epgUrl,
                isProtected: isProtected,
                pinCode: pinCode,
                expiresAt: expiresAt,
                position: position,
                lastSyncedAt: lastSyncedAt,
                accountInfo: accountInfo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required PlaylistType type,
                required PlaylistSource source,
                required String url,
                Value<String?> username = const Value.absent(),
                Value<String?> password = const Value.absent(),
                Value<String?> epgUrl = const Value.absent(),
                Value<bool> isProtected = const Value.absent(),
                Value<String?> pinCode = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<String?> accountInfo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistsCompanion.insert(
                id: id,
                name: name,
                type: type,
                source: source,
                url: url,
                username: username,
                password: password,
                epgUrl: epgUrl,
                isProtected: isProtected,
                pinCode: pinCode,
                expiresAt: expiresAt,
                position: position,
                lastSyncedAt: lastSyncedAt,
                accountInfo: accountInfo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlaylistsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                categoriesRefs = false,
                channelsRefs = false,
                moviesRefs = false,
                seriesItemsRefs = false,
                episodesRefs = false,
                epgProgramsRefs = false,
                favoritesRefs = false,
                historyRefs = false,
                channelGroupsRefs = false,
                lockedChannelsRefs = false,
                hiddenCategoriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (categoriesRefs) db.categories,
                    if (channelsRefs) db.channels,
                    if (moviesRefs) db.movies,
                    if (seriesItemsRefs) db.seriesItems,
                    if (episodesRefs) db.episodes,
                    if (epgProgramsRefs) db.epgPrograms,
                    if (favoritesRefs) db.favorites,
                    if (historyRefs) db.history,
                    if (channelGroupsRefs) db.channelGroups,
                    if (lockedChannelsRefs) db.lockedChannels,
                    if (hiddenCategoriesRefs) db.hiddenCategories,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (categoriesRefs)
                        await $_getPrefetchedData<
                          Playlist,
                          $PlaylistsTable,
                          ContentCategory
                        >(
                          currentTable: table,
                          referencedTable: $$PlaylistsTableReferences
                              ._categoriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlaylistsTableReferences(
                                db,
                                table,
                                p0,
                              ).categoriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playlistId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (channelsRefs)
                        await $_getPrefetchedData<
                          Playlist,
                          $PlaylistsTable,
                          Channel
                        >(
                          currentTable: table,
                          referencedTable: $$PlaylistsTableReferences
                              ._channelsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlaylistsTableReferences(
                                db,
                                table,
                                p0,
                              ).channelsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playlistId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (moviesRefs)
                        await $_getPrefetchedData<
                          Playlist,
                          $PlaylistsTable,
                          Movie
                        >(
                          currentTable: table,
                          referencedTable: $$PlaylistsTableReferences
                              ._moviesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlaylistsTableReferences(
                                db,
                                table,
                                p0,
                              ).moviesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playlistId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (seriesItemsRefs)
                        await $_getPrefetchedData<
                          Playlist,
                          $PlaylistsTable,
                          SeriesItem
                        >(
                          currentTable: table,
                          referencedTable: $$PlaylistsTableReferences
                              ._seriesItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlaylistsTableReferences(
                                db,
                                table,
                                p0,
                              ).seriesItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playlistId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (episodesRefs)
                        await $_getPrefetchedData<
                          Playlist,
                          $PlaylistsTable,
                          Episode
                        >(
                          currentTable: table,
                          referencedTable: $$PlaylistsTableReferences
                              ._episodesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlaylistsTableReferences(
                                db,
                                table,
                                p0,
                              ).episodesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playlistId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (epgProgramsRefs)
                        await $_getPrefetchedData<
                          Playlist,
                          $PlaylistsTable,
                          EpgProgram
                        >(
                          currentTable: table,
                          referencedTable: $$PlaylistsTableReferences
                              ._epgProgramsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlaylistsTableReferences(
                                db,
                                table,
                                p0,
                              ).epgProgramsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playlistId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (favoritesRefs)
                        await $_getPrefetchedData<
                          Playlist,
                          $PlaylistsTable,
                          Favorite
                        >(
                          currentTable: table,
                          referencedTable: $$PlaylistsTableReferences
                              ._favoritesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlaylistsTableReferences(
                                db,
                                table,
                                p0,
                              ).favoritesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playlistId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (historyRefs)
                        await $_getPrefetchedData<
                          Playlist,
                          $PlaylistsTable,
                          HistoryData
                        >(
                          currentTable: table,
                          referencedTable: $$PlaylistsTableReferences
                              ._historyRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlaylistsTableReferences(
                                db,
                                table,
                                p0,
                              ).historyRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playlistId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (channelGroupsRefs)
                        await $_getPrefetchedData<
                          Playlist,
                          $PlaylistsTable,
                          ChannelGroup
                        >(
                          currentTable: table,
                          referencedTable: $$PlaylistsTableReferences
                              ._channelGroupsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlaylistsTableReferences(
                                db,
                                table,
                                p0,
                              ).channelGroupsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playlistId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (lockedChannelsRefs)
                        await $_getPrefetchedData<
                          Playlist,
                          $PlaylistsTable,
                          LockedChannel
                        >(
                          currentTable: table,
                          referencedTable: $$PlaylistsTableReferences
                              ._lockedChannelsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlaylistsTableReferences(
                                db,
                                table,
                                p0,
                              ).lockedChannelsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playlistId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (hiddenCategoriesRefs)
                        await $_getPrefetchedData<
                          Playlist,
                          $PlaylistsTable,
                          HiddenCategory
                        >(
                          currentTable: table,
                          referencedTable: $$PlaylistsTableReferences
                              ._hiddenCategoriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlaylistsTableReferences(
                                db,
                                table,
                                p0,
                              ).hiddenCategoriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playlistId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PlaylistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaylistsTable,
      Playlist,
      $$PlaylistsTableFilterComposer,
      $$PlaylistsTableOrderingComposer,
      $$PlaylistsTableAnnotationComposer,
      $$PlaylistsTableCreateCompanionBuilder,
      $$PlaylistsTableUpdateCompanionBuilder,
      (Playlist, $$PlaylistsTableReferences),
      Playlist,
      PrefetchHooks Function({
        bool categoriesRefs,
        bool channelsRefs,
        bool moviesRefs,
        bool seriesItemsRefs,
        bool episodesRefs,
        bool epgProgramsRefs,
        bool favoritesRefs,
        bool historyRefs,
        bool channelGroupsRefs,
        bool lockedChannelsRefs,
        bool hiddenCategoriesRefs,
      })
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      required String playlistId,
      required String externalId,
      required ContentKind kind,
      required String name,
      Value<int> position,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      Value<String> playlistId,
      Value<String> externalId,
      Value<ContentKind> kind,
      Value<String> name,
      Value<int> position,
    });

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, ContentCategory> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlaylistsTable _playlistIdTable(_$AppDatabase db) =>
      db.playlists.createAlias(
        $_aliasNameGenerator(db.categories.playlistId, db.playlists.id),
      );

  $$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<String>('playlist_id')!;

    final manager = $$PlaylistsTableTableManager(
      $_db,
      $_db.playlists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ContentKind, ContentKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ContentKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          ContentCategory,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (ContentCategory, $$CategoriesTableReferences),
          ContentCategory,
          PrefetchHooks Function({bool playlistId})
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> playlistId = const Value.absent(),
                Value<String> externalId = const Value.absent(),
                Value<ContentKind> kind = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> position = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                playlistId: playlistId,
                externalId: externalId,
                kind: kind,
                name: name,
                position: position,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String playlistId,
                required String externalId,
                required ContentKind kind,
                required String name,
                Value<int> position = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                playlistId: playlistId,
                externalId: externalId,
                kind: kind,
                name: name,
                position: position,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (playlistId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playlistId,
                                referencedTable: $$CategoriesTableReferences
                                    ._playlistIdTable(db),
                                referencedColumn: $$CategoriesTableReferences
                                    ._playlistIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      ContentCategory,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (ContentCategory, $$CategoriesTableReferences),
      ContentCategory,
      PrefetchHooks Function({bool playlistId})
    >;
typedef $$ChannelsTableCreateCompanionBuilder =
    ChannelsCompanion Function({
      Value<int> id,
      required String playlistId,
      required String streamId,
      required String name,
      Value<String?> logo,
      Value<String?> categoryId,
      Value<String?> epgChannelId,
      Value<String> streamUrl,
      Value<int?> number,
      Value<bool> tvArchive,
      Value<int> tvArchiveDuration,
      Value<int> position,
    });
typedef $$ChannelsTableUpdateCompanionBuilder =
    ChannelsCompanion Function({
      Value<int> id,
      Value<String> playlistId,
      Value<String> streamId,
      Value<String> name,
      Value<String?> logo,
      Value<String?> categoryId,
      Value<String?> epgChannelId,
      Value<String> streamUrl,
      Value<int?> number,
      Value<bool> tvArchive,
      Value<int> tvArchiveDuration,
      Value<int> position,
    });

final class $$ChannelsTableReferences
    extends BaseReferences<_$AppDatabase, $ChannelsTable, Channel> {
  $$ChannelsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlaylistsTable _playlistIdTable(_$AppDatabase db) =>
      db.playlists.createAlias(
        $_aliasNameGenerator(db.channels.playlistId, db.playlists.id),
      );

  $$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<String>('playlist_id')!;

    final manager = $$PlaylistsTableTableManager(
      $_db,
      $_db.playlists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ChannelsTableFilterComposer
    extends Composer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get streamId => $composableBuilder(
    column: $table.streamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logo => $composableBuilder(
    column: $table.logo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get epgChannelId => $composableBuilder(
    column: $table.epgChannelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get streamUrl => $composableBuilder(
    column: $table.streamUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get tvArchive => $composableBuilder(
    column: $table.tvArchive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tvArchiveDuration => $composableBuilder(
    column: $table.tvArchiveDuration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChannelsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get streamId => $composableBuilder(
    column: $table.streamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logo => $composableBuilder(
    column: $table.logo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get epgChannelId => $composableBuilder(
    column: $table.epgChannelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get streamUrl => $composableBuilder(
    column: $table.streamUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get tvArchive => $composableBuilder(
    column: $table.tvArchive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tvArchiveDuration => $composableBuilder(
    column: $table.tvArchiveDuration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChannelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get streamId =>
      $composableBuilder(column: $table.streamId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get logo =>
      $composableBuilder(column: $table.logo, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get epgChannelId => $composableBuilder(
    column: $table.epgChannelId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get streamUrl =>
      $composableBuilder(column: $table.streamUrl, builder: (column) => column);

  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<bool> get tvArchive =>
      $composableBuilder(column: $table.tvArchive, builder: (column) => column);

  GeneratedColumn<int> get tvArchiveDuration => $composableBuilder(
    column: $table.tvArchiveDuration,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChannelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChannelsTable,
          Channel,
          $$ChannelsTableFilterComposer,
          $$ChannelsTableOrderingComposer,
          $$ChannelsTableAnnotationComposer,
          $$ChannelsTableCreateCompanionBuilder,
          $$ChannelsTableUpdateCompanionBuilder,
          (Channel, $$ChannelsTableReferences),
          Channel,
          PrefetchHooks Function({bool playlistId})
        > {
  $$ChannelsTableTableManager(_$AppDatabase db, $ChannelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChannelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChannelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChannelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> playlistId = const Value.absent(),
                Value<String> streamId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> logo = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> epgChannelId = const Value.absent(),
                Value<String> streamUrl = const Value.absent(),
                Value<int?> number = const Value.absent(),
                Value<bool> tvArchive = const Value.absent(),
                Value<int> tvArchiveDuration = const Value.absent(),
                Value<int> position = const Value.absent(),
              }) => ChannelsCompanion(
                id: id,
                playlistId: playlistId,
                streamId: streamId,
                name: name,
                logo: logo,
                categoryId: categoryId,
                epgChannelId: epgChannelId,
                streamUrl: streamUrl,
                number: number,
                tvArchive: tvArchive,
                tvArchiveDuration: tvArchiveDuration,
                position: position,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String playlistId,
                required String streamId,
                required String name,
                Value<String?> logo = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> epgChannelId = const Value.absent(),
                Value<String> streamUrl = const Value.absent(),
                Value<int?> number = const Value.absent(),
                Value<bool> tvArchive = const Value.absent(),
                Value<int> tvArchiveDuration = const Value.absent(),
                Value<int> position = const Value.absent(),
              }) => ChannelsCompanion.insert(
                id: id,
                playlistId: playlistId,
                streamId: streamId,
                name: name,
                logo: logo,
                categoryId: categoryId,
                epgChannelId: epgChannelId,
                streamUrl: streamUrl,
                number: number,
                tvArchive: tvArchive,
                tvArchiveDuration: tvArchiveDuration,
                position: position,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChannelsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (playlistId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playlistId,
                                referencedTable: $$ChannelsTableReferences
                                    ._playlistIdTable(db),
                                referencedColumn: $$ChannelsTableReferences
                                    ._playlistIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ChannelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChannelsTable,
      Channel,
      $$ChannelsTableFilterComposer,
      $$ChannelsTableOrderingComposer,
      $$ChannelsTableAnnotationComposer,
      $$ChannelsTableCreateCompanionBuilder,
      $$ChannelsTableUpdateCompanionBuilder,
      (Channel, $$ChannelsTableReferences),
      Channel,
      PrefetchHooks Function({bool playlistId})
    >;
typedef $$MoviesTableCreateCompanionBuilder =
    MoviesCompanion Function({
      Value<int> id,
      required String playlistId,
      required String streamId,
      required String name,
      Value<String?> poster,
      Value<String?> categoryId,
      Value<String> streamUrl,
      Value<String?> containerExtension,
      Value<double?> rating,
      Value<int?> year,
      Value<DateTime?> addedAt,
      Value<int> position,
    });
typedef $$MoviesTableUpdateCompanionBuilder =
    MoviesCompanion Function({
      Value<int> id,
      Value<String> playlistId,
      Value<String> streamId,
      Value<String> name,
      Value<String?> poster,
      Value<String?> categoryId,
      Value<String> streamUrl,
      Value<String?> containerExtension,
      Value<double?> rating,
      Value<int?> year,
      Value<DateTime?> addedAt,
      Value<int> position,
    });

final class $$MoviesTableReferences
    extends BaseReferences<_$AppDatabase, $MoviesTable, Movie> {
  $$MoviesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlaylistsTable _playlistIdTable(_$AppDatabase db) => db.playlists
      .createAlias($_aliasNameGenerator(db.movies.playlistId, db.playlists.id));

  $$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<String>('playlist_id')!;

    final manager = $$PlaylistsTableTableManager(
      $_db,
      $_db.playlists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MoviesTableFilterComposer
    extends Composer<_$AppDatabase, $MoviesTable> {
  $$MoviesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get streamId => $composableBuilder(
    column: $table.streamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get poster => $composableBuilder(
    column: $table.poster,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get streamUrl => $composableBuilder(
    column: $table.streamUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MoviesTableOrderingComposer
    extends Composer<_$AppDatabase, $MoviesTable> {
  $$MoviesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get streamId => $composableBuilder(
    column: $table.streamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get poster => $composableBuilder(
    column: $table.poster,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get streamUrl => $composableBuilder(
    column: $table.streamUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MoviesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MoviesTable> {
  $$MoviesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get streamId =>
      $composableBuilder(column: $table.streamId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get poster =>
      $composableBuilder(column: $table.poster, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get streamUrl =>
      $composableBuilder(column: $table.streamUrl, builder: (column) => column);

  GeneratedColumn<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MoviesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MoviesTable,
          Movie,
          $$MoviesTableFilterComposer,
          $$MoviesTableOrderingComposer,
          $$MoviesTableAnnotationComposer,
          $$MoviesTableCreateCompanionBuilder,
          $$MoviesTableUpdateCompanionBuilder,
          (Movie, $$MoviesTableReferences),
          Movie,
          PrefetchHooks Function({bool playlistId})
        > {
  $$MoviesTableTableManager(_$AppDatabase db, $MoviesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MoviesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MoviesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MoviesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> playlistId = const Value.absent(),
                Value<String> streamId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> poster = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> streamUrl = const Value.absent(),
                Value<String?> containerExtension = const Value.absent(),
                Value<double?> rating = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<DateTime?> addedAt = const Value.absent(),
                Value<int> position = const Value.absent(),
              }) => MoviesCompanion(
                id: id,
                playlistId: playlistId,
                streamId: streamId,
                name: name,
                poster: poster,
                categoryId: categoryId,
                streamUrl: streamUrl,
                containerExtension: containerExtension,
                rating: rating,
                year: year,
                addedAt: addedAt,
                position: position,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String playlistId,
                required String streamId,
                required String name,
                Value<String?> poster = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> streamUrl = const Value.absent(),
                Value<String?> containerExtension = const Value.absent(),
                Value<double?> rating = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<DateTime?> addedAt = const Value.absent(),
                Value<int> position = const Value.absent(),
              }) => MoviesCompanion.insert(
                id: id,
                playlistId: playlistId,
                streamId: streamId,
                name: name,
                poster: poster,
                categoryId: categoryId,
                streamUrl: streamUrl,
                containerExtension: containerExtension,
                rating: rating,
                year: year,
                addedAt: addedAt,
                position: position,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$MoviesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({playlistId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (playlistId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playlistId,
                                referencedTable: $$MoviesTableReferences
                                    ._playlistIdTable(db),
                                referencedColumn: $$MoviesTableReferences
                                    ._playlistIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MoviesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MoviesTable,
      Movie,
      $$MoviesTableFilterComposer,
      $$MoviesTableOrderingComposer,
      $$MoviesTableAnnotationComposer,
      $$MoviesTableCreateCompanionBuilder,
      $$MoviesTableUpdateCompanionBuilder,
      (Movie, $$MoviesTableReferences),
      Movie,
      PrefetchHooks Function({bool playlistId})
    >;
typedef $$SeriesItemsTableCreateCompanionBuilder =
    SeriesItemsCompanion Function({
      Value<int> id,
      required String playlistId,
      required String seriesId,
      required String name,
      Value<String?> cover,
      Value<String?> categoryId,
      Value<String?> plot,
      Value<double?> rating,
      Value<int?> year,
      Value<DateTime?> addedAt,
      Value<int> position,
    });
typedef $$SeriesItemsTableUpdateCompanionBuilder =
    SeriesItemsCompanion Function({
      Value<int> id,
      Value<String> playlistId,
      Value<String> seriesId,
      Value<String> name,
      Value<String?> cover,
      Value<String?> categoryId,
      Value<String?> plot,
      Value<double?> rating,
      Value<int?> year,
      Value<DateTime?> addedAt,
      Value<int> position,
    });

final class $$SeriesItemsTableReferences
    extends BaseReferences<_$AppDatabase, $SeriesItemsTable, SeriesItem> {
  $$SeriesItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlaylistsTable _playlistIdTable(_$AppDatabase db) =>
      db.playlists.createAlias(
        $_aliasNameGenerator(db.seriesItems.playlistId, db.playlists.id),
      );

  $$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<String>('playlist_id')!;

    final manager = $$PlaylistsTableTableManager(
      $_db,
      $_db.playlists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SeriesItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SeriesItemsTable> {
  $$SeriesItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cover => $composableBuilder(
    column: $table.cover,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plot => $composableBuilder(
    column: $table.plot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SeriesItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SeriesItemsTable> {
  $$SeriesItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cover => $composableBuilder(
    column: $table.cover,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plot => $composableBuilder(
    column: $table.plot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SeriesItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SeriesItemsTable> {
  $$SeriesItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get cover =>
      $composableBuilder(column: $table.cover, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get plot =>
      $composableBuilder(column: $table.plot, builder: (column) => column);

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SeriesItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SeriesItemsTable,
          SeriesItem,
          $$SeriesItemsTableFilterComposer,
          $$SeriesItemsTableOrderingComposer,
          $$SeriesItemsTableAnnotationComposer,
          $$SeriesItemsTableCreateCompanionBuilder,
          $$SeriesItemsTableUpdateCompanionBuilder,
          (SeriesItem, $$SeriesItemsTableReferences),
          SeriesItem,
          PrefetchHooks Function({bool playlistId})
        > {
  $$SeriesItemsTableTableManager(_$AppDatabase db, $SeriesItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeriesItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeriesItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeriesItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> playlistId = const Value.absent(),
                Value<String> seriesId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> cover = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> plot = const Value.absent(),
                Value<double?> rating = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<DateTime?> addedAt = const Value.absent(),
                Value<int> position = const Value.absent(),
              }) => SeriesItemsCompanion(
                id: id,
                playlistId: playlistId,
                seriesId: seriesId,
                name: name,
                cover: cover,
                categoryId: categoryId,
                plot: plot,
                rating: rating,
                year: year,
                addedAt: addedAt,
                position: position,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String playlistId,
                required String seriesId,
                required String name,
                Value<String?> cover = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> plot = const Value.absent(),
                Value<double?> rating = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<DateTime?> addedAt = const Value.absent(),
                Value<int> position = const Value.absent(),
              }) => SeriesItemsCompanion.insert(
                id: id,
                playlistId: playlistId,
                seriesId: seriesId,
                name: name,
                cover: cover,
                categoryId: categoryId,
                plot: plot,
                rating: rating,
                year: year,
                addedAt: addedAt,
                position: position,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SeriesItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (playlistId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playlistId,
                                referencedTable: $$SeriesItemsTableReferences
                                    ._playlistIdTable(db),
                                referencedColumn: $$SeriesItemsTableReferences
                                    ._playlistIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SeriesItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SeriesItemsTable,
      SeriesItem,
      $$SeriesItemsTableFilterComposer,
      $$SeriesItemsTableOrderingComposer,
      $$SeriesItemsTableAnnotationComposer,
      $$SeriesItemsTableCreateCompanionBuilder,
      $$SeriesItemsTableUpdateCompanionBuilder,
      (SeriesItem, $$SeriesItemsTableReferences),
      SeriesItem,
      PrefetchHooks Function({bool playlistId})
    >;
typedef $$EpisodesTableCreateCompanionBuilder =
    EpisodesCompanion Function({
      Value<int> id,
      required String playlistId,
      required String seriesId,
      required String episodeId,
      required int season,
      required int episodeNum,
      required String title,
      Value<String> streamUrl,
      Value<String?> containerExtension,
      Value<String?> poster,
      Value<int?> durationSecs,
      Value<String?> plot,
      Value<String?> resolution,
    });
typedef $$EpisodesTableUpdateCompanionBuilder =
    EpisodesCompanion Function({
      Value<int> id,
      Value<String> playlistId,
      Value<String> seriesId,
      Value<String> episodeId,
      Value<int> season,
      Value<int> episodeNum,
      Value<String> title,
      Value<String> streamUrl,
      Value<String?> containerExtension,
      Value<String?> poster,
      Value<int?> durationSecs,
      Value<String?> plot,
      Value<String?> resolution,
    });

final class $$EpisodesTableReferences
    extends BaseReferences<_$AppDatabase, $EpisodesTable, Episode> {
  $$EpisodesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlaylistsTable _playlistIdTable(_$AppDatabase db) =>
      db.playlists.createAlias(
        $_aliasNameGenerator(db.episodes.playlistId, db.playlists.id),
      );

  $$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<String>('playlist_id')!;

    final manager = $$PlaylistsTableTableManager(
      $_db,
      $_db.playlists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EpisodesTableFilterComposer
    extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get episodeId => $composableBuilder(
    column: $table.episodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get season => $composableBuilder(
    column: $table.season,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episodeNum => $composableBuilder(
    column: $table.episodeNum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get streamUrl => $composableBuilder(
    column: $table.streamUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get poster => $composableBuilder(
    column: $table.poster,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSecs => $composableBuilder(
    column: $table.durationSecs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plot => $composableBuilder(
    column: $table.plot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resolution => $composableBuilder(
    column: $table.resolution,
    builder: (column) => ColumnFilters(column),
  );

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpisodesTableOrderingComposer
    extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get episodeId => $composableBuilder(
    column: $table.episodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get season => $composableBuilder(
    column: $table.season,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episodeNum => $composableBuilder(
    column: $table.episodeNum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get streamUrl => $composableBuilder(
    column: $table.streamUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get poster => $composableBuilder(
    column: $table.poster,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSecs => $composableBuilder(
    column: $table.durationSecs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plot => $composableBuilder(
    column: $table.plot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolution => $composableBuilder(
    column: $table.resolution,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpisodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<String> get episodeId =>
      $composableBuilder(column: $table.episodeId, builder: (column) => column);

  GeneratedColumn<int> get season =>
      $composableBuilder(column: $table.season, builder: (column) => column);

  GeneratedColumn<int> get episodeNum => $composableBuilder(
    column: $table.episodeNum,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get streamUrl =>
      $composableBuilder(column: $table.streamUrl, builder: (column) => column);

  GeneratedColumn<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => column,
  );

  GeneratedColumn<String> get poster =>
      $composableBuilder(column: $table.poster, builder: (column) => column);

  GeneratedColumn<int> get durationSecs => $composableBuilder(
    column: $table.durationSecs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get plot =>
      $composableBuilder(column: $table.plot, builder: (column) => column);

  GeneratedColumn<String> get resolution => $composableBuilder(
    column: $table.resolution,
    builder: (column) => column,
  );

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpisodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EpisodesTable,
          Episode,
          $$EpisodesTableFilterComposer,
          $$EpisodesTableOrderingComposer,
          $$EpisodesTableAnnotationComposer,
          $$EpisodesTableCreateCompanionBuilder,
          $$EpisodesTableUpdateCompanionBuilder,
          (Episode, $$EpisodesTableReferences),
          Episode,
          PrefetchHooks Function({bool playlistId})
        > {
  $$EpisodesTableTableManager(_$AppDatabase db, $EpisodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpisodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpisodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EpisodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> playlistId = const Value.absent(),
                Value<String> seriesId = const Value.absent(),
                Value<String> episodeId = const Value.absent(),
                Value<int> season = const Value.absent(),
                Value<int> episodeNum = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> streamUrl = const Value.absent(),
                Value<String?> containerExtension = const Value.absent(),
                Value<String?> poster = const Value.absent(),
                Value<int?> durationSecs = const Value.absent(),
                Value<String?> plot = const Value.absent(),
                Value<String?> resolution = const Value.absent(),
              }) => EpisodesCompanion(
                id: id,
                playlistId: playlistId,
                seriesId: seriesId,
                episodeId: episodeId,
                season: season,
                episodeNum: episodeNum,
                title: title,
                streamUrl: streamUrl,
                containerExtension: containerExtension,
                poster: poster,
                durationSecs: durationSecs,
                plot: plot,
                resolution: resolution,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String playlistId,
                required String seriesId,
                required String episodeId,
                required int season,
                required int episodeNum,
                required String title,
                Value<String> streamUrl = const Value.absent(),
                Value<String?> containerExtension = const Value.absent(),
                Value<String?> poster = const Value.absent(),
                Value<int?> durationSecs = const Value.absent(),
                Value<String?> plot = const Value.absent(),
                Value<String?> resolution = const Value.absent(),
              }) => EpisodesCompanion.insert(
                id: id,
                playlistId: playlistId,
                seriesId: seriesId,
                episodeId: episodeId,
                season: season,
                episodeNum: episodeNum,
                title: title,
                streamUrl: streamUrl,
                containerExtension: containerExtension,
                poster: poster,
                durationSecs: durationSecs,
                plot: plot,
                resolution: resolution,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EpisodesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (playlistId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playlistId,
                                referencedTable: $$EpisodesTableReferences
                                    ._playlistIdTable(db),
                                referencedColumn: $$EpisodesTableReferences
                                    ._playlistIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EpisodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EpisodesTable,
      Episode,
      $$EpisodesTableFilterComposer,
      $$EpisodesTableOrderingComposer,
      $$EpisodesTableAnnotationComposer,
      $$EpisodesTableCreateCompanionBuilder,
      $$EpisodesTableUpdateCompanionBuilder,
      (Episode, $$EpisodesTableReferences),
      Episode,
      PrefetchHooks Function({bool playlistId})
    >;
typedef $$EpgProgramsTableCreateCompanionBuilder =
    EpgProgramsCompanion Function({
      Value<int> id,
      required String playlistId,
      required String channelId,
      required DateTime start,
      required DateTime end,
      required String title,
      Value<String?> description,
    });
typedef $$EpgProgramsTableUpdateCompanionBuilder =
    EpgProgramsCompanion Function({
      Value<int> id,
      Value<String> playlistId,
      Value<String> channelId,
      Value<DateTime> start,
      Value<DateTime> end,
      Value<String> title,
      Value<String?> description,
    });

final class $$EpgProgramsTableReferences
    extends BaseReferences<_$AppDatabase, $EpgProgramsTable, EpgProgram> {
  $$EpgProgramsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlaylistsTable _playlistIdTable(_$AppDatabase db) =>
      db.playlists.createAlias(
        $_aliasNameGenerator(db.epgPrograms.playlistId, db.playlists.id),
      );

  $$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<String>('playlist_id')!;

    final manager = $$PlaylistsTableTableManager(
      $_db,
      $_db.playlists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EpgProgramsTableFilterComposer
    extends Composer<_$AppDatabase, $EpgProgramsTable> {
  $$EpgProgramsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get end => $composableBuilder(
    column: $table.end,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpgProgramsTableOrderingComposer
    extends Composer<_$AppDatabase, $EpgProgramsTable> {
  $$EpgProgramsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get end => $composableBuilder(
    column: $table.end,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpgProgramsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EpgProgramsTable> {
  $$EpgProgramsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => column);

  GeneratedColumn<DateTime> get start =>
      $composableBuilder(column: $table.start, builder: (column) => column);

  GeneratedColumn<DateTime> get end =>
      $composableBuilder(column: $table.end, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpgProgramsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EpgProgramsTable,
          EpgProgram,
          $$EpgProgramsTableFilterComposer,
          $$EpgProgramsTableOrderingComposer,
          $$EpgProgramsTableAnnotationComposer,
          $$EpgProgramsTableCreateCompanionBuilder,
          $$EpgProgramsTableUpdateCompanionBuilder,
          (EpgProgram, $$EpgProgramsTableReferences),
          EpgProgram,
          PrefetchHooks Function({bool playlistId})
        > {
  $$EpgProgramsTableTableManager(_$AppDatabase db, $EpgProgramsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpgProgramsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpgProgramsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EpgProgramsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> playlistId = const Value.absent(),
                Value<String> channelId = const Value.absent(),
                Value<DateTime> start = const Value.absent(),
                Value<DateTime> end = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
              }) => EpgProgramsCompanion(
                id: id,
                playlistId: playlistId,
                channelId: channelId,
                start: start,
                end: end,
                title: title,
                description: description,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String playlistId,
                required String channelId,
                required DateTime start,
                required DateTime end,
                required String title,
                Value<String?> description = const Value.absent(),
              }) => EpgProgramsCompanion.insert(
                id: id,
                playlistId: playlistId,
                channelId: channelId,
                start: start,
                end: end,
                title: title,
                description: description,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EpgProgramsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (playlistId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playlistId,
                                referencedTable: $$EpgProgramsTableReferences
                                    ._playlistIdTable(db),
                                referencedColumn: $$EpgProgramsTableReferences
                                    ._playlistIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EpgProgramsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EpgProgramsTable,
      EpgProgram,
      $$EpgProgramsTableFilterComposer,
      $$EpgProgramsTableOrderingComposer,
      $$EpgProgramsTableAnnotationComposer,
      $$EpgProgramsTableCreateCompanionBuilder,
      $$EpgProgramsTableUpdateCompanionBuilder,
      (EpgProgram, $$EpgProgramsTableReferences),
      EpgProgram,
      PrefetchHooks Function({bool playlistId})
    >;
typedef $$FavoritesTableCreateCompanionBuilder =
    FavoritesCompanion Function({
      Value<int> id,
      required String playlistId,
      required ContentKind kind,
      required String itemId,
      Value<DateTime> addedAt,
    });
typedef $$FavoritesTableUpdateCompanionBuilder =
    FavoritesCompanion Function({
      Value<int> id,
      Value<String> playlistId,
      Value<ContentKind> kind,
      Value<String> itemId,
      Value<DateTime> addedAt,
    });

final class $$FavoritesTableReferences
    extends BaseReferences<_$AppDatabase, $FavoritesTable, Favorite> {
  $$FavoritesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlaylistsTable _playlistIdTable(_$AppDatabase db) =>
      db.playlists.createAlias(
        $_aliasNameGenerator(db.favorites.playlistId, db.playlists.id),
      );

  $$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<String>('playlist_id')!;

    final manager = $$PlaylistsTableTableManager(
      $_db,
      $_db.playlists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FavoritesTableFilterComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ContentKind, ContentKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoritesTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ContentKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoritesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoritesTable,
          Favorite,
          $$FavoritesTableFilterComposer,
          $$FavoritesTableOrderingComposer,
          $$FavoritesTableAnnotationComposer,
          $$FavoritesTableCreateCompanionBuilder,
          $$FavoritesTableUpdateCompanionBuilder,
          (Favorite, $$FavoritesTableReferences),
          Favorite,
          PrefetchHooks Function({bool playlistId})
        > {
  $$FavoritesTableTableManager(_$AppDatabase db, $FavoritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> playlistId = const Value.absent(),
                Value<ContentKind> kind = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
              }) => FavoritesCompanion(
                id: id,
                playlistId: playlistId,
                kind: kind,
                itemId: itemId,
                addedAt: addedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String playlistId,
                required ContentKind kind,
                required String itemId,
                Value<DateTime> addedAt = const Value.absent(),
              }) => FavoritesCompanion.insert(
                id: id,
                playlistId: playlistId,
                kind: kind,
                itemId: itemId,
                addedAt: addedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FavoritesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (playlistId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playlistId,
                                referencedTable: $$FavoritesTableReferences
                                    ._playlistIdTable(db),
                                referencedColumn: $$FavoritesTableReferences
                                    ._playlistIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FavoritesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoritesTable,
      Favorite,
      $$FavoritesTableFilterComposer,
      $$FavoritesTableOrderingComposer,
      $$FavoritesTableAnnotationComposer,
      $$FavoritesTableCreateCompanionBuilder,
      $$FavoritesTableUpdateCompanionBuilder,
      (Favorite, $$FavoritesTableReferences),
      Favorite,
      PrefetchHooks Function({bool playlistId})
    >;
typedef $$HistoryTableCreateCompanionBuilder =
    HistoryCompanion Function({
      Value<int> id,
      required String playlistId,
      required ContentKind kind,
      required String itemId,
      Value<String?> parentId,
      Value<int> positionMs,
      Value<int> durationMs,
      Value<DateTime> watchedAt,
    });
typedef $$HistoryTableUpdateCompanionBuilder =
    HistoryCompanion Function({
      Value<int> id,
      Value<String> playlistId,
      Value<ContentKind> kind,
      Value<String> itemId,
      Value<String?> parentId,
      Value<int> positionMs,
      Value<int> durationMs,
      Value<DateTime> watchedAt,
    });

final class $$HistoryTableReferences
    extends BaseReferences<_$AppDatabase, $HistoryTable, HistoryData> {
  $$HistoryTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlaylistsTable _playlistIdTable(_$AppDatabase db) =>
      db.playlists.createAlias(
        $_aliasNameGenerator(db.history.playlistId, db.playlists.id),
      );

  $$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<String>('playlist_id')!;

    final manager = $$PlaylistsTableTableManager(
      $_db,
      $_db.playlists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HistoryTableFilterComposer
    extends Composer<_$AppDatabase, $HistoryTable> {
  $$HistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ContentKind, ContentKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get watchedAt => $composableBuilder(
    column: $table.watchedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $HistoryTable> {
  $$HistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get watchedAt => $composableBuilder(
    column: $table.watchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $HistoryTable> {
  $$HistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ContentKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get watchedAt =>
      $composableBuilder(column: $table.watchedAt, builder: (column) => column);

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HistoryTable,
          HistoryData,
          $$HistoryTableFilterComposer,
          $$HistoryTableOrderingComposer,
          $$HistoryTableAnnotationComposer,
          $$HistoryTableCreateCompanionBuilder,
          $$HistoryTableUpdateCompanionBuilder,
          (HistoryData, $$HistoryTableReferences),
          HistoryData,
          PrefetchHooks Function({bool playlistId})
        > {
  $$HistoryTableTableManager(_$AppDatabase db, $HistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> playlistId = const Value.absent(),
                Value<ContentKind> kind = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<DateTime> watchedAt = const Value.absent(),
              }) => HistoryCompanion(
                id: id,
                playlistId: playlistId,
                kind: kind,
                itemId: itemId,
                parentId: parentId,
                positionMs: positionMs,
                durationMs: durationMs,
                watchedAt: watchedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String playlistId,
                required ContentKind kind,
                required String itemId,
                Value<String?> parentId = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<DateTime> watchedAt = const Value.absent(),
              }) => HistoryCompanion.insert(
                id: id,
                playlistId: playlistId,
                kind: kind,
                itemId: itemId,
                parentId: parentId,
                positionMs: positionMs,
                durationMs: durationMs,
                watchedAt: watchedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HistoryTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (playlistId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playlistId,
                                referencedTable: $$HistoryTableReferences
                                    ._playlistIdTable(db),
                                referencedColumn: $$HistoryTableReferences
                                    ._playlistIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HistoryTable,
      HistoryData,
      $$HistoryTableFilterComposer,
      $$HistoryTableOrderingComposer,
      $$HistoryTableAnnotationComposer,
      $$HistoryTableCreateCompanionBuilder,
      $$HistoryTableUpdateCompanionBuilder,
      (HistoryData, $$HistoryTableReferences),
      HistoryData,
      PrefetchHooks Function({bool playlistId})
    >;
typedef $$ChannelGroupsTableCreateCompanionBuilder =
    ChannelGroupsCompanion Function({
      Value<int> id,
      required String playlistId,
      required String name,
    });
typedef $$ChannelGroupsTableUpdateCompanionBuilder =
    ChannelGroupsCompanion Function({
      Value<int> id,
      Value<String> playlistId,
      Value<String> name,
    });

final class $$ChannelGroupsTableReferences
    extends BaseReferences<_$AppDatabase, $ChannelGroupsTable, ChannelGroup> {
  $$ChannelGroupsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlaylistsTable _playlistIdTable(_$AppDatabase db) =>
      db.playlists.createAlias(
        $_aliasNameGenerator(db.channelGroups.playlistId, db.playlists.id),
      );

  $$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<String>('playlist_id')!;

    final manager = $$PlaylistsTableTableManager(
      $_db,
      $_db.playlists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$GroupChannelsTable, List<GroupChannel>>
  _groupChannelsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.groupChannels,
    aliasName: $_aliasNameGenerator(
      db.channelGroups.id,
      db.groupChannels.groupId,
    ),
  );

  $$GroupChannelsTableProcessedTableManager get groupChannelsRefs {
    final manager = $$GroupChannelsTableTableManager(
      $_db,
      $_db.groupChannels,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_groupChannelsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChannelGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $ChannelGroupsTable> {
  $$ChannelGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> groupChannelsRefs(
    Expression<bool> Function($$GroupChannelsTableFilterComposer f) f,
  ) {
    final $$GroupChannelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.groupChannels,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupChannelsTableFilterComposer(
            $db: $db,
            $table: $db.groupChannels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChannelGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChannelGroupsTable> {
  $$ChannelGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChannelGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChannelGroupsTable> {
  $$ChannelGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> groupChannelsRefs<T extends Object>(
    Expression<T> Function($$GroupChannelsTableAnnotationComposer a) f,
  ) {
    final $$GroupChannelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.groupChannels,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupChannelsTableAnnotationComposer(
            $db: $db,
            $table: $db.groupChannels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChannelGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChannelGroupsTable,
          ChannelGroup,
          $$ChannelGroupsTableFilterComposer,
          $$ChannelGroupsTableOrderingComposer,
          $$ChannelGroupsTableAnnotationComposer,
          $$ChannelGroupsTableCreateCompanionBuilder,
          $$ChannelGroupsTableUpdateCompanionBuilder,
          (ChannelGroup, $$ChannelGroupsTableReferences),
          ChannelGroup,
          PrefetchHooks Function({bool playlistId, bool groupChannelsRefs})
        > {
  $$ChannelGroupsTableTableManager(_$AppDatabase db, $ChannelGroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChannelGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChannelGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChannelGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> playlistId = const Value.absent(),
                Value<String> name = const Value.absent(),
              }) => ChannelGroupsCompanion(
                id: id,
                playlistId: playlistId,
                name: name,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String playlistId,
                required String name,
              }) => ChannelGroupsCompanion.insert(
                id: id,
                playlistId: playlistId,
                name: name,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChannelGroupsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({playlistId = false, groupChannelsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (groupChannelsRefs) db.groupChannels,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (playlistId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.playlistId,
                                    referencedTable:
                                        $$ChannelGroupsTableReferences
                                            ._playlistIdTable(db),
                                    referencedColumn:
                                        $$ChannelGroupsTableReferences
                                            ._playlistIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (groupChannelsRefs)
                        await $_getPrefetchedData<
                          ChannelGroup,
                          $ChannelGroupsTable,
                          GroupChannel
                        >(
                          currentTable: table,
                          referencedTable: $$ChannelGroupsTableReferences
                              ._groupChannelsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChannelGroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).groupChannelsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.groupId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ChannelGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChannelGroupsTable,
      ChannelGroup,
      $$ChannelGroupsTableFilterComposer,
      $$ChannelGroupsTableOrderingComposer,
      $$ChannelGroupsTableAnnotationComposer,
      $$ChannelGroupsTableCreateCompanionBuilder,
      $$ChannelGroupsTableUpdateCompanionBuilder,
      (ChannelGroup, $$ChannelGroupsTableReferences),
      ChannelGroup,
      PrefetchHooks Function({bool playlistId, bool groupChannelsRefs})
    >;
typedef $$GroupChannelsTableCreateCompanionBuilder =
    GroupChannelsCompanion Function({
      required int groupId,
      required String streamId,
      Value<int> position,
      Value<int> rowid,
    });
typedef $$GroupChannelsTableUpdateCompanionBuilder =
    GroupChannelsCompanion Function({
      Value<int> groupId,
      Value<String> streamId,
      Value<int> position,
      Value<int> rowid,
    });

final class $$GroupChannelsTableReferences
    extends BaseReferences<_$AppDatabase, $GroupChannelsTable, GroupChannel> {
  $$GroupChannelsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ChannelGroupsTable _groupIdTable(_$AppDatabase db) =>
      db.channelGroups.createAlias(
        $_aliasNameGenerator(db.groupChannels.groupId, db.channelGroups.id),
      );

  $$ChannelGroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<int>('group_id')!;

    final manager = $$ChannelGroupsTableTableManager(
      $_db,
      $_db.channelGroups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GroupChannelsTableFilterComposer
    extends Composer<_$AppDatabase, $GroupChannelsTable> {
  $$GroupChannelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get streamId => $composableBuilder(
    column: $table.streamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$ChannelGroupsTableFilterComposer get groupId {
    final $$ChannelGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.channelGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelGroupsTableFilterComposer(
            $db: $db,
            $table: $db.channelGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GroupChannelsTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupChannelsTable> {
  $$GroupChannelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get streamId => $composableBuilder(
    column: $table.streamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChannelGroupsTableOrderingComposer get groupId {
    final $$ChannelGroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.channelGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelGroupsTableOrderingComposer(
            $db: $db,
            $table: $db.channelGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GroupChannelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupChannelsTable> {
  $$GroupChannelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get streamId =>
      $composableBuilder(column: $table.streamId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$ChannelGroupsTableAnnotationComposer get groupId {
    final $$ChannelGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.channelGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.channelGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GroupChannelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroupChannelsTable,
          GroupChannel,
          $$GroupChannelsTableFilterComposer,
          $$GroupChannelsTableOrderingComposer,
          $$GroupChannelsTableAnnotationComposer,
          $$GroupChannelsTableCreateCompanionBuilder,
          $$GroupChannelsTableUpdateCompanionBuilder,
          (GroupChannel, $$GroupChannelsTableReferences),
          GroupChannel,
          PrefetchHooks Function({bool groupId})
        > {
  $$GroupChannelsTableTableManager(_$AppDatabase db, $GroupChannelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupChannelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupChannelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupChannelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> groupId = const Value.absent(),
                Value<String> streamId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupChannelsCompanion(
                groupId: groupId,
                streamId: streamId,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int groupId,
                required String streamId,
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupChannelsCompanion.insert(
                groupId: groupId,
                streamId: streamId,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GroupChannelsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({groupId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (groupId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.groupId,
                                referencedTable: $$GroupChannelsTableReferences
                                    ._groupIdTable(db),
                                referencedColumn: $$GroupChannelsTableReferences
                                    ._groupIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$GroupChannelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroupChannelsTable,
      GroupChannel,
      $$GroupChannelsTableFilterComposer,
      $$GroupChannelsTableOrderingComposer,
      $$GroupChannelsTableAnnotationComposer,
      $$GroupChannelsTableCreateCompanionBuilder,
      $$GroupChannelsTableUpdateCompanionBuilder,
      (GroupChannel, $$GroupChannelsTableReferences),
      GroupChannel,
      PrefetchHooks Function({bool groupId})
    >;
typedef $$LockedChannelsTableCreateCompanionBuilder =
    LockedChannelsCompanion Function({
      required String playlistId,
      required String streamId,
      Value<int> rowid,
    });
typedef $$LockedChannelsTableUpdateCompanionBuilder =
    LockedChannelsCompanion Function({
      Value<String> playlistId,
      Value<String> streamId,
      Value<int> rowid,
    });

final class $$LockedChannelsTableReferences
    extends BaseReferences<_$AppDatabase, $LockedChannelsTable, LockedChannel> {
  $$LockedChannelsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlaylistsTable _playlistIdTable(_$AppDatabase db) =>
      db.playlists.createAlias(
        $_aliasNameGenerator(db.lockedChannels.playlistId, db.playlists.id),
      );

  $$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<String>('playlist_id')!;

    final manager = $$PlaylistsTableTableManager(
      $_db,
      $_db.playlists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LockedChannelsTableFilterComposer
    extends Composer<_$AppDatabase, $LockedChannelsTable> {
  $$LockedChannelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get streamId => $composableBuilder(
    column: $table.streamId,
    builder: (column) => ColumnFilters(column),
  );

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LockedChannelsTableOrderingComposer
    extends Composer<_$AppDatabase, $LockedChannelsTable> {
  $$LockedChannelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get streamId => $composableBuilder(
    column: $table.streamId,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LockedChannelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LockedChannelsTable> {
  $$LockedChannelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get streamId =>
      $composableBuilder(column: $table.streamId, builder: (column) => column);

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LockedChannelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LockedChannelsTable,
          LockedChannel,
          $$LockedChannelsTableFilterComposer,
          $$LockedChannelsTableOrderingComposer,
          $$LockedChannelsTableAnnotationComposer,
          $$LockedChannelsTableCreateCompanionBuilder,
          $$LockedChannelsTableUpdateCompanionBuilder,
          (LockedChannel, $$LockedChannelsTableReferences),
          LockedChannel,
          PrefetchHooks Function({bool playlistId})
        > {
  $$LockedChannelsTableTableManager(
    _$AppDatabase db,
    $LockedChannelsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LockedChannelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LockedChannelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LockedChannelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> playlistId = const Value.absent(),
                Value<String> streamId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LockedChannelsCompanion(
                playlistId: playlistId,
                streamId: streamId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String playlistId,
                required String streamId,
                Value<int> rowid = const Value.absent(),
              }) => LockedChannelsCompanion.insert(
                playlistId: playlistId,
                streamId: streamId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LockedChannelsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (playlistId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playlistId,
                                referencedTable: $$LockedChannelsTableReferences
                                    ._playlistIdTable(db),
                                referencedColumn:
                                    $$LockedChannelsTableReferences
                                        ._playlistIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LockedChannelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LockedChannelsTable,
      LockedChannel,
      $$LockedChannelsTableFilterComposer,
      $$LockedChannelsTableOrderingComposer,
      $$LockedChannelsTableAnnotationComposer,
      $$LockedChannelsTableCreateCompanionBuilder,
      $$LockedChannelsTableUpdateCompanionBuilder,
      (LockedChannel, $$LockedChannelsTableReferences),
      LockedChannel,
      PrefetchHooks Function({bool playlistId})
    >;
typedef $$HiddenCategoriesTableCreateCompanionBuilder =
    HiddenCategoriesCompanion Function({
      required String playlistId,
      required ContentKind kind,
      required String categoryId,
      Value<int> rowid,
    });
typedef $$HiddenCategoriesTableUpdateCompanionBuilder =
    HiddenCategoriesCompanion Function({
      Value<String> playlistId,
      Value<ContentKind> kind,
      Value<String> categoryId,
      Value<int> rowid,
    });

final class $$HiddenCategoriesTableReferences
    extends
        BaseReferences<_$AppDatabase, $HiddenCategoriesTable, HiddenCategory> {
  $$HiddenCategoriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlaylistsTable _playlistIdTable(_$AppDatabase db) =>
      db.playlists.createAlias(
        $_aliasNameGenerator(db.hiddenCategories.playlistId, db.playlists.id),
      );

  $$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<String>('playlist_id')!;

    final manager = $$PlaylistsTableTableManager(
      $_db,
      $_db.playlists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HiddenCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $HiddenCategoriesTable> {
  $$HiddenCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<ContentKind, ContentKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HiddenCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $HiddenCategoriesTable> {
  $$HiddenCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HiddenCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HiddenCategoriesTable> {
  $$HiddenCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<ContentKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HiddenCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HiddenCategoriesTable,
          HiddenCategory,
          $$HiddenCategoriesTableFilterComposer,
          $$HiddenCategoriesTableOrderingComposer,
          $$HiddenCategoriesTableAnnotationComposer,
          $$HiddenCategoriesTableCreateCompanionBuilder,
          $$HiddenCategoriesTableUpdateCompanionBuilder,
          (HiddenCategory, $$HiddenCategoriesTableReferences),
          HiddenCategory,
          PrefetchHooks Function({bool playlistId})
        > {
  $$HiddenCategoriesTableTableManager(
    _$AppDatabase db,
    $HiddenCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HiddenCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HiddenCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HiddenCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> playlistId = const Value.absent(),
                Value<ContentKind> kind = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HiddenCategoriesCompanion(
                playlistId: playlistId,
                kind: kind,
                categoryId: categoryId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String playlistId,
                required ContentKind kind,
                required String categoryId,
                Value<int> rowid = const Value.absent(),
              }) => HiddenCategoriesCompanion.insert(
                playlistId: playlistId,
                kind: kind,
                categoryId: categoryId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HiddenCategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (playlistId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playlistId,
                                referencedTable:
                                    $$HiddenCategoriesTableReferences
                                        ._playlistIdTable(db),
                                referencedColumn:
                                    $$HiddenCategoriesTableReferences
                                        ._playlistIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HiddenCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HiddenCategoriesTable,
      HiddenCategory,
      $$HiddenCategoriesTableFilterComposer,
      $$HiddenCategoriesTableOrderingComposer,
      $$HiddenCategoriesTableAnnotationComposer,
      $$HiddenCategoriesTableCreateCompanionBuilder,
      $$HiddenCategoriesTableUpdateCompanionBuilder,
      (HiddenCategory, $$HiddenCategoriesTableReferences),
      HiddenCategory,
      PrefetchHooks Function({bool playlistId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PlaylistsTableTableManager get playlists =>
      $$PlaylistsTableTableManager(_db, _db.playlists);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$ChannelsTableTableManager get channels =>
      $$ChannelsTableTableManager(_db, _db.channels);
  $$MoviesTableTableManager get movies =>
      $$MoviesTableTableManager(_db, _db.movies);
  $$SeriesItemsTableTableManager get seriesItems =>
      $$SeriesItemsTableTableManager(_db, _db.seriesItems);
  $$EpisodesTableTableManager get episodes =>
      $$EpisodesTableTableManager(_db, _db.episodes);
  $$EpgProgramsTableTableManager get epgPrograms =>
      $$EpgProgramsTableTableManager(_db, _db.epgPrograms);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db, _db.favorites);
  $$HistoryTableTableManager get history =>
      $$HistoryTableTableManager(_db, _db.history);
  $$ChannelGroupsTableTableManager get channelGroups =>
      $$ChannelGroupsTableTableManager(_db, _db.channelGroups);
  $$GroupChannelsTableTableManager get groupChannels =>
      $$GroupChannelsTableTableManager(_db, _db.groupChannels);
  $$LockedChannelsTableTableManager get lockedChannels =>
      $$LockedChannelsTableTableManager(_db, _db.lockedChannels);
  $$HiddenCategoriesTableTableManager get hiddenCategories =>
      $$HiddenCategoriesTableTableManager(_db, _db.hiddenCategories);
}
