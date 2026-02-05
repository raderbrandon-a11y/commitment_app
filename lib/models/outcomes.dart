enum Outcome {
  completed,
  partial,
  incomplete,
}

/// Keeps backward compatibility with your existing Session parsing code.
Outcome? outcomeFromString(String? raw) {
  if (raw == null) return null;

  switch (raw) {
    case 'completed':
      return Outcome.completed;
    case 'partial':
      return Outcome.partial;
    case 'incomplete':
      return Outcome.incomplete;

    // Safety: allow display strings (just in case)
    case 'Completed':
      return Outcome.completed;
    case 'Partially Completed':
      return Outcome.partial;
    case 'Barely Started':
      return Outcome.incomplete;
  }

  return null;
}

/// (Optional) If you ever serialize back to storage.
String? outcomeToString(Outcome? o) => o?.name;

/// Centralized display language (your requested wording).
extension OutcomeDisplay on Outcome {
  String get label {
    switch (this) {
      case Outcome.completed:
        return 'Completed';
      case Outcome.partial:
        return 'Partially Completed';
      case Outcome.incomplete:
        return 'Barely Started';
    }
  }

  String get percentRange {
    switch (this) {
      case Outcome.completed:
        return '100%';
      case Outcome.partial:
        return '25–99%';
      case Outcome.incomplete:
        return '0–24%';
    }
  }
}
