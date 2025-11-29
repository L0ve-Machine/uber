import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../models/order_tracking_model.dart';

part 'tracking_api_service.g.dart';

@RestApi()
abstract class TrackingApiService {
  factory TrackingApiService(Dio dio, {String baseUrl}) = _TrackingApiService;

  /// Get order tracking information
  @GET('/orders/{id}/tracking')
  Future<OrderTrackingModel> getOrderTracking(@Path('id') int orderId);
}
