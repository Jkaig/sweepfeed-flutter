import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../core/data/repositories/contest_repository.dart';
import '../../../core/models/contest.dart';
import '../../../core/providers/contest_providers.dart';

final paginatedContestProvider = StateNotifierProvider.family<
    PaginatedContestNotifier,
    PagingState<DocumentSnapshot?, Contest>,
    ContestQueryParams>((ref, queryParams) {
  final repository = ref.watch(contestRepositoryProvider);
  return PaginatedContestNotifier(repository, queryParams, ref);
});

class PaginatedContestNotifier
    extends StateNotifier<PagingState<DocumentSnapshot?, Contest>> {
  PaginatedContestNotifier(this._repository, this._queryParams, this._ref)
      : super(PagingState<DocumentSnapshot?, Contest>(
          itemList: [],
          nextPageKey: null,
          error: null,
        )) {
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  final ContestRepository _repository;
  final ContestQueryParams _queryParams;
  final Ref _ref;

  final PagingController<DocumentSnapshot?, Contest> _pagingController =
      PagingController(firstPageKey: null);

  PagingController<DocumentSnapshot?, Contest> get pagingController =>
      _pagingController;

  Future<void> _fetchPage(DocumentSnapshot? pageKey) async {
    try {
      final newItems = await _repository.getActiveContests(
        category: _queryParams.category,
        sortBy: _queryParams.sortBy,
        ascending: _queryParams.ascending,
        limit: _queryParams.limit,
        startAfter: pageKey,
      );

      final isLastPage = newItems.length < _queryParams.limit;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = await _repository
            .getContestById(newItems.last.id)
            .then((value) => value!.toFirestore());
        _pagingController.appendPage(newItems, nextPageKey as DocumentSnapshot?);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  void refresh() {
    _pagingController.refresh();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}
