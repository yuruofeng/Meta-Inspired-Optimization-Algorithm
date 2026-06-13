classdef MOEAD < MOBaseAlgorithm
    % MOEA/D 基于分解的多目标进化算法 (Multi-Objective Evolutionary Algorithm based on Decomposition)
    %
    % 一种将多目标优化问题分解为多个单目标子问题的经典算法，通过邻域协作机制
    % 和标量化方法实现高效的Pareto前沿搜索。
    %
    % 核心机制:
    %   1. 权重向量分解 - 将MOP分解为N个单目标子问题
    %   2. 邻域协作 - 利用相邻子问题的信息进行优化
    %   3. 标量化函数 - 使用切比雪夫聚合函数
    %   4. 外部存档 - 保存非支配解
    %
    % 参考文献:
    %   Q. Zhang, H. Li
    %   "MOEA/D: A Multiobjective Evolutionary Algorithm Based on Decomposition"
    %   IEEE Transactions on Evolutionary Computation, 2007
    %   DOI: 10.1109/TEVC.2007.892759
    %
    % 时间复杂度: O(MaxIter × N × T)
    % 空间复杂度: O(N × Dim + ArchiveSize × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 100, 'maxIterations', 200);
    %   moead = MOEAD(config);
    %   problem.lb = 0; problem.ub = 1; problem.dim = 10;
    %   problem.objCount = 2;
    %   problem.evaluate = @(x) ZDT1(x);
    %   result = moead.run(problem);
    %   result.plot();
    %
    % 原始作者: Qingfu Zhang, Hui Li
    % 重构版本: 1.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 种群位置矩阵 (N x Dim)
        fitness              % 适应度矩阵 (N x objCount)
        weights              % 权重向量矩阵 (N x objCount)
        neighborhood         % 邻域矩阵 (N x T)
        idealPoint           % 理想点 (1 x objCount)
        T                    % 邻域大小
        delta                % 邻域选择概率
        nr                   % 最大更新数量
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 100, ...
                'min', 10, ...
                'max', 10000, ...
                'description', '种群大小(子问题数量)'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 200, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'archiveMaxSize', struct(...
                'type', 'integer', ...
                'default', 100, ...
                'min', 10, ...
                'max', 1000, ...
                'description', 'Pareto存档最大容量'), ...
            'T', struct(...
                'type', 'integer', ...
                'default', 20, ...
                'min', 5, ...
                'max', 100, ...
                'description', '邻域大小'), ...
            'delta', struct(...
                'type', 'float', ...
                'default', 0.9, ...
                'min', 0, ...
                'max', 1, ...
                'description', '邻域选择概率'), ...
            'nr', struct(...
                'type', 'integer', ...
                'default', 2, ...
                'min', 1, ...
                'max', 20, ...
                'description', '最大更新数量'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = MOEAD(configStruct)
            % MOEAD 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体

            if nargin < 1 || isempty(configStruct)
                configStruct = struct();
            end

            obj = obj@MOBaseAlgorithm(configStruct);
        end

        function initialize(obj, problem)
            % initialize 初始化种群、权重向量和邻域

            lb = problem.lb;
            ub = problem.ub;
            dim = problem.dim;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;
            obj.archiveMaxSize = int32(obj.config.archiveMaxSize);
            obj.objCount = int32(problem.objCount);

            obj.T = obj.config.T;
            obj.delta = obj.config.delta;
            obj.nr = obj.config.nr;

            if isscalar(lb)
                lb = lb * ones(1, dim);
                ub = ub * ones(1, dim);
            end
            obj.problem.lb = lb;
            obj.problem.ub = ub;

            obj.positions = Initialization(N, dim, ub, lb);
            obj.fitness = zeros(N, obj.objCount);

            for i = 1:N
                obj.fitness(i, :) = obj.evaluateSolution(obj.positions(i, :));
            end

            obj.weights = obj.generateWeights(N, obj.objCount);

            obj.neighborhood = obj.calculateNeighborhood(obj.weights, obj.T);

            obj.idealPoint = min(obj.fitness, [], 1);

            obj.archiveX = zeros(obj.archiveMaxSize, dim);
            obj.archiveF = inf(obj.archiveMaxSize, obj.objCount);
            obj.archiveSize = int32(0);

            obj.updateArchive(obj.positions, obj.fitness);

            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代
            %
            % 对每个子问题进行邻域协作和更新

            lb = obj.problem.lb;
            ub = obj.problem.ub;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;
            currentIter = obj.currentIteration + 1;
            dim = size(obj.positions, 2);

            for i = 1:N
                if rand() < obj.delta
                    indices = obj.neighborhood(i, :);
                else
                    indices = randperm(N, obj.T);
                end

                parent1 = indices(randi(length(indices)));
                parent2 = indices(randi(length(indices)));

                child = obj.positions(parent1, :);
                for j = 1:dim
                    if rand() < 0.5
                        child(j) = obj.positions(parent1, j) + ...
                            0.5 * (obj.positions(parent2, j) - obj.positions(parent1, j));
                    end
                end

                child = child + 0.5 * (rand(1, dim) - 0.5);
                child = obj.clampToBounds(child, lb, ub);

                childFitness = obj.evaluateSolution(child);

                c = 0;
                for j = 1:length(indices)
                    k = indices(j);

                    f1 = obj.chebyshevScalar(obj.fitness(k, :), obj.weights(k, :));
                    f2 = obj.chebyshevScalar(childFitness, obj.weights(k, :));

                    if f2 < f1 && c < obj.nr
                        obj.positions(k, :) = child;
                        obj.fitness(k, :) = childFitness;
                        c = c + 1;
                    end
                end

                obj.idealPoint = min(obj.idealPoint, childFitness);
            end

            obj.updateArchive(obj.positions, obj.fitness);

            igd = obj.calculateIGD();
            obj.convergenceCurve(currentIter) = igd;

            if obj.config.verbose && mod(currentIter, 20) == 0
                obj.displayProgress(sprintf('IGD: %.6e, Archive size: %d', ...
                    igd, obj.archiveSize));
            end
        end

        function tf = shouldStop(obj)
            % shouldStop 判断是否应该停止迭代
            %
            % 输出参数:
            %   tf - true表示停止，false表示继续

            tf = obj.currentIteration >= obj.config.maxIterations;
        end

        function validatedConfig = validateConfig(obj, config)
            % validateConfig 验证并规范化配置参数
            %
            % 输入参数:
            %   config - 配置结构体
            %
            % 输出参数:
            %   validatedConfig - 验证后的配置

            validatedConfig = struct();

            if isfield(config, 'populationSize')
                validatedConfig.populationSize = max(10, round(config.populationSize));
            else
                validatedConfig.populationSize = 100;
            end

            if isfield(config, 'maxIterations')
                validatedConfig.maxIterations = max(1, round(config.maxIterations));
            else
                validatedConfig.maxIterations = 200;
            end

            if isfield(config, 'archiveMaxSize')
                validatedConfig.archiveMaxSize = max(10, round(config.archiveMaxSize));
            else
                validatedConfig.archiveMaxSize = 100;
            end

            if isfield(config, 'T')
                validatedConfig.T = max(5, round(config.T));
            else
                validatedConfig.T = 20;
            end

            if isfield(config, 'delta')
                validatedConfig.delta = min(1, max(0, config.delta));
            else
                validatedConfig.delta = 0.9;
            end

            if isfield(config, 'nr')
                validatedConfig.nr = max(1, round(config.nr));
            else
                validatedConfig.nr = 2;
            end

            if isfield(config, 'verbose')
                validatedConfig.verbose = logical(config.verbose);
            else
                validatedConfig.verbose = true;
            end
        end
    end

    methods (Access = protected)
        function weights = generateWeights(obj, N, M)
            % generateWeights 生成均匀分布的权重向量
            %
            % 输入参数:
            %   N - 种群大小
            %   M - 目标数量
            %
            % 输出参数:
            %   weights - 权重向量矩阵 (N x M)

            weights = zeros(N, M);

            if M == 2
                for i = 1:N
                    weights(i, 1) = (i - 1) / (N - 1);
                    weights(i, 2) = 1 - weights(i, 1);
                end
            else
                for i = 1:N
                    weights(i, :) = rand(1, M);
                    weights(i, :) = weights(i, :) / sum(weights(i, :));
                end
            end
        end

        function neighborhood = calculateNeighborhood(obj, weights, T)
            % calculateNeighborhood 计算每个子问题的邻域
            %
            % 输入参数:
            %   weights - 权重向量矩阵
            %   T - 邻域大小
            %
            % 输出参数:
            %   neighborhood - 邻域矩阵 (N x T)

            N = size(weights, 1);
            neighborhood = zeros(N, T);

            for i = 1:N
                distances = zeros(N, 1);
                for j = 1:N
                    distances(j) = norm(weights(i, :) - weights(j, :));
                end

                [~, sortedIndices] = sort(distances);
                neighborhood(i, :) = sortedIndices(1:T);
            end
        end

        function scalarValue = chebyshevScalar(obj, f, lambda)
            % chebyshevScalar 切比雪夫标量化函数
            %
            % 输入参数:
            %   f - 目标函数值向量
            %   lambda - 权重向量
            %
            % 输出参数:
            %   scalarValue - 标量化值

            lambda(lambda < 1e-6) = 1e-6;

            scalarValue = max(lambda .* abs(f - obj.idealPoint));
        end

        function igd = calculateIGD(obj)
            % calculateIGD 计算反向世代距离 (IGD)
            %
            % 输出参数:
            %   igd - IGD值

            if obj.archiveSize == 0
                igd = Inf;
                return;
            end

            referencePoints = obj.weights;
            nRef = size(referencePoints, 1);

            igd = 0;
            for i = 1:nRef
                minDist = Inf;
                for j = 1:obj.archiveSize
                    dist = norm(referencePoints(i, :) - obj.archiveF(j, :));
                    if dist < minDist
                        minDist = dist;
                    end
                end
                igd = igd + minDist;
            end
            igd = igd / nRef;
        end
    end

    methods (Static)
        function register()
            % register 将算法注册到AlgorithmRegistry
            %
            % 此方法在系统初始化时调用，将MOEA/D算法注册到全局注册表。

            AlgorithmRegistry.register('MOEAD', '1.0.0', 'MOEAD');
        end
    end
end
