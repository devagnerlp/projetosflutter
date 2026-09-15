import 'package:flutter/material.dart';

void main() {
  runApp(const GabGradingApp());
}

/* ============================================================
   MODELOS
============================================================ */

class Usuario {
  final String id;
  String nome;
  final String email;
  final String senha;
  bool ativo;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.senha,
    required this.ativo,
  });
}

class Questao {
  final String id;
  int numeroQuestao;
  String alternativaCorreta;
  String? conteudo;
  final String simuladoId;
  bool persistida;

  Questao({
    required this.id,
    required this.numeroQuestao,
    required this.alternativaCorreta,
    required this.conteudo,
    required this.simuladoId,
    this.persistida = true,
  });
}

class Simulado {
  final String id;
  String identificacao;
  DateTime dataAplicacao;
  final String usuarioId;
  bool ativo;
  List<Questao> questoes;

  Simulado({
    required this.id,
    required this.identificacao,
    required this.dataAplicacao,
    required this.usuarioId,
    required this.ativo,
    required this.questoes,
  });
}

/* ============================================================
   ESTADO LOCAL
============================================================ */

class AppState extends ChangeNotifier {
  final List<Usuario> usuarios = [];
  final List<Simulado> simulados = [];

  Usuario? usuarioAutenticado;

  AppState() {
    _criarDadosFicticios();
  }

  void _criarDadosFicticios() {
    final joao = Usuario(
      id: 'user-1',
      nome: 'João Silva',
      email: 'usuario@escola.com',
      senha: '123456',
      ativo: true,
    );

    usuarios.add(joao);

    simulados.addAll([
      Simulado(
        id: 'sim-1',
        identificacao: 'Simulado ENEM — Linguagens',
        dataAplicacao: DateTime(2026, 5, 15),
        usuarioId: joao.id,
        ativo: true,
        questoes: [
          _questao('sim-1', 1, 'B', 'Interpretação de texto'),
          _questao('sim-1', 2, 'D', 'Gêneros textuais'),
          _questao('sim-1', 3, 'A', 'Variação linguística'),
          _questao('sim-1', 4, 'C', 'Literatura brasileira'),
        ],
      ),
      Simulado(
        id: 'sim-2',
        identificacao: 'Avaliação Diagnóstica de Matemática',
        dataAplicacao: DateTime(2026, 5, 22),
        usuarioId: joao.id,
        ativo: true,
        questoes: [
          _questao('sim-2', 1, 'A', 'Operações básicas'),
          _questao('sim-2', 2, 'C', 'Equações do primeiro grau'),
          _questao('sim-2', 3, 'E', 'Geometria plana'),
        ],
      ),
      Simulado(
        id: 'sim-3',
        identificacao: 'Simulado Preparatório — Ciências Humanas',
        dataAplicacao: DateTime(2026, 6, 5),
        usuarioId: joao.id,
        ativo: true,
        questoes: [
          _questao('sim-3', 1, 'E', 'História do Brasil'),
          _questao('sim-3', 2, 'B', 'Geografia urbana'),
          _questao('sim-3', 3, 'D', 'Filosofia antiga'),
          _questao('sim-3', 4, 'A', 'Sociologia'),
          _questao('sim-3', 5, 'C', 'Cartografia'),
        ],
      ),
    ]);
  }

  Questao _questao(
    String simuladoId,
    int numero,
    String alternativa,
    String conteudo,
  ) {
    return Questao(
      id: '$simuladoId-q$numero',
      numeroQuestao: numero,
      alternativaCorreta: alternativa,
      conteudo: conteudo,
      simuladoId: simuladoId,
    );
  }

  Usuario? buscarUsuarioPorEmail(String email) {
    final normalizado = email.trim().toLowerCase();

    for (final usuario in usuarios) {
      if (usuario.email.toLowerCase() == normalizado) {
        return usuario;
      }
    }

    return null;
  }

  String? cadastrarUsuario({
    required String nome,
    required String email,
    required String senha,
  }) {
    if (buscarUsuarioPorEmail(email) != null) {
      return 'Já existe uma conta cadastrada com este e-mail.';
    }

    usuarios.add(
      Usuario(
        id: 'user-${DateTime.now().microsecondsSinceEpoch}',
        nome: nome.trim(),
        email: email.trim().toLowerCase(),
        senha: senha,
        ativo: true,
      ),
    );

    notifyListeners();
    return null;
  }

  String? login(String email, String senha) {
    final usuario = buscarUsuarioPorEmail(email);

    if (usuario == null || usuario.senha != senha) {
      return 'E-mail ou senha incorretos.';
    }

    if (!usuario.ativo) {
      return 'Esta conta está inativa e não pode acessar o sistema.';
    }

    usuarioAutenticado = usuario;
    notifyListeners();
    return null;
  }

  void logout() {
    usuarioAutenticado = null;
    notifyListeners();
  }

  void atualizarNomeUsuario(String nome) {
    usuarioAutenticado?.nome = nome.trim();
    notifyListeners();
  }

  void desativarConta() {
    usuarioAutenticado?.ativo = false;
    usuarioAutenticado = null;
    notifyListeners();
  }

  List<Simulado> get simuladosDoUsuario {
    final usuario = usuarioAutenticado;

    if (usuario == null) {
      return [];
    }

    return simulados
        .where((simulado) =>
            simulado.usuarioId == usuario.id && simulado.ativo)
        .toList();
  }

  Simulado? buscarSimuladoSeguro(String id) {
    final usuario = usuarioAutenticado;

    if (usuario == null) {
      return null;
    }

    for (final simulado in simulados) {
      if (simulado.id == id &&
          simulado.usuarioId == usuario.id &&
          simulado.ativo) {
        return simulado;
      }
    }

    return null;
  }

  void salvarSimulado({
    Simulado? existente,
    required String identificacao,
    required DateTime dataAplicacao,
    required List<Questao> questoes,
  }) {
    final usuario = usuarioAutenticado;

    if (usuario == null) {
      return;
    }

    final id = existente?.id ?? 'sim-${DateTime.now().microsecondsSinceEpoch}';

    for (var i = 0; i < questoes.length; i++) {
      questoes[i].numeroQuestao = i + 1;
      questoes[i].persistida = true;
    }

    final simulado = existente ??
        Simulado(
          id: id,
          identificacao: identificacao,
          dataAplicacao: dataAplicacao,
          usuarioId: usuario.id,
          ativo: true,
          questoes: [],
        );

    simulado.identificacao = identificacao;
    simulado.dataAplicacao = dataAplicacao;
    simulado.questoes = questoes;

    if (existente == null) {
      simulados.add(simulado);
    }

    notifyListeners();
  }

  void excluirSimulado(Simulado simulado) {
    final usuario = usuarioAutenticado;

    if (usuario == null || simulado.usuarioId != usuario.id) {
      return;
    }

    simulado.ativo = false;
    notifyListeners();
  }
}

/* ============================================================
   APLICAÇÃO
============================================================ */

class GabGradingApp extends StatefulWidget {
  const GabGradingApp({super.key});

  @override
  State<GabGradingApp> createState() => _GabGradingAppState();
}

class _GabGradingAppState extends State<GabGradingApp> {
  final AppState appState = AppState();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'GabGrading',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF164E81),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF5F7FA),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          home: appState.usuarioAutenticado == null
              ? LoginScreen(appState: appState)
              : ListaSimuladosScreen(appState: appState),
        );
      },
    );
  }
}

/* ============================================================
   COMPONENTES REUTILIZÁVEIS
============================================================ */

class AppLogo extends StatelessWidget {
  final bool compacto;

  const AppLogo({
    super.key,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compacto ? 40 : 52,
          height: compacto ? 40 : 52,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            Icons.fact_check_rounded,
            color: Colors.white,
            size: compacto ? 23 : 31,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'GabGrading',
          style: TextStyle(
            fontSize: compacto ? 20 : 28,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF16324F),
          ),
        ),
      ],
    );
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const StatusChip({
    super.key,
    required this.label,
    this.color = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(Icons.check_circle, color: color, size: 17),
      label: Text(label),
      backgroundColor: color.withOpacity(.10),
      side: BorderSide.none,
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String mensagem;
  final String? botao;
  final VoidCallback? onPressed;
  final IconData icon;

  const EmptyState({
    super.key,
    required this.mensagem,
    this.botao,
    this.onPressed,
    this.icon = Icons.assignment_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.blueGrey.shade300),
            const SizedBox(height: 16),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            if (botao != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.add),
                label: Text(botao!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String formatarData(DateTime data) {
  final dia = data.day.toString().padLeft(2, '0');
  final mes = data.month.toString().padLeft(2, '0');
  return '$dia/$mes/${data.year}';
}

void mostrarMensagem(
  BuildContext context,
  String mensagem, {
  bool erro = false,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: erro ? Colors.red.shade700 : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
}

/* ============================================================
   TELA 1 — LOGIN
============================================================ */

class LoginScreen extends StatefulWidget {
  final AppState appState;

  const LoginScreen({
    super.key,
    required this.appState,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();

  bool mostrarSenha = false;
  bool lembrarAcesso = false;

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  void entrar() {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final erro = widget.appState.login(
      emailController.text,
      senhaController.text,
    );

    if (erro != null) {
      mostrarMensagem(context, erro, erro: true);
      return;
    }

    mostrarMensagem(context, 'Login realizado com sucesso.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppLogo(),
                  const SizedBox(height: 18),
                  const Text(
                    'Gerencie simulados e gabaritos com simplicidade.',
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'E-mail',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Informe o e-mail.';
                              }

                              if (!value.contains('@')) {
                                return 'Digite um e-mail válido.';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: senhaController,
                            obscureText: !mostrarSenha,
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: 'Mostrar ou ocultar senha',
                                onPressed: () {
                                  setState(() {
                                    mostrarSenha = !mostrarSenha;
                                  });
                                },
                                icon: Icon(
                                  mostrarSenha
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Informe a senha.';
                              }

                              if (value.length < 6) {
                                return 'A senha deve ter no mínimo 6 caracteres.';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 4),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: lembrarAcesso,
                            onChanged: (value) {
                              setState(() {
                                lembrarAcesso = value ?? false;
                              });
                            },
                            title: const Text('Lembrar acesso'),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: entrar,
                              icon: const Icon(Icons.login),
                              label: const Text('Entrar'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CadastroScreen(
                                    appState: widget.appState,
                                  ),
                                ),
                              );
                            },
                            child: const Text('Criar uma conta'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    color: const Color(0xFFEAF2FA),
                    elevation: 0,
                    child: const Padding(
                      padding: EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Acesso de demonstração',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF164E81),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text('E-mail: usuario@escola.com'),
                          Text('Senha: 123456'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ============================================================
   TELA 2 — CADASTRO
============================================================ */

class CadastroScreen extends StatefulWidget {
  final AppState appState;

  const CadastroScreen({
    super.key,
    required this.appState,
  });

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final formKey = GlobalKey<FormState>();

  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  final confirmarController = TextEditingController();

  bool mostrarSenha = false;
  bool mostrarConfirmacao = false;

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    senhaController.dispose();
    confirmarController.dispose();
    super.dispose();
  }

  void cadastrar() {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final erro = widget.appState.cadastrarUsuario(
      nome: nomeController.text,
      email: emailController.text,
      senha: senhaController.text,
    );

    if (erro != null) {
      mostrarMensagem(context, erro, erro: true);
      return;
    }

    mostrarMensagem(
      context,
      'Conta criada com sucesso. Faça login para continuar.',
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const AppLogo(compacto: true),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: formKey,
              child: Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Crie sua conta',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Cadastre-se para organizar seus simulados e gabaritos.',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 26),
                      TextFormField(
                        controller: nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome completo',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe seu nome completo.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o e-mail.';
                          }

                          if (!value.contains('@')) {
                            return 'Digite um e-mail válido.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: senhaController,
                        obscureText: !mostrarSenha,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                mostrarSenha = !mostrarSenha;
                              });
                            },
                            icon: Icon(
                              mostrarSenha
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe a senha.';
                          }

                          if (value.length < 6) {
                            return 'A senha deve ter no mínimo 6 caracteres.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'A senha deve ter no mínimo 6 caracteres.',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirmarController,
                        obscureText: !mostrarConfirmacao,
                        decoration: InputDecoration(
                          labelText: 'Confirmar senha',
                          prefixIcon: const Icon(Icons.lock_reset_outlined),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                mostrarConfirmacao = !mostrarConfirmacao;
                              });
                            },
                            icon: Icon(
                              mostrarConfirmacao
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value != senhaController.text) {
                            return 'As senhas não coincidem.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: cadastrar,
                        child: const Text('Cadastrar'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Já possui uma conta? Entrar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ============================================================
   TELA 3 — LISTAGEM
============================================================ */

class ListaSimuladosScreen extends StatefulWidget {
  final AppState appState;

  const ListaSimuladosScreen({
    super.key,
    required this.appState,
  });

  @override
  State<ListaSimuladosScreen> createState() => _ListaSimuladosScreenState();
}

class _ListaSimuladosScreenState extends State<ListaSimuladosScreen> {
  final buscaController = TextEditingController();

  DateTime? dataInicial;
  DateTime? dataFinal;
  String ordenacao = 'recentes';

  @override
  void dispose() {
    buscaController.dispose();
    super.dispose();
  }

  List<Simulado> get simuladosFiltrados {
    final busca = buscaController.text.toLowerCase().trim();

    final lista = widget.appState.simuladosDoUsuario.where((simulado) {
      final correspondeBusca =
          simulado.identificacao.toLowerCase().contains(busca);

      final correspondeInicio = dataInicial == null ||
          !simulado.dataAplicacao.isBefore(dataInicial!);

      final correspondeFim = dataFinal == null ||
          !simulado.dataAplicacao.isAfter(dataFinal!);

      return correspondeBusca && correspondeInicio && correspondeFim;
    }).toList();

    lista.sort((a, b) {
      switch (ordenacao) {
        case 'antigas':
          return a.dataAplicacao.compareTo(b.dataAplicacao);
        case 'az':
          return a.identificacao.compareTo(b.identificacao);
        case 'za':
          return b.identificacao.compareTo(a.identificacao);
        default:
          return b.dataAplicacao.compareTo(a.dataAplicacao);
      }
    });

    return lista;
  }

  Future<void> selecionarData(bool inicio) async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (data == null) {
      return;
    }

    setState(() {
      if (inicio) {
        dataInicial = data;
      } else {
        dataFinal = data;
      }
    });
  }

  void limparFiltros() {
    setState(() {
      buscaController.clear();
      dataInicial = null;
      dataFinal = null;
      ordenacao = 'recentes';
    });
  }

  void abrirConta() {
    final usuario = widget.appState.usuarioAutenticado;

    if (usuario == null) {
      return;
    }

    final nomeController = TextEditingController(text: usuario.nome);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Minha conta'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SizedBox(
                width: 430,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        child: Text(
                          usuario.nome
                              .split(' ')
                              .take(2)
                              .map((item) => item[0])
                              .join()
                              .toUpperCase(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        usuario.nome,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(usuario.email),
                      const SizedBox(height: 8),
                      const StatusChip(label: 'Conta ativa'),
                      const SizedBox(height: 20),
                      TextField(
                        controller: nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () {
                          if (nomeController.text.trim().isEmpty) {
                            return;
                          }

                          widget.appState
                              .atualizarNomeUsuario(nomeController.text);

                          Navigator.of(dialogContext).pop();
                          mostrarMensagem(
                            context,
                            'Dados atualizados com sucesso.',
                          );
                        },
                        child: const Text('Salvar alterações'),
                      ),
                      const Divider(height: 32),
                      const Text(
                        'Zona de perigo',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ao desativar sua conta, você não poderá mais acessar o sistema com estas credenciais.',
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          confirmarDesativacao();
                        },
                        icon: const Icon(Icons.person_off_outlined),
                        label: const Text('Desativar minha conta'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void confirmarDesativacao() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Desativar conta?'),
          content: const Text(
            'Sua conta será desativada e a sessão será encerrada.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                widget.appState.desativarConta();

                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    mostrarMensagem(
                      context,
                      'Conta desativada com sucesso.',
                    );
                  }
                });
              },
              child: const Text('Desativar conta'),
            ),
          ],
        );
      },
    );
  }

  void abrirFormulario({Simulado? simulado}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FormularioSimuladoScreen(
          appState: widget.appState,
          simulado: simulado,
        ),
      ),
    );
  }

  void abrirDetalhe(Simulado simulado) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetalheSimuladoScreen(
          appState: widget.appState,
          simuladoId: simulado.id,
        ),
      ),
    );
  }

  void excluir(Simulado simulado) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir simulado?'),
          content: Text(
            'Tem certeza de que deseja excluir o simulado '
            '“${simulado.identificacao}”? Ele deixará de aparecer nas '
            'listagens, mas permanecerá como registro inativo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                widget.appState.excluirSimulado(simulado);
                Navigator.of(dialogContext).pop();
                mostrarMensagem(
                  context,
                  'Simulado excluído com sucesso.',
                );
              },
              child: const Text('Excluir simulado'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = widget.appState.usuarioAutenticado;
    final lista = simuladosFiltrados;
    final todos = widget.appState.simuladosDoUsuario;
    final totalQuestoes =
        todos.fold<int>(0, (total, item) => total + item.questoes.length);

    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(compacto: true),
        actions: [
          if (MediaQuery.of(context).size.width > 700)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text('Olá, ${usuario?.nome ?? ''}'),
              ),
            ),
          IconButton(
            tooltip: 'Minha conta',
            onPressed: abrirConta,
            icon: const Icon(Icons.account_circle_outlined),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: () {
              widget.appState.logout();
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  mostrarMensagem(
                    context,
                    'Sessão encerrada com sucesso.',
                  );
                }
              });
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: MediaQuery.of(context).size.width <= 700
          ? Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const DrawerHeader(
                    child: AppLogo(compacto: true),
                  ),
                  ListTile(
                    leading: const Icon(Icons.assignment_outlined),
                    title: const Text('Meus Simulados'),
                    selected: true,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_circle_outlined),
                    title: const Text('Minha conta'),
                    onTap: () {
                      Navigator.of(context).pop();
                      abrirConta();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Sair'),
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.appState.logout();
                    },
                  ),
                ],
              ),
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Novo Simulado'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 900;

          return SingleChildScrollView(
            padding: EdgeInsets.all(desktop ? 32 : 18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1250),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Meus Simulados',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Gerencie seus simulados e respectivos gabaritos.',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _ResumoCard(
                          titulo: 'Simulados ativos',
                          valor: '${todos.length}',
                          icon: Icons.assignment_turned_in_outlined,
                          color: Colors.blue,
                        ),
                        _ResumoCard(
                          titulo: 'Questões cadastradas',
                          valor: '$totalQuestoes',
                          icon: Icons.fact_check_outlined,
                          color: Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            SizedBox(
                              width: desktop ? 330 : double.infinity,
                              child: TextField(
                                controller: buscaController,
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  labelText: 'Buscar por identificação',
                                  prefixIcon: Icon(Icons.search),
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => selecionarData(true),
                              icon: const Icon(Icons.calendar_month),
                              label: Text(
                                dataInicial == null
                                    ? 'Data inicial'
                                    : formatarData(dataInicial!),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => selecionarData(false),
                              icon: const Icon(Icons.calendar_month),
                              label: Text(
                                dataFinal == null
                                    ? 'Data final'
                                    : formatarData(dataFinal!),
                              ),
                            ),
                            DropdownButton<String>(
                              value: ordenacao,
                              items: const [
                                DropdownMenuItem(
                                  value: 'recentes',
                                  child: Text('Data mais recente'),
                                ),
                                DropdownMenuItem(
                                  value: 'antigas',
                                  child: Text('Data mais antiga'),
                                ),
                                DropdownMenuItem(
                                  value: 'az',
                                  child: Text('Identificação A-Z'),
                                ),
                                DropdownMenuItem(
                                  value: 'za',
                                  child: Text('Identificação Z-A'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    ordenacao = value;
                                  });
                                }
                              },
                            ),
                            TextButton(
                              onPressed: limparFiltros,
                              child: const Text('Limpar filtros'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (todos.isEmpty)
                      SizedBox(
                        height: 320,
                        child: EmptyState(
                          mensagem: 'Nenhum simulado cadastrado ainda.',
                          botao: 'Criar primeiro simulado',
                          onPressed: () => abrirFormulario(),
                        ),
                      )
                    else if (lista.isEmpty)
                      SizedBox(
                        height: 320,
                        child: EmptyState(
                          mensagem:
                              'Nenhum simulado encontrado com os filtros selecionados.',
                          botao: 'Limpar filtros',
                          onPressed: limparFiltros,
                          icon: Icons.search_off,
                        ),
                      )
                    else
                      ...lista.map(
                        (simulado) => _SimuladoCard(
                          simulado: simulado,
                          onVisualizar: () => abrirDetalhe(simulado),
                          onEditar: () => abrirFormulario(simulado: simulado),
                          onExcluir: () => excluir(simulado),
                        ),
                      ),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ResumoCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icon;
  final Color color;

  const _ResumoCard({
    required this.titulo,
    required this.valor,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(.12),
                foregroundColor: color,
                child: Icon(icon),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  Text(
                    valor,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimuladoCard extends StatelessWidget {
  final Simulado simulado;
  final VoidCallback onVisualizar;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  const _SimuladoCard({
    required this.simulado,
    required this.onVisualizar,
    required this.onEditar,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compacto = constraints.maxWidth < 620;

            final informacoes = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  simulado.identificacao,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 18,
                  runSpacing: 8,
                  children: [
                    Text(
                      'Aplicação: ${formatarData(simulado.dataAplicacao)}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    Text(
                      '${simulado.questoes.length} questões',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const StatusChip(label: 'Ativo'),
                  ],
                ),
              ],
            );

            final acoes = Wrap(
              spacing: 4,
              children: [
                IconButton(
                  tooltip: 'Visualizar',
                  onPressed: onVisualizar,
                  icon: const Icon(Icons.visibility_outlined),
                ),
                IconButton(
                  tooltip: 'Editar',
                  onPressed: onEditar,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Excluir',
                  onPressed: onExcluir,
                  color: Colors.red,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            );

            if (compacto) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  informacoes,
                  const Divider(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: acoes,
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: informacoes),
                acoes,
              ],
            );
          },
        ),
      ),
    );
  }
}

/* ============================================================
   TELA 4 — CRIAR / EDITAR
============================================================ */

class FormularioSimuladoScreen extends StatefulWidget {
  final AppState appState;
  final Simulado? simulado;

  const FormularioSimuladoScreen({
    super.key,
    required this.appState,
    this.simulado,
  });

  @override
  State<FormularioSimuladoScreen> createState() =>
      _FormularioSimuladoScreenState();
}

class _FormularioSimuladoScreenState
    extends State<FormularioSimuladoScreen> {
  final formKey = GlobalKey<FormState>();
  final identificacaoController = TextEditingController();

  DateTime? dataAplicacao;
  late List<Questao> questoes;
  bool alterado = false;

  bool get editando => widget.simulado != null;

  @override
  void initState() {
    super.initState();

    final simulado = widget.simulado;

    identificacaoController.text = simulado?.identificacao ?? '';
    dataAplicacao = simulado?.dataAplicacao;

    questoes = simulado == null
        ? []
        : simulado.questoes
            .map(
              (questao) => Questao(
                id: questao.id,
                numeroQuestao: questao.numeroQuestao,
                alternativaCorreta: questao.alternativaCorreta,
                conteudo: questao.conteudo,
                simuladoId: questao.simuladoId,
                persistida: true,
              ),
            )
            .toList();
  }

  @override
  void dispose() {
    identificacaoController.dispose();
    super.dispose();
  }

  void marcarAlterado() {
    if (!alterado) {
      setState(() {
        alterado = true;
      });
    }
  }

  Future<void> escolherData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: dataAplicacao ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (data != null) {
      setState(() {
        dataAplicacao = data;
        alterado = true;
      });
    }
  }

  void adicionarQuestao() {
    setState(() {
      questoes.add(
        Questao(
          id: 'draft-${DateTime.now().microsecondsSinceEpoch}',
          numeroQuestao: questoes.length + 1,
          alternativaCorreta: '',
          conteudo: '',
          simuladoId: widget.simulado?.id ?? '',
          persistida: false,
        ),
      );

      alterado = true;
    });
  }

  void removerQuestao(int index) {
    if (questoes[index].persistida) {
      return;
    }

    setState(() {
      questoes.removeAt(index);
      _renumerar();
      alterado = true;
    });
  }

  void moverQuestao(int index, int deslocamento) {
    final novoIndex = index + deslocamento;

    if (novoIndex < 0 || novoIndex >= questoes.length) {
      return;
    }

    setState(() {
      final item = questoes.removeAt(index);
      questoes.insert(novoIndex, item);
      _renumerar();
      alterado = true;
    });
  }

  void _renumerar() {
    for (var i = 0; i < questoes.length; i++) {
      questoes[i].numeroQuestao = i + 1;
    }
  }

  void salvar() {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (dataAplicacao == null) {
      mostrarMensagem(
        context,
        'Selecione a data de aplicação.',
        erro: true,
      );
      return;
    }

    if (questoes.any((questao) => questao.alternativaCorreta.isEmpty)) {
      mostrarMensagem(
        context,
        'Selecione a alternativa correta para todas as questões adicionadas.',
        erro: true,
      );
      return;
    }

    _renumerar();

    widget.appState.salvarSimulado(
      existente: widget.simulado,
      identificacao: identificacaoController.text.trim(),
      dataAplicacao: dataAplicacao!,
      questoes: questoes,
    );

    mostrarMensagem(
      context,
      editando
          ? 'Alterações salvas com sucesso.'
          : 'Simulado criado com sucesso.',
    );

    final id = widget.simulado?.id ??
        widget.appState.simulados.last.id;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DetalheSimuladoScreen(
          appState: widget.appState,
          simuladoId: id,
        ),
      ),
    );
  }

  Future<bool> confirmarSaida() async {
    if (!alterado) {
      return true;
    }

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Descartar alterações?'),
          content: const Text(
            'As alterações realizadas neste simulado serão perdidas.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Continuar editando'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Descartar'),
            ),
          ],
        );
      },
    );

    return resultado ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !alterado,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && await confirmarSaida() && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(editando ? 'Editar Simulado' : 'Novo Simulado'),
        ),
        body: Form(
          key: formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Dados do simulado',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                TextFormField(
                                  controller: identificacaoController,
                                  onChanged: (_) => marcarAlterado(),
                                  decoration: const InputDecoration(
                                    labelText: 'Identificação do simulado',
                                    hintText:
                                        'Ex.: Simulado ENEM — Linguagens 2026',
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'Informe a identificação do simulado.';
                                    }

                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                InkWell(
                                  onTap: escolherData,
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Data de aplicação',
                                      prefixIcon:
                                          Icon(Icons.calendar_month_outlined),
                                    ),
                                    child: Text(
                                      dataAplicacao == null
                                          ? 'Selecione uma data'
                                          : formatarData(dataAplicacao!),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Card(
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Questões do gabarito',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'A numeração é definida automaticamente conforme a ordem das questões.',
                                  style: TextStyle(color: Colors.black54),
                                ),
                                const SizedBox(height: 16),
                                if (questoes.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Text(
                                      'Nenhuma questão adicionada. Você pode salvar o simulado sem questões.',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ...questoes.asMap().entries.map(
                                      (entry) => _QuestaoFormCard(
                                        questao: entry.value,
                                        index: entry.key,
                                        total: questoes.length,
                                        onChanged: marcarAlterado,
                                        onRemover: () =>
                                            removerQuestao(entry.key),
                                        onMoverCima: () =>
                                            moverQuestao(entry.key, -1),
                                        onMoverBaixo: () =>
                                            moverQuestao(entry.key, 1),
                                      ),
                                    ),
                                OutlinedButton.icon(
                                  onPressed: adicionarQuestao,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Adicionar questão'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () async {
                                if (await confirmarSaida() && mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                              child: const Text('Cancelar'),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: salvar,
                              icon: const Icon(Icons.save_outlined),
                              label: Text(
                                editando
                                    ? 'Salvar alterações'
                                    : 'Salvar simulado',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _QuestaoFormCard extends StatelessWidget {
  final Questao questao;
  final int index;
  final int total;
  final VoidCallback onChanged;
  final VoidCallback onRemover;
  final VoidCallback onMoverCima;
  final VoidCallback onMoverBaixo;

  const _QuestaoFormCard({
    required this.questao,
    required this.index,
    required this.total,
    required this.onChanged,
    required this.onRemover,
    required this.onMoverCima,
    required this.onMoverBaixo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF8FAFC),
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Questão ${questao.numeroQuestao}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Mover para cima',
                  onPressed: index == 0 ? null : onMoverCima,
                  icon: const Icon(Icons.keyboard_arrow_up),
                ),
                IconButton(
                  tooltip: 'Mover para baixo',
                  onPressed: index == total - 1 ? null : onMoverBaixo,
                  icon: const Icon(Icons.keyboard_arrow_down),
                ),
                if (!questao.persistida)
                  IconButton(
                    tooltip: 'Remover questão',
                    onPressed: onRemover,
                    color: Colors.red,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: questao.conteudo ?? '',
              onChanged: (value) {
                questao.conteudo = value;
                onChanged();
              },
              decoration: const InputDecoration(
                labelText: 'Conteúdo ou observação',
                hintText: 'Ex.: Matemática — Funções',
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Alternativa correta',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['A', 'B', 'C', 'D', 'E'].map((alternativa) {
                return ChoiceChip(
                  label: Text(alternativa),
                  selected: questao.alternativaCorreta == alternativa,
                  onSelected: (_) {
                    questao.alternativaCorreta = alternativa;
                    onChanged();
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================================================
   TELA 5 — DETALHE
============================================================ */

class DetalheSimuladoScreen extends StatefulWidget {
  final AppState appState;
  final String simuladoId;

  const DetalheSimuladoScreen({
    super.key,
    required this.appState,
    required this.simuladoId,
  });

  @override
  State<DetalheSimuladoScreen> createState() =>
      _DetalheSimuladoScreenState();
}

class _DetalheSimuladoScreenState
    extends State<DetalheSimuladoScreen> {
  final buscaController = TextEditingController();
  bool crescente = true;

  Simulado? get simulado =>
      widget.appState.buscarSimuladoSeguro(widget.simuladoId);

  List<Questao> get questoesFiltradas {
    final item = simulado;

    if (item == null) {
      return [];
    }

    final busca = buscaController.text.toLowerCase().trim();

    final lista = item.questoes.where((questao) {
      final numero = questao.numeroQuestao.toString();
      final conteudo = (questao.conteudo ?? '').toLowerCase();

      return numero.contains(busca) || conteudo.contains(busca);
    }).toList();

    lista.sort(
      (a, b) => crescente
          ? a.numeroQuestao.compareTo(b.numeroQuestao)
          : b.numeroQuestao.compareTo(a.numeroQuestao),
    );

    return lista;
  }

  void editar() {
    final item = simulado;

    if (item == null) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => FormularioSimuladoScreen(
          appState: widget.appState,
          simulado: item,
        ),
      ),
    );
  }

  void excluir() {
    final item = simulado;

    if (item == null) {
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir simulado?'),
          content: Text(
            'Tem certeza de que deseja excluir o simulado '
            '“${item.identificacao}”? Ele deixará de aparecer nas '
            'listagens, mas permanecerá como registro inativo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                widget.appState.excluirSimulado(item);
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
                mostrarMensagem(
                  context,
                  'Simulado excluído com sucesso.',
                );
              },
              child: const Text('Excluir simulado'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = simulado;

    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.block,
          mensagem:
              'Este simulado não está disponível para visualização.',
          botao: 'Voltar para meus simulados',
          onPressed: () => Navigator.of(context).pop(),
        ),
      );
    }

    final questoes = questoesFiltradas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe do Simulado'),
        leading: IconButton(
          tooltip: 'Voltar para simulados',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 800;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1050),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.identificacao,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const StatusChip(label: 'Ativo'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Wrap(
                          spacing: 50,
                          runSpacing: 18,
                          children: [
                            _InfoItem(
                              titulo: 'Data de aplicação',
                              valor: formatarData(item.dataAplicacao),
                              icon: Icons.calendar_month_outlined,
                            ),
                            _InfoItem(
                              titulo: 'Quantidade de questões',
                              valor: '${item.questoes.length}',
                              icon: Icons.fact_check_outlined,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: editar,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Editar simulado'),
                        ),
                        OutlinedButton.icon(
                          onPressed: excluir,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Excluir simulado'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Gabarito de questões',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (item.questoes.isNotEmpty)
                      Card(
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: desktop ? 360 : double.infinity,
                                child: TextField(
                                  controller: buscaController,
                                  onChanged: (_) => setState(() {}),
                                  decoration: const InputDecoration(
                                    labelText:
                                        'Buscar por número ou conteúdo',
                                    prefixIcon: Icon(Icons.search),
                                  ),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    crescente = !crescente;
                                  });
                                },
                                icon: const Icon(Icons.sort),
                                label: Text(
                                  crescente
                                      ? 'Número crescente'
                                      : 'Número decrescente',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    if (item.questoes.isEmpty)
                      EmptyState(
                        icon: Icons.fact_check_outlined,
                        mensagem:
                            'Este simulado ainda não possui questões cadastradas.',
                        botao: 'Editar simulado',
                        onPressed: editar,
                      )
                    else if (questoes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Nenhuma questão encontrada com o filtro informado.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ...questoes.map(
                        (questao) => _QuestaoDetalheCard(
                          questao: questao,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icon;

  const _InfoItem({
    required this.titulo,
    required this.valor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(color: Colors.black54),
            ),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuestaoDetalheCard extends StatelessWidget {
  final Questao questao;

  const _QuestaoDetalheCard({
    required this.questao,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Text('${questao.numeroQuestao}'),
        ),
        title: Text(
          'Questão ${questao.numeroQuestao}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          questao.conteudo == null || questao.conteudo!.trim().isEmpty
              ? 'Sem observação'
              : questao.conteudo!,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primary
                .withOpacity(.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            questao.alternativaCorreta,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}