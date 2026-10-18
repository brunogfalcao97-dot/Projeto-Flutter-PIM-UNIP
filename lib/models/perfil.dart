/// Dados do cliente (GET /api/perfil).
class Perfil {
  const Perfil({
    required this.id,
    required this.nome,
    required this.email,
    required this.perfil,
    this.telefone,
  });

  final int id;
  final String nome;
  final String email;
  final String perfil;
  final String? telefone;

  factory Perfil.fromJson(Map<String, dynamic> json) => Perfil(
        id: (json['id'] as num).toInt(),
        nome: json['nome'].toString(),
        email: json['email'].toString(),
        perfil: json['perfil']?.toString() ?? 'Cliente',
        telefone: json['telefone']?.toString(),
      );
}
