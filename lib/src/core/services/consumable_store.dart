// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:local_storage/local_storage.dart';

// ignore: avoid_classes_with_only_static_members
/// A store of consumable items.
///
/// This is a development prototype tha stores consumables in the shared
/// preferences. Do not use this in real world apps.
class ConsumableStore {
  ConsumableStore({
    required LocalStorage localStorage,
  }) : _localStorage = localStorage;

  static const String _kPrefKey = 'consumables';
  static Future<void> _writes = Future<void>.value();

  final LocalStorage _localStorage;

  /// Adds a consumable with ID `id` to the store.
  ///
  /// The consumable is only added after the returned Future is complete.
  Future<void> save(String id) {
    _writes = _writes.then((void _) => _doSave(id));
    return _writes;
  }

  /// Consumes a consumable with ID `id` from the store.
  ///
  /// The consumable was only consumed after the returned Future is complete.
  Future<void> consume(String id) {
    _writes = _writes.then((void _) => _doConsume(id));
    return _writes;
  }

  /// Returns the list of consumables from the store.
  Future<List<String>> load() async {
    return (await _localStorage.get<List<String>>(_kPrefKey)) ?? [];
  }

  Future<void> _doSave(String id) async {
    final List<String> cached = await load();

    cached.add(id);

    await _localStorage.store(_kPrefKey, cached);
  }

  Future<void> _doConsume(String id) async {
    final List<String> cached = await load();
    cached.remove(id);

    await _localStorage.store(_kPrefKey, cached);
  }
}
