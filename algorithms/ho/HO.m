classdef HO < BaseAlgorithm
    % HO 蜜獾优化算法 (Honey Badger Optimizer)
    %
    % 一种模拟蜜獾觅食行为的元启发式算法。通过模拟蜜獾的
    % 挖掘和蜂蜜引导行为实现全局优化。
    %
    % 算法行为:
    %   1. 挖掘行为: 模拟蜜獾挖掘洞穴寻找猎物
    %   2. 蜂蜜引导: 模拟蜜獾跟随蜂蜜向导找到蜂巢
    %   3. 密度因子: 控制探索与开发的平衡
    %
    % 参考文献:
    %   F.A. Hashim, E.H. Houssein, M.S. Mabrouk, W. Al-Atabany
    %   "Honey Badger Algorithm: New metaheuristic algorithm for solving optimization problems"
    %   Mathematics and Computers in Simulation, 2022
    %   DOI: 10.1016/j.matcom.2021.08.013
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   ho = HO(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = ho.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Fatma A. Hashim
    % 实现版本: 1.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 种群位置矩阵 (N x Dim)
        fitness              % 适应度向量 (N x 1)
        bestPosition         % 最优位置 (猎物位置, 1 x Dim)
        bestFitness          % 最优适应度
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 5, ...
                'max', 10000, ...
                'description', '蜜獾种群大小'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 500, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'C', struct(...
                'type', 'float', ...
                'default', 2, ...
                'min', 0.1, ...
                'max', 10, ...
                'description', '密度因子参数'), ...
            'beta', struct(...
                'type', 'float', ...
                'default', 6, ...
                'min', 1, ...
                'max', 12, ...
                'description', '蜂蜜引导能力参数'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = HO(configStruct)
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
            C = obj.config.C;

            alpha = C * exp(-t / MaxIter);

            for i = 1:N
                r = rand();

                if r < 0.5
                    j = randi(N);
                    while j == i
                        j = randi(N);
                    end

                    I = obj.calculateIntensity(i, j);

                    r7 = rand();
                    if r7 < 0.5
                        Xnew = obj.bestPosition + ...
                               rand(1, dim) .* alpha .* I .* ...
                               (obj.bestPosition - obj.positions(i, :));
                    else
                        Xnew = obj.bestPosition + ...
                               obj.levyFlight(dim) .* I .* ...
                               (obj.bestPosition - obj.positions(i, :));
                    end
                else
                    j = randi(N);
                    while j == i
                        j = randi(N);
                    end

                    Xnew = obj.positions(i, :) + ...
                           rand(1, dim) .* alpha .* ...
                           (obj.positions(j, :) - obj.positions(i, :)) + ...
                           rand(1, dim) .* ...
                           (obj.positions(j, :) - obj.positions(i, :));
                end

                Xnew = obj.clampToBounds(Xnew, lb, ub);

                newFitness = obj.evaluateSolution(Xnew);

                if newFitness < obj.fitness(i)
                    obj.positions(i, :) = Xnew;
                    obj.fitness(i) = newFitness;

                    if newFitness < obj.bestFitness
                        obj.bestFitness = newFitness;
                        obj.bestPosition = Xnew;
                    end
                end
            end

            obj.bestSolution = obj.bestPosition;
        end

        function tf = shouldStop(obj)
            tf = obj.currentIteration >= obj.config.maxIterations;
        end
    end

    methods (Access = protected)
        function I = calculateIntensity(obj, i, j)
            di = norm(obj.positions(i, :) - obj.bestPosition);
            dj = norm(obj.positions(j, :) - obj.bestPosition);

            epsilon = 1e-10;

            di = max(di, epsilon);
            dj = max(dj, epsilon);

            S = obj.config.beta * (1 - rand()) * di / dj;

            I = S * rand(1, size(obj.positions, 2));
        end

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
            AlgorithmRegistry.register('HO', @HO);
        end
    end
end
