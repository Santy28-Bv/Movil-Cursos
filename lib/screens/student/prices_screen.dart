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
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = AcademixApi(
      Supabase.instance.client,
    ).get('/plans', authenticated: false).then(jsonRows);
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
                          Text(
                            plan['priceMxn'] == null
                                ? 'Consulta las condiciones del plan'
                                : '\$${plan['priceMxn']} MXN${plan['months'] == null ? '' : ' / ${plan['months']} mes(es)'}',
                          ),
                          const SizedBox(height: 12),
                          for (final feature in plan['features'] as List? ?? [])
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text('✓ $feature'),
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
