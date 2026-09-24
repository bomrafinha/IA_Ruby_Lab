module AiLab
  module ExperimentCatalog
    class << self
      def all
        @all ||= [
          Experiment.new(
            slug: "regressao-linear",
            title: "Regressão linear",
            library: "Rumale",
            status: :available,
            summary: "Encontre a linha que melhor explica os dados.",
            description: "Treine um modelo com dados simples e use a reta aprendida para fazer uma previsão.",
            accent: "coral",
            steps: ["Preparar os dados", "Ajustar a reta", "Prever um novo valor"]
          ),
          Experiment.new(
            slug: "tensores",
            title: "Operações com tensores",
            library: "Torch.rb",
            status: :available,
            summary: "Veja os blocos fundamentais do deep learning.",
            description: "Explore como uma coleção de números se transforma em um tensor e passe por operações estatísticas básicas.",
            accent: "cyan",
            steps: ["Criar o tensor", "Centralizar os valores", "Medir a distribuição"]
          ),
          Experiment.new(
            slug: "classificacao-knn",
            title: "Classificação KNN",
            library: "Rumale",
            status: :soon,
            summary: "Classifique novos pontos pela vizinhança.",
            description: "Uma próxima aula para observar como distância e contexto ajudam um modelo a escolher uma classe.",
            accent: "lime",
            steps: ["Montar classes", "Encontrar vizinhos", "Classificar o ponto"]
          ),
          Experiment.new(
            slug: "rede-neural",
            title: "Rede neural",
            library: "Torch.rb",
            status: :soon,
            summary: "Construa uma rede e acompanhe o aprendizado.",
            description: "Uma próxima aula para acompanhar forward pass, função de perda e atualização dos pesos.",
            accent: "violet",
            steps: ["Definir a rede", "Calcular a perda", "Atualizar os pesos"]
          )
        ].freeze
      end

      def find(slug)
        all.find { |experiment| experiment.slug == slug }
      end
    end
  end
end
