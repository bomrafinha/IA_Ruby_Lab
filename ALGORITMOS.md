# Inventário de algoritmos

Este inventário corresponde às versões instaladas no projeto em 04/09/2026:

- `rumale 2.2.0`, distribuído como uma meta-gem com subgems de algoritmos.
- `torch-rb 0.25.0`, ligado ao LibTorch `2.13.0`.

Rumale oferece estimadores prontos no estilo `fit`/`predict`. Torch.rb é uma ponte Ruby para o PyTorch C++: ele fornece tensores e blocos para montar modelos, mas não oferece um catálogo de estimadores prontos equivalente ao Rumale.

## Rumale

### Classificação e regressão

- `Rumale::LinearModel::LinearRegression` — regressão linear para estimar valores contínuos.
- `Rumale::LinearModel::Ridge` — regressão linear com penalização L2 para reduzir pesos excessivos.
- `Rumale::LinearModel::Lasso` — regressão linear com penalização L1, útil também para seleção de atributos.
- `Rumale::LinearModel::ElasticNet` — combina penalizações L1 e L2.
- `Rumale::LinearModel::NNLS` — mínimos quadrados não negativos.
- `Rumale::LinearModel::LogisticRegression` — classificação linear probabilística.
- `Rumale::LinearModel::SGDClassifier` — classificação linear treinada por gradiente estocástico.
- `Rumale::LinearModel::SGDRegressor` — regressão linear treinada por gradiente estocástico.
- `Rumale::LinearModel::SVC` — máquina de vetores de suporte linear para classificação.
- `Rumale::LinearModel::SVR` — máquina de vetores de suporte para regressão.
- `Rumale::KernelMachine::KernelSVC` — SVM de classificação com kernels.
- `Rumale::KernelMachine::KernelRidgeClassifier` — classificação com kernel e regularização Ridge.
- `Rumale::KernelMachine::KernelRidge` — regressão Kernel Ridge.
- `Rumale::KernelMachine::KernelFDA` — análise discriminante de Fisher em espaço de kernel.
- `Rumale::NaiveBayes::BernoulliNB` — Naive Bayes para atributos binários.
- `Rumale::NaiveBayes::ComplementNB` — variante de Naive Bayes adequada a dados desbalanceados, especialmente texto.
- `Rumale::NaiveBayes::GaussianNB` — Naive Bayes para atributos contínuos aproximadamente gaussianos.
- `Rumale::NaiveBayes::MultinomialNB` — Naive Bayes para contagens e frequências, comum em texto.
- `Rumale::NaiveBayes::NegationNB` — Naive Bayes que incorpora o efeito de negação em texto.
- `Rumale::NearestNeighbors::KNeighborsClassifier` — classificação pela votação dos vizinhos mais próximos.
- `Rumale::NearestNeighbors::KNeighborsRegressor` — regressão pela média ou ponderação dos vizinhos.
- `Rumale::NearestNeighbors::NearestNeighbors` — consulta de vizinhança sem uma etapa de previsão supervisionada.

### Árvores e ensembles

- `Rumale::Tree::DecisionTreeClassifier` — árvore de decisão para classificação.
- `Rumale::Tree::DecisionTreeRegressor` — árvore de decisão para regressão.
- `Rumale::Tree::ExtraTreeClassifier` — árvore extremamente aleatorizada para classificação.
- `Rumale::Tree::ExtraTreeRegressor` — árvore extremamente aleatorizada para regressão.
- `Rumale::Tree::GradientTreeRegressor` — boosting de árvores para regressão.
- `Rumale::Tree::VRTreeClassifier` — árvore de classificação com randomização de variáveis.
- `Rumale::Tree::VRTreeRegressor` — árvore de regressão com randomização de variáveis.
- `Rumale::Ensemble::RandomForestClassifier` — conjunto de árvores com amostragem aleatória para classificação.
- `Rumale::Ensemble::RandomForestRegressor` — conjunto de árvores com amostragem aleatória para regressão.
- `Rumale::Ensemble::ExtraTreesClassifier` — ensemble de árvores extremamente aleatorizadas para classificação.
- `Rumale::Ensemble::ExtraTreesRegressor` — ensemble de árvores extremamente aleatorizadas para regressão.
- `Rumale::Ensemble::GradientBoostingClassifier` — boosting sequencial de árvores para classificação.
- `Rumale::Ensemble::GradientBoostingRegressor` — boosting sequencial de árvores para regressão.
- `Rumale::Ensemble::AdaBoostClassifier` — combina classificadores fracos dando mais peso aos erros.
- `Rumale::Ensemble::AdaBoostRegressor` — versão de AdaBoost para regressão.
- `Rumale::Ensemble::VRTreesClassifier` — ensemble de VR trees para classificação.
- `Rumale::Ensemble::VRTreesRegressor` — ensemble de VR trees para regressão.
- `Rumale::Ensemble::VotingClassifier` — combina previsões de vários classificadores por votação.
- `Rumale::Ensemble::VotingRegressor` — combina previsões de vários regressores.
- `Rumale::Ensemble::StackingClassifier` — usa um modelo final sobre as previsões de modelos base.
- `Rumale::Ensemble::StackingRegressor` — stacking aplicado à regressão.

### Clustering

- `Rumale::Clustering::KMeans` — particiona dados em `k` grupos minimizando a distância aos centróides.
- `Rumale::Clustering::MiniBatchKMeans` — K-Means em pequenos lotes, útil para conjuntos maiores.
- `Rumale::Clustering::KMedoids` — clustering por representantes reais do conjunto, os medoides.
- `Rumale::Clustering::MeanShift` — encontra regiões de alta densidade sem fixar previamente o número de grupos.
- `Rumale::Clustering::DBSCAN` — identifica grupos por densidade e separa ruído.
- `Rumale::Clustering::HDBSCAN` — versão hierárquica de DBSCAN para densidades variáveis.
- `Rumale::Clustering::SNN` — clustering baseado em similaridade de vizinhança compartilhada.
- `Rumale::Clustering::SpectralClustering` — usa a estrutura espectral de um grafo de similaridade.
- `Rumale::Clustering::SingleLinkage` — clustering hierárquico por menor distância entre grupos.
- `Rumale::Clustering::GaussianMixture` — mistura de gaussianas estimada por Expectation-Maximization.

### Redução de dimensionalidade e representação

- `Rumale::Decomposition::PCA` — componentes principais para reduzir dimensionalidade.
- `Rumale::Decomposition::SparsePCA` — PCA com componentes esparsos e mais interpretáveis.
- `Rumale::Decomposition::NMF` — fatoração não negativa para descobrir componentes aditivos.
- `Rumale::Decomposition::FastICA` — separação de fontes independentes.
- `Rumale::Decomposition::FactorAnalysis` — modelo latente baseado em fatores estatísticos.
- `Rumale::Manifold::MDS` — posiciona pontos preservando distâncias.
- `Rumale::Manifold::ClassicalMDS` — versão clássica do multidimensional scaling.
- `Rumale::Manifold::TSNE` — visualização não linear preservando vizinhanças locais.
- `Rumale::Manifold::LocallyLinearEmbedding` — preserva relações lineares locais.
- `Rumale::Manifold::LaplacianEigenmaps` — redução baseada no grafo de vizinhança.
- `Rumale::Manifold::HessianEigenmaps` — extensão de LLE com informação de segunda ordem.
- `Rumale::Manifold::LocalTangentSpaceAlignment` — alinha espaços tangentes locais.
- `Rumale::KernelMachine::KernelPCA` — PCA realizado em espaço de características não linear.
- `Rumale::KernelApproximation::Nystroem` — aproxima o mapa de características de um kernel.
- `Rumale::KernelApproximation::RBF` — transformação por base radial para aproximar kernels RBF.

### Aprendizado de métricas e redes neurais

- `Rumale::MetricLearning::FisherDiscriminantAnalysis` — aprende uma projeção que separa classes.
- `Rumale::MetricLearning::LocalFisherDiscriminantAnalysis` — versão local da análise discriminante de Fisher.
- `Rumale::MetricLearning::MLKR` — aprende uma métrica para regressão baseada em vizinhança.
- `Rumale::MetricLearning::NeighbourhoodComponentAnalysis` — aprende uma métrica que favorece vizinhos da mesma classe.
- `Rumale::NeuralNetwork::MLPClassifier` — perceptron multicamadas para classificação.
- `Rumale::NeuralNetwork::MLPRegressor` — perceptron multicamadas para regressão.
- `Rumale::NeuralNetwork::RBFClassifier` — rede de funções de base radial para classificação.
- `Rumale::NeuralNetwork::RBFRegressor` — rede de funções de base radial para regressão.
- `Rumale::NeuralNetwork::RVFLClassifier` — Random Vector Functional Link para classificação.
- `Rumale::NeuralNetwork::RVFLRegressor` — Random Vector Functional Link para regressão.

### Atributos, texto e composição de modelos

- `Rumale::FeatureExtraction::FeatureHasher` — transforma atributos em vetores por hashing.
- `Rumale::FeatureExtraction::HashVectorizer` — vetoriza tokens usando hashing.
- `Rumale::FeatureExtraction::TfidfTransformer` — pondera termos pela frequência TF-IDF.
- `Rumale::Preprocessing::StandardScaler` — padroniza atributos pela média e desvio padrão.
- `Rumale::Preprocessing::MinMaxScaler` — escala atributos para um intervalo definido.
- `Rumale::Preprocessing::MaxAbsScaler` — escala pelo maior valor absoluto sem perder esparsidade.
- `Rumale::Preprocessing::L1Normalizer` — normaliza cada amostra pela norma L1.
- `Rumale::Preprocessing::L2Normalizer` — normaliza cada amostra pela norma L2.
- `Rumale::Preprocessing::MaxNormalizer` — normaliza pelo maior valor absoluto da amostra.
- `Rumale::Preprocessing::Binarizer` — converte valores em 0/1 usando um limiar.
- `Rumale::Preprocessing::BinDiscretizer` — transforma valores contínuos em faixas.
- `Rumale::Preprocessing::PolynomialFeatures` — expande atributos com termos polinomiais e interações.
- `Rumale::Preprocessing::OneHotEncoder` — transforma categorias em colunas binárias.
- `Rumale::Preprocessing::OrdinalEncoder` — transforma categorias em códigos ordinais.
- `Rumale::Preprocessing::LabelEncoder` — codifica rótulos em inteiros.
- `Rumale::Preprocessing::LabelBinarizer` — codifica rótulos em vetores binários.
- `Rumale::Preprocessing::KernelCalculator` — calcula matrizes de kernel para outros modelos.
- `Rumale::Pipeline::Pipeline` — encadeia transformadores e um estimador final.
- `Rumale::Pipeline::FeatureUnion` — combina as saídas de vários transformadores.

### Seleção de modelo e métricas

- `Rumale::ModelSelection::KFold` — validação cruzada em `k` partes.
- `Rumale::ModelSelection::StratifiedKFold` — K-Fold preservando a proporção das classes.
- `Rumale::ModelSelection::GroupKFold` — separa grupos para evitar vazamento entre treino e validação.
- `Rumale::ModelSelection::TimeSeriesSplit` — divisão própria para séries temporais.
- `Rumale::ModelSelection::ShuffleSplit` — divisões aleatórias repetidas.
- `Rumale::ModelSelection::StratifiedShuffleSplit` — divisões aleatórias estratificadas.
- `Rumale::ModelSelection::GroupShuffleSplit` — divisões aleatórias por grupo.
- `Rumale::ModelSelection::GridSearchCV` — busca hiperparâmetros por grade e validação cruzada.
- `Rumale::ModelSelection::CrossValidation` — executor genérico de validação cruzada.
- `Rumale::EvaluationMeasure::Accuracy` — proporção de classificações corretas.
- `Rumale::EvaluationMeasure::Precision` — precisão dos positivos previstos.
- `Rumale::EvaluationMeasure::Recall` — cobertura dos positivos reais.
- `Rumale::EvaluationMeasure::FScore` — média harmônica entre precisão e recall.
- `Rumale::EvaluationMeasure::ROCAUC` — área sob a curva ROC.
- `Rumale::EvaluationMeasure::LogLoss` — qualidade de probabilidades classificatórias.
- `Rumale::EvaluationMeasure::MeanAbsoluteError` — erro absoluto médio.
- `Rumale::EvaluationMeasure::MeanSquaredError` — erro quadrático médio.
- `Rumale::EvaluationMeasure::MeanSquaredLogError` — erro quadrático médio em escala logarítmica.
- `Rumale::EvaluationMeasure::MedianAbsoluteError` — mediana dos erros absolutos.
- `Rumale::EvaluationMeasure::R2Score` — proporção da variância explicada na regressão.
- `Rumale::EvaluationMeasure::ExplainedVarianceScore` — variância do erro não explicado.
- `Rumale::EvaluationMeasure::SilhouetteScore` — coesão e separação de clusters.
- `Rumale::EvaluationMeasure::CalinskiHarabaszScore` — separação entre e dentro dos clusters.
- `Rumale::EvaluationMeasure::DaviesBouldinScore` — similaridade entre clusters, em que menor é melhor.
- `Rumale::EvaluationMeasure::AdjustedRandScore` — concordância de agrupamentos corrigida pelo acaso.
- `Rumale::EvaluationMeasure::NormalizedMutualInformation` — informação compartilhada entre rótulos e clusters.
- `Rumale::EvaluationMeasure::MutualInformation` — dependência entre duas rotulações.
- `Rumale::EvaluationMeasure::Purity` — proporção dominante de classe em cada cluster.
- `Rumale::EvaluationMeasure::PrecisionRecall` — cálculo conjunto das curvas de precisão e recall.

## Torch.rb

Torch.rb não é uma coleção de modelos prontos: é a API Ruby do LibTorch. Os itens abaixo são os blocos algorítmicos disponíveis para montar e treinar redes.

### Tensores e computação

- Criação: `Torch.tensor`, `zeros`, `ones`, `empty`, `full`, `eye`, `arange`, `linspace`, `logspace`, `rand`, `randn`, `randint` e `randperm`.
- Operações elementares: soma, subtração, produto, divisão, módulo, potência, comparações, broadcasting e operações in-place.
- Reduções: soma, média, produto, máximo, mínimo, variância, desvio padrão, `argmax`, `argmin` e normas.
- Álgebra linear: produto matricial, inversas, decomposições e operações do namespace `Torch::Linalg`.
- Autograd: grafos de diferenciação automática, gradientes, `backward` e contexto `Torch.no_grad`.
- Randomização: geração pseudoaleatória, seeds e permutações para amostragem e treinamento.
- FFT e funções especiais: transformadas de Fourier e operações numéricas especiais expostas pelo LibTorch.
- Serialização: `Torch.save`, `Torch.load`, `state_dict` e carregamento de parâmetros.
- Dispositivos: execução em CPU e suporte de backend CUDA quando a instalação do LibTorch tiver GPU compatível.

### Camadas e arquiteturas neurais (`Torch::NN`)

- `Linear` e `Bilinear` — camadas densas, respectivamente afim simples e bilinear.
- `Conv1d`, `Conv2d`, `Conv3d` e `ConvNd` — convoluções para sinais, imagens e volumes.
- `RNN`, `GRU` e `LSTM` — redes recorrentes para sequências.
- `MultiheadAttention` — atenção multi-cabeças.
- `Transformer`, `TransformerEncoder`, `TransformerEncoderLayer`, `TransformerDecoder` e `TransformerDecoderLayer` — blocos Transformer para modelagem de sequências.
- `Embedding` e `EmbeddingBag` — representação vetorial de índices, útil para texto e categorias.
- `BatchNorm`, `BatchNorm1d`, `BatchNorm2d` e `BatchNorm3d` — normalização por lote.
- `GroupNorm` — normalização por grupos de canais.
- `InstanceNorm`, `InstanceNorm1d`, `InstanceNorm2d` e `InstanceNorm3d` — normalização por instância.
- `LayerNorm` — normalização por dimensão de características.
- `LocalResponseNorm` — normalização local de respostas.
- `AvgPool1d`, `AvgPool2d`, `AvgPool3d` e `AvgPoolNd` — pooling médio.
- `AdaptiveAvgPool1d`, `AdaptiveAvgPool2d`, `AdaptiveAvgPool3d` e `AdaptiveAvgPoolNd` — pooling médio com saída de tamanho definido.
- `MaxPool1d`, `MaxPool2d`, `MaxPool3d` e `MaxPoolNd` — pooling pelo máximo.
- `AdaptiveMaxPool1d`, `AdaptiveMaxPool2d`, `AdaptiveMaxPool3d` e `AdaptiveMaxPoolNd` — max pooling adaptativo.
- `MaxUnpool1d`, `MaxUnpool2d`, `MaxUnpool3d` e `MaxUnpoolNd` — reconstrução parcial após max pooling.
- `LPPool1d`, `LPPool2d` e `LPPoolNd` — pooling baseado em norma Lp.
- `Dropout`, `Dropout2d`, `Dropout3d` e `DropoutNd` — regularização por desligamento aleatório.
- `AlphaDropout` e `FeatureAlphaDropout` — dropout compatível com ativações SELU.
- `ReLU`, `ELU`, `GELU`, `LeakyReLU`, `PReLU`, `Softplus`, `Softsign`, `Sigmoid`, `Tanh`, `Tanhshrink`, `Hardshrink` e `Softshrink` — funções de ativação.
- `Softmax`, `Softmax2d`, `Softmin`, `LogSoftmax` e `LogSigmoid` — normalizações e ativações probabilísticas/logarítmicas.
- `Identity` — camada que retorna a entrada sem transformação.
- `ConstantPad1d`, `ConstantPad2d`, `ConstantPad3d` e `ConstantPadNd` — padding constante.
- `ReflectionPad1d`, `ReflectionPad2d` e `ReflectionPadNd` — padding por reflexão.
- `ReplicationPad1d`, `ReplicationPad2d`, `ReplicationPad3d` e `ReplicationPadNd` — padding por replicação.
- `ZeroPad2d` — padding preenchido com zero.
- `Fold` e `Unfold` — conversão entre blocos locais e tensores espaciais.
- `Upsample` — aumento de resolução por interpolação.
- `Sequential`, `ModuleList`, `Parameter`, `ParameterList` e `Module` — composição, registro e gerenciamento de redes e parâmetros.

### Funções de perda (`Torch::NN`)

- `MSELoss` — erro quadrático médio para regressão.
- `L1Loss` — erro absoluto médio.
- `SmoothL1Loss` — erro robusto entre L1 e L2.
- `BCELoss` — entropia cruzada binária para probabilidades.
- `BCEWithLogitsLoss` — BCE combinada numericamente com sigmoid.
- `CrossEntropyLoss` — classificação multiclasse com logits.
- `NLLLoss` — perda de log-verossimilhança negativa.
- `CTCLoss` — alinhamento de sequências sem rótulos por posição.
- `KLDivLoss` — divergência Kullback-Leibler entre distribuições.
- `PoissonNLLLoss` — regressão de contagens com distribuição de Poisson.
- `CosineEmbeddingLoss` — aproxima ou separa pares pela similaridade de cosseno.
- `HingeEmbeddingLoss` — perda hinge para relações de similaridade.
- `MarginRankingLoss` — força uma ordem entre dois valores.
- `MultiMarginLoss` — margem para classificação multiclasse.
- `MultiLabelMarginLoss` — margem para classificação multilabel.
- `MultiLabelSoftMarginLoss` — classificação multilabel com margem logística.
- `SoftMarginLoss` — classificação binária com margem suave.
- `TripletMarginLoss` — aprendizado de representação com âncoras, positivos e negativos.
- `WeightedLoss` — base para perdas ponderadas.
- `CosineSimilarity` e `PairwiseDistance` — medidas de similaridade/distância usadas em objetivos e métricas.

### Otimização e ajuste da taxa de aprendizado (`Torch::Optim`)

- `SGD` — descida de gradiente estocástica, com momentum opcional.
- `Adam` — adaptação de momento de primeira e segunda ordem.
- `AdamW` — Adam com weight decay desacoplado.
- `Adamax` — variante de Adam baseada na norma infinito.
- `Adagrad` — taxa adaptativa acumulando gradientes históricos.
- `Adadelta` — adaptação que reduz a dependência de uma taxa inicial fixa.
- `ASGD` — stochastic gradient descent média.
- `RMSprop` — normalização do gradiente pela média móvel dos quadrados.
- `Rprop` — atualização baseada no sinal do gradiente.
- Schedulers `StepLR`, `MultiStepLR`, `ExponentialLR`, `CosineAnnealingLR`, `LambdaLR` e `MultiplicativeLR` — alteram a taxa de aprendizado ao longo do treinamento.

### Distribuições probabilísticas (`Torch::Distributions`)

- `Normal` — distribuição normal para amostragem e cálculo de log-probabilidade.
- `Distribution` — base para distribuições com amostragem, probabilidade e entropia.
- `ExponentialFamily` — base para distribuições da família exponencial.

### Dados e treinamento em lotes (`Torch::Utils::Data`)

- `Dataset` — contrato para conjuntos indexáveis.
- `IterableDataset` — conjunto percorrido por iterador.
- `TensorDataset` — associa tensores por posição.
- `DataLoader` — cria batches, embaralhamento e iteração sobre datasets.
- `Subset` — visão de um subconjunto por índices.
- `IterableWrapper` — adapta um enumerável para pipeline de dados.
- `DataPipes`, `IterDataPipe`, `FilterIterDataPipe`, `FileLister` e `FileOpener` — composição de leitura e transformação de dados.

### Utilitários

- `Torch::Hub` — baixa arquivos, checkpoints e pesos publicados.
- `Torch::NN::Init` — inicialização de pesos, incluindo estratégias constantes, uniformes e normais.
- `Torch::Autograd` — controle do rastreamento de gradientes.
- `Torch::Backends` e `Torch::Device` — consulta e seleção do dispositivo de execução.

## Como escolher uma aula

- Use **Rumale** quando quiser comparar algoritmos clássicos com `fit`, `predict`, métricas e validação cruzada.
- Use **Torch.rb** quando a aula precisar mostrar tensores, gradientes, redes neurais, funções de perda e otimização.
- Para um modelo completo em Torch.rb, combine uma arquitetura `Torch::NN`, uma perda e um otimizador `Torch::Optim`; a biblioteca fornece os blocos, não um estimador pronto.

As versões podem ganhar novos itens. Para conferir a API exata instalada, use `bundle info rumale`, `bundle info torch-rb` e os READMEs das gems.
