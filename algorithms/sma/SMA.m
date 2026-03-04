classdef SMA < BaseAlgorithm
    % SMA 黏菌算法 (Slime Mould Algorithm)
    %
    % 一种模拟黏菌觅食行为的元启发式算法。通过模拟黏菌的
    % 包围、震荡和收缩机制实现优化。
    %
    % 算法原理:
    %   1. 接近食物: 黏菌根据食物浓度调整位置
    %   2. 包围食物: 优秀个体引导种群包围优质食物源
    %   3. 震荡机制: 黏菌在探索和开发之间震荡
    %
    % 参考文献:
    %   S. Li, H. Chen, M. Wang, A. A. Heidari, S. Mirjalili
    %   "Slime mould algorithm: A new method for stochastic optimization"
    %   Future Generation Computer Systems, 2020
    %   DOI: 10.1016/j.future.2020.03.055
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   sma = SMA(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = sma.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Shimin Li, Huiling Chen
    % 实现版本: 1.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 黏菌位置矩阵 (N x Dim)
        fitness              % 适应度向量 (N x 1)
        bestPosition         % 最优位置 (1 x Dim)
        bestFitness          % 最优适应度
        worstFitness         % 最差适应度
        W                   % 权重矩阵 (N x Dim)
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 5, ...
                'max', 10000, ...
                'description', '黏菌种群大小'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 500, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'z', struct(...
                'type', 'float', ...
                'default', 0.03, ...
                'min', 0, ...
                'max', 1, ...
                'description', '震荡参数'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = SMA(configStruct)
            if nargin < 1 || isempty(configStruct)
                configStruct = struct();
            end
            obj = obj@BaseAlgorithm(configStruct);
        end

        function initialize(obj, problem)
            lb = problem.lb;
            ub = problem.ub;
            dim = problem.dim;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;

            obj.positions = Initialization(N, dim, ub, lb);

            obj.fitness = obj.evaluatePopulation(obj.positions);

            [obj.bestFitness, bestIdx] = min(obj.fitness);
            obj.bestPosition = obj.positions(bestIdx, :);

            [obj.worstFitness, ~] = max(obj.fitness);

            obj.W = ones(N, dim);

            obj.bestSolution = obj.bestPosition;
            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            lb = obj.problem.lb;
            ub = problem.ub;
            dim = obj.problem.dim;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;
            t = obj.currentIteration + 1;
            z = obj.config.z;

            [sortedFitness, sortIdx] = sort(obj.fitness);
            sortedPositions = obj.positions(sortIdx, :);

            for i = 1:N
                if i <= N / 2
                    obj.W(i, :) = 1 + rand(1, dim) * ...
                        log10((sortedFitness(1) - sortedFitness(i)) / ...
                              (sortedFitness(1) - obj.worstFitness) + 1);
                else
                    obj.W(i, :) = 1 - rand(1, dim) * ...
                        log10((sortedFitness(1) - sortedFitness(i)) / ...
                              (sortedFitness(1) - obj.worstFitness) + 1);
                end
            end

            for i = 1:N
                if rand() < z
                    obj.positions(i, :) = lb + rand(1, dim) .* (ub - lb);
                else
                    A = randi([1 N]);
                    B = randi([1 N]);
                    while B == A
                        B = randi([1 N]);
                    end

                    if rand() < 0.5
                        obj.positions(i, :) = sortedPositions(1, :) + ...
                            rand(1, dim) .* obj.W(i, :) .* ...
                            (sortedPositions(A, :) - sortedPositions(B, :));
                    else
                        obj.positions(i, :) = sortedPositions(1, :) - ...
                            rand(1, dim) .* obj.W(i, :) .* ...
                            (sortedPositions(A, :) - sortedPositions(B, :));
                    end
                end

                obj.positions(i, :) = obj.clampToBounds(obj.positions(i, :), lb, ub);
            end

            obj.fitness = obj.evaluatePopulation(obj.positions);

            [currentBestFit, currentBestIdx] = min(obj.fitness);
            if currentBestFit < obj.bestFitness
                obj.bestFitness = currentBestFit;
                obj.bestPosition = obj.positions(currentBestIdx, :);
            end

            [~, currentWorstFit] = max(obj.fitness);
            if currentWorstFit > obj.worstFitness
                obj.worstFitness = currentWorstFit;
            end

            obj.bestSolution = obj.bestPosition;
        end

        function tf = shouldStop(obj)
            tf = obj.currentIteration >= obj.config.maxIterations;
        end
    end

    methods (Access = protected)
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
        end
    end

    methods (Static)
        function register()
            AlgorithmRegistry.register('SMA', @SMA);
        end
    end
end
