import 'package:latlong2/latlong.dart';
import 'epsilon.dart';
import 'types.dart';

class SegmentChainer {
  List<List<LatLng>> chains = [];
  List<List<LatLng>> regions = [];

  List<List<LatLng>> chain(SegmentList segments) {
    chains.clear();
    regions.clear();

    for (final seg in segments) {
      final pt1 = seg.start;
      final pt2 = seg.end;

      if (epsilon.pointsSame(pt1, pt2)) {
        print(
            "PolyBool: Warning: Zero-length segment detected; your epsilon is probably too small or too large");
        continue;
      }

      final first_match =
          Match(index: 0, matches_head: false, matches_pt1: false);
      final second_match =
          Match(index: 0, matches_head: false, matches_pt1: false);
      Match next_match = first_match;

      for (int i = 0; i < chains.length; ++i) {
        final chain = chains[i];

        bool setMatch(int index, bool matchesHead, bool matchesPt1) {
          // return true if we've matched twice
          next_match.index = index;
          next_match.matches_head = matchesHead;
          next_match.matches_pt1 = matchesPt1;

          if (next_match == first_match) {
            next_match = second_match;
            return false;
          }

          next_match = Match(index: -1);

          return true; // we've matched twice, we're done here
        }

        if (epsilon.pointsSame(chain.first, pt1)) {
          if (setMatch(i, true, true)) break;
        } else if (epsilon.pointsSame(chain.first, pt2)) {
          if (setMatch(i, true, false)) break;
        } else if (epsilon.pointsSame(chain.last, pt1)) {
          if (setMatch(i, false, true)) break;
        } else if (epsilon.pointsSame(chain.last, pt2)) {
          if (setMatch(i, false, false)) break;
        }
      }

      if (next_match == first_match) {
        // we didn't match anything, so create a chain
        chains.add([pt1, pt2]);

        continue;
      }

      if (next_match == second_match) {
        // we matched a single chain

        // add the other point to the apporpriate end, and check to see if we've closed the
        // chain into a loop

        final index = first_match.index;
        final pt = first_match.matches_pt1
            ? pt2
            : pt1; // if we matched pt1, then we add pt2, etc
        final addToHead = first_match
            .matches_head; // if we matched at head, then add to the head

        final chain = chains[index];
        var grow = addToHead ? chain[0] : chain[chain.length - 1];
        final grow2 = addToHead ? chain[1] : chain[chain.length - 2];
        final oppo = addToHead ? chain[chain.length - 1] : chain[0];
        final oppo2 = addToHead ? chain[chain.length - 2] : chain[1];

        if (epsilon.pointsCollinear(grow2, grow, pt)) {
          // grow isn't needed because it's directly between grow2 and pt:
          // grow2 ---grow---> pt
          if (addToHead) {
            chain.removeAt(0);
          } else {
            chain.removeAt(chain.length - 1);
          }
          grow = grow2; // old grow is gone... grow is what grow2 was
        }

        if (epsilon.pointsSame(oppo, pt)) {
          // we're closing the loop, so remove chain from chains
          chains.removeAt(index);

          if (epsilon.pointsCollinear(oppo2, oppo, grow)) {
            // oppo isn't needed because it's directly between oppo2 and grow:
            // oppo2 ---oppo--->grow
            if (addToHead) {
              chain.removeAt(chain.length - 1);
            } else {
              chain.removeAt(0);
            }
          }

          // we have a closed chain!
          regions.add(chain);
          continue;
        }

        // not closing a loop, so just add it to the apporpriate side
        if (addToHead) {
          chain.insert(0, pt);
        } else {
          chain.add(pt);
        }

        continue;
      }

      // otherwise, we matched two chains, so we need to combine those chains together

      final F = first_match.index;
      final S = second_match.index;

      final reverseF = chains[F].length <
          chains[S].length; // reverse the shorter chain, if needed
      if (first_match.matches_head) {
        if (second_match.matches_head) {
          if (reverseF) {
            // <<<< F <<<< --- >>>> S >>>>
            reverseChain(F);
            // >>>> F >>>> --- >>>> S >>>>
            appendChain(F, S);
          } else {
            // <<<< F <<<< --- >>>> S >>>>
            reverseChain(S);
            // <<<< F <<<< --- <<<< S <<<<   logically same as:
            // >>>> S >>>> --- >>>> F >>>>
            appendChain(S, F);
          }
        } else {
          // <<<< F <<<< --- <<<< S <<<<   logically same as:
          // >>>> S >>>> --- >>>> F >>>>
          appendChain(S, F);
        }
      } else {
        if (second_match.matches_head) {
          // >>>> F >>>> --- >>>> S >>>>
          appendChain(F, S);
        } else {
          if (reverseF) {
            // >>>> F >>>> --- <<<< S <<<<
            reverseChain(F);
            // <<<< F <<<< --- <<<< S <<<<   logically same as:
            // >>>> S >>>> --- >>>> F >>>>
            appendChain(S, F);
          } else {
            // >>>> F >>>> --- <<<< S <<<<
            reverseChain(S);
            // >>>> F >>>> --- >>>> S >>>>
            appendChain(F, S);
          }
        }
      }
    }

    return regions;
  }

  void reverseChain(int index) {
    List<LatLng> pointList = [];
    pointList.addAll(chains[index].reversed.toList());
    chains[index] = pointList; // gee, that's easy
  }

  void appendChain(int index1, int index2) {
    // index1 gets index2 appended to it, and index2 is removed
    final chain1 = chains[index1];
    final chain2 = chains[index2];
    var tail = chain1[chain1.length - 1];
    final tail2 = chain1[chain1.length - 2];
    final head = chain2[0];
    final head2 = chain2[1];

    if (epsilon.pointsCollinear(tail2, tail, head)) {
      // tail isn't needed because it's directly between tail2 and head
      // tail2 ---tail---> head
      chain1.removeAt(chain1.length - 1);
      tail = tail2; // old tail is gone... tail is what tail2 was
    }

    if (epsilon.pointsCollinear(tail, head, head2)) {
      // head isn't needed because it's directly between tail and head2
      // tail ---head---> head2
      chain2.removeAt(0);
    }

    chain1.addAll(chain2);
    chains.removeAt(index2);
  }
}

class Match {
  int index;
  bool matches_head;
  bool matches_pt1;

  Match({this.index = 0, this.matches_head = false, this.matches_pt1 = false});
}
