// Testes dos modelos (leitura do JSON da API) e dos formatadores de texto.
// O app não calcula preço nem litros: aqui só se confere que o que a API manda é lido e exibido certo.
import 'package:flutter_test/flutter_test.dart';
import 'package:pim_tintas/models/calculo_tinta.dart';
import 'package:pim_tintas/models/cor.dart';
import 'package:pim_tintas/models/pedido.dart';
import 'package:pim_tintas/models/tipo_tinta.dart';
import 'package:pim_tintas/utils/formatar.dart';

void main() {
  group('formatar', () {
    test('moeda usa milhar com ponto e centavos com vírgula', () {
      expect(moeda(1234.5), 'R\$ 1.234,50');
      expect(moeda(0), 'R\$ 0,00');
      expect(moeda(99.999), 'R\$ 100,00');
    });

    test('numero tira zeros sobrando', () {
      expect(numero(18), '18');
      expect(numero(3.6), '3,6');
      expect(numero(0.9), '0,9');
    });

    test('lerNumero aceita vírgula e ponto', () {
      expect(lerNumero('2,5'), 2.5);
      expect(lerNumero('2.5'), 2.5);
      expect(lerNumero(''), isNull);
      expect(lerNumero('abc'), isNull);
    });
  });

  group('Cor', () {
    test('usa o rgb enviado pela API', () {
      final cor = Cor.fromJson({
        'id': 1,
        'nome': 'Azul',
        'codigoHex': '#1A2A6C',
        'rgb': {'r': 26, 'g': 42, 'b': 108},
      });
      expect(cor.rgb, 0x1A2A6C);
    });

    test('calcula o rgb a partir do HEX quando a API não manda', () {
      final cor = Cor.fromJson({'id': 2, 'nome': 'Branco', 'codigoHex': '#FFF'});
      expect(cor.rgb, 0xFFFFFF);
    });

    test('HEX inválido vira preto sem lançar erro', () {
      expect(hexParaRgb('xyz'), 0);
    });
  });

  test('TipoTinta lê os números técnicos da API', () {
    final tipo = TipoTinta.fromJson({
      'id': 3,
      'nome': 'Premium',
      'acabamento': 'Acetinado',
      'rendimentoM2PorLitro': 10,
      'demaosRecomendadas': 3,
      'fatorContraste': 0.9,
    });
    expect(tipo.rendimentoM2PorLitro, 10);
    expect(tipo.demaosRecomendadas, 3);
    expect(tipo.fatorContraste, 0.9);
    expect(tipo.rotulo, 'Premium · Acetinado');
  });

  group('ItemCarrinho', () {
    const item = ItemCarrinho(
      produtoId: 5,
      corId: 7,
      quantidade: 2,
      descricao: 'Tinta 18 L',
      corNome: 'Azul',
      corHex: '#1A2A6C',
    );

    test('ida e volta em JSON (cache local)', () {
      final copia = ItemCarrinho.fromJson(item.toJson());
      expect(copia.produtoId, 5);
      expect(copia.corId, 7);
      expect(copia.quantidade, 2);
      expect(copia.corNome, 'Azul');
    });

    test('para a API só vão produto, cor e quantidade', () {
      expect(item.paraApi(), {'produtoId': 5, 'corId': 7, 'quantidade': 2});
    });

    test('mesmoItem compara produto e cor', () {
      expect(item.mesmoItem(5, 7), isTrue);
      expect(item.mesmoItem(5, 8), isFalse);
      expect(item.comQuantidade(9).quantidade, 9);
    });
  });

  test('Orcamento acha a linha do item do carrinho', () {
    final orcamento = Orcamento.fromJson({
      'itens': [
        {
          'produtoId': 5,
          'produtoDescricao': 'Tinta 18 L',
          'volumeLitros': 18,
          'corId': 7,
          'corNome': 'Azul',
          'corHex': '#1A2A6C',
          'quantidade': 2,
          'precoUnitario': 100.0,
          'total': 200.0,
        }
      ],
      'litrosTotais': 36,
      'subtotal': 200.0,
      'descontoVolume': 0,
      'descontoCupom': 20.0,
      'total': 180.0,
      'cupom': 'BEMVINDO10',
    });

    const item = ItemCarrinho(
      produtoId: 5,
      corId: 7,
      quantidade: 2,
      descricao: '',
      corNome: '',
      corHex: '#000000',
    );
    expect(orcamento.linhaDe(item)?.total, 200.0);
    expect(orcamento.total, 180.0);
    expect(orcamento.cupom, 'BEMVINDO10');
  });

  test('CalculoTinta lê a resposta da API', () {
    final calculo = CalculoTinta.fromJson({
      'areaBrutaM2': 12,
      'areaDescontadaM2': 2,
      'areaLiquidaM2': 10,
      'demaos': 2,
      'rendimentoM2PorLitro': 10,
      'margemPerdaPercentual': 10,
      'litrosNecessarios': 2.2,
      'tipoTintaNome': 'Premium',
      'opcoes': [
        {
          'marcaId': 1,
          'marcaNome': 'FixTintas',
          'itens': [
            {
              'produtoId': 5,
              'sku': 'FX-36',
              'descricao': 'Tinta 3,6 L',
              'volumeLitros': 3.6,
              'quantidade': 1,
              'precoUnitario': 80,
              'subtotal': 80,
            }
          ],
          'litrosComprados': 3.6,
          'sobraLitros': 1.4,
          'total': 80,
        }
      ],
    });
    expect(calculo.litrosNecessarios, 2.2);
    expect(calculo.aviso, isNull);
    expect(calculo.opcoes.single.itens.single.quantidade, 1);
  });
}
