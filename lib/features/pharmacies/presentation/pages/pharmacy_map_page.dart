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
          _errorMessage =
              'El permiso de ubicación está bloqueado. Actívalo desde ajustes.';
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
        const SnackBar(content: Text('Primero obtén tu ubicación actual.')),
      );
      return;
    }

    setState(() {
      _isOpeningMaps = true;
      _errorMessage = null;
    });

    final latitude = position.latitude;
    final longitude = position.longitude;

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=farmacias%20cerca%20de%20mi'
      '&query_place_id='
      '&center=$latitude,$longitude',
    );

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened) {
        setState(() {
          _errorMessage = 'No se pudo abrir Google Maps.';
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'No se pudo abrir Google Maps: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningMaps = false;
        });
      }
    }
  }

  Future<void> _openRouteSearchInMaps() async {
    final position = _currentPosition;

    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero obtén tu ubicación actual.')),
      );
      return;
    }

    final latitude = position.latitude;
    final longitude = position.longitude;

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=$latitude,$longitude'
      '&destination=farmacia'
      '&travelmode=driving',
    );

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final position = _currentPosition;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Farmacias cercanas',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Usaremos tu ubicación para buscar farmacias cercanas en Google Maps.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Card(
            child: SizedBox(
              height: 260,
              child: Center(
                child: Icon(
                  Icons.map,
                  size: 96,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _getCurrentLocation,
            icon: _isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: Text(
              _isLoading ? 'Obteniendo ubicación...' : 'Usar mi ubicación',
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: position == null || _isOpeningMaps
                ? null
                : _openNearbyPharmaciesInMaps,
            icon: _isOpeningMaps
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.local_pharmacy),
            label: Text(
              _isOpeningMaps
                  ? 'Abriendo Google Maps...'
                  : 'Buscar farmacias en Google Maps',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: position == null ? null : _openRouteSearchInMaps,
            icon: const Icon(Icons.directions),
            label: const Text('Buscar ruta a una farmacia'),
          ),
          const SizedBox(height: 16),
          if (_errorMessage != null)
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: const Text('Aviso'),
                subtitle: Text(_errorMessage!),
              ),
            ),
          if (position != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ubicación actual',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text('Latitud: ${position.latitude}'),
                    Text('Longitud: ${position.longitude}'),
                    const SizedBox(height: 8),
                    Text(
                      'Con esta ubicación puedes buscar farmacias cercanas usando Google Maps.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
