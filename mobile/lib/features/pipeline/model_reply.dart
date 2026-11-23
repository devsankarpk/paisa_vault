import 'dart:convert';

/// What the model is asked for: only the fields rules cannot read reliably.
class ModelReply {
  const ModelReply({this.merchant, this.category, this.channel});
  final String? merchant;
  final String? category;
  final String? channel;
}

/// Channels the model may return.
const allowedChannels = {'UPI', 'NEFT', 'IMPS', 'ATM', 'POS', 'online'};

/// Parses and strictly checks the model's reply. Returns null when it is not valid, so the
/// caller can retry once and then fall back to "please confirm".
///
/// Valid means: one JSON object, only the three known keys with string or null values, a
/// category that is exactly one of [categories] (or null), a channel from [allowedChannels]
/// (or null), and a merchant of sensible length.
ModelReply? parseModelReply(String reply, {required List<String> categories}) {
  // Some models add a think block before the answer.
  final clean = reply.replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '');
  final start = clean.indexOf('{');
  final end = clean.lastIndexOf('}');
  if (start < 0 || end <= start) return null;

  final Object? decoded;
  try {
    decoded = jsonDecode(clean.substring(start, end + 1));
  } on FormatException {
    return null;
  }
  if (decoded is! Map<String, dynamic>) return null;
  final object = decoded;
  const known = {'merchant', 'category', 'channel'};
  if (!object.keys.every(known.contains)) return null;

  String? text(String key) {
    final v = object[key];
    if (v == null) return null;
    if (v is! String) throw const FormatException('not a string');
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  try {
    final merchant = text('merchant');
    final category = text('category');
    final channel = text('channel');
    if (merchant != null && merchant.length > 80) return null;
    if (category != null && !categories.contains(category)) return null;
    if (channel != null && !allowedChannels.contains(channel)) return null;
    return ModelReply(merchant: merchant, category: category, channel: channel);
  } on FormatException {
    return null;
  }
}
