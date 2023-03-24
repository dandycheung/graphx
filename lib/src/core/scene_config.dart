import '../../graphx.dart';

/// Configuration class used to define the properties and behavior of a GraphX
/// Scene.
class SceneConfig {
  /// **static drawing** configuration, this tells the [SceneController] that
  /// this GraphX Scene will not change (although you might invalidate it
  /// internally with code, but is error prone).
  /// This is the lightest GraphX instance you can build.
  /// Only to make custom drawings.
  static final SceneConfig static = SceneConfig(
    painterWillChange: false,
    autoUpdateRender: false,
  );

  /// **games** configuration, setup this GraphX Widget to render
  /// with full support for auto rendering, updates, mouse and keyboard.
  static final SceneConfig games = SceneConfig(
    useTicker: true,
    useKeyboard: true,
    usePointer: true,
  );

  /// **tools** configuration, is shortcut for [games].
  /// If you plan to make a custom graphics editor, or some complex desktop tool
  /// that requires keystroke shortcuts, and mouse capture.
  static final SceneConfig tools = games;

  /// **interactive** configuration:
  /// Useful for mobile interactions or custom UI components, runs with all
  /// features except [useKeyboard].
  static final SceneConfig interactive = SceneConfig(
    useTicker: true,
    usePointer: true,
  );

  /// **autoRender** configuration:
  /// Basic configuration to auto manage the update and rendering of the Scene.
  /// with no input support. Might be useful for external control of the layers,
  /// animated backgrounds, etc.
  static final SceneConfig autoRender = SceneConfig(
    useTicker: true,
  );

  /// Property defines the default configuration to be used if no other
  /// configuration is specified.
  static SceneConfig defaultConfig = games;

  /// Re-builds the SceneController (the ScenePainter and the scene class).
  /// disposes and initializes all the scene.
  late bool rebuildOnHotReload;

  /// If the GraphX [SceneController] will use keyboard events.
  late bool useKeyboard;

  /// If this GraphX [SceneController] will use pointer (touch/mouse) events.
  late bool usePointer;

  /// Will be overwritten to `true` if [autoUpdateRender] is set on any
  /// [ScenePainter] layer.
  bool useTicker = false;

  /// See [CustomPaint.willChange].
  ///
  /// Rendering caching flag. Set to `true` if using [GTicker] or pretend to
  /// re-render the Scene on demand based on keyboard or pointer signals. See
  /// [CustomPaint.isComplex] All these flags overrides the value to `true`:
  /// [autoUpdateRender], [useTicker], [usePointer], [useKeyboard]
  ///
  late bool painterWillChange;

  /// Avoids the scene from being disposed by the Widget.
  /// Meant to be used with `ScenePainter.useOwnCanvas=true`
  /// where a [ScenePainter] captures it's own drawing to be used as
  /// Picture (or Image eventually) by other [ScenePainter]s.
  /// Warning: Experimental
  ///
  late bool isPersistent;

  /// Default flag to make the engine update() the Stage and all
  /// his children (onEnterFrame), needed by [GTween] to run the tweens.
  /// [GMovieClip] and [GSimpleParticleSystem] also makes use of this.
  /// Same applies to basic "mouse out" feature detection (when mouse doesn't
  /// move but objects changed position).
  ///
  /// It overrides [useTicker] when `true`.
  /// And, unless you don't need external control over the rendering & update
  /// pipelines for the scene, or if you use a static scene,
  /// you should leave it as `true`.
  late bool autoUpdateRender;

  /// Creates a new [SceneConfig] instance.
  SceneConfig({
    this.rebuildOnHotReload = true,
    this.useKeyboard = false,
    this.usePointer = false,
    this.useTicker = false,
    this.isPersistent = false,
    this.autoUpdateRender = true,
    this.painterWillChange = true,
  }) {
    if (autoUpdateRender) {
      useTicker = true;
    }
  }

  /// Utility method used by the [SceneBuilderWidget] to set the flag
  /// `CustomPaint.willChange`
  bool painterMightChange() {
    if (useTicker || autoUpdateRender || usePointer || useKeyboard) {
      return true;
    }
    return painterWillChange;
  }
}
