# Tailwind CSS local

O projeto usa `tailwindcss-rails` v4. O executável do Tailwind vem pelo bundle Ruby e não é carregado de CDN.

## Arquivos

- Entrada: `app/assets/tailwind/application.css`
- Saída compilada: `app/assets/builds/tailwind.css`
- Processo de desenvolvimento: `Procfile.dev`

A entrada importa a folha visual do laboratório em `app/assets/stylesheets/application.css`. Assim, as páginas existentes preservam a identidade visual e as próximas aulas podem usar classes Tailwind diretamente nos templates.

## Comandos

```sh
bin/rails tailwindcss:build
bin/rails tailwindcss:watch
bin/dev
```

O comando `bin/dev` inicia Rails e o watcher local do Tailwind. Para outra porta, defina `PORT` antes de executar.
