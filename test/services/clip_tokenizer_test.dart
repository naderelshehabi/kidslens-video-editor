import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/services/clip_tokenizer.dart';

void main() {
  group('ClipTokenizer constants', () {
    test('sotToken is 49406', () {
      expect(ClipTokenizer.sotToken, 49406);
    });

    test('eotToken is 49407', () {
      expect(ClipTokenizer.eotToken, 49407);
    });

    test('contextLength is 77', () {
      expect(ClipTokenizer.contextLength, 77);
    });
  });

  group('ClipBuiltInTokens pre-tokenized constants', () {
    final namedConstants = <String, Int32List>{
      'explicitSexualAct': ClipBuiltInTokens.explicitSexualAct,
      'sexualIntercourse': ClipBuiltInTokens.sexualIntercourse,
      'peopleExercising': ClipBuiltInTokens.peopleExercising,
      'wrestlingMatch': ClipBuiltInTokens.wrestlingMatch,
      'twoPeopleKissing': ClipBuiltInTokens.twoPeopleKissing,
      'romanticKissOnTheLips': ClipBuiltInTokens.romanticKissOnTheLips,
      'twoPeopleTalkingFaceToFace':
          ClipBuiltInTokens.twoPeopleTalkingFaceToFace,
      'peopleHugging': ClipBuiltInTokens.peopleHugging,
      'womanInRevealingClothing': ClipBuiltInTokens.womanInRevealingClothing,
      'womanWearingBikini': ClipBuiltInTokens.womanWearingBikini,
      'personInUnderwear': ClipBuiltInTokens.personInUnderwear,
      'personWearingNormalClothing':
          ClipBuiltInTokens.personWearingNormalClothing,
      'personInBusinessAttire': ClipBuiltInTokens.personInBusinessAttire,
    };

    for (final entry in namedConstants.entries) {
      group(entry.key, () {
        test('has length equal to contextLength (77)', () {
          expect(entry.value.length, ClipTokenizer.contextLength);
        });

        test('starts with sotToken (49406)', () {
          expect(entry.value[0], ClipTokenizer.sotToken);
        });

        test('contains eotToken (49407) somewhere', () {
          expect(entry.value.contains(ClipTokenizer.eotToken), isTrue);
        });

        test('all token IDs are non-negative', () {
          for (var i = 0; i < entry.value.length; i++) {
            expect(entry.value[i], greaterThanOrEqualTo(0),
                reason: 'Token at index $i should be non-negative',);
          }
        });

        test('token IDs before eotToken are non-zero (actual tokens)', () {
          final eotIndex = entry.value.indexOf(ClipTokenizer.eotToken);
          expect(eotIndex, greaterThan(0),
              reason: 'eotToken should not be at index 0',);
          for (var i = 0; i < eotIndex; i++) {
            expect(entry.value[i], isNot(0),
                reason: 'Token at index $i (before eotToken) should be '
                    'non-zero',);
          }
        });
      });
    }
  });

  group('ClipBuiltInTokens.getPreTokenized', () {
    final knownPrompts = <String, Int32List>{
      'explicit sexual act': ClipBuiltInTokens.explicitSexualAct,
      'sexual intercourse': ClipBuiltInTokens.sexualIntercourse,
      'people exercising': ClipBuiltInTokens.peopleExercising,
      'wrestling match': ClipBuiltInTokens.wrestlingMatch,
      'two people kissing': ClipBuiltInTokens.twoPeopleKissing,
      'romantic kiss on the lips': ClipBuiltInTokens.romanticKissOnTheLips,
      'two people talking face to face':
          ClipBuiltInTokens.twoPeopleTalkingFaceToFace,
      'people hugging': ClipBuiltInTokens.peopleHugging,
      'woman in revealing clothing':
          ClipBuiltInTokens.womanInRevealingClothing,
      'woman wearing bikini': ClipBuiltInTokens.womanWearingBikini,
      'person in underwear': ClipBuiltInTokens.personInUnderwear,
      'person wearing normal clothing':
          ClipBuiltInTokens.personWearingNormalClothing,
      'person in business attire': ClipBuiltInTokens.personInBusinessAttire,
    };

    for (final entry in knownPrompts.entries) {
      test('returns non-null for known prompt "${entry.key}"', () {
        final result = ClipBuiltInTokens.getPreTokenized(entry.key);
        expect(result, isNotNull);
      });

      test(
          'returned value for "${entry.key}" matches the static constant', () {
        final result = ClipBuiltInTokens.getPreTokenized(entry.key);
        expect(result, same(entry.value));
      });
    }

    test('returns null for unknown prompt', () {
      final result =
          ClipBuiltInTokens.getPreTokenized('random unknown prompt');
      expect(result, isNull);
    });
  });
}
