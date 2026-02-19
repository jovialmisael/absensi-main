import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {

  // --- PDF 1: FORMULIR CUTI (Sesuai Gambar 1 & 3) ---
  Future<void> createCutiPdf(
      String name,
      String nik,
      String divisi,
      String leaveType,
      DateTime startDate,
      DateTime endDate,
      String reason,
      String handoverName,
      String address,
      String phone,
      ) async {

    final pdf = pw.Document();
    int totalDays = endDate.difference(startDate).inDays + 1;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // HEADER PTM
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(""),
                    pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          // Ganti dengan Logo Image jika ada
                          pw.Text("PT. PRIMA TUNGGAL MANDIRI", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                        ]
                    )
                  ]
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text("PERMOHONAN CUTI", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, decoration: pw.TextDecoration.underline)),
              ),
              pw.SizedBox(height: 20),

              // BODY CUTI
              _buildRowInfo("Nama", ": $name", "Divisi / Departement", ": $divisi"),
              pw.SizedBox(height: 5),
              _buildRowInfo("NIK / Barcode", ": $nik", "Hari / Tanggal", ": ${DateFormat('dd-MM-yyyy').format(DateTime.now())}"),

              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),

              pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                        flex: 1,
                        child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text("Jenis Cuti :"),
                              pw.SizedBox(height: 5),
                              _buildCheckbox("Cuti Tahunan", leaveType == "Cuti Tahunan"),
                              _buildCheckbox("Cuti Hamil / Melahirkan", leaveType.contains("Hamil") || leaveType.contains("Melahirkan")),
                              _buildCheckbox("Cuti / Izin Khusus", leaveType.contains("Khusus")),
                            ]
                        )
                    ),
                    pw.Expanded(
                        flex: 1,
                        child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text("Diisi oleh Pemohon :"),
                              pw.SizedBox(height: 5),
                              _buildSimpleRow("Mulai tanggal", ": ${DateFormat('dd-MM-yyyy').format(startDate)}"),
                              _buildSimpleRow("Sampai tanggal", ": ${DateFormat('dd-MM-yyyy').format(endDate)}"),
                              _buildSimpleRow("Jumlah hari", ": $totalDays Hari"),
                            ]
                        )
                    )
                  ]
              ),

              pw.SizedBox(height: 15),
              pw.Text("Pekerjaan yang ditinggalkan & masih harus diselesaikan :"),
              pw.Container(
                  width: double.infinity,
                  height: 30,
                  decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1))),
                  child: pw.Text(reason, style: const pw.TextStyle(fontSize: 10))
              ),

              pw.SizedBox(height: 15),
              pw.Text("Selama melakukan cuti :"),
              pw.SizedBox(height: 5),

              pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                        child: pw.Column(children: [
                          _buildSimpleRow("Pekerjaan diserahkan kepada", ""),
                          _buildSimpleRow("Nama", ": $handoverName"),
                          _buildSimpleRow("Tanda Tangan", ": _____________"),
                        ])
                    ),
                    pw.SizedBox(width: 20),
                    pw.Expanded(
                        child: pw.Column(children: [
                          _buildSimpleRow("Dapat dihubungi di", ""),
                          _buildSimpleRow("Alamat", ": $address"),
                          _buildSimpleRow("No. Telp/HP", ": $phone"),
                        ])
                    )
                  ]
              ),

              pw.SizedBox(height: 20),

              // FOOTER CUTI (Tabel)
              pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  child: pw.Row(
                      children: [
                        pw.Expanded(
                            child: pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text("Perhitungan cuti tahunan :", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                                      pw.Divider(),
                                      _buildTableItem("Tgl. Masuk Kerja", ": _______"),
                                      pw.SizedBox(height: 10),
                                      _buildTableItem("Sisa Cuti tahun", ": _______ hari"),
                                      _buildTableItem("Cuti yang diambil", ": $totalDays hari (-)"),
                                      pw.Divider(),
                                      _buildTableItem("Sisa Cuti", ": _______ hari"),
                                    ]
                                )
                            )
                        ),
                        pw.Container(width: 1, height: 100, color: PdfColors.black),
                        pw.Expanded(
                            child: pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text("Cuti Khusus (tidak mengurangi cuti tahunan) :", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                                      pw.Divider(),
                                      _buildSmallText("1. Karyawan Menikah : 3 hari"),
                                      _buildSmallText("2. Menikahkan anak : 2 hari"),
                                      _buildSmallText("3. Istri melahirkan/keguguran : 2 hari"),
                                    ]
                                )
                            )
                        ),
                      ]
                  )
              ),
              pw.SizedBox(height: 10),
              // Tanda Tangan
              pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Karyawan", textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Div. / Dept. Head", textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("HR Dept.", textAlign: pw.TextAlign.center)),
                    ]),
                    pw.TableRow(children: [
                      pw.Container(height: 40),
                      pw.Container(height: 40),
                      pw.Container(height: 40),
                    ]),
                  ]
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  // --- PDF 2: FORM IZIN & SUBSTITUSI (Sesuai Gambar 4 - SB) ---
  Future<void> createHourlyPdf(
      String name,
      String jabatan,
      DateTime permitDate,
      String startTime,
      String endTime,
      bool isBackToWork,
      String reason,
      ) async {
    final pdf = pw.Document();

    // Hitung Durasi
    // Format string HH:mm ke DateTime untuk hitung selisih
    DateTime startT = DateFormat("HH:mm").parse(startTime);
    DateTime endT = DateFormat("HH:mm").parse(endTime);
    int diffMinutes = endT.difference(startT).inMinutes;
    String durationStr = "${(diffMinutes / 60).floor()} Jam ${diffMinutes % 60} Menit";

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        orientation: pw.PageOrientation.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // KONTEN UTAMA (Kiri)
                pw.Expanded(
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Header Data Diri
                          _buildFormLine("Nama", name),
                          _buildFormLine("Jabatan", jabatan),
                          _buildFormLine("Tanggal pengajuan ijin", DateFormat('dd MMM yyyy').format(DateTime.now())),
                          _buildFormLine("Tanggal ijin", DateFormat('dd MMM yyyy').format(permitDate)),
                          _buildFormLine("Waktu ijin", "$startTime s/d $endTime"),
                          _buildFormLine("Total waktu ijin", durationStr),
                          _buildFormLine("Alasan", reason),

                          pw.SizedBox(height: 10),
                          pw.Text("Kembali lagi kerja", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 5),
                          pw.Row(
                              children: [
                                _buildCheckbox("    ", isBackToWork), // Kotak centang
                                pw.SizedBox(width: 10),
                                pw.Text("Tidak kembali/pulang"),
                                pw.SizedBox(width: 10),
                                _buildCheckbox("    ", !isBackToWork),
                              ]
                          ),

                          pw.SizedBox(height: 20),

                          // TABEL SUBSTITUSI
                          pw.Text("Rincian penggantian waktu ijin:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 5),
                          pw.Table(
                              border: pw.TableBorder.all(),
                              children: [
                                pw.TableRow(
                                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                                    children: [
                                      _buildTableCell("Tanggal", isHeader: true),
                                      _buildTableCell("Waktu", isHeader: true),
                                      _buildTableCell("Hal yang dikerjakan", isHeader: true),
                                    ]
                                ),
                                // Baris Kosong untuk diisi manual
                                _buildEmptyRow(),
                                _buildEmptyRow(),
                                _buildEmptyRow(),
                                _buildEmptyRow(),
                              ]
                          ),

                          pw.Spacer(),

                          // TANDA TANGAN
                          pw.Table(
                              border: pw.TableBorder.all(),
                              children: [
                                pw.TableRow(children: [
                                  pw.Container(padding: const pw.EdgeInsets.all(5), child: pw.Center(child: pw.Text("Karyawan"))),
                                  pw.Container(padding: const pw.EdgeInsets.all(5), child: pw.Center(child: pw.Text("Atasan"))),
                                  pw.Container(padding: const pw.EdgeInsets.all(5), child: pw.Center(child: pw.Text("HRD"))),
                                ]),
                                pw.TableRow(children: [
                                  pw.Container(height: 50),
                                  pw.Container(height: 50),
                                  pw.Container(height: 50),
                                ]),
                                pw.TableRow(children: [
                                  pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text("Diterima pada tanggal :", style: const pw.TextStyle(fontSize: 8))),
                                  pw.Container(),
                                  pw.Container(),
                                ]),
                              ]
                          ),
                        ]
                    )
                ),

                // HEADER LOGO PERUSAHAAN (Kanan - Rotated/Sidebar style sesuai gambar 4)
                pw.SizedBox(width: 20),
                pw.Container(
                    width: 150,
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          // LOGO SB
                          pw.Text("SB", style: pw.TextStyle(fontSize: 40, fontWeight: pw.FontWeight.bold)),
                          pw.Text("PT. Sumber Baru Ban", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                          pw.Text("Jalan MT Haryono 662 Semarang\nTelp. (024) 3515708\nFax. (024) 3519696", style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right),
                          pw.SizedBox(height: 20),
                          pw.Container(
                              padding: const pw.EdgeInsets.all(5),
                              color: PdfColors.black,
                              child: pw.Text("Form Ijin dan Substitusi Kerja", style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10))
                          ),
                          pw.Container(width: 5, height: 400, color: PdfColors.black), // Garis vertikal tebal
                        ]
                    )
                )
              ]
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }


  // --- HELPERS ---
  pw.Widget _buildRowInfo(String l1, String v1, String l2, String v2) {
    return pw.Row(children: [
      pw.Expanded(child: pw.Row(children: [pw.Container(width: 80, child: pw.Text(l1)), pw.Text(v1)])),
      pw.Expanded(child: pw.Row(children: [pw.Container(width: 100, child: pw.Text(l2)), pw.Text(v2)])),
    ]);
  }

  pw.Widget _buildSimpleRow(String l, String v) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 2), child: pw.Row(children: [pw.Container(width: 100, child: pw.Text(l, style: const pw.TextStyle(fontSize: 10))), pw.Text(v, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))]));

  pw.Widget _buildCheckbox(String label, bool checked) {
    return pw.Row(children: [
      pw.Container(width: 12, height: 12, decoration: pw.BoxDecoration(border: pw.Border.all(), color: checked ? PdfColors.black : null)),
      pw.SizedBox(width: 5),
      pw.Text(label)
    ]);
  }

  pw.Widget _buildTableItem(String l, String v) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(l, style: const pw.TextStyle(fontSize: 9)), pw.Text(v, style: const pw.TextStyle(fontSize: 9))]);
  pw.Widget _buildSmallText(String t) => pw.Text(t, style: const pw.TextStyle(fontSize: 8));

  // Helper untuk Form Ijin
  pw.Widget _buildFormLine(String label, String value) {
    return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5),
        child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(width: 100, child: pw.Text(label)),
              pw.Text(":  "),
              pw.Expanded(child: pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            ]
        )
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Center(child: pw.Text(text, style: pw.TextStyle(fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal, fontSize: 10)))
    );
  }

  pw.TableRow _buildEmptyRow() {
    return pw.TableRow(children: [
      pw.Container(height: 20),
      pw.Container(height: 20),
      pw.Container(height: 20),
    ]);
  }
}