classdef CPO < BaseAlgorithm
    % CPO 冠豪猪优化算法 (Crested Porcupine Optimizer)
    %
    % 一种模拟冠豪猪防御行为的2024年新算法。通过模拟冠豪猪的
    % 四种防御机制实现全局优化。
    %
    % 算法防御机制:
    %   1. 视觉防御: 展示刺毛进行威慑
    %   2. 声音防御: 发出警告声音
    %   3. 气味防御: 释放强烈气味
    %   4. 身体攻击: 使用刺毛直接攻击
    %
    % 参考文献:
    %   E.H. Houssein, A. H. Hussein, M. M. Eid
    %   "Crested porcupine optimizer: A new nature-inspired metaheuristic algorithm"
    %   Knowledge-Based Systems, 2024
    %   DOI: 10.1016/j.knosys.2024.111257
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   cpo = CPO(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = cpo.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Essam H. Houssein
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
                'description', '豪猪种群大小'), ...
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
        function obj = CPO(configStruct)
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

            alpha = 1 - t / MaxIter;
            Tf = cos((pi / 2) * (t / MaxIter)^2);

            for i = 1:N
                r = rand();

                if r < 0.25
                    Xnew = obj.visualDefense(i, N, dim, alpha);
                elseif r < 0.5
                    Xnew = obj.soundDefense(i, N, dim, alpha, Tf);
                elseif r < 0.75
                    Xnew = obj.odorDefense(i, N, dim, alpha, lb, ub);
                else
                    Xnew = obj.physicalAttack(i, N, dim, alpha, Tf);
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
        function Xnew = visualDefense(obj, i, N, dim, alpha)
            j = randi(N);
            while j == i
                j = randi(N);
            end
            k = randi(N);
            while k == i || k == j
                k = randi(N);
            end

            step = alpha * rand(1, dim) .* (obj.positions(j, :) - obj.positions(k, :));
            Xnew = obj.bestPosition + rand(1, dim) .* step;
        end

        function Xnew = soundDefense(obj, i, N, ~, alpha, Tf)
            j = randi(N);
            while j == i
                j = randi(N);
            end

            gamma = 2 * rand() - 1;
            Xnew = obj.positions(i, :) + Tf * alpha * gamma .* ...
                   (obj.positions(j, :) - obj.positions(i, :));
        end

        function Xnew = odorDefense(obj, i, N, dim, alpha, ~, ~)
            randIdx = randperm(N, 2);
            j = randIdx(1);
            k = randIdx(2);

            step = alpha * rand(1, dim) .* (obj.positions(j, :) - obj.positions(k, :));
            Xnew = obj.positions(i, :) + rand(1, dim) .* step;
        end

        function Xnew = physicalAttack(obj, i, N, ~, alpha, Tf)
            j = randi(N);
            while j == i
                j = randi(N);
            end

            step = obj.levyFlight(dim);
            Xnew = obj.bestPosition + Tf * alpha * rand(1, dim) .* ...
                   (obj.positions(j, :) - obj.positions(i, :)) + step;
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
            AlgorithmRegistry.register('CPO', @CPO);
        end
    end
end
