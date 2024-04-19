import 'package:latlong2/latlong.dart';
import 'package:test/test.dart';

import 'package:polybool/polybool.dart';

void main() {
  test('Two partially overlapping squares', () {
    final poly1 = Polygon(regions: [
      [
        LatLng(1, 1),
        LatLng(10, 1),
        LatLng(10, 10),
        LatLng(1, 10),
      ]
    ]);

    final poly2 = Polygon(regions: [
      [
        LatLng(-4, -4),
        LatLng(4, -4),
        LatLng(4, 4),
        LatLng(-4, 4),
      ]
    ]);

    // Self-union is identity.
    expect(poly1.union(poly1).regions.first,
        unorderedEquals(poly1.regions.first.sublist(0, 4)));
    expect(
        poly1.union(poly2).regions.first,
        orderedEquals([
          LatLng(10.0, 10.0),
          LatLng(10.0, 1.0),
          LatLng(4.0, 1.0),
          LatLng(4.0, -4.0),
          LatLng(-4.0, -4.0),
          LatLng(-4.0, 4.0),
          LatLng(1.0, 4.0),
          LatLng(1.0, 10.0),
        ]));

    // Self-intersection is also identity.
    expect(poly1.intersect(poly1).regions.first,
        unorderedEquals(poly1.regions.first.sublist(0, 4)));
    final intersection = poly1.intersect(poly2);
    expect(
        intersection.regions.first,
        orderedEquals([
          LatLng(4.0, 4.0),
          LatLng(4.0, 1.0),
          LatLng(1.0, 1.0),
          LatLng(1.0, 4.0),
        ]));
    expect(poly2.intersect(poly1).regions.first,
        equals(intersection.regions.first));

    // Self-difference is empty.
    expect(poly1.difference(poly1).regions, equals([]));
    expect(
        poly1.difference(poly2).regions.first,
        orderedEquals([
          LatLng(10.0, 10.0),
          LatLng(10.0, 1.0),
          LatLng(4.0, 1.0),
          LatLng(4.0, 4.0),
          LatLng(1.0, 4.0),
          LatLng(1.0, 10.0)
        ]));

    // Self-difference is empty.
    expect(poly1.differenceRev(poly1).regions, equals([]));
    expect(
        poly1.differenceRev(poly2).regions.first,
        orderedEquals([
          LatLng(4.0, 1.0),
          LatLng(4.0, -4.0),
          LatLng(-4.0, -4.0),
          LatLng(-4.0, 4.0),
          LatLng(1.0, 4.0),
          LatLng(1.0, 1.0),
        ]));
    //// Make sure -(P1 - P2) == (P2 - P1).
    expect(poly1.differenceRev(poly2).regions.first,
        equals(poly2.difference(poly1).regions.first));

    // Self-XOR is empty.
    expect(poly1.xor(poly1).regions, equals([]));
    final xor = poly1.xor(poly2);
    expect(
        xor.regions.first,
        equals([
          LatLng(4.0, 1.0),
          LatLng(4.0, -4.0),
          LatLng(-4.0, -4.0),
          LatLng(-4.0, 4.0),
          LatLng(1.0, 4.0),
          LatLng(1.0, 1.0),
        ]));
    expect(
        xor.regions.last,
        equals([
          LatLng(10.0, 10.0),
          LatLng(10.0, 1.0),
          LatLng(4.0, 1.0),
          LatLng(4.0, 4.0),
          LatLng(1.0, 4.0),
          LatLng(1.0, 10.0),
        ]));

    // Make sure multiple regions are merged.
    expect(intersection.union(xor).regions, equals(poly1.union(poly2).regions));
  });
}
