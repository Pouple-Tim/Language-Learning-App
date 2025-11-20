import 'package:flutter_test/flutter_test.dart';
// Assurez-vous que le chemin d'importation correspond à votre structure de projet
import 'package:language_learning_app/core/utils/date_helper.dart'; 

void main() {
  group('DateHelper Tests', () {
    test('isToday retourne true pour la date actuelle', () {
      final now = DateTime.now();
      expect(DateHelper.isToday(now), isTrue);
    });

    test('isToday retourne false pour une date différente', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(DateHelper.isToday(yesterday), isFalse);
    });

    test('needsReset retourne true si la date n\'est pas aujourd\'hui', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(DateHelper.needsReset(yesterday), isTrue);
    });

    test('needsReset retourne false si la date est aujourd\'hui', () {
      final now = DateTime.now();
      expect(DateHelper.needsReset(now), isFalse);
    });

    test('startOfDay remet les heures, minutes et secondes à zéro', () {
      final date = DateTime(2023, 11, 20, 14, 30, 45);
      final start = DateHelper.startOfDay(date);
      
      expect(start.year, 2023);
      expect(start.month, 11);
      expect(start.day, 20);
      expect(start.hour, 0);
      expect(start.minute, 0);
      expect(start.second, 0);
      expect(start.millisecond, 0);
    });

    test('today retourne le début de la journée actuelle', () {
      final todayHelper = DateHelper.today;
      final now = DateTime.now();
      
      expect(todayHelper.year, now.year);
      expect(todayHelper.month, now.month);
      expect(todayHelper.day, now.day);
      expect(todayHelper.hour, 0);
    });

    test('formatDate formate correctement en français', () {
      final date = DateTime(2025, 11, 13); // 13 Novembre 2025
      expect(DateHelper.formatDate(date), '13 Nov 2025');

      final dateJan = DateTime(2025, 1, 1); // 1 Janvier 2025
      expect(DateHelper.formatDate(dateJan), '1 Jan 2025');
    });

    test('daysBetween calcule correctement la différence en jours', () {
      final start = DateTime(2023, 11, 20);
      final end = DateTime(2023, 11, 25);
      
      expect(DateHelper.daysBetween(start, end), 5);
    });

    test('daysBetween ignore les heures pour le calcul', () {
      // Du 20 à 23h au 21 à 1h, c'est +1 jour calendaire de différence selon la logique startOfDay
      final start = DateTime(2023, 11, 20, 23, 0, 0);
      final end = DateTime(2023, 11, 21, 1, 0, 0);
      
      expect(DateHelper.daysBetween(start, end), 1);
    });
  });
}