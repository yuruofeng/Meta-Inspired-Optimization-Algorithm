classdef MPA < BaseAlgorithm
    % MPA 海洋捕食者算法 (Marine Predators Algorithm)
    %
    % 一种模拟海洋捕食者觅食行为的元启发式优化算法，灵感来源于海洋生态系统中
    % 捕食者的Lévy飞行和布朗运动策略。通过模拟捕食者与猎物的相互作用实现
    % 全局优化。
    %
    % 核心机制:
    %   1. 海洋记忆机制 - 存储历史最优位置
    %   2. Lévy飞行与布朗运动 - 平衡探索与开发
    %   3. FADs效应 - 模拟鱼群聚集装置的影响
    %   4. 三阶段搜索策略 - 适应不同优化阶段
    %
    % 参考文献:
    %   A. F. Faramarzi, M. Heidarinejad, S. Mirjalili, A. H. Gandomi
    %   "Marine Predators Algorithm: A nature-inspired metaheuristic"
    %   Expert Systems with Applications, 2020
    %   DOI: 10.1016/j.eswa.2020.113377
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   mpa = MPA(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = mpa.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Afshin Faramarzi, et al.
    % 重构版本: 1.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 捕食者位置矩阵 (N x Dim)
        bestPosition         % 全局最优位置 (1 x Dim)
        allFitness           % 所有个体适应度 (N x 1)
        marineMemory         % 海洋记忆矩阵 (N x Dim)
        memoryFitness        % 记忆适应度 (N x 1)
        AD                   % FADs效应参数
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 10, ...
                'max', 10000, ...
                'description', '海洋捕食者种群数量'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 500, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'FADs', struct(...
                'type', 'float', ...
                'default', 0.2, ...
                'min', 0, ...
                'max', 1, ...
                'description', 'FADs效应参数'), ...
            'P', struct(...
                'type', 'float', ...
                'default', 0.5, ...
                'min', 0, ...
                'max', 1, ...
                'description', '捕食者概率'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = MPA(configStruct)
            % MPA 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，可选字段:
            %     - populationSize: 种群大小 (默认: 30)
            %     - maxIterations: 最大迭代次数 (默认: 500)
            %     - FADs: FADs效应参数 (默认: 0.2)
            %     - P: 捕食者概率 (默认: 0.5)
            %     - verbose: 是否显示进度 (默认: true)

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

            obj.allFitness = obj.evaluatePopulation(obj.positions);

            [minFitness, minIdx] = min(obj.allFitness);
            obj.bestFitness = minFitness;
            obj.bestPosition = obj.positions(minIdx, :);

            obj.marineMemory = obj.positions;
            obj.memoryFitness = obj.allFitness;

            obj.AD = obj.config.FADs;

            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代
            %
            % 根据迭代阶段选择不同的搜索策略

            lb = obj.problem.lb;
            ub = obj.problem.ub;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;
            currentIter = obj.currentIteration + 1;
            dim = size(obj.positions, 2);

            obj.allFitness = obj.evaluatePopulation(obj.positions);

            for i = 1:N
                if obj.allFitness(i) < obj.memoryFitness(i)
                    obj.memoryFitness(i) = obj.allFitness(i);
                    obj.marineMemory(i, :) = obj.positions(i, :);
                end
            end

            [minFitness, minIdx] = min(obj.allFitness);
            if minFitness < obj.bestFitness
                obj.bestFitness = minFitness;
                obj.bestPosition = obj.positions(minIdx, :);
            end

            Elite = repmat(obj.bestPosition, N, 1);

            if currentIter < MaxIter / 3
                for i = 1:N
                    RB = obj.brownianMotion(N, dim);
                    stepsize = Elite(i, :) - RB .* obj.positions(i, :);
                    obj.positions(i, :) = obj.positions(i, :) + P .* (obj.config.P / 1) .* stepsize;
                end

            elseif currentIter >= MaxIter / 3 && currentIter < 2 * MaxIter / 3
                for i = 1:N
                    if i <= N / 2
                        RL = obj.levyMotion(dim);
                        stepsize = Elite(i, :) - RL .* obj.positions(i, :);
                        obj.positions(i, :) = obj.positions(i, :) + P .* (obj.config.P / 1) .* stepsize;
                    else
                        RB = obj.brownianMotion(1, dim);
                        stepsize = RB .* Elite(i, :) - obj.positions(i, :);
                        obj.positions(i, :) = Elite(i, :) + P .* (obj.config.P / 1) .* stepsize;
                    end
                end

            else
                for i = 1:N
                    RL = obj.levyMotion(dim);
                    stepsize = RL .* Elite(i, :) - obj.positions(i, :);
                    obj.positions(i, :) = Elite(i, :) + P .* (obj.config.P / 1) .* stepsize;
                end
            end

            obj.positions = obj.clampToBounds(obj.positions, lb, ub);

            if rand() < obj.AD
                for i = 1:N
                    obj.positions(i, :) = obj.positions(i, :) + obj.config.FADs .* ...
                        (rand(1, dim) .* (lb + rand(1, dim) .* (ub - lb)) - obj.positions(i, :));
                end
            else
                for i = 1:N
                    if rand() < 0.5
                        obj.positions(i, :) = obj.bestPosition + obj.config.FADs .* ...
                            (obj.marineMemory(i, :) - obj.positions(i, :));
                    else
                        obj.positions(i, :) = obj.bestPosition + obj.config.FADs .* ...
                            (obj.positions(i, :) - obj.marineMemory(i, :));
                    end
                end
            end

            obj.positions = obj.clampToBounds(obj.positions, lb, ub);

            obj.allFitness = obj.evaluatePopulation(obj.positions);
            [minFitness, minIdx] = min(obj.allFitness);
            if minFitness < obj.bestFitness
                obj.bestFitness = minFitness;
                obj.bestPosition = obj.positions(minIdx, :);
            end

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

            if isfield(config, 'FADs')
                validatedConfig.FADs = min(1, max(0, config.FADs));
            else
                validatedConfig.FADs = 0.2;
            end

            if isfield(config, 'P')
                validatedConfig.P = min(1, max(0, config.P));
            else
                validatedConfig.P = 0.5;
            end

            if isfield(config, 'verbose')
                validatedConfig.verbose = logical(config.verbose);
            else
                validatedConfig.verbose = true;
            end
        end
    end

    methods (Access = protected)
        function RB = brownianMotion(obj, N, dim)
            % brownianMotion 生成布朗运动向量
            %
            % 输入参数:
            %   N - 数量
            %   dim - 维度
            %
            % 输出参数:
            %   RB - 布朗运动向量

            RB = randn(N, dim) ./ sqrt(N);
        end

        function RL = levyMotion(obj, dim)
            % levyMotion 生成Lévy飞行向量
            %
            % 输入参数:
            %   dim - 维度
            %
            % 输出参数:
            %   RL - Lévy飞行向量

            beta = 1.5;
            sigma = (gamma(1 + beta) * sin(pi * beta / 2) / ...
                    (gamma((1 + beta) / 2) * beta * 2^((beta - 1) / 2)))^(1 / beta);

            u = randn(1, dim) * sigma;
            v = randn(1, dim);
            step = u ./ abs(v).^(1 / beta);

            RL = 0.05 * step;
        end
    end

    methods (Static)
        function register()
            % register 将算法注册到AlgorithmRegistry
            %
            % 此方法在系统初始化时调用，将MPA算法注册到全局注册表。

            AlgorithmRegistry.register('MPA', '1.0.0', 'MPA');
        end
    end
end
