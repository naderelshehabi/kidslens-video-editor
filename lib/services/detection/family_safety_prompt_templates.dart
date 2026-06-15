import 'package:kidslens_video_editor/data/models/models.dart';

enum FamilySafetyPromptKind {
  caption,
  policy,
  grounding,
}

class FamilySafetyPromptContext {
  const FamilySafetyPromptContext({
    required this.mediaId,
    required this.chunk,
    required this.frames,
    required this.modelBundle,
    this.enabledCategoryIds = const <String>[],
    this.includeGroundingInstructions = true,
  });

  final String mediaId;
  final VideoChunk chunk;
  final List<SampledFrameRef> frames;
  final ModelBundleManifest modelBundle;
  final List<String> enabledCategoryIds;
  final bool includeGroundingInstructions;

  List<String> get categoryIds => enabledCategoryIds.isEmpty
      ? FamilySafetyPolicyCategory.values
          .map((category) => category.id)
          .toList(growable: false)
      : enabledCategoryIds;
}

class FamilySafetyPromptTemplate {
  const FamilySafetyPromptTemplate({
    required this.id,
    required this.version,
    required this.kind,
    required this.text,
  });

  final String id;
  final int version;
  final FamilySafetyPromptKind kind;
  final String text;
}

class FamilySafetyPromptExample {
  const FamilySafetyPromptExample({
    required this.id,
    required this.title,
    required this.visibleContext,
    required this.expectedHandling,
  });

  final String id;
  final String title;
  final String visibleContext;
  final String expectedHandling;

  String render() =>
      '- $title: visible context: $visibleContext; expected handling: $expectedHandling';
}

class FamilySafetyPromptTemplates {
  FamilySafetyPromptTemplates._();

  static const schemaVersion = 1;

  static const localizableCategoryIds = <String>{
    'explicit_nudity',
    'immodest_female_clothing',
    'gore',
    'blood',
    'weapons',
  };

  static const examples = <FamilySafetyPromptExample>[
    FamilySafetyPromptExample(
      id: 'safe_beach_swimwear',
      title: 'safe beach/swimwear',
      visibleContext:
          'people at a public beach wearing ordinary swimwear with no sexualized posing',
      expectedHandling:
          'mark safe or low concern; do not label normal swimwear as nudity',
    ),
    FamilySafetyPromptExample(
      id: 'bikini_revealing_clothing',
      title: 'bikini or revealing clothing',
      visibleContext:
          'adult-presenting person in a bikini or revealing outfit, no explicit nudity',
      expectedHandling:
          'use suggestive_content or immodest_female_clothing only when the configured category applies; include exposureSignals and provide rationale',
    ),
    FamilySafetyPromptExample(
      id: 'exposed_female_legs',
      title: 'exposed female legs',
      visibleContext: 'female-presenting person with visibly bare legs',
      expectedHandling:
          'use immodest_female_clothing when configured, include exposureSignals such as bare_legs, and include region IDs if localized',
    ),
    FamilySafetyPromptExample(
      id: 'explicit_nudity',
      title: 'explicit nudity',
      visibleContext: 'visible exposed genitals, buttocks, or breasts',
      expectedHandling:
          'use explicit_nudity with high severity and region IDs whenever a boundary is available',
    ),
    FamilySafetyPromptExample(
      id: 'romantic_kissing',
      title: 'romantic kissing',
      visibleContext: 'romantic kissing without nudity or sexual activity',
      expectedHandling:
          'use kissing_romance; brief/peck kissing is low severity, prolonged or passionate kissing is medium, and sexualized touching escalates to sexual_content',
    ),
    FamilySafetyPromptExample(
      id: 'sexualized_behavior',
      title: 'sexualized behavior',
      visibleContext:
          'sexualized touching, explicit gestures, or simulated sexual activity',
      expectedHandling:
          'use sexual_content and describe the visible behavior factually',
    ),
    FamilySafetyPromptExample(
      id: 'sports_contact_vs_violence',
      title: 'sports contact vs violence',
      visibleContext:
          'people colliding during a sport with uniforms and game context',
      expectedHandling:
          'do not mark ordinary sports contact as violence unless aggressive injury or fighting is visible',
    ),
    FamilySafetyPromptExample(
      id: 'medical_blood_vs_gore',
      title: 'medical blood vs gore',
      visibleContext: 'blood in a clinical or first-aid setting',
      expectedHandling:
          'use blood if visible, reserve gore for graphic tissue or severe injury',
    ),
    FamilySafetyPromptExample(
      id: 'halloween_makeup_vs_gore',
      title: 'Halloween makeup vs gore',
      visibleContext: 'costume makeup resembling wounds in a festive setting',
      expectedHandling:
          'record uncertainty and avoid gore unless realistic injury is visible',
    ),
    FamilySafetyPromptExample(
      id: 'weapons_toy_ambiguity',
      title: 'weapons/toy weapons ambiguity',
      visibleContext: 'object resembles a weapon but may be a toy or prop',
      expectedHandling:
          'use weapons only when plausible; state weaponState as in_hand, aimed, worn/holstered, displayed, or toy/prop in the rationale; toy/prop is none or low severity',
    ),
  ];

  static const immodestyExposureSignals = <String>[
    'cleavage',
    'bare_midriff',
    'bare_legs',
    'bare_arms',
    'swimwear',
    'lingerie',
    'miniskirt_minishort',
    'sheer_clothing',
  ];

  static const weaponStates = <String>[
    'in_hand',
    'aimed',
    'worn/holstered',
    'displayed',
    'toy/prop',
  ];

  static FamilySafetyPromptTemplate caption(
    FamilySafetyPromptContext context,
  ) =>
      FamilySafetyPromptTemplate(
        id: 'family_safety_caption_v$schemaVersion',
        version: schemaVersion,
        kind: FamilySafetyPromptKind.caption,
        text: '''
You are analyzing a private family video locally on this device.
Produce a dense, factual caption for the provided video chunk.
Do not make final policy judgments in this pass.
Describe visible people, clothing, actions, injuries, blood, weapons, scene context, and uncertainty.
Do not infer age. Do not moralize. Use "unclear" when visibility is limited.

Chunk:
${_chunkBlock(context)}

Return JSON only with this shape:
{
  "schemaVersion": $schemaVersion,
  "caption": "dense factual caption",
  "visibleEntities": ["short factual observations"],
  "uncertainty": ["visibility, ambiguity, or missing-context notes"]
}
''',
      );

  static FamilySafetyPromptTemplate policy(FamilySafetyPromptContext context) =>
      FamilySafetyPromptTemplate(
        id: 'family_safety_policy_v$schemaVersion',
        version: schemaVersion,
        kind: FamilySafetyPromptKind.policy,
        text: '''
You are converting local video observations into structured family-safety JSON.
Return JSON only. Do not include Markdown, prose outside JSON, comments, or trailing commas.
Keep all findings factual and category-specific.
Every unsafe finding must include category, severity, confidence, startTimeMs, endTimeMs, rationale, groundingStatus, needsReview, and regionIds.
Every response must include an uncertainty list, even when empty.
If a finding is localizable and a region boundary is available, groundingStatus must be "grounded" and regionIds must reference groundedRegions.
If a finding is localizable but no reliable boundary is available, use "scene_level_only", "unsupported_by_model", "failed", or "ambiguous" and explain in uncertainty.

Allowed categories: ${context.categoryIds.join(', ')}
Localizable categories: ${localizableCategoryIds.join(', ')}
Allowed severity values: none, low, medium, high, critical
Allowed groundingStatus values: grounded, scene_level_only, unsupported_by_model, failed, ambiguous
For kissing_romance: use low severity for brief/peck kissing, medium for prolonged or passionate kissing, and use sexual_content instead when sexualized touching or simulated sexual activity is visible.
For immodest_female_clothing: include exposureSignals from: ${immodestyExposureSignals.join(', ')}. Use low for one mild signal such as bare_arms or bare_legs; use medium or higher for multiple signals, swimwear, lingerie, sheer clothing, or miniskirt/minishort.
For weapons: the rationale must state weaponState as one of: ${weaponStates.join(', ')}. Toy/prop ambiguity should be severity none or low unless other context makes it unsafe.
For substances: distinguish alcohol_consumption, smoking_vaping, illegal_drugs, or drug_paraphernalia in the rationale text.

Examples:
$_examplesBlock

Chunk:
${_chunkBlock(context)}

Return JSON only with this shape:
${FamilySafetyVlmOutputSchema.schemaDescription}
''',
      );

  static FamilySafetyPromptTemplate grounding(
    FamilySafetyPromptContext context,
  ) =>
      FamilySafetyPromptTemplate(
        id: 'family_safety_grounding_v$schemaVersion',
        version: schemaVersion,
        kind: FamilySafetyPromptKind.grounding,
        text: '''
You are localizing policy-relevant visible items in a private family video.
Return JSON only. Do not include Markdown.
Ground only visible, policy-relevant items such as exposed body regions, blood, gore, weapons, and clearly relevant clothing regions.
Use normalized frame-relative boxes in [0, 1] with box fields x, y, width, height.
Do not return Qwen-style absolute pixel coordinates. If your native grounding output is pixel coordinates, convert x and width by the supplied frame width and y and height by the supplied frame height before writing JSON.
Clamp boxes to the visible object; avoid full-frame boxes unless the object fills the frame.
Every grounded region needs regionId, label, category, frameId, box, confidence, and rationale.

Grounding support advertised by model:
- boxes: ${context.modelBundle.supportsBoundingBoxes}
- masks: ${context.modelBundle.supportsMasks}
- points: ${context.modelBundle.supportsPointLocalization}

Chunk:
${_chunkBlock(context)}

Return JSON only with this shape:
{
  "schemaVersion": $schemaVersion,
  "groundedRegions": [
    {
      "regionId": "region_1",
      "label": "exposed female legs",
      "category": "immodest_female_clothing",
      "frameId": "frame id from request",
      "box": {"x": 0.0, "y": 0.0, "width": 0.1, "height": 0.1},
      "maskRef": null,
      "confidence": 0.0,
      "rationale": "short factual visible evidence"
    }
  ],
  "uncertainty": ["why any requested boundary could not be localized"]
}
''',
      );

  static String get _examplesBlock =>
      examples.map((example) => example.render()).join('\n');

  static String _chunkBlock(FamilySafetyPromptContext context) {
    final frames = context.frames
        .map(
          (frame) =>
              '- ${frame.id}: timestampMs=${frame.timestamp.inMilliseconds}, frameIndex=${frame.frameIndex}',
        )
        .join('\n');
    return '''
- mediaId: ${context.mediaId}
- chunkId: ${context.chunk.id}
- chunkIndex: ${context.chunk.index}
- startTimeMs: ${context.chunk.startTime.inMilliseconds}
- endTimeMs: ${context.chunk.endTime.inMilliseconds}
- modelBundleId: ${context.modelBundle.modelId}
- frames:
$frames''';
  }
}

class FamilySafetyVlmOutputSchema {
  FamilySafetyVlmOutputSchema._();

  static const schemaDescription = '''
{
  "schemaVersion": 1,
  "caption": "short factual summary",
  "groundedRegions": [
    {
      "regionId": "region_1",
      "label": "visible item or body/clothing region",
      "category": "policy category id",
      "frameId": "frame id from request",
      "box": {"x": 0.0, "y": 0.0, "width": 0.1, "height": 0.1},
      "maskRef": null,
      "confidence": 0.0,
      "rationale": "short factual visible evidence"
    }
  ],
  "findings": [
    {
      "category": "explicit_nudity|sexual_content|suggestive_content|kissing_romance|immodest_female_clothing|violence|gore|blood|weapons|substances|profanity|other",
      "severity": "none|low|medium|high|critical",
      "confidence": 0.0,
      "startTimeMs": 0,
      "endTimeMs": 0,
      "rationale": "short factual visible evidence",
      "exposureSignals": ["bare_legs"],
      "weaponState": "in_hand|aimed|worn/holstered|displayed|toy/prop",
      "regionIds": ["region_1"],
      "groundingStatus": "grounded|scene_level_only|unsupported_by_model|failed|ambiguous",
      "needsReview": true
    }
  ],
  "searchTerms": ["short searchable terms"],
  "uncertainty": ["ambiguity or low-visibility notes"]
}
''';

  static final jsonSchema = <String, dynamic>{
    'type': 'object',
    'additionalProperties': false,
    'required': [
      'schemaVersion',
      'caption',
      'groundedRegions',
      'findings',
      'searchTerms',
      'uncertainty',
    ],
    'properties': {
      'schemaVersion': {'const': FamilySafetyPromptTemplates.schemaVersion},
      'caption': {'type': 'string', 'minLength': 1},
      'groundedRegions': {
        'type': 'array',
        'items': {
          'type': 'object',
          'additionalProperties': false,
          'required': [
            'regionId',
            'label',
            'category',
            'frameId',
            'box',
            'confidence',
            'rationale',
          ],
          'properties': {
            'regionId': {'type': 'string', 'minLength': 1},
            'label': {'type': 'string', 'minLength': 1},
            'category': {
              'type': 'string',
              'enum': allowedCategoryIds.toList(growable: false),
            },
            'frameId': {'type': 'string', 'minLength': 1},
            'box': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['x', 'y', 'width', 'height'],
              'properties': {
                'x': {'type': 'number', 'minimum': 0, 'maximum': 1},
                'y': {'type': 'number', 'minimum': 0, 'maximum': 1},
                'width': {
                  'type': 'number',
                  'exclusiveMinimum': 0,
                  'maximum': 1,
                },
                'height': {
                  'type': 'number',
                  'exclusiveMinimum': 0,
                  'maximum': 1,
                },
              },
            },
            'maskRef': {
              'anyOf': [
                {'type': 'string'},
                {'type': 'null'},
              ],
            },
            'confidence': {'type': 'number', 'minimum': 0, 'maximum': 1},
            'rationale': {'type': 'string', 'minLength': 1},
          },
        },
      },
      'findings': {
        'type': 'array',
        'items': {
          'type': 'object',
          'additionalProperties': false,
          'required': [
            'category',
            'severity',
            'confidence',
            'startTimeMs',
            'endTimeMs',
            'rationale',
            'regionIds',
            'groundingStatus',
            'needsReview',
          ],
          'properties': {
            'category': {
              'type': 'string',
              'enum': allowedCategoryIds.toList(growable: false),
            },
            'severity': {
              'type': 'string',
              'enum': allowedSeverityIds.toList(growable: false),
            },
            'confidence': {'type': 'number', 'minimum': 0, 'maximum': 1},
            'startTimeMs': {'type': 'number', 'minimum': 0},
            'endTimeMs': {'type': 'number', 'minimum': 0},
            'rationale': {'type': 'string', 'minLength': 1},
            'regionIds': {
              'type': 'array',
              'items': {'type': 'string'},
            },
            'groundingStatus': {
              'type': 'string',
              'enum': allowedGroundingStatusIds.toList(growable: false),
            },
            'exposureSignals': {
              'type': 'array',
              'items': {
                'type': 'string',
                'enum': allowedExposureSignalIds.toList(growable: false),
              },
            },
            'weaponState': {
              'type': 'string',
              'enum': allowedWeaponStateIds.toList(growable: false),
            },
            'needsReview': {'type': 'boolean'},
          },
        },
      },
      'searchTerms': {
        'type': 'array',
        'items': {'type': 'string'},
      },
      'uncertainty': {
        'type': 'array',
        'items': {'type': 'string'},
      },
    },
  };

  static const allowedSeverityIds = <String>{
    'none',
    'low',
    'medium',
    'high',
    'critical',
  };

  static final allowedCategoryIds = <String>{
    ...FamilySafetyPolicyCategory.values.map((category) => category.id),
    'other',
  };

  static final allowedExposureSignalIds =
      FamilySafetyPromptTemplates.immodestyExposureSignals.toSet();

  static final allowedWeaponStateIds =
      FamilySafetyPromptTemplates.weaponStates.toSet();

  static final allowedGroundingStatusIds = <String>{
    for (final status in GroundingStatus.values) status.jsonValue,
  };

  static List<String> validate(
    Map<String, dynamic> json, {
    bool requireSchemaVersion = true,
    bool requireUncertainty = true,
    bool requireRegionIdsForGroundedFindings = true,
  }) {
    final issues = <String>[];
    if (requireSchemaVersion &&
        json['schemaVersion'] != FamilySafetyPromptTemplates.schemaVersion) {
      issues.add(
        'schemaVersion must be ${FamilySafetyPromptTemplates.schemaVersion}',
      );
    }
    final caption = json['caption'];
    if (caption is! String || caption.trim().isEmpty) {
      issues.add('caption is required');
    }

    final uncertainty = json['uncertainty'];
    if (requireUncertainty && uncertainty is! List) {
      issues.add('uncertainty list is required');
    } else if (uncertainty is List) {
      for (final item in uncertainty) {
        if (item is! String || item.trim().isEmpty) {
          issues.add('uncertainty entries must be non-empty strings');
        }
      }
    }

    final groundedRegionIds = <String>{};
    final groundedRegions = json['groundedRegions'];
    if (groundedRegions != null) {
      if (groundedRegions is! List) {
        issues.add('groundedRegions must be a list');
      } else {
        for (var i = 0; i < groundedRegions.length; i++) {
          final region = groundedRegions[i];
          if (region is! Map) {
            issues.add('groundedRegions[$i] must be an object');
            continue;
          }
          final regionMap = Map<String, dynamic>.from(region);
          final regionId = _requiredString(regionMap, 'regionId');
          if (regionId == null) {
            issues.add('groundedRegions[$i].regionId is required');
          } else {
            groundedRegionIds.add(regionId);
          }
          _validateGroundedRegion(regionMap, i, issues);
        }
      }
    }

    final findings = json['findings'];
    if (findings is! List) {
      issues.add('findings list is required');
    } else {
      for (var i = 0; i < findings.length; i++) {
        final finding = findings[i];
        if (finding is! Map) {
          issues.add('findings[$i] must be an object');
          continue;
        }
        _validateFinding(
          Map<String, dynamic>.from(finding),
          i,
          groundedRegionIds,
          requireRegionIdsForGroundedFindings,
          issues,
        );
      }
    }

    final searchTerms = json['searchTerms'];
    if (searchTerms != null && searchTerms is! List) {
      issues.add('searchTerms must be a list when provided');
    }
    return issues.toSet().toList(growable: false);
  }

  static void _validateGroundedRegion(
    Map<String, dynamic> region,
    int index,
    List<String> issues,
  ) {
    for (final field in <String>[
      'label',
      'category',
      'frameId',
      'rationale',
    ]) {
      if (_requiredString(region, field) == null) {
        issues.add('groundedRegions[$index].$field is required');
      }
    }
    final confidence = region['confidence'];
    if (confidence is! num || confidence < 0 || confidence > 1) {
      issues.add('groundedRegions[$index].confidence must be 0..1');
    }
    final box = region['box'];
    if (box is! Map) {
      issues.add('groundedRegions[$index].box is required');
      return;
    }
    _validateGroundedRegionBox(Map<String, dynamic>.from(box), index, issues);
  }

  static void _validateGroundedRegionBox(
    Map<String, dynamic> box,
    int index,
    List<String> issues,
  ) {
    final x = box['x'];
    final y = box['y'];
    final width = box['width'];
    final height = box['height'];
    if (x is! num || y is! num || width is! num || height is! num) {
      issues.add(
        'groundedRegions[$index].box must contain numeric x, y, width, height',
      );
      return;
    }
    if (!_isFiniteNonNegative(x) ||
        !_isFiniteNonNegative(y) ||
        !_isFinitePositive(width) ||
        !_isFinitePositive(height)) {
      issues.add(
        'groundedRegions[$index].box must contain finite non-negative coordinates and positive size',
      );
    }
  }

  static void _validateFinding(
    Map<String, dynamic> finding,
    int index,
    Set<String> groundedRegionIds,
    bool requireRegionIdsForGroundedFindings,
    List<String> issues,
  ) {
    final category = _requiredString(finding, 'category');
    if (category == null) {
      issues.add('findings[$index].category is required');
    } else if (!allowedCategoryIds.contains(category)) {
      issues.add('findings[$index].category is not allowed: $category');
    }

    final severity = _requiredString(finding, 'severity');
    if (severity == null) {
      issues.add('findings[$index].severity is required');
    } else if (!allowedSeverityIds.contains(severity)) {
      issues.add('findings[$index].severity is not allowed: $severity');
    }

    final confidence = finding['confidence'];
    if (confidence is! num || confidence < 0 || confidence > 1) {
      issues.add('findings[$index].confidence must be 0..1');
    }
    if (_requiredString(finding, 'rationale') == null) {
      issues.add('findings[$index].rationale is required');
    }

    final startTimeMs = finding['startTimeMs'];
    final endTimeMs = finding['endTimeMs'];
    if (startTimeMs is! num || endTimeMs is! num || endTimeMs < startTimeMs) {
      issues.add('findings[$index].timestamp range is invalid');
    }

    final groundingStatus = _requiredString(finding, 'groundingStatus');
    if (groundingStatus == null) {
      issues.add('findings[$index].groundingStatus is required');
    } else if (!allowedGroundingStatusIds.contains(groundingStatus)) {
      issues.add(
        'findings[$index].groundingStatus is not allowed: $groundingStatus',
      );
    }

    final regionIds = finding['regionIds'];
    if (regionIds is! List) {
      issues.add('findings[$index].regionIds list is required');
    } else {
      for (final regionId in regionIds) {
        if (regionId is! String || regionId.trim().isEmpty) {
          issues.add('findings[$index].regionIds entries must be strings');
          continue;
        }
        if (groundedRegionIds.isNotEmpty &&
            !groundedRegionIds.contains(regionId)) {
          issues
              .add('findings[$index].regionIds contains unknown id: $regionId');
        }
      }
      if (requireRegionIdsForGroundedFindings &&
          groundingStatus == GroundingStatus.grounded.jsonValue &&
          regionIds.isEmpty) {
        issues.add('findings[$index].grounded findings require regionIds');
      }
    }

    if (finding['needsReview'] is! bool) {
      issues.add('findings[$index].needsReview boolean is required');
    }

    final exposureSignals = finding['exposureSignals'];
    if (exposureSignals != null) {
      if (exposureSignals is! List) {
        issues.add('findings[$index].exposureSignals must be a list');
      } else {
        for (final signal in exposureSignals) {
          if (signal is! String || !allowedExposureSignalIds.contains(signal)) {
            issues.add(
              'findings[$index].exposureSignals contains unsupported signal: $signal',
            );
          }
        }
      }
    }

    final weaponState = finding['weaponState'];
    if (weaponState != null &&
        (weaponState is! String ||
            !allowedWeaponStateIds.contains(weaponState))) {
      issues.add('findings[$index].weaponState is not allowed: $weaponState');
    }
  }

  static String? _requiredString(Map<String, dynamic> json, String field) {
    final value = json[field];
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  static bool _isFiniteNonNegative(num value) => value.isFinite && value >= 0;

  static bool _isFinitePositive(num value) => value.isFinite && value > 0;
}
