import 'package:flutter_test/flutter_test.dart';
import 'package:rm_boutique/core/boutique_location.dart';

void main() {
  test('coordinates are shown with five decimals, latitude first', () {
    expect(formatCoordinates(31.7040, 35.2063), '31.70400, 35.20630');
    expect(formatCoordinates(31.123456789, 35.1), '31.12346, 35.10000');
  });

  test('the pickup point is a valid place near Bethlehem', () {
    expect(kBoutiqueLatLng.latitude, inInclusiveRange(31.6, 31.8));
    expect(kBoutiqueLatLng.longitude, inInclusiveRange(35.1, 35.3));
    expect(kBoutiqueName, contains('R&M Boutique'));
  });
}
