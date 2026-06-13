classdef NRBO < BaseAlgorithm
    % NRBO 牛顿-拉夫森优化算法 (Newton-Raphson-Based Optimizer)
    %
    % 一种基于牛顿-拉夫森方法的元启发式算法。利用牛顿-拉夫森
    % 迭代法的思想实现全局优化。
    %
    % 算法原理:
    %   1. 模拟牛顿-拉夫森迭代求解根的过程
    %   2. 通过梯度信息调整搜索方向
    %   3. 结合种群优化策略实现全局搜索
    %   4. 自适应调整搜索步长
    %
    % 参考文献:
    %   J. Xue, B. Shen
    %   "Newton-Raphson-based optimizer: A new meta-heuristic algorithm for global optimization"
    %   Knowledge-Based Systems, 2023
    %   DOI: 10.1016/j.knosys.2023.110552
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   nrbo = NRBO(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = nrbo.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Jiankai Xue, Bo Shen
    % 实现版本: 1.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 种群位置矩阵 (N x Dim)
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
                'description', '种群大小'), ...
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
        function obj = NRBO(configStruct)
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

            delta = 1 - t / MaxIter;

            for i = 1:N
                r1 = randi(N);
                while r1 == i
                    r1 = randi(N);
                end
                r2 = randi(N);
                while r2 == i || r2 == r1
                    r2 = randi(N);
                end

                rho = rand() * 2 - 1;

                N_I = rand() * (2 - delta);

                step = obj.positions(r1, :) - obj.positions(r2, :);

                Xnew = obj.positions(i, :) + rho .* ...
                       (obj.bestPosition - obj.positions(i, :)) + ...
                       N_I .* step;

                if rand() < 0.5
                    Xnew = Xnew + rand() .* delta .* ...
                           (obj.positions(r1, :) - obj.positions(r2, :));
                else
                    Xnew = Xnew - rand() .* delta .* ...
                           (obj.positions(r1, :) - obj.positions(r2, :));
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
            AlgorithmRegistry.register('NRBO', @NRBO);
        end
    end
end
