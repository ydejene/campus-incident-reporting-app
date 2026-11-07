import '../models/incident.dart';
import '../models/incident_category.dart';
import '../models/incident_status.dart';

/// Pure domain helper for client-side search matching and filtering.
///
/// Evaluates incident fields against a case-insensitive, whitespace-trimmed
/// search query and optional category and status filters.
class IncidentFilterService {
  IncidentFilterService._();

  /// Returns true if [incident] satisfies the given [query], [category], and [status].
  static bool matches({
    required Incident incident,
    String query = '',
    IncidentCategory? category,
    IncidentStatus? status,
  }) {
    // Category filter
    if (category != null && incident.category != category) {
      return false;
    }

    // Status filter
    if (status != null && incident.status != status) {
      return false;
    }

    // Case-insensitive, whitespace-trimmed keyword search
    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.isEmpty) {
      return true;
    }

    final inDescription =
        incident.description.toLowerCase().contains(trimmedQuery);
    final inCategory =
        incident.category.label.toLowerCase().contains(trimmedQuery);
    final inBuilding =
        incident.building.toLowerCase().contains(trimmedQuery);
    final inBlock =
        incident.block.toLowerCase().contains(trimmedQuery);
    final inSpecificArea =
        incident.specificArea.toLowerCase().contains(trimmedQuery);
    final inFormattedLocation =
        incident.formattedLocation.toLowerCase().contains(trimmedQuery);
    final inTitle =
        incident.title?.toLowerCase().contains(trimmedQuery) ?? false;

    return inDescription ||
        inCategory ||
        inBuilding ||
        inBlock ||
        inSpecificArea ||
        inFormattedLocation ||
        inTitle;
  }

  /// Filters a list of incidents according to [query], [category], and [status].
  static List<Incident> filterList(
    List<Incident> incidents, {
    String query = '',
    IncidentCategory? category,
    IncidentStatus? status,
  }) {
    return incidents
        .where((incident) => matches(
              incident: incident,
              query: query,
              category: category,
              status: status,
            ))
        .toList();
  }
}

