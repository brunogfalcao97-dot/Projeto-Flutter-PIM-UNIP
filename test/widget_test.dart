// Testes do algoritmo de pintura (o arquivo mantém o nome widget_test.dart para o
// `flutter create` não gerar o teste de exemplo do contador por cima).
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pim_tintas/utils/pintura.dart';

const _w = 100, _h = 100;

/// Metade esquerda = parede bege (com um furinho escuro 3x3), metade direita = objeto escuro.
Uint8List _imagemSintetica() {
  final px = Uint8List(_w * _h * 4);
  for (var y = 0; y < _h; y++) {
    for (var x = 0; x < _w; x++) {
      final o = (y * _w + x) * 4;
      final ruido = (x * 7 + y * 13) % 5;
      final parede = x < 50;
      px[o] = (parede ? 200 : 30) + ruido;
      px[o + 1] = (parede ? 190 : 30) + ruido;
      px[o + 2] = (parede ? 180 : 30) + ruido;
      px[o + 3] = 255;
    }
  }
  for (var y = 20; y <= 22; y++) {
    for (var x = 20; x <= 22; x++) {
      final o = (y * _w + x) * 4;
      px[o] = 20;
      px[o + 1] = 20;
      px[o + 2] = 20;
    }
  }
  return px;
}

Uint8List _selecionar() => selecionarParede(
      ParametrosSelecao(rgba: _imagemSintetica(), largura: _w, altura: _h, x: 10, y: 10, tolerancia: 40),
    );

void main() {
  test('selecionarParede pega só a parede e preenche furos pequenos', () {
    final mascara = _selecionar();
    expect(mascara[10 * _w + 10], 255); // dentro da parede
    expect(mascara[50 * _w + 90], 0); // objeto escuro, fora
    expect(mascara[21 * _w + 21], greaterThan(200)); // furinho 3x3 foi preenchido
  });

  test('pintarParede troca a cor da parede e preserva o resto', () {
    final jpg = pintarParede(
      ParametrosPintura(
        rgba: _imagemSintetica(),
        largura: _w,
        altura: _h,
        mascara: _selecionar(),
        corRgb: 0xCC2222,
        fatorContraste: 0.95,
      ),
    );

    final saida = img.decodeJpg(jpg)!;
    final parede = saida.getPixel(10, 10);
    expect(parede.r, greaterThan(parede.g + 60)); // ficou avermelhada
    final objeto = saida.getPixel(90, 50);
    expect(objeto.r, lessThan(60)); // objeto escuro não mudou
  });

  test('prepararImagem devolve dimensões e pixels RGBA coerentes', () {
    final png = img.encodePng(img.Image(width: 40, height: 30));
    final preparada = prepararImagem(Uint8List.fromList(png));
    expect(preparada.largura, 40);
    expect(preparada.altura, 30);
    expect(preparada.rgba.length, 40 * 30 * 4);
    expect(preparada.jpg, isNotEmpty);
  });
}
