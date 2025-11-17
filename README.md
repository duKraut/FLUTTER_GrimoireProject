# Grimório - Gerenciador de Coleção e Deck Builder Inteligente para Magic: The Gathering

Gerenciamento da sua coleção e construção de decks com inteligência.


**AVISOS**
> Se certifique que tenha o Flutter baixado e extraido na maquina e com as variaveis de ambiente corretamente configurados.
> Caso não tenha, [baixe aqui](https://docs.flutter.dev/install/manual)

>Tenha também o Node.js, recomendado a versão (LTS), pode [baixar aqui](https://nodejs.org/en/download)

> Este projeto utiliza Firebase para autenticação e banco de dados. Para rodar o projeto localmente, você **precisa** vincular ao seu próprio projeto Firebase.
> Atualmente, **somente a versão Web** está configurada com Firebase.
> Android e iOS possuem placeholders e precisam ser configurados manualmente para funcionar.
> A versão Web exige o uso da Google Chrome

# Tecnologias

* Flutter 3.9+
* Dart
* Provider (state management)
* Firebase (Web: Authentication + Firestore)

## Passo a passo para rodar o projeto

### 1) Clonar o repositório

```bash
git clone https://github.com/duKraut/FLUTTER_GrimoireProject.git
cd FLUTTER_GrimoireProject
```

### 2) Instalar dependências

```bash
flutter pub get
```

### 3) Configurar as Ferramentas CLI do Firebase

Vamos instalar as ferramentas de linha de comando (CLI) necessárias para ligar o projeto.

### Instale o Firebase CLI (via npm):

```bash
npm install -g firebase-tools
```

### Instale o FlutterFire CLI (via Dart):

```bash
dart pub global activate flutterfire_cli
```

### 4) Criar e Ligar o seu Projeto Firebase

### Crie o seu Projeto Firebase:

* Vá ao Console do Firebase.
* Clique em "Adicionar projeto" e dê-lhe um nome (ex: "MeuGrimorio").
* Importante: Não precisa de ativar o Google Analytics.

### Faça Login no Firebase:

* No seu terminal, faça login na sua conta Google:

```bash
firebase login
```

### Vincule o Flutter ao Firebase:

* No terminal, na raiz do seu projeto Flutter, rode o comando de configuração:

```bash
flutterfire configure
```

* O comando irá listar os seus projetos Firebase. Use as setas para selecionar o projeto que acabou de criar (ex: "MeuGrimorio").
* Ele perguntará para quais plataformas deseja registar. Selecione web.
* O comando irá sobrescrever o ficheiro lib/firebase_options.dart com as chaves de API do seu projeto. Isto é o que "vincula" o app.

### 5) Configurar os Serviços no Firebase

O seu app está vinculado, mas os serviços estão desligados. Vá ao console do seu projeto Firebase:

### Ativar Autenticação (Authentication):

* No menu "Criação" (Build), clique em Authentication.
* Clique em "Começar".
* Em "Sign-in method" (Método de login), clique em "Email/Senha".
* Ative o primeiro interruptor ("Email/Senha") e clique em Salvar.

### Ativar o Banco de Dados (Firestore):

* No menu "Criação", clique em Firestore Database.
* Clique em "Criar banco de dados".
* Selecione "Iniciar em modo de produção" (Production mode). Clique em "Próximo".
* Escolha uma localização para o servidor (southamerica-east1 (São Paulo)). **Clique em Ativar**.

### Configurar as Regras de Segurança (Obrigatório!):

* Dentro do Firestore, clique na aba "Regras".
* Apague todo o texto que lá está e substitua por estas regras:

```bash
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permite que um utilizador leia e escreva APENAS os seus próprios dados
    match /users/{userId}/{documents=**} {
      allow read, write: if request.auth.uid == userId;
    }
  }
}
```

### Clique em "Publicar".

### 6) Rodar o Aplicativo

Está tudo pronto! Como o projeto está configurado para a web, rode o seguinte comando:

```bash
flutter run -d chrome
```

O app irá abrir no Chrome. Pode agora criar uma nova conta (que será salva no seu banco de dados) e usar o aplicativo.



## 🔌 Documentação das Rotas e APIs

### API Scryfall

O projeto utiliza a API Scryfall (gratuita e sem autenticação necessária) para buscar informações das cartas Magic: The Gathering.

* Serviço: ScryfallService
* Arquivo: lib/api/scryfall_service.dart
* Classe: ScryfallService

### Método Principal:

```bash
Future<List<ScryfallCard>> searchCards(
  String query, {
  bool isCommanderSearch = false,
  List<String>? commanderIdentity,
})
```

Parâmetros:

* **query** (String): Termo de busca (obrigatório)
* **isCommanderSearch** (bool): Se deve filtrar apenas cartas de comandante
* **commanderIdentity** (List<String>?): Identificadores de cor para filtro (ex: ['U', 'B'])

### Exemplos de Uso:

```bash
// Buscar cartas simples
final cards = await scryfallService.searchCards('Black Lotus');

// Buscar comandantes azuis
final blueCommanders = await scryfallService.searchCards('', 
  isCommanderSearch: true, 
  commanderIdentity: ['U']
);

// Buscar cartas com filtros complexos
final cards = await scryfallService.searchCards('type:creature power>3');
```

### Retorno:

* Lista de objetos ScryfallCard contendo informações das cartas

### Modelo de Dados: *ScryfallCard*

Arquivo: lib/models/scryfall_card.dart

```bash
class ScryfallCard {
  final String id;                      // ID único da carta
  final String name;                    // Nome da carta
  final String typeLine;                // Tipo de carta (ex: "Creature — Elf")
  final String? oracleText;             // Texto do efeito
  final String? imageUrlNormal;         // URL da imagem normal
  final String? imageUrlSmall;          // URL da imagem pequena
  final String? artCrop;                // URL da arte recortada
  final List<String> colorIdentity;     // Identificadores de cor (W, U, B, R, G)
}
```

### Factory Method:

```bash
factory ScryfallCard.fromScryfallJson(Map<String, dynamic> json)
```
Converte JSON da API Scryfall para objeto ScryfallCard. Trata automaticamente cartas com múltiplas faces.



### 🔑 Providers (Gerenciamento de Estado)

O projeto utiliza Riverpod para gerenciamento de estado.

### AuthProvider

```bash
// Provider de autenticação
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>(...)
```

### ScryfallProvider

```bash
// Provider de busca de cartas
final scryfallSearchProvider = FutureProvider<List<ScryfallCard>>((ref) async {
  // Implementação de busca
})
```

### DeckProvider

```bash
// Provider de gerenciamento de decks
final deckProvider = StateNotifierProvider<DeckNotifier, List<Deck>>(...)
```
