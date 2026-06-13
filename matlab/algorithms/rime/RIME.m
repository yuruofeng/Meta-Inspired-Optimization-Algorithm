classdef RIME < BaseAlgorithm
    % RIME 雾凇优化算法 (Rime Optimization Algorithm)
    %
    % 一种基于雾凇形成过程的物理启发式优化算法，灵感来源于自然界中雾凇的
    % 生长机制。通过模拟软雾凇和硬雾凇的相互作用实现全局优化。
    %
    % 核心机制:
    %   1. 软雾凇策略 - 模拟小水滴的附着行为
    %   2. 硬雾凇策略 - 模拟冰晶的沉积过程
    %   3. 雾凇生长机制 - 模拟雾凇的累积过程
    %   4. 融化机制 - 模拟温度变化导致的雾凇融化
    %
    % 参考文献:
    %   H. Su, D. Zhao, M. A. Heidari, et al.
    %   "RIME: A Physics-Inspired Optimization Algorithm"
    %   Scientific Reports, 2023
    %   DOI: 10.1038/s41598-023-04314-7
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   rime = RIME(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = rime.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Huiling Su, et al.
    % 重构版本: 1.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 雾凇位置矩阵 (N x Dim)
        bestPosition         % 最优位置 (1 x Dim)
        allFitness           % 所有个体适应度 (N x 1)
        softRime             % 软雾凇标志 (N x 1)
        hardRime             % 硬雾凇标志 (N x 1)
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 10, ...
                'max', 10000, ...
                'description', '雾凇种群数量'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 500, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'w', struct(...
                'type', 'float', ...
                'default', 5, ...
                'min', 1, ...
                'max', 10, ...
                'description', '雾凇生长参数'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = RIME(configStruct)
            % RIME 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，可选字段:
            %     - populationSize: 种群大小 (默认: 30)
            %     - maxIterations: 最大迭代次数 (默认: 500)
            %     - w: 雾凇生长参数 (默认: 5)
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

            obj.softRime = zeros(N, 1);
            obj.hardRime = zeros(N, 1);

            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代
            %
            % 包括软雾凇和硬雾凇策略

            lb = obj.problem.lb;
            ub = obj.problem.ub;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;
            currentIter = obj.currentIteration + 1;
            dim = size(obj.positions, 2);

            t = currentIter / MaxIter;
            E = obj.config.w * sin(currentIter / MaxIter * pi());
            R = 2 * rand() - 1;

            for i = 1:N
                if rand() < 0.5
                    obj.softRime(i) = 1;
                    obj.hardRime(i) = 0;
                else
                    obj.softRime(i) = 0;
                    obj.hardRime(i) = 1;
                end
            end

            for i = 1:N
                if obj.softRime(i) == 1
                    idx = randperm(N, 1);
                    while idx == i
                        idx = randperm(N, 1);
                    end

                    H = obj.positions(i, :) - obj.positions(idx, :);
                    obj.positions(i, :) = obj.positions(i, :) + R .* H .* E;
                else
                    theta = rand() * 2 * pi();
                    S1 = cos(theta);
                    S2 = sin(theta);
                    
                    W = E * (2 * rand() - 1);
                    obj.positions(i, :) = obj.bestPosition + ...
                        W .* (S1 .* (obj.bestPosition - obj.positions(i, :)) + ...
                             S2 .* (obj.bestPosition - obj.positions(i, :)));
                end

                obj.positions(i, :) = obj.clampToBounds(obj.positions(i, :), lb, ub);
            end

            if rand() < t
                iceIdx = randperm(N, 1);
                obj.positions(iceIdx, :) = obj.positions(iceIdx, :) + ...
                    (ub - lb) * rand(1, dim) + lb;
                obj.positions(iceIdx, :) = obj.clampToBounds(obj.positions(iceIdx, :), lb, ub);
            end

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

            if isfield(config, 'w')
                validatedConfig.w = min(10, max(1, config.w));
            else
                validatedConfig.w = 5;
            end

            if isfield(config, 'verbose')
                validatedConfig.verbose = logical(config.verbose);
            else
                validatedConfig.verbose = true;
            end
        end
    end

    methods (Static)
        function register()
            % register 将算法注册到AlgorithmRegistry
            %
            % 此方法在系统初始化时调用，将RIME算法注册到全局注册表。

            AlgorithmRegistry.register('RIME', '1.0.0', 'RIME');
        end
    end
end
