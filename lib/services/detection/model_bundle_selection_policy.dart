import 'package:kidslens_video_editor/data/models/models.dart';

class ModelBundleSelectionPolicy {
  const ModelBundleSelectionPolicy({
    this.productionMode = true,
    this.catalog = ModelBundleCatalog.initialCandidates,
  });

  final bool productionMode;
  final List<ModelBundleManifest> catalog;

  List<ModelBundleManifest> candidatesForRole(ModelBundleRole role) => catalog
      .where((manifest) => manifest.roles.contains(role))
      .toList(growable: false);

  List<ModelBundleManifest> selectableForRole({
    required ModelBundleRole role,
    required String localRuntimeId,
    required Set<String> acceptedTerms,
  }) =>
      candidatesForRole(role)
          .where(
            (manifest) => canSelect(
              manifest: manifest,
              role: role,
              localRuntimeId: localRuntimeId,
              acceptedTerms: acceptedTerms,
            ),
          )
          .toList(growable: false);

  bool canSelect({
    required ModelBundleManifest manifest,
    required ModelBundleRole role,
    required String localRuntimeId,
    required Set<String> acceptedTerms,
  }) =>
      blockers(
        manifest: manifest,
        role: role,
        localRuntimeId: localRuntimeId,
        acceptedTerms: acceptedTerms,
      ).isEmpty;

  List<String> blockers({
    required ModelBundleManifest manifest,
    required ModelBundleRole role,
    required String localRuntimeId,
    required Set<String> acceptedTerms,
  }) {
    final issues = <String>[];
    if (!manifest.roles.contains(role)) {
      issues.add('Bundle does not support the ${role.name} role.');
    }
    if (productionMode) {
      final productionIssues = manifest.validateForProductionSelection();
      if (productionIssues.isNotEmpty) {
        issues.add('Not production approved.');
      }
    }
    if (!ModelSourceGovernance.isAcceptedOfficialOrganization(
      manifest.officialOrganization,
    )) {
      issues.add('Source organization is not approved.');
    }
    if (manifest.commercialUse == CommercialUseStatus.blocked ||
        manifest.license == ModelBundleLicense.nonCommercial) {
      issues.add('Commercial use is blocked.');
    }
    if (manifest.acceptedTermsRequired &&
        !acceptedTerms.contains(manifest.modelId)) {
      issues.add('Terms must be accepted before selection.');
    }

    final runtimeProfile = LocalRuntimeProfile.byModelRuntime(
      manifest.runtime,
    );
    if (runtimeProfile == null) {
      issues.add('Runtime is not validated.');
    } else if (runtimeProfile.id.jsonValue != localRuntimeId) {
      issues.add('Requires ${runtimeProfile.displayName}.');
    }

    return issues.toSet().toList(growable: false);
  }

  String checksumLabel(ModelBundleManifest manifest) =>
      manifest.sha256 == null ? 'Checksum pending' : 'Checksum verified';

  String termsLabel(
    ModelBundleManifest manifest,
    Set<String> acceptedTerms,
  ) {
    if (!manifest.acceptedTermsRequired) {
      return 'No terms gate';
    }
    return acceptedTerms.contains(manifest.modelId)
        ? 'Terms accepted'
        : 'Terms required';
  }

  String approvalLabel(ModelBundleManifest manifest) {
    switch (manifest.approvalStatus) {
      case ModelBundleApprovalStatus.productionApproved:
        return 'Production approved';
      case ModelBundleApprovalStatus.evaluationOnly:
        return 'Evaluation only';
      case ModelBundleApprovalStatus.watchlist:
        return 'Watchlist';
      case ModelBundleApprovalStatus.blocked:
        return 'Blocked';
    }
  }

  String commercialUseLabel(ModelBundleManifest manifest) {
    switch (manifest.commercialUse) {
      case CommercialUseStatus.allowed:
        return 'Commercial allowed';
      case CommercialUseStatus.allowedWithTerms:
        return 'Commercial allowed with terms';
      case CommercialUseStatus.reviewRequired:
        return 'Commercial review required';
      case CommercialUseStatus.blocked:
        return 'Commercial blocked';
    }
  }
}
