import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/exceptions.dart';
import '../../../data/datasources/remote/feed_remote.dart';
import '../../../data/models/feed_models.dart';

/// State of a paged server list.
class FeedState<T> extends Equatable {
  const FeedState({
    this.items = const [],
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.page = 0,
    this.hasMore = false,
  });

  final List<T> items;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final int page;
  final bool hasMore;

  FeedState<T> copyWith({
    List<T>? items,
    bool? loading,
    bool? loadingMore,
    String? error,
    bool clearError = false,
    int? page,
    bool? hasMore,
  }) {
    return FeedState<T>(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: clearError ? null : (error ?? this.error),
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [items, loading, loadingMore, error, page, hasMore];
}

/// Loads page 0 on [refresh] and appends on [loadMore]; a newer refresh
/// discards replies from older ones (fast typing in search).
abstract class FeedCubit<T> extends Cubit<FeedState<T>> {
  FeedCubit() : super(FeedState<T>());

  int _generation = 0;

  Future<PageResult<T>> fetch(int page);

  Future<void> refresh() async {
    final gen = ++_generation;
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final result = await fetch(0);
      if (gen != _generation || isClosed) return;
      emit(FeedState<T>(items: result.items, page: 0, hasMore: result.hasMore));
    } catch (e) {
      if (gen != _generation || isClosed) return;
      emit(state.copyWith(loading: false, error: _message(e)));
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loading || state.loadingMore) return;
    final gen = _generation;
    emit(state.copyWith(loadingMore: true));
    try {
      final result = await fetch(state.page + 1);
      if (gen != _generation || isClosed) return;
      emit(state.copyWith(
        items: [...state.items, ...result.items],
        page: state.page + 1,
        hasMore: result.hasMore,
        loadingMore: false,
      ));
    } catch (e) {
      if (gen != _generation || isClosed) return;
      emit(state.copyWith(loadingMore: false, error: _message(e)));
    }
  }

  static String _message(Object e) =>
      e is ServerException ? e.message : 'Could not load. Check your connection and try again.';
}

/// Status pill filter on the transactions feed. Applied on the device (the
/// feed contract has no status parameter), so the screen holds it.
enum TxStatusFilter {
  all,
  paid,
  unpaid,
  partial;

  bool accepts(TransactionItem t) {
    final s = (t.status ?? '').toUpperCase();
    switch (this) {
      case TxStatusFilter.all:
        return true;
      case TxStatusFilter.paid:
        return s == 'PAID' || s == 'SETTLED' || s == 'COMPLETED';
      case TxStatusFilter.unpaid:
        return s == 'UNPAID' || s == 'OPEN' || s == 'OVERDUE';
      case TxStatusFilter.partial:
        return s == 'PARTIAL' || s == 'PARTIALLY_PAID';
    }
  }
}

/// Server-side filters of the transactions feed.
class TransactionsFilter extends Equatable {
  const TransactionsFilter({
    this.types = const {},
    this.from,
    this.to,
    this.search = '',
    this.partyType,
    this.partyId,
  });

  final Set<TxType> types;
  final DateTime? from;
  final DateTime? to;
  final String search;
  final PartyType? partyType;
  final String? partyId;

  TransactionsFilter copyWith({
    Set<TxType>? types,
    DateTime? from,
    DateTime? to,
    bool clearDates = false,
    String? search,
  }) {
    return TransactionsFilter(
      types: types ?? this.types,
      from: clearDates ? null : (from ?? this.from),
      to: clearDates ? null : (to ?? this.to),
      search: search ?? this.search,
      partyType: partyType,
      partyId: partyId,
    );
  }

  @override
  List<Object?> get props => [types, from, to, search, partyType, partyId];
}

class TransactionsCubit extends FeedCubit<TransactionItem> {
  TransactionsCubit(this._remote, {TransactionsFilter filter = const TransactionsFilter()})
      : _filter = filter;

  final FeedRemoteDataSource _remote;
  TransactionsFilter _filter;
  TransactionsFilter get filter => _filter;

  Future<void> setFilter(TransactionsFilter next) async {
    if (next == _filter) return;
    _filter = next;
    await refresh();
  }

  @override
  Future<PageResult<TransactionItem>> fetch(int page) => _remote.getTransactions(
        types: _filter.types,
        from: _filter.from,
        to: _filter.to,
        search: _filter.search,
        partyType: _filter.partyType,
        partyId: _filter.partyId,
        page: page,
      );
}

class PartiesCubit extends FeedCubit<PartySummary> {
  PartiesCubit(this._remote);

  final FeedRemoteDataSource _remote;
  PartyType? type;
  String search = '';

  Future<void> setType(PartyType? t) async {
    type = t;
    await refresh();
  }

  Future<void> setSearch(String s) async {
    search = s;
    await refresh();
  }

  @override
  Future<PageResult<PartySummary>> fetch(int page) =>
      _remote.getParties(type: type, search: search, page: page);
}
