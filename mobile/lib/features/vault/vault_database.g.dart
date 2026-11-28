// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vault_database.dart';

// ignore_for_file: type=lint
class $HiddenTransactionsTable extends HiddenTransactions
    with TableInfo<$HiddenTransactionsTable, HiddenTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HiddenTransactionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _amountPaiseMeta = const VerificationMeta(
    'amountPaise',
  );
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
    'amount_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('INR'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Direction, String> direction =
      GeneratedColumn<String>(
        'direction',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Direction>($HiddenTransactionsTable.$converterdirection);
  static const VerificationMeta _channelMeta = const VerificationMeta(
    'channel',
  );
  @override
  late final GeneratedColumn<String> channel = GeneratedColumn<String>(
    'channel',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _merchantMeta = const VerificationMeta(
    'merchant',
  );
  @override
  late final GeneratedColumn<String> merchant = GeneratedColumn<String>(
    'merchant',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryNameMeta = const VerificationMeta(
    'categoryName',
  );
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
    'category_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bankCodeMeta = const VerificationMeta(
    'bankCode',
  );
  @override
  late final GeneratedColumn<String> bankCode = GeneratedColumn<String>(
    'bank_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _last4Meta = const VerificationMeta('last4');
  @override
  late final GeneratedColumn<String> last4 = GeneratedColumn<String>(
    'last4',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountKindMeta = const VerificationMeta(
    'accountKind',
  );
  @override
  late final GeneratedColumn<String> accountKind = GeneratedColumn<String>(
    'account_kind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fingerprintMeta = const VerificationMeta(
    'fingerprint',
  );
  @override
  late final GeneratedColumn<String> fingerprint = GeneratedColumn<String>(
    'fingerprint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    amountPaise,
    currency,
    direction,
    channel,
    merchant,
    categoryName,
    bankCode,
    last4,
    accountKind,
    reference,
    note,
    fingerprint,
    occurredAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hidden_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<HiddenTransaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
        _amountPaiseMeta,
        amountPaise.isAcceptableOrUnknown(
          data['amount_paise']!,
          _amountPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('channel')) {
      context.handle(
        _channelMeta,
        channel.isAcceptableOrUnknown(data['channel']!, _channelMeta),
      );
    }
    if (data.containsKey('merchant')) {
      context.handle(
        _merchantMeta,
        merchant.isAcceptableOrUnknown(data['merchant']!, _merchantMeta),
      );
    }
    if (data.containsKey('category_name')) {
      context.handle(
        _categoryNameMeta,
        categoryName.isAcceptableOrUnknown(
          data['category_name']!,
          _categoryNameMeta,
        ),
      );
    }
    if (data.containsKey('bank_code')) {
      context.handle(
        _bankCodeMeta,
        bankCode.isAcceptableOrUnknown(data['bank_code']!, _bankCodeMeta),
      );
    }
    if (data.containsKey('last4')) {
      context.handle(
        _last4Meta,
        last4.isAcceptableOrUnknown(data['last4']!, _last4Meta),
      );
    }
    if (data.containsKey('account_kind')) {
      context.handle(
        _accountKindMeta,
        accountKind.isAcceptableOrUnknown(
          data['account_kind']!,
          _accountKindMeta,
        ),
      );
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('fingerprint')) {
      context.handle(
        _fingerprintMeta,
        fingerprint.isAcceptableOrUnknown(
          data['fingerprint']!,
          _fingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fingerprintMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HiddenTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HiddenTransaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      amountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_paise'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      direction: $HiddenTransactionsTable.$converterdirection.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}direction'],
        )!,
      ),
      channel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel'],
      ),
      merchant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant'],
      ),
      categoryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name'],
      ),
      bankCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_code'],
      ),
      last4: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last4'],
      ),
      accountKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_kind'],
      ),
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      fingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fingerprint'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $HiddenTransactionsTable createAlias(String alias) {
    return $HiddenTransactionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Direction, String, String> $converterdirection =
      const EnumNameConverter<Direction>(Direction.values);
}

class HiddenTransaction extends DataClass
    implements Insertable<HiddenTransaction> {
  final int id;
  final int amountPaise;
  final String currency;
  final Direction direction;
  final String? channel;
  final String? merchant;
  final String? categoryName;
  final String? bankCode;
  final String? last4;
  final String? accountKind;
  final String? reference;
  final String? note;
  final String fingerprint;
  final DateTime occurredAt;
  final DateTime createdAt;
  const HiddenTransaction({
    required this.id,
    required this.amountPaise,
    required this.currency,
    required this.direction,
    this.channel,
    this.merchant,
    this.categoryName,
    this.bankCode,
    this.last4,
    this.accountKind,
    this.reference,
    this.note,
    required this.fingerprint,
    required this.occurredAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['amount_paise'] = Variable<int>(amountPaise);
    map['currency'] = Variable<String>(currency);
    {
      map['direction'] = Variable<String>(
        $HiddenTransactionsTable.$converterdirection.toSql(direction),
      );
    }
    if (!nullToAbsent || channel != null) {
      map['channel'] = Variable<String>(channel);
    }
    if (!nullToAbsent || merchant != null) {
      map['merchant'] = Variable<String>(merchant);
    }
    if (!nullToAbsent || categoryName != null) {
      map['category_name'] = Variable<String>(categoryName);
    }
    if (!nullToAbsent || bankCode != null) {
      map['bank_code'] = Variable<String>(bankCode);
    }
    if (!nullToAbsent || last4 != null) {
      map['last4'] = Variable<String>(last4);
    }
    if (!nullToAbsent || accountKind != null) {
      map['account_kind'] = Variable<String>(accountKind);
    }
    if (!nullToAbsent || reference != null) {
      map['reference'] = Variable<String>(reference);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['fingerprint'] = Variable<String>(fingerprint);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  HiddenTransactionsCompanion toCompanion(bool nullToAbsent) {
    return HiddenTransactionsCompanion(
      id: Value(id),
      amountPaise: Value(amountPaise),
      currency: Value(currency),
      direction: Value(direction),
      channel: channel == null && nullToAbsent
          ? const Value.absent()
          : Value(channel),
      merchant: merchant == null && nullToAbsent
          ? const Value.absent()
          : Value(merchant),
      categoryName: categoryName == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryName),
      bankCode: bankCode == null && nullToAbsent
          ? const Value.absent()
          : Value(bankCode),
      last4: last4 == null && nullToAbsent
          ? const Value.absent()
          : Value(last4),
      accountKind: accountKind == null && nullToAbsent
          ? const Value.absent()
          : Value(accountKind),
      reference: reference == null && nullToAbsent
          ? const Value.absent()
          : Value(reference),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      fingerprint: Value(fingerprint),
      occurredAt: Value(occurredAt),
      createdAt: Value(createdAt),
    );
  }

  factory HiddenTransaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HiddenTransaction(
      id: serializer.fromJson<int>(json['id']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
      currency: serializer.fromJson<String>(json['currency']),
      direction: $HiddenTransactionsTable.$converterdirection.fromJson(
        serializer.fromJson<String>(json['direction']),
      ),
      channel: serializer.fromJson<String?>(json['channel']),
      merchant: serializer.fromJson<String?>(json['merchant']),
      categoryName: serializer.fromJson<String?>(json['categoryName']),
      bankCode: serializer.fromJson<String?>(json['bankCode']),
      last4: serializer.fromJson<String?>(json['last4']),
      accountKind: serializer.fromJson<String?>(json['accountKind']),
      reference: serializer.fromJson<String?>(json['reference']),
      note: serializer.fromJson<String?>(json['note']),
      fingerprint: serializer.fromJson<String>(json['fingerprint']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'amountPaise': serializer.toJson<int>(amountPaise),
      'currency': serializer.toJson<String>(currency),
      'direction': serializer.toJson<String>(
        $HiddenTransactionsTable.$converterdirection.toJson(direction),
      ),
      'channel': serializer.toJson<String?>(channel),
      'merchant': serializer.toJson<String?>(merchant),
      'categoryName': serializer.toJson<String?>(categoryName),
      'bankCode': serializer.toJson<String?>(bankCode),
      'last4': serializer.toJson<String?>(last4),
      'accountKind': serializer.toJson<String?>(accountKind),
      'reference': serializer.toJson<String?>(reference),
      'note': serializer.toJson<String?>(note),
      'fingerprint': serializer.toJson<String>(fingerprint),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  HiddenTransaction copyWith({
    int? id,
    int? amountPaise,
    String? currency,
    Direction? direction,
    Value<String?> channel = const Value.absent(),
    Value<String?> merchant = const Value.absent(),
    Value<String?> categoryName = const Value.absent(),
    Value<String?> bankCode = const Value.absent(),
    Value<String?> last4 = const Value.absent(),
    Value<String?> accountKind = const Value.absent(),
    Value<String?> reference = const Value.absent(),
    Value<String?> note = const Value.absent(),
    String? fingerprint,
    DateTime? occurredAt,
    DateTime? createdAt,
  }) => HiddenTransaction(
    id: id ?? this.id,
    amountPaise: amountPaise ?? this.amountPaise,
    currency: currency ?? this.currency,
    direction: direction ?? this.direction,
    channel: channel.present ? channel.value : this.channel,
    merchant: merchant.present ? merchant.value : this.merchant,
    categoryName: categoryName.present ? categoryName.value : this.categoryName,
    bankCode: bankCode.present ? bankCode.value : this.bankCode,
    last4: last4.present ? last4.value : this.last4,
    accountKind: accountKind.present ? accountKind.value : this.accountKind,
    reference: reference.present ? reference.value : this.reference,
    note: note.present ? note.value : this.note,
    fingerprint: fingerprint ?? this.fingerprint,
    occurredAt: occurredAt ?? this.occurredAt,
    createdAt: createdAt ?? this.createdAt,
  );
  HiddenTransaction copyWithCompanion(HiddenTransactionsCompanion data) {
    return HiddenTransaction(
      id: data.id.present ? data.id.value : this.id,
      amountPaise: data.amountPaise.present
          ? data.amountPaise.value
          : this.amountPaise,
      currency: data.currency.present ? data.currency.value : this.currency,
      direction: data.direction.present ? data.direction.value : this.direction,
      channel: data.channel.present ? data.channel.value : this.channel,
      merchant: data.merchant.present ? data.merchant.value : this.merchant,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      bankCode: data.bankCode.present ? data.bankCode.value : this.bankCode,
      last4: data.last4.present ? data.last4.value : this.last4,
      accountKind: data.accountKind.present
          ? data.accountKind.value
          : this.accountKind,
      reference: data.reference.present ? data.reference.value : this.reference,
      note: data.note.present ? data.note.value : this.note,
      fingerprint: data.fingerprint.present
          ? data.fingerprint.value
          : this.fingerprint,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HiddenTransaction(')
          ..write('id: $id, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('currency: $currency, ')
          ..write('direction: $direction, ')
          ..write('channel: $channel, ')
          ..write('merchant: $merchant, ')
          ..write('categoryName: $categoryName, ')
          ..write('bankCode: $bankCode, ')
          ..write('last4: $last4, ')
          ..write('accountKind: $accountKind, ')
          ..write('reference: $reference, ')
          ..write('note: $note, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    amountPaise,
    currency,
    direction,
    channel,
    merchant,
    categoryName,
    bankCode,
    last4,
    accountKind,
    reference,
    note,
    fingerprint,
    occurredAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HiddenTransaction &&
          other.id == this.id &&
          other.amountPaise == this.amountPaise &&
          other.currency == this.currency &&
          other.direction == this.direction &&
          other.channel == this.channel &&
          other.merchant == this.merchant &&
          other.categoryName == this.categoryName &&
          other.bankCode == this.bankCode &&
          other.last4 == this.last4 &&
          other.accountKind == this.accountKind &&
          other.reference == this.reference &&
          other.note == this.note &&
          other.fingerprint == this.fingerprint &&
          other.occurredAt == this.occurredAt &&
          other.createdAt == this.createdAt);
}

class HiddenTransactionsCompanion extends UpdateCompanion<HiddenTransaction> {
  final Value<int> id;
  final Value<int> amountPaise;
  final Value<String> currency;
  final Value<Direction> direction;
  final Value<String?> channel;
  final Value<String?> merchant;
  final Value<String?> categoryName;
  final Value<String?> bankCode;
  final Value<String?> last4;
  final Value<String?> accountKind;
  final Value<String?> reference;
  final Value<String?> note;
  final Value<String> fingerprint;
  final Value<DateTime> occurredAt;
  final Value<DateTime> createdAt;
  const HiddenTransactionsCompanion({
    this.id = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.currency = const Value.absent(),
    this.direction = const Value.absent(),
    this.channel = const Value.absent(),
    this.merchant = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.bankCode = const Value.absent(),
    this.last4 = const Value.absent(),
    this.accountKind = const Value.absent(),
    this.reference = const Value.absent(),
    this.note = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  HiddenTransactionsCompanion.insert({
    this.id = const Value.absent(),
    required int amountPaise,
    this.currency = const Value.absent(),
    required Direction direction,
    this.channel = const Value.absent(),
    this.merchant = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.bankCode = const Value.absent(),
    this.last4 = const Value.absent(),
    this.accountKind = const Value.absent(),
    this.reference = const Value.absent(),
    this.note = const Value.absent(),
    required String fingerprint,
    required DateTime occurredAt,
    required DateTime createdAt,
  }) : amountPaise = Value(amountPaise),
       direction = Value(direction),
       fingerprint = Value(fingerprint),
       occurredAt = Value(occurredAt),
       createdAt = Value(createdAt);
  static Insertable<HiddenTransaction> custom({
    Expression<int>? id,
    Expression<int>? amountPaise,
    Expression<String>? currency,
    Expression<String>? direction,
    Expression<String>? channel,
    Expression<String>? merchant,
    Expression<String>? categoryName,
    Expression<String>? bankCode,
    Expression<String>? last4,
    Expression<String>? accountKind,
    Expression<String>? reference,
    Expression<String>? note,
    Expression<String>? fingerprint,
    Expression<DateTime>? occurredAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (currency != null) 'currency': currency,
      if (direction != null) 'direction': direction,
      if (channel != null) 'channel': channel,
      if (merchant != null) 'merchant': merchant,
      if (categoryName != null) 'category_name': categoryName,
      if (bankCode != null) 'bank_code': bankCode,
      if (last4 != null) 'last4': last4,
      if (accountKind != null) 'account_kind': accountKind,
      if (reference != null) 'reference': reference,
      if (note != null) 'note': note,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  HiddenTransactionsCompanion copyWith({
    Value<int>? id,
    Value<int>? amountPaise,
    Value<String>? currency,
    Value<Direction>? direction,
    Value<String?>? channel,
    Value<String?>? merchant,
    Value<String?>? categoryName,
    Value<String?>? bankCode,
    Value<String?>? last4,
    Value<String?>? accountKind,
    Value<String?>? reference,
    Value<String?>? note,
    Value<String>? fingerprint,
    Value<DateTime>? occurredAt,
    Value<DateTime>? createdAt,
  }) {
    return HiddenTransactionsCompanion(
      id: id ?? this.id,
      amountPaise: amountPaise ?? this.amountPaise,
      currency: currency ?? this.currency,
      direction: direction ?? this.direction,
      channel: channel ?? this.channel,
      merchant: merchant ?? this.merchant,
      categoryName: categoryName ?? this.categoryName,
      bankCode: bankCode ?? this.bankCode,
      last4: last4 ?? this.last4,
      accountKind: accountKind ?? this.accountKind,
      reference: reference ?? this.reference,
      note: note ?? this.note,
      fingerprint: fingerprint ?? this.fingerprint,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(
        $HiddenTransactionsTable.$converterdirection.toSql(direction.value),
      );
    }
    if (channel.present) {
      map['channel'] = Variable<String>(channel.value);
    }
    if (merchant.present) {
      map['merchant'] = Variable<String>(merchant.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (bankCode.present) {
      map['bank_code'] = Variable<String>(bankCode.value);
    }
    if (last4.present) {
      map['last4'] = Variable<String>(last4.value);
    }
    if (accountKind.present) {
      map['account_kind'] = Variable<String>(accountKind.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (fingerprint.present) {
      map['fingerprint'] = Variable<String>(fingerprint.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HiddenTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('currency: $currency, ')
          ..write('direction: $direction, ')
          ..write('channel: $channel, ')
          ..write('merchant: $merchant, ')
          ..write('categoryName: $categoryName, ')
          ..write('bankCode: $bankCode, ')
          ..write('last4: $last4, ')
          ..write('accountKind: $accountKind, ')
          ..write('reference: $reference, ')
          ..write('note: $note, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $HiddenFingerprintsTable extends HiddenFingerprints
    with TableInfo<$HiddenFingerprintsTable, HiddenFingerprint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HiddenFingerprintsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fingerprintMeta = const VerificationMeta(
    'fingerprint',
  );
  @override
  late final GeneratedColumn<String> fingerprint = GeneratedColumn<String>(
    'fingerprint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [fingerprint, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hidden_fingerprints';
  @override
  VerificationContext validateIntegrity(
    Insertable<HiddenFingerprint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('fingerprint')) {
      context.handle(
        _fingerprintMeta,
        fingerprint.isAcceptableOrUnknown(
          data['fingerprint']!,
          _fingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fingerprintMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {fingerprint};
  @override
  HiddenFingerprint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HiddenFingerprint(
      fingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fingerprint'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $HiddenFingerprintsTable createAlias(String alias) {
    return $HiddenFingerprintsTable(attachedDatabase, alias);
  }
}

class HiddenFingerprint extends DataClass
    implements Insertable<HiddenFingerprint> {
  final String fingerprint;
  final DateTime createdAt;
  const HiddenFingerprint({required this.fingerprint, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['fingerprint'] = Variable<String>(fingerprint);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  HiddenFingerprintsCompanion toCompanion(bool nullToAbsent) {
    return HiddenFingerprintsCompanion(
      fingerprint: Value(fingerprint),
      createdAt: Value(createdAt),
    );
  }

  factory HiddenFingerprint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HiddenFingerprint(
      fingerprint: serializer.fromJson<String>(json['fingerprint']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fingerprint': serializer.toJson<String>(fingerprint),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  HiddenFingerprint copyWith({String? fingerprint, DateTime? createdAt}) =>
      HiddenFingerprint(
        fingerprint: fingerprint ?? this.fingerprint,
        createdAt: createdAt ?? this.createdAt,
      );
  HiddenFingerprint copyWithCompanion(HiddenFingerprintsCompanion data) {
    return HiddenFingerprint(
      fingerprint: data.fingerprint.present
          ? data.fingerprint.value
          : this.fingerprint,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HiddenFingerprint(')
          ..write('fingerprint: $fingerprint, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(fingerprint, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HiddenFingerprint &&
          other.fingerprint == this.fingerprint &&
          other.createdAt == this.createdAt);
}

class HiddenFingerprintsCompanion extends UpdateCompanion<HiddenFingerprint> {
  final Value<String> fingerprint;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const HiddenFingerprintsCompanion({
    this.fingerprint = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HiddenFingerprintsCompanion.insert({
    required String fingerprint,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : fingerprint = Value(fingerprint),
       createdAt = Value(createdAt);
  static Insertable<HiddenFingerprint> custom({
    Expression<String>? fingerprint,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HiddenFingerprintsCompanion copyWith({
    Value<String>? fingerprint,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return HiddenFingerprintsCompanion(
      fingerprint: fingerprint ?? this.fingerprint,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fingerprint.present) {
      map['fingerprint'] = Variable<String>(fingerprint.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HiddenFingerprintsCompanion(')
          ..write('fingerprint: $fingerprint, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CardSecretsTable extends CardSecrets
    with TableInfo<$CardSecretsTable, CardSecret> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardSecretsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numberCipherMeta = const VerificationMeta(
    'numberCipher',
  );
  @override
  late final GeneratedColumn<String> numberCipher = GeneratedColumn<String>(
    'number_cipher',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pinCipherMeta = const VerificationMeta(
    'pinCipher',
  );
  @override
  late final GeneratedColumn<String> pinCipher = GeneratedColumn<String>(
    'pin_cipher',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    numberCipher,
    pinCipher,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'card_secrets';
  @override
  VerificationContext validateIntegrity(
    Insertable<CardSecret> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('number_cipher')) {
      context.handle(
        _numberCipherMeta,
        numberCipher.isAcceptableOrUnknown(
          data['number_cipher']!,
          _numberCipherMeta,
        ),
      );
    }
    if (data.containsKey('pin_cipher')) {
      context.handle(
        _pinCipherMeta,
        pinCipher.isAcceptableOrUnknown(data['pin_cipher']!, _pinCipherMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CardSecret map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardSecret(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      numberCipher: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}number_cipher'],
      ),
      pinCipher: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pin_cipher'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CardSecretsTable createAlias(String alias) {
    return $CardSecretsTable(attachedDatabase, alias);
  }
}

class CardSecret extends DataClass implements Insertable<CardSecret> {
  final String id;
  final String? numberCipher;
  final String? pinCipher;
  final DateTime createdAt;
  const CardSecret({
    required this.id,
    this.numberCipher,
    this.pinCipher,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || numberCipher != null) {
      map['number_cipher'] = Variable<String>(numberCipher);
    }
    if (!nullToAbsent || pinCipher != null) {
      map['pin_cipher'] = Variable<String>(pinCipher);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CardSecretsCompanion toCompanion(bool nullToAbsent) {
    return CardSecretsCompanion(
      id: Value(id),
      numberCipher: numberCipher == null && nullToAbsent
          ? const Value.absent()
          : Value(numberCipher),
      pinCipher: pinCipher == null && nullToAbsent
          ? const Value.absent()
          : Value(pinCipher),
      createdAt: Value(createdAt),
    );
  }

  factory CardSecret.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardSecret(
      id: serializer.fromJson<String>(json['id']),
      numberCipher: serializer.fromJson<String?>(json['numberCipher']),
      pinCipher: serializer.fromJson<String?>(json['pinCipher']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'numberCipher': serializer.toJson<String?>(numberCipher),
      'pinCipher': serializer.toJson<String?>(pinCipher),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CardSecret copyWith({
    String? id,
    Value<String?> numberCipher = const Value.absent(),
    Value<String?> pinCipher = const Value.absent(),
    DateTime? createdAt,
  }) => CardSecret(
    id: id ?? this.id,
    numberCipher: numberCipher.present ? numberCipher.value : this.numberCipher,
    pinCipher: pinCipher.present ? pinCipher.value : this.pinCipher,
    createdAt: createdAt ?? this.createdAt,
  );
  CardSecret copyWithCompanion(CardSecretsCompanion data) {
    return CardSecret(
      id: data.id.present ? data.id.value : this.id,
      numberCipher: data.numberCipher.present
          ? data.numberCipher.value
          : this.numberCipher,
      pinCipher: data.pinCipher.present ? data.pinCipher.value : this.pinCipher,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardSecret(')
          ..write('id: $id, ')
          ..write('numberCipher: $numberCipher, ')
          ..write('pinCipher: $pinCipher, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, numberCipher, pinCipher, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardSecret &&
          other.id == this.id &&
          other.numberCipher == this.numberCipher &&
          other.pinCipher == this.pinCipher &&
          other.createdAt == this.createdAt);
}

class CardSecretsCompanion extends UpdateCompanion<CardSecret> {
  final Value<String> id;
  final Value<String?> numberCipher;
  final Value<String?> pinCipher;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CardSecretsCompanion({
    this.id = const Value.absent(),
    this.numberCipher = const Value.absent(),
    this.pinCipher = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CardSecretsCompanion.insert({
    required String id,
    this.numberCipher = const Value.absent(),
    this.pinCipher = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt);
  static Insertable<CardSecret> custom({
    Expression<String>? id,
    Expression<String>? numberCipher,
    Expression<String>? pinCipher,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (numberCipher != null) 'number_cipher': numberCipher,
      if (pinCipher != null) 'pin_cipher': pinCipher,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CardSecretsCompanion copyWith({
    Value<String>? id,
    Value<String?>? numberCipher,
    Value<String?>? pinCipher,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CardSecretsCompanion(
      id: id ?? this.id,
      numberCipher: numberCipher ?? this.numberCipher,
      pinCipher: pinCipher ?? this.pinCipher,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (numberCipher.present) {
      map['number_cipher'] = Variable<String>(numberCipher.value);
    }
    if (pinCipher.present) {
      map['pin_cipher'] = Variable<String>(pinCipher.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardSecretsCompanion(')
          ..write('id: $id, ')
          ..write('numberCipher: $numberCipher, ')
          ..write('pinCipher: $pinCipher, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VaultAuditTable extends VaultAudit
    with TableInfo<$VaultAuditTable, VaultAuditEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaultAuditTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
    'opened_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, openedAt, method];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vault_audit';
  @override
  VerificationContext validateIntegrity(
    Insertable<VaultAuditEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_openedAtMeta);
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VaultAuditEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VaultAuditEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      openedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}opened_at'],
      )!,
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
    );
  }

  @override
  $VaultAuditTable createAlias(String alias) {
    return $VaultAuditTable(attachedDatabase, alias);
  }
}

class VaultAuditEntry extends DataClass implements Insertable<VaultAuditEntry> {
  final int id;
  final DateTime openedAt;
  final String method;
  const VaultAuditEntry({
    required this.id,
    required this.openedAt,
    required this.method,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['opened_at'] = Variable<DateTime>(openedAt);
    map['method'] = Variable<String>(method);
    return map;
  }

  VaultAuditCompanion toCompanion(bool nullToAbsent) {
    return VaultAuditCompanion(
      id: Value(id),
      openedAt: Value(openedAt),
      method: Value(method),
    );
  }

  factory VaultAuditEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VaultAuditEntry(
      id: serializer.fromJson<int>(json['id']),
      openedAt: serializer.fromJson<DateTime>(json['openedAt']),
      method: serializer.fromJson<String>(json['method']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'openedAt': serializer.toJson<DateTime>(openedAt),
      'method': serializer.toJson<String>(method),
    };
  }

  VaultAuditEntry copyWith({int? id, DateTime? openedAt, String? method}) =>
      VaultAuditEntry(
        id: id ?? this.id,
        openedAt: openedAt ?? this.openedAt,
        method: method ?? this.method,
      );
  VaultAuditEntry copyWithCompanion(VaultAuditCompanion data) {
    return VaultAuditEntry(
      id: data.id.present ? data.id.value : this.id,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      method: data.method.present ? data.method.value : this.method,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VaultAuditEntry(')
          ..write('id: $id, ')
          ..write('openedAt: $openedAt, ')
          ..write('method: $method')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, openedAt, method);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VaultAuditEntry &&
          other.id == this.id &&
          other.openedAt == this.openedAt &&
          other.method == this.method);
}

class VaultAuditCompanion extends UpdateCompanion<VaultAuditEntry> {
  final Value<int> id;
  final Value<DateTime> openedAt;
  final Value<String> method;
  const VaultAuditCompanion({
    this.id = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.method = const Value.absent(),
  });
  VaultAuditCompanion.insert({
    this.id = const Value.absent(),
    required DateTime openedAt,
    required String method,
  }) : openedAt = Value(openedAt),
       method = Value(method);
  static Insertable<VaultAuditEntry> custom({
    Expression<int>? id,
    Expression<DateTime>? openedAt,
    Expression<String>? method,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (openedAt != null) 'opened_at': openedAt,
      if (method != null) 'method': method,
    });
  }

  VaultAuditCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? openedAt,
    Value<String>? method,
  }) {
    return VaultAuditCompanion(
      id: id ?? this.id,
      openedAt: openedAt ?? this.openedAt,
      method: method ?? this.method,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VaultAuditCompanion(')
          ..write('id: $id, ')
          ..write('openedAt: $openedAt, ')
          ..write('method: $method')
          ..write(')'))
        .toString();
  }
}

abstract class _$VaultDatabase extends GeneratedDatabase {
  _$VaultDatabase(QueryExecutor e) : super(e);
  $VaultDatabaseManager get managers => $VaultDatabaseManager(this);
  late final $HiddenTransactionsTable hiddenTransactions =
      $HiddenTransactionsTable(this);
  late final $HiddenFingerprintsTable hiddenFingerprints =
      $HiddenFingerprintsTable(this);
  late final $CardSecretsTable cardSecrets = $CardSecretsTable(this);
  late final $VaultAuditTable vaultAudit = $VaultAuditTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    hiddenTransactions,
    hiddenFingerprints,
    cardSecrets,
    vaultAudit,
  ];
}

typedef $$HiddenTransactionsTableCreateCompanionBuilder =
    HiddenTransactionsCompanion Function({
      Value<int> id,
      required int amountPaise,
      Value<String> currency,
      required Direction direction,
      Value<String?> channel,
      Value<String?> merchant,
      Value<String?> categoryName,
      Value<String?> bankCode,
      Value<String?> last4,
      Value<String?> accountKind,
      Value<String?> reference,
      Value<String?> note,
      required String fingerprint,
      required DateTime occurredAt,
      required DateTime createdAt,
    });
typedef $$HiddenTransactionsTableUpdateCompanionBuilder =
    HiddenTransactionsCompanion Function({
      Value<int> id,
      Value<int> amountPaise,
      Value<String> currency,
      Value<Direction> direction,
      Value<String?> channel,
      Value<String?> merchant,
      Value<String?> categoryName,
      Value<String?> bankCode,
      Value<String?> last4,
      Value<String?> accountKind,
      Value<String?> reference,
      Value<String?> note,
      Value<String> fingerprint,
      Value<DateTime> occurredAt,
      Value<DateTime> createdAt,
    });

class $$HiddenTransactionsTableFilterComposer
    extends Composer<_$VaultDatabase, $HiddenTransactionsTable> {
  $$HiddenTransactionsTableFilterComposer({
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

  ColumnFilters<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Direction, Direction, String> get direction =>
      $composableBuilder(
        column: $table.direction,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankCode => $composableBuilder(
    column: $table.bankCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get last4 => $composableBuilder(
    column: $table.last4,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountKind => $composableBuilder(
    column: $table.accountKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HiddenTransactionsTableOrderingComposer
    extends Composer<_$VaultDatabase, $HiddenTransactionsTable> {
  $$HiddenTransactionsTableOrderingComposer({
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

  ColumnOrderings<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankCode => $composableBuilder(
    column: $table.bankCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get last4 => $composableBuilder(
    column: $table.last4,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountKind => $composableBuilder(
    column: $table.accountKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HiddenTransactionsTableAnnotationComposer
    extends Composer<_$VaultDatabase, $HiddenTransactionsTable> {
  $$HiddenTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Direction, String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get channel =>
      $composableBuilder(column: $table.channel, builder: (column) => column);

  GeneratedColumn<String> get merchant =>
      $composableBuilder(column: $table.merchant, builder: (column) => column);

  GeneratedColumn<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bankCode =>
      $composableBuilder(column: $table.bankCode, builder: (column) => column);

  GeneratedColumn<String> get last4 =>
      $composableBuilder(column: $table.last4, builder: (column) => column);

  GeneratedColumn<String> get accountKind => $composableBuilder(
    column: $table.accountKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$HiddenTransactionsTableTableManager
    extends
        RootTableManager<
          _$VaultDatabase,
          $HiddenTransactionsTable,
          HiddenTransaction,
          $$HiddenTransactionsTableFilterComposer,
          $$HiddenTransactionsTableOrderingComposer,
          $$HiddenTransactionsTableAnnotationComposer,
          $$HiddenTransactionsTableCreateCompanionBuilder,
          $$HiddenTransactionsTableUpdateCompanionBuilder,
          (
            HiddenTransaction,
            BaseReferences<
              _$VaultDatabase,
              $HiddenTransactionsTable,
              HiddenTransaction
            >,
          ),
          HiddenTransaction,
          PrefetchHooks Function()
        > {
  $$HiddenTransactionsTableTableManager(
    _$VaultDatabase db,
    $HiddenTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HiddenTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HiddenTransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HiddenTransactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> amountPaise = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<Direction> direction = const Value.absent(),
                Value<String?> channel = const Value.absent(),
                Value<String?> merchant = const Value.absent(),
                Value<String?> categoryName = const Value.absent(),
                Value<String?> bankCode = const Value.absent(),
                Value<String?> last4 = const Value.absent(),
                Value<String?> accountKind = const Value.absent(),
                Value<String?> reference = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> fingerprint = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => HiddenTransactionsCompanion(
                id: id,
                amountPaise: amountPaise,
                currency: currency,
                direction: direction,
                channel: channel,
                merchant: merchant,
                categoryName: categoryName,
                bankCode: bankCode,
                last4: last4,
                accountKind: accountKind,
                reference: reference,
                note: note,
                fingerprint: fingerprint,
                occurredAt: occurredAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int amountPaise,
                Value<String> currency = const Value.absent(),
                required Direction direction,
                Value<String?> channel = const Value.absent(),
                Value<String?> merchant = const Value.absent(),
                Value<String?> categoryName = const Value.absent(),
                Value<String?> bankCode = const Value.absent(),
                Value<String?> last4 = const Value.absent(),
                Value<String?> accountKind = const Value.absent(),
                Value<String?> reference = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required String fingerprint,
                required DateTime occurredAt,
                required DateTime createdAt,
              }) => HiddenTransactionsCompanion.insert(
                id: id,
                amountPaise: amountPaise,
                currency: currency,
                direction: direction,
                channel: channel,
                merchant: merchant,
                categoryName: categoryName,
                bankCode: bankCode,
                last4: last4,
                accountKind: accountKind,
                reference: reference,
                note: note,
                fingerprint: fingerprint,
                occurredAt: occurredAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HiddenTransactionsTable, HiddenTransaction>(
                    table,
                  ),
                  BaseReferences<
                    _$VaultDatabase,
                    $HiddenTransactionsTable,
                    HiddenTransaction
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HiddenTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$VaultDatabase,
      $HiddenTransactionsTable,
      HiddenTransaction,
      $$HiddenTransactionsTableFilterComposer,
      $$HiddenTransactionsTableOrderingComposer,
      $$HiddenTransactionsTableAnnotationComposer,
      $$HiddenTransactionsTableCreateCompanionBuilder,
      $$HiddenTransactionsTableUpdateCompanionBuilder,
      (
        HiddenTransaction,
        BaseReferences<
          _$VaultDatabase,
          $HiddenTransactionsTable,
          HiddenTransaction
        >,
      ),
      HiddenTransaction,
      PrefetchHooks Function()
    >;
typedef $$HiddenFingerprintsTableCreateCompanionBuilder =
    HiddenFingerprintsCompanion Function({
      required String fingerprint,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$HiddenFingerprintsTableUpdateCompanionBuilder =
    HiddenFingerprintsCompanion Function({
      Value<String> fingerprint,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$HiddenFingerprintsTableFilterComposer
    extends Composer<_$VaultDatabase, $HiddenFingerprintsTable> {
  $$HiddenFingerprintsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HiddenFingerprintsTableOrderingComposer
    extends Composer<_$VaultDatabase, $HiddenFingerprintsTable> {
  $$HiddenFingerprintsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HiddenFingerprintsTableAnnotationComposer
    extends Composer<_$VaultDatabase, $HiddenFingerprintsTable> {
  $$HiddenFingerprintsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$HiddenFingerprintsTableTableManager
    extends
        RootTableManager<
          _$VaultDatabase,
          $HiddenFingerprintsTable,
          HiddenFingerprint,
          $$HiddenFingerprintsTableFilterComposer,
          $$HiddenFingerprintsTableOrderingComposer,
          $$HiddenFingerprintsTableAnnotationComposer,
          $$HiddenFingerprintsTableCreateCompanionBuilder,
          $$HiddenFingerprintsTableUpdateCompanionBuilder,
          (
            HiddenFingerprint,
            BaseReferences<
              _$VaultDatabase,
              $HiddenFingerprintsTable,
              HiddenFingerprint
            >,
          ),
          HiddenFingerprint,
          PrefetchHooks Function()
        > {
  $$HiddenFingerprintsTableTableManager(
    _$VaultDatabase db,
    $HiddenFingerprintsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HiddenFingerprintsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HiddenFingerprintsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HiddenFingerprintsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> fingerprint = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HiddenFingerprintsCompanion(
                fingerprint: fingerprint,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String fingerprint,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => HiddenFingerprintsCompanion.insert(
                fingerprint: fingerprint,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HiddenFingerprintsTable, HiddenFingerprint>(
                    table,
                  ),
                  BaseReferences<
                    _$VaultDatabase,
                    $HiddenFingerprintsTable,
                    HiddenFingerprint
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HiddenFingerprintsTableProcessedTableManager =
    ProcessedTableManager<
      _$VaultDatabase,
      $HiddenFingerprintsTable,
      HiddenFingerprint,
      $$HiddenFingerprintsTableFilterComposer,
      $$HiddenFingerprintsTableOrderingComposer,
      $$HiddenFingerprintsTableAnnotationComposer,
      $$HiddenFingerprintsTableCreateCompanionBuilder,
      $$HiddenFingerprintsTableUpdateCompanionBuilder,
      (
        HiddenFingerprint,
        BaseReferences<
          _$VaultDatabase,
          $HiddenFingerprintsTable,
          HiddenFingerprint
        >,
      ),
      HiddenFingerprint,
      PrefetchHooks Function()
    >;
typedef $$CardSecretsTableCreateCompanionBuilder =
    CardSecretsCompanion Function({
      required String id,
      Value<String?> numberCipher,
      Value<String?> pinCipher,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$CardSecretsTableUpdateCompanionBuilder =
    CardSecretsCompanion Function({
      Value<String> id,
      Value<String?> numberCipher,
      Value<String?> pinCipher,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$CardSecretsTableFilterComposer
    extends Composer<_$VaultDatabase, $CardSecretsTable> {
  $$CardSecretsTableFilterComposer({
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

  ColumnFilters<String> get numberCipher => $composableBuilder(
    column: $table.numberCipher,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinCipher => $composableBuilder(
    column: $table.pinCipher,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CardSecretsTableOrderingComposer
    extends Composer<_$VaultDatabase, $CardSecretsTable> {
  $$CardSecretsTableOrderingComposer({
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

  ColumnOrderings<String> get numberCipher => $composableBuilder(
    column: $table.numberCipher,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinCipher => $composableBuilder(
    column: $table.pinCipher,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CardSecretsTableAnnotationComposer
    extends Composer<_$VaultDatabase, $CardSecretsTable> {
  $$CardSecretsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get numberCipher => $composableBuilder(
    column: $table.numberCipher,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pinCipher =>
      $composableBuilder(column: $table.pinCipher, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CardSecretsTableTableManager
    extends
        RootTableManager<
          _$VaultDatabase,
          $CardSecretsTable,
          CardSecret,
          $$CardSecretsTableFilterComposer,
          $$CardSecretsTableOrderingComposer,
          $$CardSecretsTableAnnotationComposer,
          $$CardSecretsTableCreateCompanionBuilder,
          $$CardSecretsTableUpdateCompanionBuilder,
          (
            CardSecret,
            BaseReferences<_$VaultDatabase, $CardSecretsTable, CardSecret>,
          ),
          CardSecret,
          PrefetchHooks Function()
        > {
  $$CardSecretsTableTableManager(_$VaultDatabase db, $CardSecretsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardSecretsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardSecretsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardSecretsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> numberCipher = const Value.absent(),
                Value<String?> pinCipher = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CardSecretsCompanion(
                id: id,
                numberCipher: numberCipher,
                pinCipher: pinCipher,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> numberCipher = const Value.absent(),
                Value<String?> pinCipher = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CardSecretsCompanion.insert(
                id: id,
                numberCipher: numberCipher,
                pinCipher: pinCipher,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CardSecretsTable, CardSecret>(table),
                  BaseReferences<
                    _$VaultDatabase,
                    $CardSecretsTable,
                    CardSecret
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CardSecretsTableProcessedTableManager =
    ProcessedTableManager<
      _$VaultDatabase,
      $CardSecretsTable,
      CardSecret,
      $$CardSecretsTableFilterComposer,
      $$CardSecretsTableOrderingComposer,
      $$CardSecretsTableAnnotationComposer,
      $$CardSecretsTableCreateCompanionBuilder,
      $$CardSecretsTableUpdateCompanionBuilder,
      (
        CardSecret,
        BaseReferences<_$VaultDatabase, $CardSecretsTable, CardSecret>,
      ),
      CardSecret,
      PrefetchHooks Function()
    >;
typedef $$VaultAuditTableCreateCompanionBuilder = VaultAuditCompanion Function({
  Value<int> id,
  required DateTime openedAt,
  required String method,
});
typedef $$VaultAuditTableUpdateCompanionBuilder = VaultAuditCompanion Function({
  Value<int> id,
  Value<DateTime> openedAt,
  Value<String> method,
});

class $$VaultAuditTableFilterComposer
    extends Composer<_$VaultDatabase, $VaultAuditTable> {
  $$VaultAuditTableFilterComposer({
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

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VaultAuditTableOrderingComposer
    extends Composer<_$VaultDatabase, $VaultAuditTable> {
  $$VaultAuditTableOrderingComposer({
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

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VaultAuditTableAnnotationComposer
    extends Composer<_$VaultDatabase, $VaultAuditTable> {
  $$VaultAuditTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);
}

class $$VaultAuditTableTableManager
    extends
        RootTableManager<
          _$VaultDatabase,
          $VaultAuditTable,
          VaultAuditEntry,
          $$VaultAuditTableFilterComposer,
          $$VaultAuditTableOrderingComposer,
          $$VaultAuditTableAnnotationComposer,
          $$VaultAuditTableCreateCompanionBuilder,
          $$VaultAuditTableUpdateCompanionBuilder,
          (
            VaultAuditEntry,
            BaseReferences<_$VaultDatabase, $VaultAuditTable, VaultAuditEntry>,
          ),
          VaultAuditEntry,
          PrefetchHooks Function()
        > {
  $$VaultAuditTableTableManager(_$VaultDatabase db, $VaultAuditTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VaultAuditTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VaultAuditTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VaultAuditTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> openedAt = const Value.absent(),
            Value<String> method = const Value.absent(),
          }) => VaultAuditCompanion(id: id, openedAt: openedAt, method: method),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime openedAt,
                required String method,
              }) => VaultAuditCompanion.insert(
                id: id,
                openedAt: openedAt,
                method: method,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VaultAuditTable, VaultAuditEntry>(table),
                  BaseReferences<
                    _$VaultDatabase,
                    $VaultAuditTable,
                    VaultAuditEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VaultAuditTableProcessedTableManager =
    ProcessedTableManager<
      _$VaultDatabase,
      $VaultAuditTable,
      VaultAuditEntry,
      $$VaultAuditTableFilterComposer,
      $$VaultAuditTableOrderingComposer,
      $$VaultAuditTableAnnotationComposer,
      $$VaultAuditTableCreateCompanionBuilder,
      $$VaultAuditTableUpdateCompanionBuilder,
      (
        VaultAuditEntry,
        BaseReferences<_$VaultDatabase, $VaultAuditTable, VaultAuditEntry>,
      ),
      VaultAuditEntry,
      PrefetchHooks Function()
    >;

class $VaultDatabaseManager {
  final _$VaultDatabase _db;
  $VaultDatabaseManager(this._db);
  $$HiddenTransactionsTableTableManager get hiddenTransactions =>
      $$HiddenTransactionsTableTableManager(_db, _db.hiddenTransactions);
  $$HiddenFingerprintsTableTableManager get hiddenFingerprints =>
      $$HiddenFingerprintsTableTableManager(_db, _db.hiddenFingerprints);
  $$CardSecretsTableTableManager get cardSecrets =>
      $$CardSecretsTableTableManager(_db, _db.cardSecrets);
  $$VaultAuditTableTableManager get vaultAudit =>
      $$VaultAuditTableTableManager(_db, _db.vaultAudit);
}
