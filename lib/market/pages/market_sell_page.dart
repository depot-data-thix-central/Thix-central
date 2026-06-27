import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';
import 'package:thix_central/theme.dart';
import 'package:thix_central/widgets/thix_app_bar.dart';

class MarketSellPage extends StatefulWidget {
  const MarketSellPage({super.key});

  @override
  State<MarketSellPage> createState() => _MarketSellPageState();
}

class _MarketSellPageState extends State<MarketSellPage> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _currency = TextEditingController(text: 'XOF');
  final _stock = TextEditingController(text: '1');
  final _coverUrl = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _currency.dispose();
    _stock.dispose();
    _coverUrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final client = SupabaseClientProvider.clientOrNull;
    final user = client?.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      context.push('/auth/login?next=/market/sell');
      return;
    }

    final title = _title.text.trim();
    if (title.isEmpty) {
      _showSnack('Titre requis');
      return;
    }

    final priceNum = num.tryParse(_price.text.trim().replaceAll(',', '.'));
    if (priceNum == null || priceNum < 0) {
      _showSnack('Prix invalide');
      return;
    }
    final priceCents = (priceNum * 100).round();
    final stock = int.tryParse(_stock.text.trim()) ?? 0;

    setState(() => _saving = true);
    try {
      final row = await SupabaseClientProvider.client
          .from('market_products')
          .insert({
            'seller_id': user.id,
            'title': title,
            'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
            'price_cents': priceCents,
            'currency': _currency.text.trim().isEmpty ? 'XOF' : _currency.text.trim().toUpperCase(),
            'stock': stock,
            'is_active': true,
          })
          .select('id')
          .single();

      final productId = (row as Map)['id'] as String?;
      final url = _coverUrl.text.trim();
      if (productId != null && url.isNotEmpty) {
        await SupabaseClientProvider.client.from('market_product_media').insert({'product_id': productId, 'url': url, 'sort_order': 0});
      }

      if (!mounted) return;
      _showSnack('Produit publié');
      context.go('/market');
    } catch (e) {
      debugPrint('MarketSellPage submit failed: $e');
      if (!mounted) return;
      _showSnack('Erreur: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: ThixTopBar(title: 'Vendre', subtitle: 'Publier un produit sur THIX Market', onMenuTap: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 12, AppSpacing.md, 110),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Infos produit', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                TextField(controller: _title, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Titre', hintText: 'Ex: AirPods Pro 2')),
                const SizedBox(height: 10),
                TextField(controller: _description, minLines: 3, maxLines: 6, decoration: const InputDecoration(labelText: 'Description', hintText: 'Décris ton produit…')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Prix', hintText: 'Ex: 15000'))),
                    const SizedBox(width: 10),
                    SizedBox(width: 92, child: TextField(controller: _currency, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Devise'))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: _stock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock', hintText: 'Ex: 10')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Média (optionnel)', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                TextField(controller: _coverUrl, decoration: const InputDecoration(labelText: 'URL image', hintText: 'https://…')),
                const SizedBox(height: 8),
                Text('Astuce: tu peux d’abord uploader dans Supabase Storage, puis coller l’URL publique ici.', style: context.textStyles.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
              ),
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.publish, size: 18, color: AppColors.white),
                        const SizedBox(width: 10),
                        Text('Publier', style: context.textStyles.titleSmall?.copyWith(color: AppColors.white, fontWeight: FontWeight.w900)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
