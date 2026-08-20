import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'login_screen.dart';

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
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarController = TextEditingController();

  String? _perfil;
  bool _mostrarSenha = false;
  bool _mostrarConfirmacao = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  String? _validarEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o e-mail.';
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value.trim())) {
      return 'Informe um e-mail válido.';
    }

    return null;
  }

  void _cadastrar() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          appState: widget.appState,
          mensagemInicial:
              'Conta criada com sucesso. Faça login para continuar.',
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Crie sua conta',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cadastre seu perfil para utilizar o CorrigeProvas.',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 26),
                      TextFormField(
                        controller: _nomeController,
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
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: _validarEmail,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _senhaController,
                        obscureText: !_mostrarSenha,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() => _mostrarSenha = !_mostrarSenha);
                            },
                            icon: Icon(
                              _mostrarSenha
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe uma senha.';
                          }
                          if (value.length < 6) {
                            return 'A senha deve ter no mínimo 6 caracteres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: _senhaController.text.length >= 6
                                ? Colors.green
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          const Text('A senha deve ter no mínimo 6 caracteres'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmarController,
                        obscureText: !_mostrarConfirmacao,
                        decoration: InputDecoration(
                          labelText: 'Confirmar senha',
                          prefixIcon: const Icon(Icons.lock_reset_outlined),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(
                                () => _mostrarConfirmacao = !_mostrarConfirmacao,
                              );
                            },
                            icon: Icon(
                              _mostrarConfirmacao
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirme sua senha.';
                          }
                          if (value != _senhaController.text) {
                            return 'As senhas não coincidem.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _perfil,
                        decoration: const InputDecoration(
                          labelText: 'Perfil',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Professor',
                            child: Text('Professor'),
                          ),
                          DropdownMenuItem(
                            value: 'Aluno',
                            child: Text('Aluno'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _perfil = value);
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Selecione um perfil.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: _cadastrar,
                          child: const Text('Cadastrar'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
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