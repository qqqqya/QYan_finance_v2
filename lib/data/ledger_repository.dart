part of 'finance_repository.dart';

extension LedgerOperations on FinanceRepository {
  Stream<LedgerWorkspace> watchLedger() => database
      .customSelect(
        '''
    SELECT 'category' AS kind, json_object(
      'id',id,'createdAtMs',created_at_ms,'updatedAtMs',updated_at_ms,
      'type',type,'nameKey',name_key,'customName',custom_name,
      'sortOrder',sort_order,'isActive',is_active) AS payload FROM categories
    UNION ALL SELECT 'bill', json_object(
      'id',id,'createdAtMs',created_at_ms,'updatedAtMs',updated_at_ms,
      'type',type,'amountMinor',amount_minor,'categoryId',category_id,
      'businessDate',business_date,'businessTime',business_time,'note',note) FROM bills
    UNION ALL SELECT 'memo', json_object(
      'id',id,'createdAtMs',created_at_ms,'updatedAtMs',updated_at_ms,
      'title',title,'body',body,'businessDate',business_date,'tagsJson',tags_json) FROM memos
  ''',
        readsFrom: {database.categories, database.bills, database.memos},
      )
      .watch()
      .map((rows) {
        final categories = <CategoryRow>[],
            bills = <BillRow>[],
            memos = <MemoRow>[];
        for (final row in rows) {
          final p =
              jsonDecode(row.read<String>('payload')) as Map<String, dynamic>;
          switch (row.read<String>('kind')) {
            case 'category':
              p['isActive'] = p['isActive'] == 1;
              categories.add(CategoryRow.fromJson(p));
            case 'bill':
              bills.add(BillRow.fromJson(p));
            case 'memo':
              memos.add(MemoRow.fromJson(p));
          }
        }
        categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        return LedgerWorkspace(categories, bills, memos);
      });

  Future<CategoryRow> _ledgerCategory(String id) async {
    final c = await (database.select(
      database.categories,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    if (c == null) throw const FinanceValidation('missing');
    return c;
  }

  void _direction(String type) {
    if (!{'income', 'expense'}.contains(type)) {
      throw const FinanceValidation('type');
    }
  }

  Map<String, dynamic> _billPayload(BillRow b, CategoryRow c) => {
    ...b.toJson(),
    'categoryCustomName': c.customName,
    'categoryNameKey': c.nameKey,
  };
  Future<String> saveBill({
    String? id,
    required String type,
    required int amount,
    required String categoryId,
    required BusinessMoment moment,
    String note = '',
  }) => database.transaction(() async {
    _direction(type);
    if (amount < 1 || amount > maxRecordMinor) {
      throw const FinanceValidation('amount');
    }
    if (note.length > 2000) throw const FinanceValidation('text');
    await _validateMoment(moment);
    final old = id == null
        ? null
        : await (database.select(
            database.bills,
          )..where((b) => b.id.equals(id))).getSingleOrNull();
    if (id != null && old == null) throw const FinanceValidation('missing');
    final category = await _ledgerCategory(categoryId);
    if (category.type != type ||
        (!category.isActive &&
            (old?.categoryId != categoryId || old?.type != type))) {
      throw const FinanceValidation('categoryUnavailable');
    }
    final stamp = clock().toUtc().millisecondsSinceEpoch;
    final row = BillRow(
      id: id ?? FinanceRepository._uuid.v4(),
      createdAtMs: old?.createdAtMs ?? stamp,
      updatedAtMs: stamp,
      type: type,
      amountMinor: amount,
      categoryId: categoryId,
      businessDate: moment.date.toString(),
      businessTime: moment.time,
      note: note.trim(),
    );
    if (old == null) {
      await database.into(database.bills).insert(row);
    } else {
      if (old.copyWith(updatedAtMs: stamp) == row) return row.id;
      await (database.update(
        database.bills,
      )..where((b) => b.id.equals(row.id))).write(row);
      await _history(
        'bill',
        row.id,
        _billPayload(old, await _ledgerCategory(old.categoryId)),
        _billPayload(row, category),
      );
    }
    return row.id;
  });
  Future<void> deleteBill(String id) => database.transaction(() async {
    await (database.delete(database.bills)..where((b) => b.id.equals(id))).go();
  });

  Future<String> saveCategory({
    String? id,
    required String name,
    required String type,
    bool active = true,
    bool keepBuiltInName = false,
  }) => database.transaction(() async {
    _direction(type);
    if (name.trim().isEmpty || name.trim().length > 80) {
      throw const FinanceValidation('name');
    }
    final old = id == null ? null : await _ledgerCategory(id);
    if (old != null && old.type != type) {
      throw const FinanceValidation('lockedType');
    }
    final stamp = clock().toUtc().millisecondsSinceEpoch;
    final all = await database.select(database.categories).get();
    final nextOrder =
        all.fold<int>(-1, (v, c) => c.sortOrder > v ? c.sortOrder : v) + 1;
    final row = CategoryRow(
      id: id ?? FinanceRepository._uuid.v4(),
      createdAtMs: old?.createdAtMs ?? stamp,
      updatedAtMs: stamp,
      type: type,
      nameKey: keepBuiltInName ? old?.nameKey : null,
      customName: keepBuiltInName ? old?.customName : name.trim(),
      sortOrder: old?.sortOrder ?? nextOrder,
      isActive: active,
    );
    if (old == null) {
      await database.into(database.categories).insert(row);
    } else {
      if (old.copyWith(updatedAtMs: stamp) == row) return row.id;
      await (database.update(
        database.categories,
      )..where((c) => c.id.equals(row.id))).write(row);
      await _history('category', row.id, old.toJson(), row.toJson());
    }
    return row.id;
  });
  Future<void> deleteCategory(String id, {String? replacementId}) =>
      database.transaction(() async {
        final category = await _ledgerCategory(id);
        final references = await (database.select(
          database.bills,
        )..where((b) => b.categoryId.equals(id))).get();
        if (references.isNotEmpty) {
          if (replacementId == null || replacementId == id) {
            throw const FinanceValidation('categoryReferenced');
          }
          final target = await _ledgerCategory(replacementId);
          if (!target.isActive || target.type != category.type) {
            throw const FinanceValidation('categoryUnavailable');
          }
          for (final before in references) {
            final after = before.copyWith(
              categoryId: target.id,
              updatedAtMs: clock().toUtc().millisecondsSinceEpoch,
            );
            await (database.update(
              database.bills,
            )..where((b) => b.id.equals(before.id))).write(after);
            await _history(
              'bill',
              before.id,
              _billPayload(before, category),
              _billPayload(after, target),
            );
          }
        }
        await (database.delete(
          database.categories,
        )..where((c) => c.id.equals(id))).go();
      });

  Future<String> saveMemo({
    String? id,
    required String title,
    required String body,
    required BusinessDate date,
    required List<String> tags,
  }) => database.transaction(() async {
    if (title.trim().isEmpty ||
        title.trim().length > 200 ||
        body.length > 20000) {
      throw const FinanceValidation('memoText');
    }
    final normalized = tags
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
    if (normalized.length > 10 || normalized.any((t) => t.length > 30)) {
      throw const FinanceValidation('tags');
    }
    await _validateMoment(BusinessMoment(date, '00:00'));
    final old = id == null
        ? null
        : await (database.select(
            database.memos,
          )..where((m) => m.id.equals(id))).getSingleOrNull();
    if (id != null && old == null) throw const FinanceValidation('missing');
    final stamp = clock().toUtc().millisecondsSinceEpoch;
    final row = MemoRow(
      id: id ?? FinanceRepository._uuid.v4(),
      createdAtMs: old?.createdAtMs ?? stamp,
      updatedAtMs: stamp,
      title: title.trim(),
      body: body.trim(),
      businessDate: date.toString(),
      tagsJson: jsonEncode(normalized),
    );
    Map<String, dynamic> payload(MemoRow m) => {
      ...m.toJson()..remove('tagsJson'),
      'tags': memoTags(m),
    };
    if (old == null) {
      await database.into(database.memos).insert(row);
    } else {
      if (old.copyWith(updatedAtMs: stamp) == row) return row.id;
      await (database.update(
        database.memos,
      )..where((m) => m.id.equals(row.id))).write(row);
      await _history('memo', row.id, payload(old), payload(row));
    }
    return row.id;
  });
  Future<void> deleteMemo(String id) => database.transaction(() async {
    await (database.delete(database.memos)..where((m) => m.id.equals(id))).go();
  });
}
