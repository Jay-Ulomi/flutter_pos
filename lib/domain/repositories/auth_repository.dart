import '../../data/models/auth_models.dart';
import '../../data/models/business_models.dart';

abstract class AuthRepository {
  Future<AuthResponse> login(LoginRequest request);
  Future<ContextResponse> switchContext(SwitchContextRequest request);
  Future<User> getCurrentUser();
  Future<List<Business>> getBusinesses();
  Future<List<Branch>> getBranches(String businessId);
  Future<List<TenantFeature>> getTenantFeatures();
  Future<SubscriptionInfo?> getSubscription();
  Future<void> logout();
}
