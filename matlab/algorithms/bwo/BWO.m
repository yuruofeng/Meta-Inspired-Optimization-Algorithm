classdef BWO < BaseAlgorithm
    % BWO 白鲸优化算法 (Beluga Whale Optimization)
    %
    % 一种模拟白鲸游泳、捕食和鲸落行为的2022年新算法，
    % 具有良好的探索与开发平衡能力。
    %
    % 算法阶段:
    %   1. 探索阶段: 模拟白鲸成对游泳行为
    %   2. 开发阶段: 模拟白鲸捕食行为
    %   3. 鲸落阶段: 模拟白鲸死亡后沉入海底的行为
    %
    % 参考文献:
    %   T. Zhong, H. Chen, A. A. Heidari, Y. Zhang, X. Zhao, S. Li, C. Yu
    %   "Beluga whale optimization: A novel nature-inspired metaheuristic algorithm"
    %   Knowledge-Based Systems, 2022
    %   DOI: 10.1016/j.knosys.2022.109215
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   bwo = BWO(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = bwo.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Tingqi Zhong, Huiling Chen
    % 实现版本: 1.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 白鲸位置矩阵 (N x Dim)
        fitness              % 适应度向量 (N x 1)
        bestPosition         % 最优位置 (1 x Dim)
        bestFitness          % 最优适应度
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 5, ...
                'max', 10000, ...
                'description', '白鲸种群大小'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 500, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = BWO(configStruct)
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

            for i = 1:N
                if rand() < 0.5
                    r1 = rand();
                    r2 = rand();
                    j = randi(N);
                    while j == i
                        j = randi(N);
                    end
                    k = randi(N);
                    while k == i || k == j
                        k = randi(N);
                    end

                    if rand() < 0.5
                        obj.positions(i, :) = obj.positions(i, :) + r1 * ...
                            (obj.positions(j, :) - obj.positions(k, :));
                    else
                        theta = 2 * pi * rand();
                        obj.positions(i, :) = obj.positions(i, :) + r2 * ...
                            sin(theta) .* (obj.positions(j, :) - obj.positions(i, :)) + ...
                            cos(theta) .* (obj.positions(k, :) - obj.positions(i, :));
                    end
                else
                    r3 = rand();
                    r4 = rand();
                    C1 = 2 * r4 * (1 - t / MaxIter);

                    alpha = (1 - t / MaxIter) * (2 * rand() - 1);

                    if rand() < 0.5
                        obj.positions(i, :) = r3 * obj.bestPosition + ...
                            r4 * (obj.bestPosition - obj.positions(i, :)) - ...
                            C1 * (obj.positions(i, :) - obj.bestPosition);
                    else
                        D = randn(1, dim) * exp(-t / MaxIter);
                        obj.positions(i, :) = obj.bestPosition + D + ...
                            alpha * (obj.positions(i, :) - obj.bestPosition);
                    end
                end

                wf = 0.1 * exp(-t / MaxIter);
                if rand() < wf
                    j = randi(N);
                    while j == i
                        j = randi(N);
                    end

                    C2 = 0.05 * (1 - t / MaxIter);
                    step = obj.levyFlight(dim);
                    obj.positions(i, :) = obj.positions(i, :) + C2 * ...
                        (obj.positions(j, :) - obj.positions(i, :)) + ...
                        C2 * step .* (obj.positions(i, :) - obj.bestPosition);
                end

                obj.positions(i, :) = obj.clampToBounds(obj.positions(i, :), lb, ub);
            end

            obj.fitness = obj.evaluatePopulation(obj.positions);

            [currentBestFit, currentBestIdx] = min(obj.fitness);
            if currentBestFit < obj.bestFitness
                obj.bestFitness = currentBestFit;
                obj.bestPosition = obj.positions(currentBestIdx, :);
            end

            obj.bestSolution = obj.bestPosition;
        end

        function tf = shouldStop(obj)
            tf = obj.currentIteration >= obj.config.maxIterations;
        end
    end

    methods (Access = protected)
        function steps = levyFlight(obj, dim)
            beta = 1.5;
            sigma = (gamma(1 + beta) * sin(pi * beta / 2) / ...
                     (gamma((1 + beta) / 2) * beta * 2^((beta - 1) / 2)))^(1 / beta);

            u = randn(1, dim) * sigma;
            v = randn(1, dim);
            steps = u ./ (abs(v).^(1 / beta));
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
        end
    end

    methods (Static)
        function register()
            AlgorithmRegistry.register('BWO', @BWO);
        end
    end
end
