import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/nominatim_service.dart';
import '../theme/app_theme.dart';

class AddressAutocompleteField extends StatefulWidget {
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController postalCodeController;

  const AddressAutocompleteField({
    super.key,
    required this.addressController,
    required this.cityController,
    required this.postalCodeController,
  });

  @override
  State<AddressAutocompleteField> createState() => _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  final NominatimService _nominatimService = NominatimService();
  Timer? _debounceTimer;
  List<NominatimPlace> _suggestions = [];
  bool _isSearching = false;
  bool _showOverlay = false;

  void _onAddressChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (query.trim().length < 3) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
        _showOverlay = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      setState(() {
        _isSearching = true;
        _showOverlay = true;
      });

      final results = await _nominatimService.searchPlaces(query);

      if (mounted) {
        setState(() {
          _suggestions = results;
          _isSearching = false;
        });
      }
    });
  }

  void _selectPlace(NominatimPlace place) {
    setState(() {
      widget.addressController.text = place.street.isNotEmpty ? place.street : place.displayName;
      if (place.city.isNotEmpty) {
        widget.cityController.text = place.city;
      }
      if (place.postcode.isNotEmpty) {
        widget.postalCodeController.text = place.postcode;
      }
      _suggestions = [];
      _showOverlay = false;
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de Dirección
        TextField(
          controller: widget.addressController,
          onChanged: _onAddressChanged,
          decoration: InputDecoration(
            labelText: "Adreça",
            prefixIcon: const Icon(Icons.home_outlined),
            suffixIcon: _isSearching
                ? const UnconstrainedBox(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : (widget.addressController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.map_outlined),
                        tooltip: "Buscar adreça",
                        onPressed: () => _onAddressChanged(widget.addressController.text),
                      )
                    : null),
          ),
        ),

        // Sugerencias de OpenStreetMap
        if (_showOverlay && (_isSearching || _suggestions.isNotEmpty))
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
            ),
            child: _isSearching
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Cercant adreça...",
                          style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final place = _suggestions[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on, color: AppColors.secondary, size: 20),
                        title: Text(
                          place.displayName,
                          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: (place.city.isNotEmpty || place.postcode.isNotEmpty)
                            ? Text(
                                "${place.city} ${place.postcode}".trim(),
                                style: GoogleFonts.manrope(fontSize: 11, color: Colors.grey.shade600),
                              )
                            : null,
                        onTap: () => _selectPlace(place),
                      );
                    },
                  ),
          ),

        const SizedBox(height: 20),
        // Campo de Ciudad
        TextField(
          controller: widget.cityController,
          decoration: const InputDecoration(
            labelText: "Ciutat",
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),

        const SizedBox(height: 20),
        // Campo de Código Postal
        TextField(
          controller: widget.postalCodeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Codi postal",
            prefixIcon: Icon(Icons.local_post_office_outlined),
          ),
        ),
      ],
    );
  }
}
