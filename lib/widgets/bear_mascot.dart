import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

/// Interactive Rive bear for the Login/Register screens.
///
/// Wired to the real State Machine found in assets/animations/bear.riv:
///   State Machine: "State Machine 1"
///   Inputs: Check (bool), Look (number), hands_up (bool),
///            success (trigger), fail (trigger)
class BearMascot extends StatefulWidget {
  /// True while the email field is focused — the bear "checks"/looks at
  /// what's being typed.
  final bool checking;

  /// -1..1-ish look direction while checking (maps to Look_down_left /
  /// look_idle / Look_down_right blend). 0 = centered.
  final double lookX;

  /// True while the password field is focused — triggers hands_up.
  final bool coverEyes;

  final double size;

  const BearMascot({
    super.key,
    this.checking = false,
    this.lookX = 0,
    this.coverEyes = false,
    this.size = 160,
  });

  @override
  State<BearMascot> createState() => BearMascotState();
}

class BearMascotState extends State<BearMascot> {
  late final FileLoader _fileLoader = FileLoader.fromAsset(
    'assets/animations/bear.riv',
    riveFactory: Factory.rive,
  );
  BooleanInput? _checkInput;
  NumberInput? _lookInput;
  BooleanInput? _handsUpInput;
  TriggerInput? _successInput;
  TriggerInput? _failInput;

  static const _stateMachineName = 'State Machine 1';

  void _onRiveLoaded(RiveLoaded state) {
    final machine = state.controller.stateMachine;
    // These inputs belong to the existing bear.riv state machine. Rive now
    // recommends Data Binding for new files, but keeping these named inputs
    // preserves the mascot's current behavior without changing the asset.
    // ignore: deprecated_member_use
    _checkInput = machine.boolean('Check');
    // ignore: deprecated_member_use
    _lookInput = machine.number('Look');
    // ignore: deprecated_member_use
    _handsUpInput = machine.boolean('hands_up');
    // ignore: deprecated_member_use
    _successInput = machine.trigger('success');
    // ignore: deprecated_member_use
    _failInput = machine.trigger('fail');
    _syncInputs();
  }

  void _syncInputs() {
    _checkInput?.value = widget.checking;
    _lookInput?.value = widget.lookX;
    _handsUpInput?.value = widget.coverEyes;
  }

  /// Call after a successful login/register to play the happy reaction.
  void playSuccess() => _successInput?.fire();

  /// Call after a failed login/register attempt.
  void playFail() => _failInput?.fire();

  @override
  void didUpdateWidget(covariant BearMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncInputs();
  }

  @override
  void dispose() {
    _checkInput?.dispose();
    _lookInput?.dispose();
    _handsUpInput?.dispose();
    _successInput?.dispose();
    _failInput?.dispose();
    _fileLoader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RiveWidgetBuilder(
        fileLoader: _fileLoader,
        stateMachineSelector: StateMachineSelector.byName(_stateMachineName),
        onLoaded: _onRiveLoaded,
        onFailed: (error, _) {
          debugPrint('[BearMascot] Failed to load bear.riv: $error');
        },
        builder: (context, state) => switch (state) {
          RiveLoaded() => RiveWidget(
              controller: state.controller,
              fit: Fit.contain,
            ),
          RiveLoading() => const SizedBox.shrink(),
          RiveFailed() => const SizedBox.shrink(),
        },
      ),
    );
  }
}
