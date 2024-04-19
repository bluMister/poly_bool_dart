// provides the raw computation functions that takes epsilon into account
//
// zero is defined to be between (-epsilon, epsilon) exclusive
//

import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'types.dart';

const epsilon = Epsilon();

class Epsilon {
  static const eps = 1e-10; // sane default? sure why not

  const Epsilon();

  bool pointAboveOrOnLine(LatLng pt, LatLng left, LatLng right) {
    final Ax = left.latitude;
    final Ay = left.longitude;
    final Bx = right.latitude;
    final By = right.longitude;
    final Cx = pt.latitude;
    final Cy = pt.longitude;
    final ABx = Bx - Ax;
    final ABy = By - Ay;
    final AB = math.sqrt(ABx * ABx + ABy * ABy);
    // algebraic distance of 'pt' to ('left', 'right') line is:
    // [ABx * (Cy - Ay) - ABy * (Cx - Ax)] / AB
    return ABx * (Cy - Ay) - ABy * (Cx - Ax) >= -eps * AB;
  }

  bool pointBetween(LatLng p, LatLng left, LatLng right) {
    // p must be collinear with left->right
    // returns false if p == left, p == right, or left == right
    if (pointsSame(p, left) || pointsSame(p, right)) return false;
    final d_py_ly = p.longitude - left.longitude;
    final d_rx_lx = right.latitude - left.latitude;
    final d_px_lx = p.latitude - left.latitude;
    final d_ry_ly = right.longitude - left.longitude;

    final dot = d_px_lx * d_rx_lx + d_py_ly * d_ry_ly;
    // dot < 0 is p is to the left of 'left'
    if (dot < 0) return false;
    final sqlen = d_rx_lx * d_rx_lx + d_ry_ly * d_ry_ly;
    // dot <= sqlen is p is to the left of 'right'
    return dot <= sqlen;
  }

  bool pointsSameX(LatLng p1, LatLng p2) {
    return (p1.latitude - p2.latitude).abs() < eps;
  }

  bool pointsSameY(LatLng p1, LatLng p2) {
    return (p1.longitude - p2.longitude).abs() < eps;
  }

  bool pointsSame(LatLng p1, LatLng p2) {
    return pointsSameX(p1, p2) && pointsSameY(p1, p2);
  }

  int pointsCompare(LatLng p1, LatLng p2) {
    // returns -1 if p1 is smaller, 1 if p2 is smaller, 0 if equal
    if (pointsSameX(p1, p2))
      return pointsSameY(p1, p2) ? 0 : (p1.longitude < p2.longitude ? -1 : 1);
    return p1.latitude < p2.latitude ? -1 : 1;
  }

  bool pointsCollinear(LatLng pt1, LatLng pt2, LatLng pt3) {
    // does pt1->pt2->pt3 make a straight line?
    // essentially this is just checking to see if the slope(pt1->pt2) === slope(pt2->pt3)
    // if slopes are equal, then they must be collinear, because they share pt2
    final dx1 = pt1.latitude - pt2.latitude;
    final dy1 = pt1.longitude - pt2.longitude;
    final dx2 = pt2.latitude - pt3.latitude;
    final dy2 = pt2.longitude - pt3.longitude;
    final n1 = math.sqrt(dx1 * dx1 + dy1 * dy1);
    final n2 = math.sqrt(dx2 * dx2 + dy2 * dy2);
    // Assuming det(u, v) = 0, we have:
    // |det(u + u_err, v + v_err)| = |det(u + u_err, v + v_err) - det(u,v)|
    // =|det(u, v_err) + det(u_err. v) + det(u_err, v_err)|
    // <= |det(u, v_err)| + |det(u_err, v)| + |det(u_err, v_err)|
    // <= N(u)N(v_err) + N(u_err)N(v) + N(u_err)N(v_err)
    // <= eps * (N(u) + N(v) + eps)
    // We have N(u) ~ N(u + u_err) and N(v) ~ N(v + v_err).
    // Assuming eps << N(u) and eps << N(v), we end with:
    // |det(u + u_err, v + v_err)| <= eps * (N(u + u_err) + N(v + v_err))
    return (dx1 * dy2 - dx2 * dy1).abs() <= eps * (n1 + n2);
  }

  Intersection? linesIntersect(Segment a, Segment b) {
    // returns false if the lines are coincident (e.g., parallel or on top of each other)
    //
    // returns an object if the lines intersect:
    //   {
    //     pt: [x, y],    where the intersection point is at
    //     alongA: where intersection point is along A,
    //     alongB: where intersection point is along B
    //   }
    //
    //  alongA and alongB will each be one of: -2, -1, 0, 1, 2
    //
    //  with the following meaning:
    //
    //    -2   intersection point is before segment's first point
    //    -1   intersection point is directly on segment's first point
    //     0   intersection point is between segment's first and second points (exclusive)
    //     1   intersection point is directly on segment's second point
    //     2   intersection point is after segment's second point
    final a0 = a.start;
    final a1 = a.end;
    final b0 = b.start;
    final b1 = b.end;

    final adx = a1.latitude - a0.latitude;
    final ady = a1.longitude - a0.longitude;
    final bdx = b1.latitude - b0.latitude;
    final bdy = b1.longitude - b0.longitude;

    final axb = adx * bdy - ady * bdx;
    final n1 = math.sqrt(adx * adx + ady * ady);
    final n2 = math.sqrt(bdx * bdx + bdy * bdy);
    if ((axb).abs() <= eps * (n1 + n2)) {
      return null;
    }

    final dx = a0.latitude - b0.latitude;
    final dy = a0.longitude - b0.longitude;

    final A = (bdx * dy - bdy * dx) / axb;
    final B = (adx * dy - ady * dx) / axb;

    final pt = LatLng(a0.latitude + A * adx, a0.longitude + A * ady);
    final intersection = Intersection(alongA: 0, alongB: 0, pt: pt);

    // categorize where intersection point is along A and B

    if (pointsSame(pt, a0)) {
      intersection.alongA = -1;
    } else if (pointsSame(pt, a1)) {
      intersection.alongA = 1;
    } else if (A < 0) {
      intersection.alongA = -2;
    } else if (A > 1) {
      intersection.alongA = 2;
    }

    if (pointsSame(pt, b0)) {
      intersection.alongB = -1;
    } else if (pointsSame(pt, b1)) {
      intersection.alongB = 1;
    } else if (B < 0) {
      intersection.alongB = -2;
    } else if (B > 1) {
      intersection.alongB = 2;
    }

    return intersection;
  }
}
