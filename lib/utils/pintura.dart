import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

// ---------------------------------------------------------------------------
// Algoritmo de "pintar a parede" (100% em Dart, sem internet e sem IA).
//
// São três etapas, todas feitas em funções de nível superior para rodarem em
// outra thread com `compute(...)` e não travarem a tela:
//
//   1. prepararImagem  -> decodifica a foto, corrige a rotação e reduz o tamanho
//   2. selecionarParede -> a partir do toque, acha os pixels da parede (flood fill)
//   3. pintarParede    -> troca matiz/saturação pela cor da tinta e MANTÉM a luz
//                         e a sombra originais, para parecer tinta e não adesivo
//
// Os parâmetros são classes simples (só números e listas de bytes) para poderem
// ser enviadas entre threads.
// ---------------------------------------------------------------------------

/// Foto já pronta para processar: pixels RGBA (4 bytes por pixel) e um JPEG para exibir.
class ImagemPreparada {
  const ImagemPreparada(this.largura, this.altura, this.rgba, this.jpg);

  final int largura;
  final int altura;
  final Uint8List rgba;
  final Uint8List jpg;
}

class ParametrosSelecao {
  const ParametrosSelecao({
    required this.rgba,
    required this.largura,
    required this.altura,
    required this.x,
    required this.y,
    required this.tolerancia,
  });

  final Uint8List rgba;
  final int largura;
  final int altura;

  /// Pixel tocado pelo usuário.
  final int x;
  final int y;

  /// Distância máxima de cor (RGB, 0 a 441) para um pixel contar como "mesma parede".
  final double tolerancia;
}

class ParametrosPintura {
  const ParametrosPintura({
    required this.rgba,
    required this.largura,
    required this.altura,
    required this.mascara,
    required this.corRgb,
    required this.fatorContraste,
  });

  final Uint8List rgba;
  final int largura;
  final int altura;

  /// Máscara 0..255 devolvida por [selecionarParede] (255 = parede).
  final Uint8List mascara;

  /// Cor da tinta no formato 0xRRGGBB.
  final int corRgb;

  /// Quanto do sombreamento original é mantido (fosco < acetinado < brilhante).
  final double fatorContraste;
}

const _dx = [-1, 1, 0, 0];
const _dy = [0, 0, -1, 1];

int _lim(int v, int min, int max) => v < min ? min : (v > max ? max : v);

int _dist2(int r1, int g1, int b1, int r2, int g2, int b2) {
  final dr = r1 - r2, dg = g1 - g2, db = b1 - b2;
  return dr * dr + dg * dg + db * db;
}

// ---------------------------------------------------------------------------
// 1) Preparar a imagem
// ---------------------------------------------------------------------------

/// Maior lado da imagem de trabalho. Fotos de celular têm 4000+ pixels; reduzir
/// para ~1080 deixa o processamento rápido e o upload leve.
const int ladoMaximo = 1080;

ImagemPreparada prepararImagem(Uint8List bytes) {
  final decodificada = img.decodeImage(bytes);
  if (decodificada == null) {
    throw const FormatException('Não foi possível ler a imagem.');
  }

  // Fotos de celular vêm "deitadas" com uma flag de rotação (EXIF): aplica de verdade.
  var imagem = img.bakeOrientation(decodificada);

  if (imagem.width > ladoMaximo || imagem.height > ladoMaximo) {
    imagem = imagem.width >= imagem.height
        ? img.copyResize(imagem, width: ladoMaximo, interpolation: img.Interpolation.linear)
        : img.copyResize(imagem, height: ladoMaximo, interpolation: img.Interpolation.linear);
  }

  final rgb = imagem.convert(numChannels: 3);
  final rgba = imagem.convert(numChannels: 4);

  return ImagemPreparada(
    imagem.width,
    imagem.height,
    Uint8List.fromList(rgba.getBytes(order: img.ChannelOrder.rgba)),
    Uint8List.fromList(img.encodeJpg(rgb, quality: 88)),
  );
}

// ---------------------------------------------------------------------------
// 2) Selecionar a parede a partir do toque
// ---------------------------------------------------------------------------

Uint8List selecionarParede(ParametrosSelecao p) {
  final w = p.largura, h = p.altura, px = p.rgba;
  final total = w * h;

  // Cor da semente: média de uma janela 5x5 em volta do toque (evita pegar um pixel "sujo").
  var somaR = 0, somaG = 0, somaB = 0, qtd = 0;
  for (var dy = -2; dy <= 2; dy++) {
    for (var dx = -2; dx <= 2; dx++) {
      final xx = _lim(p.x + dx, 0, w - 1);
      final yy = _lim(p.y + dy, 0, h - 1);
      final o = (yy * w + xx) * 4;
      somaR += px[o];
      somaG += px[o + 1];
      somaB += px[o + 2];
      qtd++;
    }
  }
  final r0 = somaR ~/ qtd, g0 = somaG ~/ qtd, b0 = somaB ~/ qtd;

  // Regras para um pixel vizinho entrar na parede:
  //  a) está perto da cor da semente (tolerância), OU
  //  b) está um pouco mais longe da semente (até 1,8x) mas é quase igual ao pixel
  //     de onde veio. Isso acompanha degradês de luz sem vazar para outros objetos.
  final tolSemente = p.tolerancia * p.tolerancia;
  final tolLimite = (p.tolerancia * 1.8) * (p.tolerancia * 1.8);
  final tolVizinho = math.max(4.0, p.tolerancia * 0.25);
  final tolVizinho2 = tolVizinho * tolVizinho;

  final mascara = Uint8List(total);
  final pilha = Int32List(total); // cada pixel entra na pilha no máximo uma vez
  var topo = 0;

  final inicio = _lim(p.y, 0, h - 1) * w + _lim(p.x, 0, w - 1);
  mascara[inicio] = 1;
  pilha[topo++] = inicio;

  while (topo > 0) {
    final atual = pilha[--topo];
    final cx = atual % w, cy = atual ~/ w;
    final oa = atual * 4;
    final ar = px[oa], ag = px[oa + 1], ab = px[oa + 2];

    for (var d = 0; d < 4; d++) {
      final nx = cx + _dx[d], ny = cy + _dy[d];
      if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
      final n = ny * w + nx;
      if (mascara[n] != 0) continue;

      final on = n * 4;
      final nr = px[on], ng = px[on + 1], nb = px[on + 2];

      final distSemente = _dist2(nr, ng, nb, r0, g0, b0);
      var aceito = distSemente <= tolSemente;
      if (!aceito && distSemente <= tolLimite) {
        aceito = _dist2(nr, ng, nb, ar, ag, ab) <= tolVizinho2;
      }
      if (aceito) {
        mascara[n] = 1;
        pilha[topo++] = n;
      }
    }
  }

  // Ruído da câmera deixa "furinhos" na seleção: preenche os pequenos.
  // Objetos maiores (quadros, tomadas grandes, janelas) continuam de fora.
  _preencherBuracos(mascara, w, h, math.max(30, (total * 0.001).round()));

  // Borda suave (0..255) para a tinta não ficar com serrilhado.
  final fonte = Uint8List(total);
  for (var i = 0; i < total; i++) {
    if (mascara[i] != 0) fonte[i] = 255;
  }
  return _desfocar(fonte, w, h, 2);
}

/// Preenche regiões "fora da parede" com no máximo [limite] pixels.
void _preencherBuracos(Uint8List mascara, int w, int h, int limite) {
  final total = w * h;
  final visto = Uint8List(total);
  final pilha = Int32List(total);
  final membros = Int32List(limite + 1);

  for (var i = 0; i < total; i++) {
    if (mascara[i] != 0 || visto[i] != 0) continue;

    var topo = 0, qtd = 0;
    pilha[topo++] = i;
    visto[i] = 1;

    while (topo > 0) {
      final atual = pilha[--topo];
      if (qtd <= limite) membros[qtd] = atual;
      qtd++;

      final cx = atual % w, cy = atual ~/ w;
      for (var d = 0; d < 4; d++) {
        final nx = cx + _dx[d], ny = cy + _dy[d];
        if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
        final n = ny * w + nx;
        if (mascara[n] != 0 || visto[n] != 0) continue;
        visto[n] = 1;
        pilha[topo++] = n;
      }
    }

    if (qtd <= limite) {
      for (var k = 0; k < qtd; k++) {
        mascara[membros[k]] = 1;
      }
    }
  }
}

/// Desfoque de caixa (box blur) separável, raio [r].
Uint8List _desfocar(Uint8List origem, int w, int h, int r) {
  final tmp = Uint8List(w * h);
  final saida = Uint8List(w * h);
  final janela = 2 * r + 1;

  for (var y = 0; y < h; y++) {
    final base = y * w;
    var soma = 0;
    for (var k = -r; k <= r; k++) {
      soma += origem[base + _lim(k, 0, w - 1)];
    }
    for (var x = 0; x < w; x++) {
      tmp[base + x] = soma ~/ janela;
      soma += origem[base + _lim(x + r + 1, 0, w - 1)] - origem[base + _lim(x - r, 0, w - 1)];
    }
  }

  for (var x = 0; x < w; x++) {
    var soma = 0;
    for (var k = -r; k <= r; k++) {
      soma += tmp[_lim(k, 0, h - 1) * w + x];
    }
    for (var y = 0; y < h; y++) {
      saida[y * w + x] = soma ~/ janela;
      soma += tmp[_lim(y + r + 1, 0, h - 1) * w + x] - tmp[_lim(y - r, 0, h - 1) * w + x];
    }
  }
  return saida;
}

// ---------------------------------------------------------------------------
// 3) Pintar
// ---------------------------------------------------------------------------

/// Devolve a foto inteira (JPEG) com a parede pintada.
///
/// Para cada pixel da parede:
///   - matiz e saturação vêm da tinta;
///   - a luminosidade é a da tinta multiplicada pela "razão de luz" do pixel
///     (quão mais claro/escuro ele era em relação à média da parede), elevada ao
///     [ParametrosPintura.fatorContraste]. É isso que mantém sombras, reflexos
///     e a textura da parede visíveis por baixo da cor nova.
Uint8List pintarParede(ParametrosPintura p) {
  final total = p.largura * p.altura;
  final px = p.rgba, mascara = p.mascara;

  // Luminosidade média da parede original.
  var somaY = 0.0;
  var qtd = 0;
  for (var i = 0; i < total; i++) {
    if (mascara[i] >= 128) {
      final o = i * 4;
      somaY += 0.299 * px[o] + 0.587 * px[o + 1] + 0.114 * px[o + 2];
      qtd++;
    }
  }

  final saida = Uint8List.fromList(px);

  if (qtd > 0) {
    final yMedio = math.max(somaY / qtd / 255, 0.05);
    final tinta = _rgbParaHsl((p.corRgb >> 16) & 255, (p.corRgb >> 8) & 255, p.corRgb & 255);

    for (var i = 0; i < total; i++) {
      final a = mascara[i];
      if (a == 0) continue;

      final o = i * 4;
      final r = px[o], g = px[o + 1], b = px[o + 2];

      final y = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
      final razao = math.min(2.0, math.max(0.3, y / yMedio));
      final fator = math.pow(razao, p.fatorContraste).toDouble();
      final luz = math.min(0.98, math.max(0.02, tinta.l * fator));

      final rgb = _hslParaRgb(tinta.h, tinta.s, luz);
      final nr = (rgb >> 16) & 255, ng = (rgb >> 8) & 255, nb = rgb & 255;

      if (a == 255) {
        saida[o] = nr;
        saida[o + 1] = ng;
        saida[o + 2] = nb;
      } else {
        // Borda: mistura a tinta com a foto original.
        final inv = 255 - a;
        saida[o] = (r * inv + nr * a) ~/ 255;
        saida[o + 1] = (g * inv + ng * a) ~/ 255;
        saida[o + 2] = (b * inv + nb * a) ~/ 255;
      }
    }
  }

  final imagem = img.Image.fromBytes(
    width: p.largura,
    height: p.altura,
    bytes: saida.buffer,
    numChannels: 4,
  );
  return Uint8List.fromList(img.encodeJpg(imagem.convert(numChannels: 3), quality: 88));
}

/// RGB (0..255) -> HSL com h em graus (0..360), s e l entre 0 e 1.
({double h, double s, double l}) _rgbParaHsl(int r, int g, int b) {
  final rf = r / 255, gf = g / 255, bf = b / 255;
  final mx = math.max(rf, math.max(gf, bf));
  final mn = math.min(rf, math.min(gf, bf));
  final l = (mx + mn) / 2;
  final d = mx - mn;

  var h = 0.0, s = 0.0;
  if (d != 0) {
    s = d / (1 - (2 * l - 1).abs());
    if (mx == rf) {
      h = 60 * (((gf - bf) / d) % 6);
    } else if (mx == gf) {
      h = 60 * ((bf - rf) / d + 2);
    } else {
      h = 60 * ((rf - gf) / d + 4);
    }
    if (h < 0) h += 360;
  }
  return (h: h, s: s, l: l);
}

/// HSL -> inteiro 0xRRGGBB.
int _hslParaRgb(double h, double s, double l) {
  final c = (1 - (2 * l - 1).abs()) * s;
  final hp = h / 60;
  final x = c * (1 - (hp % 2 - 1).abs());

  var r1 = 0.0, g1 = 0.0, b1 = 0.0;
  if (hp < 1) {
    r1 = c;
    g1 = x;
  } else if (hp < 2) {
    r1 = x;
    g1 = c;
  } else if (hp < 3) {
    g1 = c;
    b1 = x;
  } else if (hp < 4) {
    g1 = x;
    b1 = c;
  } else if (hp < 5) {
    r1 = x;
    b1 = c;
  } else {
    r1 = c;
    b1 = x;
  }

  final m = l - c / 2;
  final r = _lim(((r1 + m) * 255).round(), 0, 255);
  final g = _lim(((g1 + m) * 255).round(), 0, 255);
  final b = _lim(((b1 + m) * 255).round(), 0, 255);
  return (r << 16) | (g << 8) | b;
}
