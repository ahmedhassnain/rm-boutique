import 'package:latlong2/latlong.dart';

/// Where riders collect the orders: the R&M Boutique shop in Bethlehem.
///
/// These are approximate coordinates for the centre of Bethlehem. To point
/// riders at the exact shop door, change the two numbers below (open Google
/// Maps, long-press the shop, and copy the pair shown at the top).
const kBoutiqueLatLng = LatLng(31.7040, 35.2063);

/// The name shown for the pickup point.
const String kBoutiqueName = 'R&M Boutique (pickup)';

/// "31.70400, 35.20630": the same format on every screen that shows a point.
String formatCoordinates(double lat, double lng) =>
    '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
