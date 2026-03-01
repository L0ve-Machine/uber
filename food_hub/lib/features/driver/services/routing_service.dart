import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

/// OpenStreetMap Routing Service (OSRM)
///
/// 道路に沿ったルートを取得するサービス
class RoutingService {
  static const String _baseUrl = 'https://router.project-osrm.org/route/v1';
  static final Dio _dio = Dio();

  /// 2地点間のルートを取得
  ///
  /// [from] 出発地点
  /// [to] 到着地点
  /// [mode] 移動手段 (driving, walking, cycling) デフォルト: driving
  ///
  /// 戻り値: 道路に沿った座標リスト、失敗時は直線（2点）を返す
  static Future<List<LatLng>> getRoute(
    LatLng from,
    LatLng to, {
    String mode = 'driving',
  }) async {
    try {
      // OSRM APIエンドポイント
      // 形式: /{mode}/{lon1},{lat1};{lon2},{lat2}
      final url = '$_baseUrl/$mode/'
          '${from.longitude},${from.latitude};'
          '${to.longitude},${to.latitude}'
          '?overview=full&geometries=geojson';

      print('[RoutingService] Fetching route: $url');

      final response = await _dio.get(
        url,
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode != 200) {
        print('[RoutingService] API error: ${response.statusCode}');
        return _fallbackToStraightLine(from, to);
      }

      final data = response.data;

      // レスポンス検証
      if (data['code'] != 'Ok' || data['routes'] == null || data['routes'].isEmpty) {
        print('[RoutingService] Invalid response: ${data['code']}');
        return _fallbackToStraightLine(from, to);
      }

      // 座標リストを取得（GeoJSON形式）
      final coordinates = data['routes'][0]['geometry']['coordinates'] as List;

      // [lng, lat] → LatLng に変換
      final route = coordinates
          .map((coord) => LatLng(coord[1] as double, coord[0] as double))
          .toList();

      print('[RoutingService] Route fetched: ${route.length} points');
      return route;

    } catch (e) {
      print('[RoutingService] Error fetching route: $e');
      return _fallbackToStraightLine(from, to);
    }
  }

  /// 複数地点を経由するルートを取得
  ///
  /// [points] 経由地点リスト（最低2点）
  ///
  /// 例: [レストラン, 配達員, 配達先] → 2本のルートを返す
  static Future<List<List<LatLng>>> getMultiPointRoute(
    List<LatLng> points, {
    String mode = 'driving',
  }) async {
    if (points.length < 2) {
      throw ArgumentError('At least 2 points are required');
    }

    final routes = <List<LatLng>>[];

    // 各区間のルートを取得
    for (int i = 0; i < points.length - 1; i++) {
      final route = await getRoute(points[i], points[i + 1], mode: mode);
      routes.add(route);
    }

    return routes;
  }

  /// ルート取得失敗時のフォールバック（直線）
  static List<LatLng> _fallbackToStraightLine(LatLng from, LatLng to) {
    print('[RoutingService] Falling back to straight line');
    return [from, to];
  }

  /// ルートの総距離を計算（メートル）
  static double calculateRouteDistance(List<LatLng> route) {
    if (route.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < route.length - 1; i++) {
      totalDistance += const Distance().as(
        LengthUnit.Meter,
        route[i],
        route[i + 1],
      );
    }

    return totalDistance;
  }

  /// 到着予定時刻を推定（分）
  ///
  /// [distanceKm] 距離（km）
  /// [avgSpeedKmh] 平均速度（km/h）デフォルト: 20km/h（バイク・自転車）
  static int estimateArrivalMinutes(double distanceKm, {double avgSpeedKmh = 20.0}) {
    final hours = distanceKm / avgSpeedKmh;
    final minutes = (hours * 60).round();
    return minutes < 1 ? 1 : minutes;
  }

  /// 到着予定時刻を文字列で取得
  static String estimateArrivalTimeString(double distanceKm) {
    final minutes = estimateArrivalMinutes(distanceKm);

    if (minutes < 1) return '1分以内';
    if (minutes > 60) {
      final hrs = (minutes / 60).floor();
      final mins = minutes % 60;
      return '約${hrs}時間${mins}分';
    }
    return '約${minutes}分';
  }
}
