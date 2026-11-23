import '../pipeline/rule_extractor.dart';

/// What the user types in the amount box: "499", "499.5", "1,250.00". Null when not a number.
int? rupeesToPaise(String text) => parsePaise(text.trim());
