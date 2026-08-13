/// Single canonical partial-text, case-insensitive matcher for every
/// search/filter in the app. Before this existed, the same
/// `field.toLowerCase().contains(query.toLowerCase())` pattern had been
/// independently reimplemented three times (Nearby Lands' village/district
/// filter, Vets Nearby's village/district filter, and the Explore map's
/// unified land+vet search) — all correct, but three copies of logic that
/// must stay in sync by hand. Everything now routes through here instead.
bool matchesQuery(String query, Iterable<String?> fields) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return fields.any((f) => f != null && f.toLowerCase().contains(q));
}
