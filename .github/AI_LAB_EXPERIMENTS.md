# Plano de experimentos do IA Lab

## Fonte de verdade

- Inventário funcional: `ALGORITMOS.md`.
- Catálogo e rotas: `app/services/ai_lab/experiment_catalog.rb` e `config/routes.rb`.
- Execução: `app/services/ai_lab/experiment_runner.rb`.
- Cada item do inventário deve ter uma página própria em `/experimentos/:slug`.
- Cada página deve identificar a biblioteca, a API/constante, a categoria e executar um exemplo determinístico ou explicar claramente quando a API não existe na versão instalada.

## Cobertura validada em 27/09/2026

| Biblioteca | Entradas no inventário | Situação conhecida |
| --- | ---: | --- |
| Rumale | 126 | 125 constantes presentes; `Rumale::NearestNeighbors::NearestNeighbors` não existe em Rumale 2.2.0 |
| Torch.rb | 175 APIs extraídas dos bullets | Namespace `Torch::NN`, `Torch::Optim`, `Torch::Distributions` e `Torch::Utils::Data` presentes |
| **Total** | **301** | A implementação deve preservar rastreabilidade com `ALGORITMOS.md` |

### Estado de execução validado

- 236 entradas executam chamadas reais das gems e produzem payload de gráfico.
- 36 entradas são indisponíveis nesta instalação: 19 dependem de `Numo::Linalg`, 5 operadores Torch estão expostos mas não implementados no binding, 6 schedulers não são expostos por `torch-rb 0.25.0`, 5 DataPipes não são expostos e uma loss Torch tem construtor incompatível.
- 28 entradas são namespaces, classes-base ou compositores sem uma operação numérica isolada; aparecem como inspeção, sem gráfico inventado.
- 1 entrada é incompatível: `Rumale::NearestNeighbors::NearestNeighbors`.

## Regra de implementação

1. O catálogo deve ser derivado de definições explícitas, sem deixar algoritmos apenas como cards “em breve”.
2. O slug deve ser estável, ASCII, único e derivado da biblioteca + nome da API.
3. O executor deve selecionar adapters por biblioteca; a lógica funcional fica em `app/services/ai_lab/experiments/`, evitando 301 implementações copiadas no roteador.
4. Um erro de uma API individual não pode derrubar a home nem esconder os demais experimentos; o resultado deve mostrar a causa de forma legível.
5. Seeds e conjuntos pequenos devem ser determinísticos sempre que a API permitir.
6. A página deve exibir fonte Ruby, saída observável e os passos do experimento.
7. Cada resultado com `mode: :executed` deve conter `chart` derivado da saída do algoritmo; inspeções e indisponíveis não devem fabricar visualizações.

## Lotes

- [x] Registrar escopo e contagem validada.
- [x] Lote 1: transformar as 126 entradas Rumale em definições catalogadas e executáveis.
- [x] Lote 2: transformar as 175 APIs Torch.rb em definições catalogadas e executáveis.
- [x] Lote 3: atualizar home, filtros e apresentação para o catálogo ampliado.
- [x] Lote 4: adicionar testes de cobertura do catálogo, rotas e execução por família.
- [x] Lote 5: executar `bin/rails test`, `zeitwerk:check`, build Tailwind e smoke test HTTP.

## Organização funcional

- `app/services/ai_lab/experiments/base.rb` concentra resultados, resolução de constantes e utilitários de apresentação.
- `app/services/ai_lab/experiments/rumale_adapter.rb` contém os fixtures e chamadas Rumale.
- `app/services/ai_lab/experiments/torch_adapter.rb` contém os fixtures e chamadas Torch.rb.
- `app/services/ai_lab/experiment_executor.rb` apenas escolhe o adapter e traduz erros para a interface.

## Nota de compatibilidade

`Rumale::NearestNeighbors::NearestNeighbors` foi listado no inventário, mas não está exposto pela Rumale 2.2.0 instalada. Ele deve continuar tendo uma página individual marcada como incompatível, com a explicação e a versão detectada, em vez de ser silenciosamente removido.
