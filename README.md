# PIM Tintas — App Flutter (FixTintas)

Aplicativo do PIM (UNIP) que conversa com a API ASP.NET (.NET 10 + SQL Server) da loja.
O cliente fotografa o ambiente, toca na parede e vê como ela ficaria com a cor e o tipo de tinta
escolhidos; também calcula quanto de tinta comprar, monta o carrinho e faz pedidos.

> **Status:** o código foi escrito mas **ainda não foi compilado nem testado em um aparelho**
> (o ambiente onde foi gerado não tinha o Flutter SDK). Rode `flutter pub get`, `flutter analyze`
> e `flutter test` assim que abrir e corrija o que aparecer.

## Divisão de responsabilidades

**A API é a fonte da verdade.** O app não tem nenhuma regra de negócio.

| API (.NET / SQL Server) | App (Flutter) |
|---|---|
| Catálogo: cores (HEX/RGB/Pantone), marcas, tipos e acabamentos, produtos, preço e estoque | Telas, navegação, animações |
| Cálculo de litros por m², perda, demãos e combinação de latas mais barata | Câmera e pintura da parede (flood fill + HSL, roda no aparelho) |
| Descontos por volume, cupons, total do pedido, validação de estoque | Cache local (`shared_preferences`): catálogo e carrinho |
| Pedidos e histórico de compras, status e cancelamento | Chamadas HTTP (`http`) com o token JWT |
| Perfil, favoritos, projetos (fotos privadas) | Guarda o token no armazenamento seguro |
| Login, senha, JWT, perfis Cliente/Admin | Só esconde/mostra botões; a permissão de verdade é checada na API |

Valores de preço, desconto, litros e total que aparecem na tela **sempre vêm da API**.
Os formatadores em `lib/utils/formatar.dart` só transformam números em texto (`R$ 1.234,50`).

## Como rodar

Dentro desta pasta:

```bash
# 1. Gera as pastas android/, ios/ etc. (não sobrescreve o que já existe em lib/ e test/)
flutter create --org br.com.unip --project-name pim_tintas .

# 2. Baixa as dependências
flutter pub get

# 3. Testes (pintura e modelos)
flutter test

# 4. Roda (com a API ligada)
flutter run
```

### Endereço da API

Por padrão o app usa `http://10.0.2.2:5000` no emulador Android e `http://localhost:5000` nos demais.
Ajuste a porta em `lib/config/api_config.dart` (`portaLocal`) ou passe o endereço na hora de rodar:

```bash
flutter run --dart-define=API_URL=http://192.168.0.10:5000
```

Em celular real, use o IP do PC na rede Wi-Fi e deixe a API escutando nele
(`dotnet run --urls "http://0.0.0.0:5000"`) e o firewall liberado.

### Ajustes nativos (depois do `flutter create`)

**Android** — `android/app/src/main/AndroidManifest.xml`, dentro de `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

e na tag `<application ...>` (só enquanto a API for `http://`, sem HTTPS):

```xml
android:usesCleartextTraffic="true"
```

`flutter_secure_storage` exige `minSdk` 23 em `android/app/build.gradle(.kts)`.

**iOS** — `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Usamos a câmera para fotografar o ambiente que será pintado.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Usamos suas fotos para simular a cor da tinta.</string>
```

## Telas

- **Início:** tirar foto / galeria e atalhos. Catálogo, calculadora e simulação funcionam **sem login**.
- **Simular cor:** toque na parede, escolha cor e tipo de tinta; na barra de cima: favoritar, calcular
  quantidade, comprar essa cor e carrinho. Salvar pede login e um nome para o projeto.
- **Comprar tintas:** produtos com preço e estoque da API; escolhe a cor e adiciona ao carrinho.
- **Calculadora:** altura × largura (ou m²), desconto de portas/janelas, tipo e demãos → a API devolve
  litros e as opções de latas mais baratas por marca.
- **Carrinho:** orçamento da API a cada mudança (subtotal, desconto por volume, cupom, total).
  Finalizar pede login.
- **Meus pedidos / detalhe:** histórico; o botão cancelar só aparece quando a API diz que pode.
- **Favoritas, Meus projetos, Meu perfil:** dados da conta, na API. As fotos dos projetos são privadas
  e baixadas com o token.

A área de administração (catálogo, estoque, cupons, status de pedidos) é usada pela documentação da API
(Scalar), não há tela de admin no app.

## Cache local

`lib/services/cache_local.dart` guarda cópias do catálogo (cores, tipos, marcas) por 10 minutos para o
app abrir mais rápido, e usa a última cópia se a API estiver fora do ar. Produtos (preço e estoque)
sempre vêm da API quando há conexão. O carrinho fica no aparelho (produto, cor e quantidade);
nada sensível é guardado ali.

## Como funciona a pintura (para a apresentação)

Tudo roda no aparelho, sem internet e sem IA, em `lib/utils/pintura.dart`:

1. **Preparar:** decodifica a foto, corrige a rotação (EXIF) e reduz para no máximo 1080 px.
2. **Selecionar a parede:** a partir do toque, um *flood fill* espalha pelos pixels de cor parecida.
   A "sensibilidade" (slider) é a tolerância de cor. O algoritmo também acompanha degradês de luz
   sem vazar para outros objetos, preenche furinhos causados por ruído da câmera e suaviza a borda.
3. **Pintar:** em cada pixel da parede troca o **matiz e a saturação** pelos da tinta e mantém a
   **luz e a sombra originais** (a luminosidade da tinta é multiplicada pela razão de luz do pixel).
4. **Tipo de tinta:** o quanto do sombreamento original é mantido (`fatorContraste`) vem da API
   por tipo de tinta. É uma aproximação visual, não uma simulação física.

As etapas rodam em outra thread (`compute`) para a tela não travar.

## Estrutura

```
lib/
  main.dart                  # providers e tema
  config/                    # endereço da API, tema, marca
  models/                    # Cor, TipoTinta, Produto, CalculoTinta, Pedido, Simulacao, Perfil
  services/                  # ApiClient (JWT, erros), um serviço por área da API, CacheLocal
  providers/                 # sessão (auth), carrinho, favoritos
  screens/                   # telas
  widgets/                   # logo, seletor de cor, botão do carrinho, estados vazios/erros
  utils/                     # pintura.dart (visual) e formatar.dart (texto)
test/
  widget_test.dart           # algoritmo de pintura
  modelos_test.dart          # leitura do JSON da API e formatadores
```

## Limitações conhecidas

- A seleção é por cor: paredes com sombras muito fortes, ou de cor parecida com o teto/móveis, podem
  exigir ajustar o slider ou tocar em outro ponto da parede.
- Cada toque substitui a seleção anterior: só uma parede por vez.
- A cor na tela depende do brilho do celular; é uma simulação aproximada.
- Pagamento não está implementado: o pedido fica como "Pendente" na API.
