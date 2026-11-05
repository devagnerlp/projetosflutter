import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/catalogo.dart';
import '../models/questao.dart';
import '../services/questao_service.dart';
import '../services/traducao.dart';

// Uma tela só para cadastrar e para editar uma questão. A alternativa certa e o
// componente curricular são escolhas de uma lista fechada (RN-10); o conteúdo é
// opcional. O número da questão não aparece: a API o atribui, em sequência.
class QuestaoFormularioScreen extends StatefulWidget {
  const QuestaoFormularioScreen({super.key, required this.simuladoId, this.questao});

  final int simuladoId;

  // A questão a editar; null é uma questão nova.
  final Questao? questao;

  @override
  State<QuestaoFormularioScreen> createState() => _QuestaoFormularioScreenState();
}

class _QuestaoFormularioScreenState extends State<QuestaoFormularioScreen> {
  final chave = GlobalKey<FormState>();
  final conteudo = TextEditingController();
  String? alternativa;
  String? componente;
  bool salvando = false;
  String? erro;

  @override
  void initState() {
    super.initState();
    final questao = widget.questao;
    if (questao != null) {
      alternativa = questao.alternativaCorreta;
      componente = questao.componente;
      conteudo.text = questao.conteudo ?? '';
    }
  }

  Future<void> salvar() async {
    if (!chave.currentState!.validate()) {
      return;
    }
    setState(() {
      salvando = true;
      erro = null;
    });
    final servico = context.read<QuestaoService>();
    try {
      if (widget.questao == null) {
        await servico.criar(widget.simuladoId, alternativa!, componente!, conteudo.text);
      } else {
        await servico.atualizar(widget.simuladoId, widget.questao!.id, alternativa!, componente!, conteudo.text);
      }
    } on ErroDeApi catch (e) {
      setState(() {
        salvando = false;
        erro = '$e';
      });
      return;
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    conteudo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.questao != null;
    return Scaffold(
      appBar: AppBar(title: Text(editando ? 'Editar questão ${widget.questao!.numero}' : 'Nova questão')),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: chave,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: componente,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Componente curricular',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final nome in disciplinas) DropdownMenuItem(value: nome, child: Text(nome)),
                    ],
                    onChanged: (valor) => componente = valor,
                    validator: (valor) => valor == null ? 'Escolha o componente curricular' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: alternativa,
                    decoration: const InputDecoration(
                      labelText: 'Alternativa certa',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final letra in alternativas) DropdownMenuItem(value: letra, child: Text(letra)),
                    ],
                    onChanged: (valor) => alternativa = valor,
                    validator: (valor) => valor == null ? 'Escolha a alternativa certa' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: conteudo,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Conteúdo (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (erro != null) ...[
                    const SizedBox(height: 16),
                    Text(erro!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: salvando ? null : salvar,
                    child: Text(salvando ? 'Salvando...' : 'Salvar'),
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
