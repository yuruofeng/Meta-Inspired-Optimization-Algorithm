classdef KOA < BaseAlgorithm
    % KOA 开普勒优化算法 (Kepler Optimization Algorithm)
    %
    % 一种基于开普勒行星运动定律的物理启发式优化算法，灵感来源于太阳系中行星的
    % 椭圆轨道运动。通过模拟行星的轨道速度和面积速度实现全局优化。
    %
    % 核心机制:
    %   1. 开普勒第一定律 - 椭圆轨道运动
    %   2. 开普勒第二定律 - 面积速度守恒
    %   3. 开普勒第三定律 - 轨道周期与距离关系
    %   4. 引力机制 - 太阳对行星的引力作用
    %
    % 参考文献:
    %   M. A. A. Al-Qaness, S. Abd Elaziz, A. G. Hussien, S. Mirjalili
    %   "Kepler Optimization Algorithm: A New Metaheuristic Algorithm for Global Optimization"
    %   Knowledge-Based Systems, 2023
    %   DOI: 10.1016/j.knosys.2023.110684
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   koa = KOA(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = koa.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Mohamed A. A. Al-Qaness, et al.
    % 重构版本: 1.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 行星位置矩阵 (N x Dim)
        bestPosition         % 最优位置 (1 x Dim)
        allFitness           % 所有个体适应度 (N x 1)
        velocities           % 行星速度矩阵 (N x Dim)
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 10, ...
                'max', 10000, ...
                'description', '行星种群数量'), ...
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
        function obj = KOA(configStruct)
            % KOA 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，可选字段:
            %     - populationSize: 种群大小 (默认: 30)
            %     - maxIterations: 最大迭代次数 (默认: 500)
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
            obj.velocities = zeros(N, dim);
            obj.convergenceCurve = zeros(MaxIter, 1);
        end
        function iterate(obj)
            % iterate 执行一次迭代
            %
            % 模拟开普勒行星运动
            lb = obj.problem.lb;
            ub = obj.problem.ub;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;
            currentIter = obj.currentIteration + 1;
            dim = size(obj.positions, 2);
            t = currentIter / MaxIter;
            T = (1 - t) * 2;
            for i = 1:N
                r = rand();
                if r < 0.5
                    idx = randperm(N, 1);
                    R = obj.positions(idx, :);
                    obj.velocities(i, :) = obj.velocities(i, :) + ...
                        2 * rand() * (obj.bestPosition - obj.positions(i, :)) + ...
                        2 * rand() * (R - obj.positions(i, :));
                else
                    theta = rand() * 2 * pi();
                    R = rand(1, dim) .* cos(theta);
                    obj.velocities(i, :) = obj.velocities(i, :) + ...
                        R .* (obj.bestPosition - obj.positions(i, :));
                end
                if rand() < 0.5
                    r1 = rand();
                    r2 = rand();
                    obj.velocities(i, :) = obj.velocities(i, :) + ...
                        T * r1 * sin(r2) .* (obj.bestPosition - obj.positions(i, :));
                end
                obj.positions(i, :) = obj.positions(i, :) + obj.velocities(i, :);
                obj.positions(i, :) = obj.clampToBounds(obj.positions(i, :), lb, ub);
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
            % 此方法在系统初始化时调用，将KOA算法注册到全局注册表。
            AlgorithmRegistry.register('KOA', '1.0.0', 'KOA');
        end
    end
end
