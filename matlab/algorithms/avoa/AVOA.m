classdef AVOA < BaseAlgorithm
    % AVOA 非洲秃鹫优化算法 (African Vultures Optimization Algorithm)
    %
    % 一种模拟非洲秃鹫觅食和导航行为的元启发式优化算法，灵感来源于秃鹫的
    % 觅食策略、饱腹率控制和探索开发平衡机制。
    %
    % 核心机制:
    %   1. 探索阶段 - 秃鹫在不同区域搜索食物
    %   2. 开发阶段 - 围绕最优解进行精细搜索
    %   3. 饱腹率控制 - 动态调整探索/开发转换
    %   4. 多种觅食策略 - 模拟秃鹫的不同觅食行为
    %
    % 参考文献:
    %   B. Abdollahzadeh, F. S. Gharehchopogh, N. Khodadadi, S. Mirjalili
    %   "African Vultures Optimization Algorithm: A New Nature-Inspired
    %    Metaheuristic Algorithm for Global Optimization Problems"
    %   Scientific Reports, 2022
    %   DOI: 10.1038/s41598-022-06039-4
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   avoa = AVOA(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = avoa.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Benyamin Abdollahzadeh, et al.
    % 重构版本: 1.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 秃鹫位置矩阵 (N x Dim)
        bestPosition         % 最优位置 (1 x Dim)
        secondBestPosition   % 次优位置 (1 x Dim)
        secondBestFitness    % 次优适应度
        allFitness           % 所有个体适应度 (N x 1)
        fullness             % 饱腹率向量 (N x 1)
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 10, ...
                'max', 10000, ...
                'description', '秃鹫种群数量'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 500, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'alpha', struct(...
                'type', 'float', ...
                'default', 0.8, ...
                'min', 0, ...
                'max', 1, ...
                'description', '饱腹率参数'), ...
            'beta', struct(...
                'type', 'float', ...
                'default', 0.2, ...
                'min', 0, ...
                'max', 1, ...
                'description', '探索/开发平衡参数'), ...
            'gamma', struct(...
                'type', 'float', ...
                'default', 2.5, ...
                'min', 1, ...
                'max', 5, ...
                'description', '饱腹率衰减参数'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = AVOA(configStruct)
            % AVOA 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，可选字段:
            %     - populationSize: 种群大小 (默认: 30)
            %     - maxIterations: 最大迭代次数 (默认: 500)
            %     - alpha: 饱腹率参数 (默认: 0.8)
            %     - beta: 探索/开发平衡参数 (默认: 0.2)
            %     - gamma: 饱腹率衰减参数 (默认: 2.5)
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
            obj.secondBestPosition = zeros(1, dim);
            obj.secondBestFitness = Inf;

            obj.allFitness = obj.evaluatePopulation(obj.positions);

            [sortedFitness, sortedIndices] = sort(obj.allFitness);
            obj.bestFitness = sortedFitness(1);
            obj.bestPosition = obj.positions(sortedIndices(1), :);
            obj.secondBestFitness = sortedFitness(2);
            obj.secondBestPosition = obj.positions(sortedIndices(2), :);

            obj.fullness = ones(N, 1);

            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代
            %
            % 包括饱腹率更新、探索和开发阶段

            lb = obj.problem.lb;
            ub = obj.problem.ub;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;
            currentIter = obj.currentIteration + 1;
            dim = size(obj.positions, 2);

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

            h = (2 * rand() - 1) * (1 - currentIter / MaxIter);

            for i = 1:N
                t = 2 * rand() - 1;
                F = (2 * rand() - 1) * h * (1 - obj.fullness(i) / (2 * obj.config.alpha));

                if abs(F) >= 1
                    idx = randperm(N, 1);
                    obj.positions(i, :) = obj.bestPosition + t * (rand() * obj.positions(idx, :) - obj.positions(i, :));
                else
                    if abs(F) >= 0.5
                        obj.positions(i, :) = obj.bestPosition - abs((2 * rand() - 1) * ...
                            obj.bestPosition - obj.positions(i, :)) * F;
                    else
                        A = obj.bestPosition * (1 - currentIter / MaxIter) + ...
                            obj.secondBestPosition * (currentIter / MaxIter);
                        
                        if rand() < obj.config.beta
                            obj.positions(i, :) = A - F + rand() * ...
                                (obj.bestPosition - obj.secondBestPosition);
                        else
                            S1 = obj.bestPosition - obj.positions(i, :);
                            S2 = obj.secondBestPosition - obj.positions(i, :);
                            
                            obj.positions(i, :) = obj.bestPosition - abs(S1) * F - ...
                                abs(S2) * (1 - F);
                        end
                    end
                end

                obj.positions(i, :) = obj.clampToBounds(obj.positions(i, :), lb, ub);
            end

            for i = 1:N
                if rand() < obj.config.gamma * h
                    if rand() < 0.5
                        obj.positions(i, :) = obj.bestPosition + (2 * rand() - 1) * ...
                            abs(obj.bestPosition - obj.positions(i, :));
                    else
                        obj.positions(i, :) = obj.bestPosition - (2 * rand() - 1) * ...
                            abs(obj.bestPosition - obj.positions(i, :));
                    end
                end

                obj.positions(i, :) = obj.clampToBounds(obj.positions(i, :), lb, ub);
            end

            obj.fullness = obj.fullness + (2 * rand(N, 1) - 1) * 0.1;
            obj.fullness = max(0.1, min(obj.config.alpha, obj.fullness));

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

            if isfield(config, 'alpha')
                validatedConfig.alpha = min(1, max(0, config.alpha));
            else
                validatedConfig.alpha = 0.8;
            end

            if isfield(config, 'beta')
                validatedConfig.beta = min(1, max(0, config.beta));
            else
                validatedConfig.beta = 0.2;
            end

            if isfield(config, 'gamma')
                validatedConfig.gamma = min(5, max(1, config.gamma));
            else
                validatedConfig.gamma = 2.5;
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
            % 此方法在系统初始化时调用，将AVOA算法注册到全局注册表。

            AlgorithmRegistry.register('AVOA', '1.0.0', 'AVOA');
        end
    end
end
