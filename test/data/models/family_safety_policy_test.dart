import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/content_category.dart';
import 'package:kidslens_video_editor/data/models/family_safety_policy.dart';

void main() {
  group('FamilySafetyPolicyCatalog', () {
    test('defines the complete v1 policy taxonomy', () {
      expect(
        FamilySafetyPolicyCategory.values.map((category) => category.id),
        containsAllInOrder(const [
          'explicit_nudity',
          'sexual_content',
          'suggestive_content',
          'kissing_romance',
          'immodest_female_clothing',
          'violence',
          'gore',
          'blood',
          'weapons',
          'substances',
          'profanity',
        ]),
      );
      expect(FamilySafetyPolicyCategory.values, hasLength(11));
      expect(FamilySafetyPolicyCatalog.definitions, hasLength(11));
    });

    test('defines all severity levels', () {
      expect(
        FamilySafetyPolicyCatalog.severityLevels,
        FamilySafetySeverity.values,
      );
      expect(
        FamilySafetySeverity.values.map((severity) => severity.name),
        containsAllInOrder(const [
          'none',
          'low',
          'medium',
          'high',
          'critical',
        ]),
      );
    });

    test('maps high-risk visual categories to bounded actions', () {
      expect(
        FamilySafetyPolicyCatalog.byCategory(
          FamilySafetyPolicyCategory.explicitNudity,
        ).defaultAction,
        RemediationAction.blurRegion,
      );
      expect(
        FamilySafetyPolicyCatalog.byCategory(
          FamilySafetyPolicyCategory.immodestFemaleClothing,
        ).boundaryRequirement,
        BoundaryRequirement.regionWhenAvailable,
      );
      expect(
        FamilySafetyPolicyCatalog.byCategory(FamilySafetyPolicyCategory.weapons)
            .boundaryRequirement,
        BoundaryRequirement.objectWhenAvailable,
      );
    });

    test('uses review-first mode for ambiguous policy categories', () {
      expect(
        FamilySafetyPolicyCatalog.byCategory(
          FamilySafetyPolicyCategory.sexualContent,
        ).enforcementMode,
        FamilySafetyEnforcementMode.reviewFirst,
      );
      expect(
        FamilySafetyPolicyCatalog.byCategory(
          FamilySafetyPolicyCategory.kissingRomance,
        ).boundaryRequirement,
        BoundaryRequirement.sceneLevelAllowed,
      );
      expect(
        FamilySafetyPolicyCatalog.byCategory(
          FamilySafetyPolicyCategory.violence,
        ).boundaryRequirement,
        BoundaryRequirement.sceneLevelAllowed,
      );
    });

    test('requires all user-facing explanation fields', () {
      expect(
        FamilySafetyPolicyCatalog.requiredExplanationFields,
        containsAll(ExplanationField.values),
      );
    });
  });

  group('LocalInferenceGovernance', () {
    test('is hard-coded to local-only inference', () {
      expect(LocalInferenceGovernance.isLocalOnly, isTrue);
    });

    test('allows only approved local inference transports', () {
      for (final transport in InferenceTransport.values) {
        expect(LocalInferenceGovernance.isApprovedTransport(transport), isTrue);
      }
    });

    test('accepts only localhost and 127.0.0.1 loopback URIs', () {
      expect(
        LocalInferenceGovernance.isApprovedLoopbackUri(
          Uri.parse('http://localhost:8000/v1/chat/completions'),
        ),
        isTrue,
      );
      expect(
        LocalInferenceGovernance.isApprovedLoopbackUri(
          Uri.parse('http://127.0.0.1:8000/v1/chat/completions'),
        ),
        isTrue,
      );
      expect(
        LocalInferenceGovernance.isApprovedLoopbackUri(
          Uri.parse('https://api.example.com/v1/chat/completions'),
        ),
        isFalse,
      );
      expect(
        LocalInferenceGovernance.isApprovedLoopbackUri(
          Uri.parse('http://192.168.1.20:8000/v1/chat/completions'),
        ),
        isFalse,
      );
    });
  });

  group('ModelSourceGovernance', () {
    test('allows only approved major provider organizations', () {
      expect(
        ModelSourceGovernance.isAcceptedOfficialOrganization('nvidia'),
        isTrue,
      );
      expect(
        ModelSourceGovernance.isAcceptedOfficialOrganization('Qwen'),
        isTrue,
      );
      expect(
        ModelSourceGovernance.isAcceptedOfficialOrganization('google'),
        isTrue,
      );
      expect(
        ModelSourceGovernance.isAcceptedOfficialOrganization('community-user'),
        isFalse,
      );
    });

    test('lists all prohibited source kinds', () {
      expect(
        ModelSourceGovernance.prohibitedSourceKinds,
        containsAll(ProhibitedModelSourceKind.values),
      );
    });
  });

  group('InternalConversionPolicy', () {
    test('accepts reproducible RTX 5070-validated conversions', () {
      const policy = InternalConversionPolicy(
        officialWeightsSource: 'google/gemma-4-E4B-it',
        conversionRecipeId: 'gemma4-e4b-int4-v1',
        outputSha256:
            '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        publishedArtifactUri: 'https://huggingface.co/kidslens/gemma4-e4b-int4',
        sourceRevision: 'abc123',
        validatedOnRtx5070: true,
      );

      expect(policy.validate(), isEmpty);
      expect(policy.isValid, isTrue);
    });

    test('rejects incomplete or unvalidated conversions', () {
      const policy = InternalConversionPolicy(
        officialWeightsSource: '',
        conversionRecipeId: '',
        outputSha256: '',
        publishedArtifactUri: '',
        sourceRevision: '',
        validatedOnRtx5070: false,
      );

      expect(policy.validate(), hasLength(6));
      expect(policy.isValid, isFalse);
    });
  });
}
