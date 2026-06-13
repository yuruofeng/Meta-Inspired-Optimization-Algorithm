classdef GTO < BaseAlgorithm
    % GTO 人工大猩猩部队优化器 (Artificial Gorilla Troops Optimizer)
    %
    % 一种模拟大猩猩社会行为和群体智能的元启发式优化算法，灵感来源于大猩猩的
    % 生活习性和团队协作机制。通过模拟大猩猩的探索、开发和迁移行为实现
    % 全局优化。
    %
    % 核心机制:
    %   1. 探索阶段 - 模拟大猩猩的觅食行为
    %   2. 开发阶段 - 银背领导者引导机制
    %   3. 迁移机制 - 大猩猩群体的迁移行为
    %   4. 社会层级 - Alpha银背的领导作用
    %
    % 参考文献:
    %   B. Abdollahzadeh, F. S. Gharehchopogh, S. Mirjalili
    %   "Artificial Gorilla Troops Optimizer: A New Nature‐Inspired
    %    Metaheuristic Algorithm for Global Optimization Problems"
    %   International Journal of Intelligent Systems, 2021
    %   DOI: 10.1002/int.22535
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   gto = GTO(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = gto.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Benyamin Abdollahzadeh, et al.
    % 重构版本: 1.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 大猩猩位置矩阵 (N x Dim)
        bestPosition         % 银背最优位置 (1 x Dim)
        allFitness           % 所有个体适应度 (N x 1)
        gorilla              % 当前大猩猩位置
        p                    % 迁移概率参数
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 10, ...
                'max', 10000, ...
                'description', '大猩猩种群大小'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 500, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'p', struct(...
                'type', 'float', ...
                'default', 0.03, ...
                'min', 0.01, ...
                'max', 0.1, ...
                'description', '迁移概率参数'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = GTO(configStruct)
            % GTO 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，可选字段:
            %     - populationSize: 种群大小 (默认: 30)
            %     - maxIterations: 最大迭代次数 (默认: 500)
            %     - p: 迁移概率参数 (默认: 0.03)
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

            obj.gorilla = obj.positions;
            obj.p = obj.config.p;

            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代
            %
            % 包括探索阶段和开发阶段

            lb = obj.problem.lb;
            ub = obj.problem.ub;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;
            currentIter = obj.currentIteration + 1;
            dim = size(obj.positions, 2);

            a = (cos(2 * rand() * pi() / MaxIter) + 1) * (1 - currentIter / MaxIter);

            for i = 1:N
                if rand() < 0.03
                    obj.gorilla(i, :) = (ub - lb) * rand(1, dim) + lb;
                else
                    r = rand();
                    if r >= 0.5
                        Z = obj.generateZ();
                        H = obj.positions(i, :) - obj.bestPosition;
                        obj.gorilla(i, :) = (obj.positions(i, :) - obj.bestPosition) * Z + H;
                    else
                        idx = randperm(N, 1);
                        H = (obj.positions(i, :) - obj.positions(idx, :)) * rand();
                        obj.gorilla(i, :) = obj.positions(i, :) - H;
                    end
                end

                obj.gorilla(i, :) = obj.clampToBounds(obj.gorilla(i, :), lb, ub);
            end

            gorillaFitness = obj.evaluatePopulation(obj.gorilla);

            for i = 1:N
                if gorillaFitness(i) < obj.allFitness(i)
                    obj.allFitness(i) = gorillaFitness(i);
                    obj.positions(i, :) = obj.gorilla(i, :);
                end
            end

            [minFitness, minIdx] = min(obj.allFitness);
            if minFitness < obj.bestFitness
                obj.bestFitness = minFitness;
                obj.bestPosition = obj.positions(minIdx, :);
            end

            C = a * (2 * rand() - 1);
            for i = 1:N
                if rand() < C
                    obj.gorilla(i, :) = obj.bestPosition - ...
                        (obj.positions(i, :) - obj.bestPosition) * (2 * rand() - 1);
                else
                    if rand() >= 0.5
                        L = obj.generateL(dim);
                        obj.gorilla(i, :) = obj.bestPosition - ...
                            (obj.positions(i, :) - obj.bestPosition) * L;
                    else
                        idx1 = randperm(N, 1);
                        idx2 = randperm(N, 1);
                        M = obj.positions(idx1, :) - obj.positions(idx2, :);
                        obj.gorilla(i, :) = obj.bestPosition - ...
                            (obj.positions(i, :) - obj.bestPosition) * M(1, :) * rand();
                    end
                end

                obj.gorilla(i, :) = obj.clampToBounds(obj.gorilla(i, :), lb, ub);
            end

            gorillaFitness = obj.evaluatePopulation(obj.gorilla);

            for i = 1:N
                if gorillaFitness(i) < obj.allFitness(i)
                    obj.allFitness(i) = gorillaFitness(i);
                    obj.positions(i, :) = obj.gorilla(i, :);
                end
            end

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

            if isfield(config, 'p')
                validatedConfig.p = min(0.1, max(0.01, config.p));
            else
                validatedConfig.p = 0.03;
            end

            if isfield(config, 'verbose')
                validatedConfig.verbose = logical(config.verbose);
            else
                validatedConfig.verbose = true;
            end
        end
    end

    methods (Access = protected)
        function Z = generateZ(obj)
            % generateZ 生成Z向量用于探索
            %
            % 输出参数:
            %   Z - 随机向量

            Z = ones(1, 3);
            if rand() < 0.5
                Z(1) = rand() - rand();
            end
            if rand() < 0.5
                Z(2) = rand() - rand();
            end
            if rand() < 0.5
                Z(3) = rand() - rand();
            end
        end

        function L = generateL(obj, dim)
            % generateL 生成L向量用于开发
            %
            % 输入参数:
            %   dim - 维度
            %
            % 输出参数:
            %   L - Lévy飞行向量

            beta = 1.5;
            sigma = (gamma(1 + beta) * sin(pi * beta / 2) / ...
                    (gamma((1 + beta) / 2) * beta * 2^((beta - 1) / 2)))^(1 / beta);

            u = randn(1, dim) * sigma;
            v = randn(1, dim);
            step = u ./ abs(v).^(1 / beta);

            L = 0.05 * step;
        end
    end

    methods (Static)
        function register()
            % register 将算法注册到AlgorithmRegistry
            %
            % 此方法在系统初始化时调用，将GTO算法注册到全局注册表。

            AlgorithmRegistry.register('GTO', '1.0.0', 'GTO');
        end
    end
end
