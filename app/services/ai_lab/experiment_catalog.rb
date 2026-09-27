module AiLab
  module ExperimentCatalog
    MISSING_RUMALE_API = "Rumale::NearestNeighbors::NearestNeighbors"

    LEGACY_SLUGS = {
      "Rumale::LinearModel::LinearRegression" => "regressao-linear",
      "Rumale::NearestNeighbors::KNeighborsClassifier" => "classificacao-knn",
      "Torch.tensor" => "tensores",
      "Torch::NN::Linear" => "rede-neural"
    }.freeze

    LEGACY_TITLES = {
      "regressao-linear" => "Regressão linear",
      "classificacao-knn" => "Classificação KNN",
      "tensores" => "Operações com tensores",
      "rede-neural" => "Rede neural"
    }.freeze

    class << self
      def all
        @all ||= parse_inventory.freeze
      end

      def find(slug)
        all.find { |experiment| experiment.slug == slug }
      end

      def reset!
        @all = nil
      end

      private

      def parse_inventory
        library = nil
        category = nil
        namespace = nil
        experiments = []

        File.readlines(Rails.root.join("ALGORITMOS.md"), chomp: true).each do |line|
          if line == "## Rumale" || line == "## Torch.rb"
            library = line.delete_prefix("## ")
            category = nil
            namespace = nil
            next
          end

          if line.start_with?("## ")
            library = nil
            next
          end

          if line.start_with?("### ")
            heading = line.delete_prefix("### ").strip
            namespace = heading[/`([^`]+)`/, 1]
            category = heading.sub(/\s*\(`[^`]+`\)/, "")
            next
          end

          next unless library && line.start_with?("- ")

          body = line.delete_prefix("- ").strip
          description = body.split(" — ", 2).last.to_s.strip
          tokens = line.scan(/`([^`]+)`/).flatten
          tokens = tokens.select { |token| token.start_with?("Rumale::") } if library == "Rumale"
          tokens = [ nil ] if tokens.empty?

          tokens.each do |token|
            experiments << build_experiment(
              library: library,
              category: category,
              namespace: namespace,
              api_name: qualify_api(token, library, namespace),
              label: body.split(":", 2).first,
              description: description
            )
          end
        end

        experiments
      end

      def build_experiment(library:, category:, namespace:, api_name:, label:, description:)
        slug = LEGACY_SLUGS[api_name] || slug_for(library, api_name, label, namespace)
        title = LEGACY_TITLES.fetch(slug) { humanize(api_name || label) }
        status = api_name == MISSING_RUMALE_API ? :incompatible : :available

        Experiment.new(
          slug: slug,
          title: title,
          library: library,
          status: status,
          summary: description.presence || "Execute um exemplo individual desta API.",
          description: [ api_name || label, description ].compact.join(": "),
          accent: accent_for(library, category),
          steps: steps_for(category),
          api_name: api_name,
          namespace: namespace,
          category: category
        )
      end

      def qualify_api(token, library, namespace)
        return nil unless token
        return token if library == "Rumale" || token.include?("::") || token.include?(".")
        return "#{namespace}::#{token}" if namespace
        return "Torch.#{token}" if library == "Torch.rb"

        token
      end

      def slug_for(library, api_name, label, namespace)
        prefix = library == "Rumale" ? "rumale" : "torch"
        value = api_name || [ namespace, label ].compact.join(" ")
        value = value.sub(/\A(?:Rumale::|Torch::|Torch\.)/, "")
        "#{prefix}-#{slugify(value)}"
      end

      def slugify(value)
        value.to_s
          .gsub("::", "-")
          .gsub(".", "-")
          .gsub(/([a-z\d])([A-Z])/, '\\1-\\2')
          .downcase
          .gsub(/[^a-z0-9]+/, "-")
          .sub(/\A-+/, "")
          .sub(/-+\z/, "")
      end

      def humanize(value)
        words = value.to_s
          .sub(/\A(?:Rumale::|Torch::|Torch\.)/, "")
          .gsub("::", " ")
          .gsub(".", " ")
          .gsub(/([A-Z]+)([A-Z][a-z])/, '\\1 \\2')
          .gsub(/([a-z\d])([A-Z])/, '\\1 \\2')
          .tr("_", " ")
          .split

        words.map { |word| word.length <= 3 && word == word.upcase ? word : word.capitalize }.join(" ")
      end

      def accent_for(library, category)
        return "cyan" if library == "Torch.rb"
        return "lime" if category.to_s.include?("Clustering")
        return "violet" if category.to_s.include?("Rede") || category.to_s.include?("Métricas")

        "coral"
      end

      def steps_for(category)
        return [ "Ler a API", "Executar o exemplo", "Observar a saída" ] unless category
        return [ "Preparar os dados", "Ajustar o modelo", "Observar a saída" ] if category.match?("Classificação|regressão|Árvores|ensembles|Aprendizado")
        return [ "Montar a entrada", "Aplicar a transformação", "Inspecionar o resultado" ] if category.match?("Redução|Atributos")
        return [ "Preparar os pontos", "Executar a análise", "Interpretar a saída" ] if category.include?("Clustering")
        return [ "Separar as amostras", "Executar a avaliação", "Ler a medida" ] if category.include?("Seleção")

        [ "Ler a API", "Executar o exemplo", "Observar a saída" ]
      end
    end
  end
end
