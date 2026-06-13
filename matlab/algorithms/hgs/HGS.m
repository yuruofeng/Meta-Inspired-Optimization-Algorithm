classdef HGS < BaseAlgorithm
    % HGS 饥饿游戏搜索算法 (Hunger Games Search)
    %
    % 一种基于饥饿驱动行为的元启发式优化算法，灵感来源于生物界中饥饿是所有动物
    % 生活中行为、决策和行动的最重要的稳态动机。该算法通过模拟饥饿对搜索行为的
    % 影响来实现全局优化。
    %
    % 核心机制:
    %   1. 饥饿角色建模 - 每个个体维护饥饿度
    %   2. 接近食物 - 通过位置更新向最优解靠拢
    %   3. 自适应权重 - W1和W2动态调整搜索强度
    %   4. 活动范围控制 - R参数限制搜索范围
    %
    % 参考文献:
    %   Y. Yang, H. Chen, A. A. Heidari, A. H. Gandomi
    %   "Hunger games search: Visions, conception, implementation, deep analysis, 
    %    perspectives, and towards performance shifts"
    %   Expert Systems with Applications, 2021
    %   DOI: 10.1016/j.eswa.2021.114865
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   hgs = HGS(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = hgs.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Yutao Yang, Huiling Chen, et al.
    % 重构版本: 1.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 种群位置矩阵 (N x Dim)
        hungers              % 饥饿度向量 (N x 1)
        bestPosition         % 全局最优位置 (1 x Dim)
        secondBestPosition   % 次优位置 (1 x Dim)
        secondBestFitness    % 次优适应度
        allFitness           % 所有个体适应度 (N x 1)
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 10, ...
                'max', 10000, ...
                'description', '种群个体数量'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 500, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息'), ...
            'hungerThreshold', struct(...
                'type', 'double', ...
                'default', 0.3, ...
                'min', 0.0, ...
                'max', 1.0, ...
                'description', '饥饿阈值，控制饥饿度更新') ...
        )
    end

    methods
        function obj = HGS(configStruct)
            % HGS 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，可选字段:
            %     - populationSize: 种群大小 (默认: 30)
            %     - maxIterations: 最大迭代次数 (默认: 500)
            %     - verbose: 是否显示进度 (默认: true)
            %     - hungerThreshold: 饥饿阈值 (默认: 0.3)

            if nargin < 1 || isempty(configStruct)
                configStruct = struct();
            end

            obj = obj@BaseAlgorithm(configStruct);
        end

        function initialize(obj, problem)
            % initialize 初始化种群
            %
            % 输入参数:
            %   problem - 问题对象，需包含 lb, ub, dim 字段

            lb = problem.lb;
            ub = problem.ub;
            dim = problem.dim;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;

            obj.positions = Initialization(N, dim, ub, lb);

            obj.bestPosition = zeros(1, dim);
            obj.bestFitness = Inf;
            obj.secondBestPosition = zeros(1, dim);
            obj.secondBestFitness = Inf;

            obj.allFitness = obj.evaluatePopulation(obj.positions);

            [sortedFitness, sortedIndices] = sort(obj.allFitness);
            obj.bestFitness = sortedFitness(1);
            obj.bestPosition = obj.positions(sortedIndices(1), :);
            obj.secondBestFitness = sortedFitness(2);
            obj.secondBestPosition = obj.positions(sortedIndices(2), :);

            obj.hungers = ones(N, 1);

            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代
            %
            % 包括更新饥饿度、计算权重、更新位置

            lb = obj.problem.lb;
            ub = obj.problem.ub;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;
            currentIter = obj.currentIteration + 1;

            obj.allFitness = obj.evaluatePopulation(obj.positions);

            for i = 1:N
                if obj.allFitness(i) < obj.bestFitness
                    obj.secondBestFitness = obj.bestFitness;
                    obj.secondBestPosition = obj.bestPosition;
                    obj.bestFitness = obj.allFitness(i);
                    obj.bestPosition = obj.positions(i, :);
                elseif obj.allFitness(i) < obj.secondBestFitness && ...
                       obj.allFitness(i) > obj.bestFitness
                    obj.secondBestFitness = obj.allFitness(i);
                    obj.secondBestPosition = obj.positions(i, :);
                end
            end

            sumHungers = sum(obj.hungers);
            for i = 1:N
                obj.hungers(i) = obj.updateHunger(obj.allFitness(i), ...
                    obj.bestFitness, obj.hungers(i), sumHungers, N);
            end

            minHunger = min(obj.hungers);
            if minHunger == 0
                minHunger = 1e-10;
            end

            a = 2 - currentIter * (2 / MaxIter);

            for i = 1:N
                W1 = obj.calculateW1(obj.hungers(i), sumHungers, N);
                W2 = obj.calculateW2(obj.hungers(i), minHunger);

                R = 2 * a * rand - a;

                for j = 1:size(obj.positions, 2)
                    r1 = rand;
                    r2 = rand;
                    r3 = rand;

                    if r1 < 0.5
                        vb = (2 * rand - 1) * W2;
                        vc = obj.hungers(i);
                        
                        obj.positions(i, j) = W1 * obj.bestPosition(j) + ...
                            R * abs(obj.bestPosition(j) - obj.positions(i, j)) * ...
                            vb + vc * (obj.secondBestPosition(j) - obj.positions(i, j));
                    else
                        if r2 < obj.config.hungerThreshold
                            obj.positions(i, j) = obj.positions(i, j) + ...
                                R * (obj.bestPosition(j) - obj.positions(i, j));
                        else
                            E = cos(2 * pi * r3);
                            obj.positions(i, j) = obj.positions(i, j) + ...
                                E * abs(obj.bestPosition(j) - obj.positions(i, j));
                        end
                    end
                end

                obj.positions(i, :) = obj.clampToBounds(obj.positions(i, :), lb, ub);
            end

            obj.bestFitness = min(obj.allFitness);
            [~, bestIdx] = min(obj.allFitness);
            obj.bestPosition = obj.positions(bestIdx, :);

            obj.convergenceCurve(currentIter) = obj.bestFitness;

            if obj.config.verbose && mod(currentIter, 50) == 0
                obj.displayProgress(sprintf('Best fitness: %.6e', obj.bestFitness));
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
                validatedConfig.populationSize = 30;
            end

            if isfield(config, 'maxIterations')
                validatedConfig.maxIterations = max(1, round(config.maxIterations));
            else
                validatedConfig.maxIterations = 500;
            end

            if isfield(config, 'verbose')
                validatedConfig.verbose = logical(config.verbose);
            else
                validatedConfig.verbose = true;
            end

            if isfield(config, 'hungerThreshold')
                hungerThreshold = config.hungerThreshold;
                if hungerThreshold < 0
                    hungerThreshold = 0;
                elseif hungerThreshold > 1
                    hungerThreshold = 1;
                end
                validatedConfig.hungerThreshold = hungerThreshold;
            else
                validatedConfig.hungerThreshold = 0.3;
            end
        end
    end

    methods (Access = protected)
        function hunger = updateHunger(obj, fitness, bestFitness, currentHunger, sumHungers, N)
            % updateHunger 更新个体的饥饿度
            %
            % 输入参数:
            %   fitness - 当前个体适应度
            %   bestFitness - 全局最优适应度
            %   currentHunger - 当前饥饿度
            %   sumHungers - 所有个体饥饿度之和
            %   N - 种群大小
            %
            % 输出参数:
            %   hunger - 更新后的饥饿度

            r3 = rand;
            r4 = rand;
            r5 = rand;

            if fitness == bestFitness
                hunger = 0;
            else
                H = (fitness - bestFitness) / (obj.allFitness(obj.findSecondBest()) - bestFitness + eps);
                hunger = currentHunger + r3 * (H * sumHungers / N - currentHunger);
            end

            hunger = max(0, hunger);

            if r4 < 0.25 && hunger > 0
                hunger = hunger * (1 + r5);
            end
        end

        function W1 = calculateW1(obj, hunger, sumHungers, N)
            % calculateW1 计算自适应权重W1
            %
            % 输入参数:
            %   hunger - 当前个体饥饿度
            %   sumHungers - 所有个体饥饿度之和
            %   N - 种群大小
            %
            % 输出参数:
            %   W1 - 权重值

            r2 = rand;
            W1 = 2 * rand * (hunger / (sumHungers / N + eps)) - 1;
            W1 = W1 * exp(-r2);
        end

        function W2 = calculateW2(obj, hunger, minHunger)
            % calculateW2 计算自适应权重W2
            %
            % 输入参数:
            %   hunger - 当前个体饥饿度
            %   minHunger - 最小饥饿度
            %
            % 输出参数:
            %   W2 - 权重值

            r1 = rand;
            W2 = 2 * r1 * (1 - hunger / (minHunger + eps));
        end

        function idx = findSecondBest(obj)
            % findSecondBest 找到次优个体的索引
            %
            % 输出参数:
            %   idx - 次优个体索引

            [sortedFitness, sortedIndices] = sort(obj.allFitness);
            if length(sortedIndices) >= 2
                idx = sortedIndices(2);
            else
                idx = sortedIndices(1);
            end
        end
    end

    methods (Static)
        function register()
            % register 将算法注册到AlgorithmRegistry
            %
            % 此方法在系统初始化时调用，将HGS算法注册到全局注册表。

            AlgorithmRegistry.register('HGS', '1.0.0', 'HGS');
        end
    end
end
