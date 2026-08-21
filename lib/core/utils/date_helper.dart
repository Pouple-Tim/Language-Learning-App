class DateHelper {
  // Vérifier si une date est aujourd'hui
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  // Vérifier si un reset est nécessaire (nouveau jour)
  static bool needsReset(DateTime lastReset) {
    return !isToday(lastReset);
  }

  // Obtenir le début de la journée (00:00:00)
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Obtenir le début d'aujourd'hui
  static DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // Formater une date (ex: "13 Nov 2025")
  static String formatDate(DateTime date) {
    final months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Obtenir le nombre de jours entre deux dates
  static int daysBetween(DateTime from, DateTime to) {
    from = startOfDay(from);
    to = startOfDay(to);
    return (to.difference(from).inHours / 24).round();
  }
}