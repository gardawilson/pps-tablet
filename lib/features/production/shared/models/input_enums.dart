enum ModeInput { full, select, partial }


extension ModeInputX on ModeInput {
  String get label => switch (this) {
    ModeInput.full => 'FULL PALLET',
    ModeInput.select => 'SEBAGIAN PALLET',
    ModeInput.partial => 'PARTIAL',
  };
}