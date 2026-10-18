import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

import '../config/api_config.dart';

/// Erro "amigável" vindo da API ou da conexão. A mensagem já pode ir direto para a tela.
/// [statusCode] é null quando nem chegou a haver resposta (sem internet, API desligada, tempo esgotado).
class ApiException implements Exception {
  ApiException(this.mensagem, {this.statusCode});

  final String mensagem;
  final int? statusCode;

  bool get semConexao => statusCode == null;

  @override
  String toString() => mensagem;
}

/// Cliente HTTP único do app: coloca o token JWT, trata erros e converte o JSON.
class ApiClient {
  ApiClient({this.tokenProvider, this.onSessaoExpirada});

  final String? Function()? tokenProvider;
  final void Function()? onSessaoExpirada;

  Uri _uri(String caminho) => Uri.parse('${ApiConfig.baseUrl}$caminho');

  Map<String, String> _cabecalhos({bool json = true}) {
    final token = tokenProvider?.call();
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Cabeçalho com o token, para baixar arquivos privados (ex.: Image.network da foto de um projeto).
  Map<String, String> get cabecalhosAutenticados {
    final token = tokenProvider?.call();
    return {if (token != null) 'Authorization': 'Bearer $token'};
  }

  Future<dynamic> get(String caminho) =>
      _enviar(() => http.get(_uri(caminho), headers: _cabecalhos()));

  Future<dynamic> post(String caminho, [Map<String, dynamic>? corpo]) => _enviar(
        () => http.post(_uri(caminho), headers: _cabecalhos(), body: jsonEncode(corpo ?? {})),
      );

  Future<dynamic> put(String caminho, [Map<String, dynamic>? corpo]) => _enviar(
        () => http.put(_uri(caminho), headers: _cabecalhos(), body: jsonEncode(corpo ?? {})),
      );

  Future<dynamic> delete(String caminho) =>
      _enviar(() => http.delete(_uri(caminho), headers: _cabecalhos()));

  /// Envia campos de formulário + uma imagem JPEG (multipart/form-data).
  Future<dynamic> postImagem(
    String caminho, {
    required Map<String, String> campos,
    required String campoArquivo,
    required List<int> bytes,
    required String nomeArquivo,
  }) {
    return _enviar(() async {
      final requisicao = http.MultipartRequest('POST', _uri(caminho))
        ..headers.addAll(_cabecalhos(json: false))
        ..fields.addAll(campos)
        ..files.add(http.MultipartFile.fromBytes(
          campoArquivo,
          bytes,
          filename: nomeArquivo,
          contentType: MediaType('image', 'jpeg'),
        ));
      return http.Response.fromStream(await requisicao.send());
    }, limite: const Duration(seconds: 60));
  }

  Future<dynamic> _enviar(
    Future<http.Response> Function() requisicao, {
    Duration limite = const Duration(seconds: 20),
  }) async {
    final http.Response resposta;
    try {
      resposta = await requisicao().timeout(limite);
    } on TimeoutException {
      throw ApiException('O servidor demorou demais para responder.');
    } catch (e) {
      debugPrint('Falha ao conectar em ${ApiConfig.baseUrl}: $e');
      throw ApiException(
        'Não foi possível conectar ao servidor. Verifique a internet e o endereço da API.',
      );
    }
    return _tratar(resposta);
  }

  dynamic _tratar(http.Response resposta) {
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      if (resposta.bodyBytes.isEmpty) return null;
      try {
        return jsonDecode(utf8.decode(resposta.bodyBytes));
      } on FormatException {
        return null;
      }
    }

    final tinhaToken = tokenProvider?.call() != null;
    if (resposta.statusCode == 401 && tinhaToken) {
      onSessaoExpirada?.call();
      throw ApiException('Sua sessão expirou. Faça login novamente.', statusCode: 401);
    }
    if (resposta.statusCode == 429) {
      throw ApiException('Muitas tentativas seguidas. Aguarde um minuto e tente de novo.', statusCode: 429);
    }
    throw ApiException(_mensagemDeErro(resposta), statusCode: resposta.statusCode);
  }

  String _mensagemDeErro(http.Response resposta) {
    try {
      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (dados is Map<String, dynamic>) {
        for (final chave in ['mensagem', 'message', 'detail']) {
          final valor = dados[chave];
          if (valor is String && valor.isNotEmpty) return valor;
        }
        // Erros de validação do ASP.NET: { "errors": { "Campo": ["mensagem"] } }
        final erros = dados['errors'];
        if (erros is Map && erros.isNotEmpty) {
          final primeiro = erros.values.first;
          if (primeiro is List && primeiro.isNotEmpty) return primeiro.first.toString();
        }
        if (erros is List && erros.isNotEmpty) return erros.first.toString();
      } else if (dados is String && dados.isNotEmpty) {
        return dados;
      }
    } catch (_) {
      // corpo não era JSON: cai nas mensagens padrão abaixo
    }

    switch (resposta.statusCode) {
      case 400:
        return 'Dados inválidos. Confira as informações e tente de novo.';
      case 401:
        return 'E-mail ou senha inválidos.';
      case 403:
        return 'Você não tem permissão para fazer isso.';
      case 404:
        return 'Recurso não encontrado na API.';
      case 409:
        return 'Os dados mudaram. Atualize e tente de novo.';
      default:
        return 'Erro no servidor (${resposta.statusCode}).';
    }
  }
}
