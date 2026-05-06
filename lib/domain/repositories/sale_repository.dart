import '../../data/models/sale_models.dart';
import '../../data/models/sync_models.dart';

abstract class SaleRepository {
  Future<Sale> completeSale(Sale sale);
  Future<Sale> getSaleByNumber(String saleNumber);
  Future<Sale> processReturn({
    required String saleId,
    required List<Map<String, dynamic>> returnItems,
    required String reason,
  });
  Future<Receipt> getReceipt(String saleId);
  Future<List<Sale>> getRecentSales({int page = 0, int size = 50});
  Future<void> savePendingSale(PendingSale pendingSale);
  Future<List<PendingSale>> getPendingSales();
  Future<int> getPendingSaleCount();
}
