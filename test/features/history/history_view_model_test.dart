import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_ai_scanner/features/history/history_view_model.dart';

void main() {
  group('HistoryViewModel', () {
    late HistoryViewModel viewModel;

    setUp(() {
      viewModel = HistoryViewModel();
    });

    test('initial state is idle', () {
      expect(viewModel.state, equals(HistoryState.idle));
      expect(viewModel.entries, isEmpty);
      expect(viewModel.selectedIds, isEmpty);
      expect(viewModel.selectionMode, isFalse);
    });

    test('toggleSelectionMode enables selection mode', () {
      viewModel.toggleSelectionMode();

      expect(viewModel.selectionMode, isTrue);
    });

    test('toggleSelectionMode disables and clears selection', () {
      viewModel.toggleSelectionMode();
      viewModel.toggleSelection('test-id');
      viewModel.toggleSelectionMode();

      expect(viewModel.selectionMode, isFalse);
      expect(viewModel.selectedIds, isEmpty);
    });

    test('exitSelectionMode clears selection and disables mode', () {
      viewModel.toggleSelectionMode();
      viewModel.toggleSelection('test-id');
      viewModel.exitSelectionMode();

      expect(viewModel.selectionMode, isFalse);
      expect(viewModel.selectedIds, isEmpty);
    });

    test('toggleSelection adds and removes ids', () {
      viewModel.toggleSelectionMode();

      viewModel.toggleSelection('id-1');
      expect(viewModel.selectedIds, contains('id-1'));
      expect(viewModel.selectedCount, equals(1));

      viewModel.toggleSelection('id-2');
      expect(viewModel.selectedIds, contains('id-2'));
      expect(viewModel.selectedCount, equals(2));

      viewModel.toggleSelection('id-1');
      expect(viewModel.selectedIds, isNot(contains('id-1')));
      expect(viewModel.selectedCount, equals(1));
    });

    test('clearSelection removes all selected ids', () {
      viewModel.toggleSelectionMode();
      viewModel.toggleSelection('id-1');
      viewModel.toggleSelection('id-2');
      viewModel.clearSelection();

      expect(viewModel.selectedIds, isEmpty);
      expect(viewModel.hasSelection, isFalse);
    });

    test('search updates searchQuery', () {
      viewModel.search('test query');

      expect(viewModel.searchQuery, equals('test query'));
    });

    test('clearSearch resets searchQuery', () {
      viewModel.search('test query');
      viewModel.clearSearch();

      expect(viewModel.searchQuery, isEmpty);
    });

    test('hasSelection returns correct value', () {
      expect(viewModel.hasSelection, isFalse);

      viewModel.toggleSelectionMode();
      viewModel.toggleSelection('id-1');

      expect(viewModel.hasSelection, isTrue);
    });
  });
}

