import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:thix_central/pages/profile/models/profile_models.dart';

class ProfilePdfService {
  const ProfilePdfService();

  Future<void> printDigitalCv({
    required String displayName,
    required String thixId,
    ProfileDetailsModel? details,
    required List<ProfileExperienceModel> experiences,
    required List<ProfileEducationModel> education,
    required List<ProfileSkillModel> skills,
    required List<ProfileLanguageModel> languages,
  }) async {
    final doc = pw.Document();
    final df = DateFormat('dd/MM/yyyy');

    pw.Widget kv(String k, String v) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.SizedBox(width: 120, child: pw.Text(k, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey800))),
            pw.Expanded(child: pw.Text(v)),
          ]),
        );

    pw.Widget sectionTitle(String t) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 12, bottom: 6),
          child: pw.Text(t, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
        );

    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(28)),
        build: (context) {
          return [
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Expanded(
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(displayName, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('THIX ID: $thixId', style: pw.TextStyle(color: PdfColors.grey700)),
                ]),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(color: PdfColors.blue50, borderRadius: pw.BorderRadius.circular(20)),
                child: pw.Text('Digital CV', style: pw.TextStyle(color: PdfColors.blue900, fontWeight: pw.FontWeight.bold)),
              ),
            ]),
            sectionTitle('Informations'),
            if ((details?.bio ?? '').trim().isNotEmpty) kv('Bio', details!.bio!.trim()),
            if ((details?.phone ?? '').trim().isNotEmpty) kv('Téléphone', details!.phone!.trim()),
            if ((details?.city ?? '').trim().isNotEmpty) kv('Ville', details!.city!.trim()),
            if ((details?.address ?? '').trim().isNotEmpty) kv('Adresse', details!.address!.trim()),
            if ((details?.nationality ?? '').trim().isNotEmpty) kv('Nationalité', details!.nationality!.trim()),
            sectionTitle('Expériences'),
            if (experiences.isEmpty) pw.Text('Aucune expérience.'),
            for (final e in experiences)
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                margin: const pw.EdgeInsets.only(bottom: 8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(10)),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(e.title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    [e.organization, e.city].where((v) => (v ?? '').trim().isNotEmpty).map((v) => v!.trim()).join(' • '),
                    style: pw.TextStyle(color: PdfColors.grey700),
                  ),
                  if (e.startDate != null || e.endDate != null)
                    pw.Text(
                      '${e.startDate == null ? '' : df.format(e.startDate!)}  →  ${e.endDate == null ? 'Aujourd\'hui' : df.format(e.endDate!)}',
                      style: pw.TextStyle(color: PdfColors.grey700),
                    ),
                  if ((e.missions ?? '').trim().isNotEmpty) pw.SizedBox(height: 6),
                  if ((e.missions ?? '').trim().isNotEmpty) pw.Text(e.missions!.trim()),
                ]),
              ),
            sectionTitle('Formations'),
            if (education.isEmpty) pw.Text('Aucune formation.'),
            for (final ed in education)
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                margin: const pw.EdgeInsets.only(bottom: 8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(10)),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(ed.institution, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    [ed.degree, ed.level].where((v) => (v ?? '').trim().isNotEmpty).map((v) => v!.trim()).join(' • '),
                    style: pw.TextStyle(color: PdfColors.grey700),
                  ),
                  if (ed.startYear != null || ed.endYear != null)
                    pw.Text('${ed.startYear ?? ''}  →  ${ed.endYear ?? ''}', style: pw.TextStyle(color: PdfColors.grey700)),
                  if ((ed.description ?? '').trim().isNotEmpty) pw.SizedBox(height: 6),
                  if ((ed.description ?? '').trim().isNotEmpty) pw.Text(ed.description!.trim()),
                ]),
              ),
            sectionTitle('Compétences'),
            if (skills.isEmpty) pw.Text('Aucune compétence.'),
            if (skills.isNotEmpty)
              pw.Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in skills)
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(18)),
                      child: pw.Text('${s.name} • ${s.level}'),
                    ),
                ],
              ),
            sectionTitle('Langues'),
            if (languages.isEmpty) pw.Text('Aucune langue.'),
            for (final l in languages) kv(l.name, (l.level ?? '').isEmpty ? '-' : l.level!),
            pw.SizedBox(height: 14),
            pw.Text('Généré automatiquement par THIX.', style: pw.TextStyle(color: PdfColors.grey600, fontSize: 10)),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }
}
