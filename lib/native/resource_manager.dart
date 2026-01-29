import 'dart:async';

/// Manages all native FFI resources with deterministic cleanup
class NativeResourceManager {
  NativeResourceManager._();

  static final NativeResourceManager instance = NativeResourceManager._();

  final Map<int, WeakReference<NativeResource>> _resources = {};
  final Finalizer<int> _finalizer = Finalizer(instance._cleanupResource);

  int _nextId = 0;

  /// Register a native resource for tracking
  T register<T extends NativeResource>(T resource) {
    final id = _nextId++;
    _resources[id] = WeakReference(resource);
    _finalizer.attach(resource, id, detach: resource);
    return resource;
  }

  /// Explicitly release a resource
  void release(NativeResource resource) {
    resource.dispose();
    _finalizer.detach(resource);
  }

  void _cleanupResource(int id) {
    final weak = _resources.remove(id);
    if (weak?.target != null) {
      weak!.target!.releaseNative();
    }
  }

  /// Force cleanup of all resources (app shutdown)
  Future<void> disposeAll() async {
    for (final weak in _resources.values) {
      weak.target?.dispose();
    }
    _resources.clear();
  }

  /// Get count of tracked resources
  int get resourceCount => _resources.length;
}

/// Base class for FFI-backed resources
abstract class NativeResource {
  bool _disposed = false;

  bool get isDisposed => _disposed;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    releaseNative();
  }

  /// Override to release native resources
  void releaseNative();
}
