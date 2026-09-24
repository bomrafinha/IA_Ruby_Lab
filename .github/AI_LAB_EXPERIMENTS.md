# Plano de experimentos do IA Lab

## Fonte de verdade

- Inventário funcional: `ALGORITMOS.md`.
- Catálogo e rotas: `app/services/ai_lab/experiment_catalog.rb` e `config/routes.rb`.
- Execução: `app/services/ai_lab/experiment_runner.rb`.
- Cada item do inventário deve ter uma página própria em `/experimentos/:slug`.
- Cada página deve identificar a biblioteca, a API/constante, a categoria e executar um exemplo determinístico ou explicar claramente quando a API não existe na versão instalada.

## Cobertura validada em 24/09/2026

| Biblioteca | Entradas no inventário | Situação conhecida |
| --- | ---: | --- |
| Rumale | 126 | 125 constantes presentes; `Rumale::NearestNeighbors::NearestNeighbors` não existe em Rumale 2.2.0 |
| Torch.rb | 82 blocos/API | Namespace `Torch::NN`, `Torch::Optim`, `Torch::Distributions` e `Torch::Utils::Data` presentes |
| **Total** | **208** | A implementação deve preservar rastreabilidade com `ALGORITMOS.md` |

## Regra de implementação

1. O catálogo deve ser derivado de definições explícitas, sem deixar algoritmos apenas como cards “em breve”.
2. O slug deve ser estável, ASCII, único e derivado da biblioteca + nome da API.
3. O runner deve usar adaptadores por família (`fit/predict`, transformadores, clustering, métricas, Torch NN, perdas, otimização, dados e utilitários), evitando 208 implementações copiadas.
4. Um erro de uma API individual não pode derrubar a home nem esconder os demais experimentos; o resultado deve mostrar a causa de forma legível.
5. Seeds e conjuntos pequenos devem ser determinísticos sempre que a API permitir.
6. A página deve exibir fonte Ruby, saída observável e os passos do experimento.

## Lotes

- [x] Registrar escopo e contagem validada.
- [ ] Lote 1: transformar as 126 entradas Rumale em definições catalogadas e executáveis.
- [ ] Lote 2: transformar os 82 blocos/API Torch.rb em definições catalogadas e executáveis.
- [ ] Lote 3: atualizar home, filtros e apresentação para o catálogo ampliado.
- [ ] Lote 4: adicionar testes de cobertura do catálogo, rotas e execução por família.
- [ ] Lote 5: executar `bin/rails test`, `zeitwerk:check`, build Tailwind e smoke test HTTP.

## Nota de compatibilidade

`Rumale::NearestNeighbors::NearestNeighbors` foi listado no inventário, mas não está exposto pela Rumale 2.2.0 instalada. Ele deve continuar tendo uma página individual marcada como incompatível, com a explicação e a versão detectada, em vez de ser silenciosamente removido.
