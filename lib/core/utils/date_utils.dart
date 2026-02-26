String getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return "Günaydın";
  if (hour < 18) return "İyi Günler";
  return "İyi Akşamlar";
}

String getFormattedDate() {
  final now = DateTime.now();
  return "${now.day}.${now.month}.${now.year}";
}
