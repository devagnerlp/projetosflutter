import 'package:flutter/material.dart';

// Os estados de uma tela que pede dados à API, um de cada vez: carregando, erro
// (com o Tentar de novo), vazia e os dados. É o bloco que a lista de simulados
// escreve à mão; as telas novas usam este, para não copiá-lo em cada uma.
//
// O `pedido` vem de fora e nasce UMA vez, no initState da tela: criado aqui
// dentro, sairia de novo a cada redesenho.
class EstadosDaTela<T> extends StatelessWidget {
  const EstadosDaTela({
    super.key,
    required this.pedido,
    required this.tituloDoErro,
    required this.pedirDeNovo,
    required this.construir,
    this.mensagemVazia,
    this.estaVazio,
  });

  final Future<T> pedido;
  final String tituloDoErro;
  final VoidCallback pedirDeNovo;

  // Desenha a tela quando os dados chegaram.
  final Widget Function(BuildContext context, T dados) construir;

  // Se os dados contam como "vazios" (uma lista sem itens), a tela mostra esta
  // mensagem em vez de `construir`. O pedido deu certo: vazio não é erro.
  final String? mensagemVazia;
  final bool Function(T dados)? estaVazio;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: pedido,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 56),
                const SizedBox(height: 16),
                Text(tituloDoErro),
                const SizedBox(height: 8),
                Text('${snapshot.error}', style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: pedirDeNovo, child: const Text('Tentar de novo')),
              ],
            ),
          );
        }
        final dados = snapshot.data as T;
        if (estaVazio != null && estaVazio!(dados)) {
          return Center(child: Text(mensagemVazia ?? 'Nada por aqui ainda.'));
        }
        return construir(context, dados);
      },
    );
  }
}
