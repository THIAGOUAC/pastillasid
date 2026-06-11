import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class PharmacyMapPage extends StatefulWidget {
  const PharmacyMapPage({super.key});

  @override
  State<PharmacyMapPage> createState() => _PharmacyMapPageState();
}

class _PharmacyMapPageState extends State<PharmacyMapPage> {
  Position? _currentPosition;
  bool _isLoading = false;
  bool _isOpeningMaps = false;
  String? _errorMessage;

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Activa la ubicación del dispositivo.';
          _isLoading = false;
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        setState(() {
          _errorMessage = 'Permiso de ubicación denegado.';
          _isLoading = false;
        });
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Permiso bloqueado. Actívalo desde ajustes.';
          _isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      // Abrir farmacias automáticamente al obtener ubicación
      await _openNearbyPharmaciesInMaps();
    } catch (error) {
      setState(() {
        _errorMessage = 'No se pudo obtener la ubicación: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _openNearbyPharmaciesInMaps() async {
    final position = _currentPosition;
    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero obtén tu ubicación.')),
      );
      return;
    }

    setState(() {
      _isOpeningMaps = true;
      _errorMessage = null;
    });

    final lat = position.latitude;
    final lng = position.longitude;

    // URL que abre Google Maps centrado en tu posición buscando farmacias
    final uri = Uri.parse(
      'https://www.google.com/maps/search/farmacias/@$lat,$lng,15z',
    );

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        setState(() => _errorMessage = 'No se pudo abrir Google Maps.');
      }
    } catch (error) {
      setState(() => _errorMessage = 'Error al abrir Google Maps: $error');
    } finally {
      if (mounted) setState(() => _isOpeningMaps = false);
    }
  }

  Future<void> _openRouteToPharmacy() async {
    final position = _currentPosition;
    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero obtén tu ubicación.')),
      );
      return;
    }

    final lat = position.latitude;
    final lng = position.longitude;

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=$lat,$lng'
      '&destination=farmacia'
      '&travelmode=driving',
    );

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final position = _currentPosition;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          // ── Header ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_pharmacy,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Farmacias cercanas', style: tt.titleLarge),
                      Text(
                        'Encuentra la más cercana a ti',
                        style: tt.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Card ilustración + botón principal ───────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Buscar farmacias cerca de mí',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Obtenemos tu ubicación y abrimos Google Maps con las farmacias más cercanas.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading || _isOpeningMaps
                          ? null
                          : _getCurrentLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: cs.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: _isLoading || _isOpeningMaps
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.primary,
                              ),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(
                        _isLoading
                            ? 'Obteniendo ubicación...'
                            : _isOpeningMaps
                            ? 'Abriendo Google Maps...'
                            : 'Buscar farmacias cercanas',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Error ────────────────────────────────────
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.error.withValues(alpha: 0.30)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: cs.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: tt.bodyMedium?.copyWith(color: cs.error),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Ubicación obtenida ────────────────────────
          if (position != null) ...[
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E8B57).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2E8B57).withValues(alpha: 0.30),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF2E8B57),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ubicación obtenida correctamente',
                        style: tt.bodyMedium?.copyWith(
                          color: const Color(0xFF1B5E20),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Opciones adicionales ──────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'OTRAS OPCIONES',
                style: tt.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                child: InkWell(
                  onTap: _isOpeningMaps ? null : _openNearbyPharmaciesInMaps,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.local_pharmacy,
                            color: cs.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ver farmacias en el mapa',
                                style: tt.titleMedium,
                              ),
                              Text(
                                'Abre Google Maps centrado en tu zona',
                                style: tt.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: cs.primary),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Card(
                child: InkWell(
                  onTap: _openRouteToPharmacy,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF2E8B57,
                            ).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.directions,
                            color: Color(0xFF2E8B57),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cómo llegar a una farmacia',
                                style: tt.titleMedium,
                              ),
                              Text(
                                'Obtén ruta en Google Maps',
                                style: tt.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF2E8B57),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── Info ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: cs.primary.withValues(alpha: 0.60),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'La búsqueda se realiza a través de Google Maps. Necesitas conexión a internet.',
                      style: tt.bodyMedium?.copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
