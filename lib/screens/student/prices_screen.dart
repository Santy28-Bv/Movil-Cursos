import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../repositories/student_repository.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/academix_api.dart';

class PricesScreen extends StatefulWidget {
  const PricesScreen({super.key});
  @override
  State<PricesScreen> createState() => _PricesScreenState();
}

class _PricesScreenState extends State<PricesScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  late final AcademixApi _api;
  final _preferences = SharedPreferencesAsync();
  bool _purchasing = false;
  @override
  void initState() {
    super.initState();
    _api = AcademixApi(Supabase.instance.client);
    _load();
  }

  void _load() {
    _future = _loadPlans();
  }

  Future<List<Map<String, dynamic>>> _loadPlans() async {
    try {
      return jsonRows(await _api.get('/plans', authenticated: false));
    } on ApiException catch (error) {
      if (error.code != 'NETWORK_ERROR' && error.status < 500) rethrow;
      return jsonRows(
        jsonDecode(await rootBundle.loadString('assets/plan-reference.json')),
      );
    }
  }

  String _price(Map<String, dynamic> plan) {
    final amount = plan['priceMxn'] as num?;
    final months = plan['months'];
    return amount == null
        ? 'Consulta las condiciones del plan'
        : '\$${amount.toStringAsFixed(2)} MXN / ${months == 1 ? 'mes' : '$months meses'}';
  }

  Future<Map<String, dynamic>> _livePlan(String id) async {
    final plans = jsonRows(
      await _api.get('/plans', authenticated: false, allowSavedResponse: false),
    );
    final plan =
        plans
            .where((row) => row['id'] == id && row['purchasable'] == true)
            .firstOrNull;
    if (plan == null) {
      throw const ApiException(
        'Este plan ya no está disponible.',
        code: 'PLAN_CHANGED',
      );
    }
    return plan;
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _subscribe(Map<String, dynamic> displayed) async {
    if (_purchasing) return;
    final owner = _api.client.auth.currentUser?.id;
    if (owner == null) {
      _message('Inicia sesión para suscribirte.');
      return;
    }
    setState(() => _purchasing = true);
    try {
      final id = displayed['id'] as String;
      final plan = await _livePlan(id);
      final institutional = plan['audience'] == 'organization';
      String? organizationId;
      if (institutional) {
        final organizations =
            await StudentRepository(_api.client, api: _api).organizations();
        final administrators =
            organizations
                .where(
                  (row) =>
                      row['role'] == 'administrator' && row['active'] != false,
                )
                .toList();
        if (!mounted || _api.client.auth.currentUser?.id != owner) return;
        if (administrators.isEmpty) {
          _message(
            'Necesitas administrar una organización para contratar el plan.',
          );
          return;
        }
        organizationId = await showDialog<String>(
          context: context,
          builder:
              (context) => SimpleDialog(
                title: const Text('Elige la organización'),
                children: [
                  for (final organization in administrators)
                    SimpleDialogOption(
                      onPressed:
                          () => Navigator.pop(
                            context,
                            organization['id'] as String,
                          ),
                      child: Text('${organization['name']}'),
                    ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
        );
        if (organizationId == null) return;
      }
      if (!mounted || _api.client.auth.currentUser?.id != owner) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Confirmar ${plan['name']}'),
              content: Text(
                '${_price(plan)}. La compra es simulada y no genera un cobro real.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirmar compra'),
                ),
              ],
            ),
      );
      if (confirmed != true ||
          !mounted ||
          _api.client.auth.currentUser?.id != owner) {
        return;
      }
      final current = await _livePlan(id);
      if (!mounted || _api.client.auth.currentUser?.id != owner) return;
      if (current['priceMxn'] != plan['priceMxn'] ||
          current['months'] != plan['months']) {
        setState(_load);
        _message('El precio cambió. Revisa el plan y confirma de nuevo.');
        return;
      }
      final request =
          'academix:plan-purchase:$owner:$id:${organizationId ?? "personal"}';
      final key = await _preferences.getString(request) ?? const Uuid().v4();
      await _preferences.setString(request, key);
      if (!mounted || _api.client.auth.currentUser?.id != owner) return;
      await _api.post('/subscriptions/simulated-purchase', {
        'planId': id,
        if (organizationId != null) 'organizationId': organizationId,
        'idempotencyKey': key,
      });
      await _preferences.remove(request);
      if (mounted && _api.client.auth.currentUser?.id == owner) {
        _message('Tu suscripción simulada está activa.');
      }
    } on ApiException catch (error) {
      if (!mounted || _api.client.auth.currentUser?.id != owner) return;
      _message(
        error.code == 'NETWORK_ERROR' || error.status >= 500
            ? 'Conéctate a internet y vuelve a confirmar para suscribirte.'
            : studentError(error, 'No pudimos confirmar tu suscripción.'),
      );
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Precios y modalidades')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Elige cómo aprender',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        const Text(
          'Puedes consultar el precio de cada curso en su detalle. Los cursos de tu institución pueden estar incluidos mientras tu membresía y su plan estén activos.',
        ),
        const SizedBox(height: 12),
        const Text('Se requiere internet para confirmar una suscripción.'),
        const SizedBox(height: 20),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LinearProgressIndicator();
            }
            if (snapshot.hasError) {
              return Column(
                children: [
                  Text(
                    studentError(
                      snapshot.error,
                      'No pudimos consultar los planes.',
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(_load),
                    child: const Text('Reintentar'),
                  ),
                ],
              );
            }
            return Column(
              children: [
                for (final plan in snapshot.data!)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${plan['name']}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Text(_price(plan)),
                          const SizedBox(height: 12),
                          for (final feature in plan['features'] as List? ?? [])
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text('✓ $feature'),
                            ),
                          if (plan['purchasable'] == true)
                            FilledButton(
                              onPressed:
                                  _purchasing ? null : () => _subscribe(plan),
                              child: const Text('Suscribirme'),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}
