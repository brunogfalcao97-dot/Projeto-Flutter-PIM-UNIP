// Formatadores só de apresentação (texto na tela). Nenhuma regra de negócio mora aqui:
// preços, descontos e litros chegam prontos da API.

/// 1234.5 vira "R$ 1.234,50".
String moeda(num valor) {
  final negativo = valor < 0;
  final centavos = (valor.abs() * 100).round();
  final reais = centavos ~/ 100;
  final resto = centavos % 100;

  final digitos = reais.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digitos.length; i++) {
    if (i > 0 && (digitos.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digitos[i]);
  }
  return '${negativo ? '-' : ''}R\$ $buffer,${resto.toString().padLeft(2, '0')}';
}

/// Número com até duas casas e vírgula, sem zeros sobrando: 18 vira "18", 3.6 vira "3,6".
String numero(num valor) {
  var texto = valor.toStringAsFixed(2);
  texto = texto.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  return texto.replaceAll('.', ',');
}

/// 0.9 vira "0,9 L".
String litros(num valor) => '${numero(valor)} L';

/// 12.5 vira "12,5 m²".
String metrosQuadrados(num valor) => '${numero(valor)} m²';

/// "15/10/2026 21:04", no horário do aparelho.
String dataHora(DateTime data) {
  final d = data.toLocal();
  String dois(int n) => n.toString().padLeft(2, '0');
  return '${dois(d.day)}/${dois(d.month)}/${d.year} ${dois(d.hour)}:${dois(d.minute)}';
}

/// Aceita "2,5" ou "2.5". Devolve null se não for um número.
double? lerNumero(String texto) {
  final limpo = texto.trim().replaceAll(',', '.');
  if (limpo.isEmpty) return null;
  return double.tryParse(limpo);
}
