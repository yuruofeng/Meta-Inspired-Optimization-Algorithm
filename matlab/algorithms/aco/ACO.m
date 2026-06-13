classdef ACO < BaseAlgorithm
    % ACO 蚁群优化算法 (Ant Colony Optimization)
    %
    % 一种模拟蚂蚁觅食行为的群体智能算法。通过信息素的正反馈机制
    % 引导搜索，适用于连续优化问题（离散版本可用于组合优化)。
    %
    % 算法原理:
    %   1. 每只蚂蚁根据信息素浓度和启发式信息选择路径
    %   2. 完成路径后释放信息素
    %   3. 信息素随时间挥发
    %   4. 较优路径获得更多信息素
    %
    % 连续域适配:
    %   - 使用高斯核函数采样
    %   - 信息素表示为解空间的概率分布
    %
    % 参考文献:
    %   M. Dorigo, V. Maniezzo, A. Colorni
    %   "Ant System: Optimization by a Colony of Cooperating Agents"
    %   IEEE Transactions on Systems, Man, and Cybernetics, 1996
    %   DOI: 10.1109/3477.484436
    %
    % 时间复杂度: O(MaxIter × N × Dim × K)
    % 空间复杂度: O(N × Dim × K)
    % 其中 K 为高斯核数量
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   aco = ACO(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = aco.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Marco Dorigo
    % 实现版本: 1.0.0 (连续域适配)
    % 日期: 2025

    properties (Access = protected)
        archive             % 解档案 (K x Dim)
        archiveFitness      % 档案适应度 (K x 1)
        weights             % 权重向量 (K x 1)
        sigma               % 标准差向量 (K x Dim)
        bestPosition        % 最优位置 (1 x Dim)
        bestFitness         % 最优适应度
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 5, ...
                'max', 10000, ...
                'description', '蚂蚁数量'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 500, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'archiveSize', struct(...
                'type', 'integer', ...
                'default', 50, ...
                'min', 10, ...
                'max', 10000, ...
                'description', '解档案大小'), ...
            'q', struct(...
                'type', 'float', ...
                'default', 0.5, ...
                'min', 0.1, ...
                'max', 10, ...
                'description', '学习速率参数'), ...
            'xi', struct(...
                'type', 'float', ...
                'default', 0.85, ...
                'min', 0, ...
                'max', 1, ...
                'description', '信息素衰减系数'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = ACO(configStruct)
            if nargin < 1 || isempty(configStruct)
                configStruct = struct();
            end
            obj = obj@BaseAlgorithm(configStruct);
        end

        function initialize(obj, problem)
            lb = problem.lb;
            ub = problem.ub;
            dim = problem.dim;
            K = obj.config.archiveSize;
            MaxIter = obj.config.maxIterations;

            obj.archive = Initialization(K, dim, ub, lb);
            obj.archiveFitness = obj.evaluatePopulation(obj.archive);

            [obj.archiveFitness, sortIdx] = sort(obj.archiveFitness);
            obj.archive = obj.archive(sortIdx, :);

            obj.bestFitness = obj.archiveFitness(1);
            obj.bestPosition = obj.archive(1, :);

            obj.weights = obj.calculateWeights(K);
            obj.sigma = zeros(K, dim);

            obj.bestSolution = obj.bestPosition;
            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            lb = obj.problem.lb;
            ub = obj.problem.ub;
            dim = obj.problem.dim;
            N = obj.config.populationSize;
            K = obj.config.archiveSize;

            obj.updateSigma(K, dim);

            newSolutions = zeros(N, dim);
            newFitness = zeros(N, 1);

            for i = 1:N
                j = obj.selectGaussianKernel(K);
                newSolutions(i, :) = obj.sampleFromGaussian(j, dim, lb, ub);
                newFitness(i) = obj.evaluateSolution(newSolutions(i, :));
            end

            combinedArchive = [obj.archive; newSolutions];
            combinedFitness = [obj.archiveFitness; newFitness];

            [~, sortIdx] = sort(combinedFitness);
            obj.archive = combinedArchive(sortIdx(1:K), :);
            obj.archiveFitness = combinedFitness(sortIdx(1:K));

            if obj.archiveFitness(1) < obj.bestFitness
                obj.bestFitness = obj.archiveFitness(1);
                obj.bestPosition = obj.archive(1, :);
            end

            obj.bestSolution = obj.bestPosition;
        end

        function tf = shouldStop(obj)
            tf = obj.currentIteration >= obj.config.maxIterations;
        end
    end

    methods (Access = protected)
        function weights = calculateWeights(obj, K)
            q = obj.config.q;
            ranks = (1:K)';

            weights = 1 / (q * K * sqrt(2 * pi)) * ...
                      exp(-(ranks - 1).^2 / (2 * (q * K)^2));

            weights = weights / sum(weights);
        end

        function j = selectGaussianKernel(obj, K)
            r = rand() * sum(obj.weights);
            cumSum = 0;
            j = 1;

            for k = 1:K
                cumSum = cumSum + obj.weights(k);
                if cumSum >= r
                    j = k;
                    break;
                end
            end
        end

        function solution = sampleFromGaussian(obj, j, dim, lb, ub)
            solution = zeros(1, dim);

            for d = 1:dim
                mu = obj.archive(j, d);
                sigmaVal = obj.sigma(j, d);

                solution(d) = mu + sigmaVal * randn();

                while solution(d) < lb(d) || solution(d) > ub(d)
                    solution(d) = mu + sigmaVal * randn();
                end
            end
        end

        function updateSigma(obj, K, dim)
            xi = obj.config.xi;

            for d = 1:dim
                col = obj.archive(:, d);
                for j = 1:K
                    diffSum = sum(abs(col - col(j)));
                    obj.sigma(j, d) = xi * diffSum / (K - 1);
                end
            end

            obj.sigma(obj.sigma < 1e-10) = 1e-10;
        end

        function validatedConfig = validateConfig(obj, configStruct)
            validatedConfig = struct();
            
            fields = fieldnames(obj.PARAM_SCHEMA);
            for i = 1:length(fields)
                field = fields{i};
                schema = obj.PARAM_SCHEMA.(field);
                
                if isfield(configStruct, field)
                    validatedConfig.(field) = configStruct.(field);
                else
                    validatedConfig.(field) = schema.default;
                end
            end

            if validatedConfig.archiveSize < validatedConfig.populationSize
                warning('ACO:Config', ...
                    'Archive size (%d) < population size (%d). Consider increasing archive size.', ...
                    validatedConfig.archiveSize, validatedConfig.populationSize);
            end
        end
    end

    methods (Static)
        function register()
            AlgorithmRegistry.register('ACO', @ACO);
        end
    end
end
