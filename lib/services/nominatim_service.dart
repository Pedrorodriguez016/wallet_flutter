import 'package:dio/dio.dart';

class NominatimPlace {
  final String displayName;
  final String street;
  final String houseNumber;
  final String city;
  final String postcode;

  NominatimPlace({
    required this.displayName,
    required this.street,
    required this.houseNumber,
    required this.city,
    required this.postcode,
  });

  factory NominatimPlace.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>? ?? {};
    
    final street = (address['road'] ??
            address['pedestrian'] ??
            address['footway'] ??
            address['suburb'] ??
            json['display_name'] ??
            '')
        .toString();

    final houseNumber = (address['house_number'] ?? '').toString();
    final fullStreet = houseNumber.isNotEmpty ? "$street, $houseNumber" : street;

    final city = (address['city'] ??
            address['town'] ??
            address['village'] ??
            address['municipality'] ??
            address['county'] ??
            address['state'] ??
            '')
        .toString();

    final postcode = (address['postcode'] ?? '').toString();

    return NominatimPlace(
      displayName: (json['display_name'] ?? fullStreet).toString(),
      street: fullStreet,
      houseNumber: houseNumber,
      city: city,
      postcode: postcode,
    );
  }
}

class NominatimService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://nominatim.openstreetmap.org',
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
    headers: {
      'User-Agent': 'WalletApp/1.0',
      'Accept-Language': 'ca,es,en',
    },
  ));

  Future<List<NominatimPlace>> searchPlaces(String query) async {
    if (query.trim().length < 3) return [];

    try {
      final response = await _dio.get(
        '/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': 1,
          'limit': 5,
        },
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((item) => NominatimPlace.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
