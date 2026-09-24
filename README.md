# IA Lab

Laboratório Rails para aulas práticas de inteligência artificial em Ruby. Cada algoritmo ganha uma rota própria e todos os experimentos aparecem no mapa da página inicial.

## Stack

- Ruby 3.4.9
- Rails 8.1
- SQLite
- Tailwind CSS 4.3, compilado localmente por `tailwindcss-rails`
- [Rumale](https://github.com/yoshoku/rumale) para machine learning clássico
- [Torch.rb](https://github.com/ankane/torch.rb) para tensores e deep learning

## Primeiro setup

O Torch.rb compila uma extensão nativa sobre o LibTorch. A versão usada neste projeto é `torch-rb 0.25.x`, compatível com LibTorch `2.13.x`.

Pré-requisitos do Linux:

- Ruby e Bundler
- compilador C++ (`g++`)
- `curl` e `unzip`

Execute:

```sh
bin/setup --skip-server
```

O script baixa a distribuição CPU do LibTorch para `~/.cache/torch-rb/2.13.0`, configura o Bundler e instala as gems. O download é ignorado nas próximas execuções quando a instalação já estiver completa.

Para usar uma instalação LibTorch existente:

```sh
TORCH_DIR=/caminho/para/libtorch bin/setup --skip-server
```

## Executar

```sh
bin/dev
```

O padrão local é a porta `3120`; para sobrescrever, use `PORT=outra_porta bin/dev`. Abra `http://localhost:3120`. A home lista as aulas disponíveis e as próximas aulas reservadas. As aulas atuais são:

- **Regressão linear**: treina uma reta com Rumale e prevê um novo valor.
- **Operações com tensores**: cria um tensor com Torch.rb e calcula média e variância.

## Tailwind local

O Tailwind entra pelo bundle Ruby, sem CDN. A entrada está em `app/assets/tailwind/application.css`, a saída em `app/assets/builds/tailwind.css` e a folha visual do laboratório é importada pela entrada do Tailwind. Use `bin/dev` para Rails mais o watcher ou compile manualmente:

```sh
bin/rails tailwindcss:build
```

Mais detalhes estão em [TAILWIND.md](TAILWIND.md).

## Deploy local com Nginx

O alias multi-projeto usado nesta máquina é:

```text
/var/www/ia.rafinha.dev/current -> /home/rafinha/Projetos/Ruby IA
```

O Puma escuta apenas `127.0.0.1:3120`. Os templates ficam em `config/deploy/`:

- `config/deploy/nginx/ia.rafinha.dev.conf`
- `config/deploy/nginx/snippets/ia.rafinha.dev.proxy.conf`
- `config/deploy/systemd/ia-lab.service`

Para instalar o alias, o certificado local, o snippet Nginx, o virtual host e o serviço de boot, execute no terminal:

```sh
./bin/install-local-deployment
```

Esse comando usa o `sudo` disponível, cria uma CA local confiável e um certificado HTTPS assinado para `ia.rafinha.dev`, adiciona o domínio a `/etc/hosts`, habilita o serviço systemd e recarrega o Nginx. O arquivo `psw.txt` não é lido pelo projeto.

Depois da instalação, use `https://ia.rafinha.dev`. Feche e reabra o navegador para que ele carregue a CA local instalada no trust store do Fedora e no banco NSS compartilhado.

O inventário das APIs de IA está em [ALGORITMOS.md](ALGORITMOS.md).

## Testes

```sh
bin/rails test
```

## Criar uma nova aula

1. Adicione a definição do experimento em `app/services/ai_lab/experiment_catalog.rb`.
2. Implemente a execução correspondente em `app/services/ai_lab/experiment_runner.rb` ou extraia um serviço próprio quando o algoritmo crescer.
3. Inclua o formulário específico em `app/views/experiments/show.html.erb`.
4. Cubra a página e a execução com um teste em `test/controllers/experiments_controller_test.rb`.

A rota dinâmica `experimentos/:slug` e o link da home já são compartilhados por todos os experimentos.
