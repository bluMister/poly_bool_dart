import 'dart:collection';

import 'package:latlong2/latlong.dart';
import 'epsilon.dart';
import 'types.dart';

class EventNode extends LinkedListEntry<EventNode> {
  final bool isStart;
  LatLng pt;
  final Segment seg;
  final bool primary;
  late final EventNode other;

  StatusNode? status;

  EventNode({
    required this.isStart,
    required this.pt,
    required this.seg,
    required this.primary,
  });

  int compareTo(EventNode p2) {
    final p1_isStart = isStart;
    final p1_1 = pt;
    final p1_2 = other.pt;
    final p2_isStart = p2.isStart;
    final p2_1 = p2.pt;
    final p2_2 = p2.other.pt;

    // compare the selected points first
    final comp = epsilon.pointsCompare(p1_1, p2_1);
    if (comp != 0) return comp;

    // the selected points are the same

    if (epsilon.pointsSame(
        p1_2, p2_2)) // if the non-selected points are the same too...
      return 0; // then the segments are equal

    if (p1_isStart != p2_isStart) // if one is a start and the other isn't...
      return p1_isStart ? 1 : -1; // favor the one that isn't the start

    // otherwise, we'll have to calculate which one is below the other manually
    return epsilon.pointAboveOrOnLine(
            p1_2,
            p2_isStart ? p2_1 : p2_2, // order matters
            p2_isStart ? p2_2 : p2_1)
        ? 1
        : -1;
  }
}

class StatusNode extends LinkedListEntry<StatusNode> {
  final EventNode ev;

  StatusNode({required this.ev});

  int compareTo(StatusNode other) {
    final a1 = ev.seg.start;
    final a2 = ev.seg.end;
    final b1 = other.ev.seg.start;
    final b2 = other.ev.seg.end;

    if (epsilon.pointsCollinear(a1, b1, b2)) {
      if (epsilon.pointsCollinear(a2, b1, b2))
        return 1; //eventCompare(true, a1, a2, true, b1, b2);

      return epsilon.pointAboveOrOnLine(a2, b1, b2) ? 1 : -1;
    }

    return epsilon.pointAboveOrOnLine(a1, b1, b2) ? 1 : -1;
  }
}

class StatusLinkedList extends LinkedList<StatusNode> {
  StatusNode? get head => isEmpty ? null : first;

  Transition findTransition(EventNode ev) {
    final newNode = StatusNode(ev: ev);
    StatusNode insertBack() {
      add(newNode);
      return newNode;
    }

    if (isEmpty) {
      return Transition(insert: insertBack);
    }

    StatusNode? here = null;
    try {
      here = firstWhere((s) => newNode.compareTo(s) > 0);
    } catch (_) {}

    StatusNode? prev = (here == null) ? last : here.previous;

    return Transition(
      above: prev?.ev,
      below: here?.ev,
      insert: here != null
          ? () {
              here!.insertBefore(newNode);
              return newNode;
            }
          : insertBack,
    );
  }
}

class EventLinkedList extends LinkedList<EventNode> {
  EventNode? get head => isEmpty ? null : first;

  void insertBefore(EventNode node) {
    try {
      final ev = firstWhere((e) {
        return node.compareTo(e) < 0;
      });
      ev.insertBefore(node);
    } catch (_) {
      add(node);
    }
  }
}
