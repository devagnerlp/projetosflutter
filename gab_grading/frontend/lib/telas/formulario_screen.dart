import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/simulado.dart';
import '../services/simulado_service.dart';
import 'simulados_screen.dart';

// Uma tela só para criar e para editar: sem simulado, cria; com o simulado,
// edita. Os campos e as regras são os mesmos; muda o título da barra, o que
// vem preenchido e o pedido que sai (POST para criar, PATCH para editar).
class FormularioScreen extends StatefulWidget {
  const FormularioScreen({super.key, this.simulado});

  // O simulado a editar, que veio nos arguments; null é um simulado novo.
  final Simulado? simulado;

  @override
  State<FormularioScreen> createState() => _FormularioScreenState();
}

class _FormularioScreenState extends State<FormularioScreen> {
  // A chave do Form: é por ela que o Salvar alcança o formulário e confere
  // todos os campos de uma vez.
  final chave = GlobalKey<FormState>();
  final identificacao = TextEditingController();
  final data = TextEditingController();
  bool salvando = false;
  String? erro;

  @override
  void initState() {
    super.initState();
    // Editando: os campos já começam com o que o simulado tem.
    if (widget.simulado != null) {
      identificacao.text = widget.simulado!.identificacao;
      data.text = widget.simulado!.dataFormatada;
    }
  }

  // O calendário é um atalho para escrever a data: o que ele escolhe vai para
  // o mesmo campo de texto, e a regra continua sendo a do validator.
  Future<void> escolherData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: lerData(data.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (escolhida != null) {
      data.text = formatarData(escolhida);
    }
  }

  Future<void> salvar() async {
    // A ponta do app: cada validator confere o seu campo. Se algum devolver
    // uma frase, ela aparece embaixo do campo, e nada vai para a API.
    if (!chave.currentState!.validate()) {
      return;
    }
    setState(() {
      salvando = true;
      erro = null;
    });
    // A ponta da API: ela confere tudo de novo, e pode recusar (422). O
    // service é o SimuladoService, pego uma vez para as duas chamadas abaixo.
    final servico = context.read<SimuladoService>();
    final dia = lerData(data.text)!;
    try {
      if (widget.simulado == null) {
        await servico.criar(identificacao.text.trim(), dia);
      } else {
        await servico.atualizar(widget.simulado!.id, identificacao.text.trim(), dia);
      }
    } on ErroDeSimulados catch (e) {
      setState(() {
        salvando = false;
        erro = '$e';
      });
      return;
    }
    if (!mounted) return;
    // Deu certo: o formulário fecha com true, e quem o abriu pede de novo.
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    identificacao.dispose();
    data.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Depois de um F5, o formulário é a primeira tela da pilha: ninguém o
    // abriu, e não há quem receba o true. Aí, ele mostra a lista, como o detalhe.
    if (ModalRoute.of(context)!.isFirst) {
      return const SimuladosScreen();
    }
    final editando = widget.simulado != null;
    return Scaffold(
      appBar: AppBar(title: Text(editando ? 'Editar simulado' : 'Novo simulado')),
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
                  TextFormField(
                    controller: identificacao,
                    decoration: const InputDecoration(
                      labelText: 'Identificação',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) {
                      if ((valor ?? '').trim().isEmpty) {
                        return 'Informe a identificação';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: data,
                    decoration: InputDecoration(
                      labelText: 'Data de aplicação (dd/mm/aaaa)',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: 'Escolher no calendário',
                        icon: const Icon(Icons.calendar_month),
                        onPressed: escolherData,
                      ),
                    ),
                    keyboardType: TextInputType.datetime,
                    validator: (valor) {
                      if (lerData(valor ?? '') == null) {
                        return 'Informe uma data válida, como 09/11/2025';
                      }
                      return null;
                    },
                  ),
                  if (erro != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      erro!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
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
