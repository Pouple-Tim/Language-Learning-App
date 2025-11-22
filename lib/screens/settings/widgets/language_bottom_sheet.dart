import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/providers/locale_provider.dart';

class LanguageBottomSheet {
  static Future<void> show(BuildContext context, LocaleProvider localeProvider) async {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle de drag
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            _buildLanguageItem(context, localeProvider, 'fr', 'Français', 'FR'),
            _buildLanguageItem(context, localeProvider, 'en', 'English', 'GB'),
            _buildLanguageItem(context, localeProvider, 'es', 'Español', 'ES'),
            _buildLanguageItem(context, localeProvider, 'it', 'Italiano', 'IT'),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _buildLanguageItem(
    BuildContext context,
    LocaleProvider provider,
    String code,
    String name,
    String countryCode,
  ) {
    final isSelected = provider.locale.languageCode == code;
    
    return ListTile(
      leading: SizedBox(
        width: 32,
        height: 24,
        child: CountryFlag.fromCountryCode(
          countryCode,
          theme: const ImageTheme(shape: RoundedRectangle(4)),
        ),
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected 
        ? const Icon(Icons.check_circle, color: AppColors.primary) 
        : null,
      onTap: () {
        provider.setLocale(Locale(code));
        Navigator.pop(context);
      },
    );
  }
}