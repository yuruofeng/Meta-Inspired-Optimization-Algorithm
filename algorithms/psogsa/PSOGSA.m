classdef PSOGSA < BaseAlgorithm
    % PSOGSA 混合粒子群-引力搜索算法 (Hybrid PSO and Gravitational Search Algorithm)
    %
    % 一种结合粒子群优化(PSO)和引力搜索算法(GSA)的混合元启发式算法。
    % 通过融合PSO的社会学习能力和GSA的物理引力机制，实现更高效的全局优化。
    %
    % 算法特点:
    %   - 引力机制：基于质量相互作用的群体智能
    %   - 惯性权重：平衡全局搜索和局部开发
    %   - 社会学习：融合PSO的全局最优引导
    %   - 自适应参数：引力常数和惯性权重的动态调整
    %
    % 参考文献:
    %   S. Mirjalili, S. Z. Mohd Hashim, "A New Hybrid PSOGSA Algorithm for Function Optimization"
    %   International Conference on Computer and Information Application (ICCIA 2010), pp. 374-377
    %
    % 时间复杂度: O(MaxIter × N^2 × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   psogsa = PSOGSA(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = psogsa.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Seyedali Mirjalili
    % 重构版本: 2.0.0
    % 日期: 2026

    properties (Access = protected)
        positions            % 粒子位置矩阵 (N x Dim)
        velocities           % 速度向量 (N x Dim)
        accelerations        % 加速度向量 (N x Dim)
        masses               % 质量向量 (N x 1)
        forces               % 力向量 (N x Dim)
        gBestPosition        % 全局最优位置 (1 x Dim)
        gBestFitness         % 全局最优适应度
        G0                   % 初始引力常数
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 10, ...
                'max', 10000, ...
                'description', '粒子种群个体数量'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 500, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'wMax', struct(...
                'type', 'double', ...
                'default', 0.9, ...
                'min', 0, ...
                'max', 1, ...
                'description', '最大惯性权重'), ...
            'wMin', struct(...
                'type', 'double', ...
                'default', 0.5, ...
                'min', 0, ...
                'max', 1, ...
                'description', '最小惯性权重'), ...
            'G0', struct(...
                'type', 'double', ...
                'default', 1, ...
                'min', 0.1, ...
                'max', 100, ...
                'description', '初始引力常数'), ...
            'alpha', struct(...
                'type', 'double', ...
                'default', 20, ...
                'min', 1, ...
                'max', 100, ...
                'description', '引力衰减系数'), ...
            'c1', struct(...
                'type', 'double', ...
                'default', 0.5, ...
                'min', 0, ...
                'max', 2, ...
                'description', '认知学习因子'), ...
            'c2', struct(...
                'type', 'double', ...
                'default', 0.5, ...
                'min', 0, ...
                'max', 2, ...
                'description', '社会学习因子'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = PSOGSA(configStruct)
            % PSOGSA 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，可选字段:
            %     - populationSize: 种群大小 (默认: 30)
            %     - maxIterations: 最大迭代次数 (默认: 500)
            %     - wMax: 最大惯性权重 (默认: 0.9)
            %     - wMin: 最小惯性权重 (默认: 0.5)
            %     - G0: 初始引力常数 (默认: 1)
            %     - alpha: 引力衰减系数 (默认: 20)
            %     - c1: 认知学习因子 (默认: 0.5)
            %     - c2: 社会学习因子 (默认: 0.5)
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

            range = ub - lb;
            obj.velocities = 0.3 * randn(N, dim) .* repmat(range, N, 1);

            obj.accelerations = zeros(N, dim);
            obj.masses = zeros(N, 1);
            obj.forces = zeros(N, dim);

            obj.gBestPosition = zeros(1, dim);
            obj.gBestFitness = Inf;

            fitness = obj.evaluatePopulation(obj.positions);

            [sortedFitness, sortedIndices] = sort(fitness);
            obj.gBestFitness = sortedFitness(1);
            obj.gBestPosition = obj.positions(sortedIndices(1), :);

            obj.bestFitness = obj.gBestFitness;
            obj.bestSolution = obj.gBestPosition;

            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代
            %
            % 包括适应度评估、质量计算、引力计算、速度和位置更新

            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;
            dim = size(obj.positions, 2);
            currentIter = obj.currentIteration + 1;

            fitness = obj.evaluatePopulation(obj.positions);

            [best, ~, minIdx] = min(fitness);
            worst = max(fitness);

            if best < obj.gBestFitness
                obj.gBestFitness = best;
                obj.gBestPosition = obj.positions(minIdx, :);
            end

            if best ~= worst
                for i = 1:N
                    obj.masses(i) = (fitness(i) - 0.99 * worst) / (best - worst);
                end
                obj.masses = obj.masses * N / sum(obj.masses);
            else
                obj.masses = ones(N, 1);
            end

            G = obj.config.G0 * exp(-obj.config.alpha * currentIter / MaxIter);

            obj.forces = zeros(N, dim);
            for i = 1:N
                for j = 1:N
                    if i ~= j
                        diff = obj.positions(j, :) - obj.positions(i, :);
                        dist = norm(diff);
                        if dist > eps
                            for d = 1:dim
                                if diff(d) ~= 0
                                    obj.forces(i, d) = obj.forces(i, d) + rand() * G * ...
                                        obj.masses(j) * obj.masses(i) * sign(diff(d));
                                end
                            end
                        end
                    end
                end
            end

            for i = 1:N
                if obj.masses(i) > eps
                    obj.accelerations(i, :) = obj.forces(i, :) / obj.masses(i);
                end
            end

            w = obj.config.wMax - currentIter * ((obj.config.wMax - obj.config.wMin) / MaxIter);

            for i = 1:N
                for d = 1:dim
                    obj.velocities(i, d) = w * obj.velocities(i, d) + ...
                        obj.config.c1 * rand() * obj.accelerations(i, d) + ...
                        obj.config.c2 * rand() * (obj.gBestPosition(d) - obj.positions(i, d));
                end
            end

            obj.positions = obj.positions + obj.velocities;

            lb = obj.problem.lb;
            ub = obj.problem.ub;
            for i = 1:N
                obj.positions(i, :) = shared.utils.BoundaryHandler.quickClip(obj.positions(i, :), lb, ub);
            end

            if obj.gBestFitness < obj.bestFitness
                obj.bestFitness = obj.gBestFitness;
                obj.bestSolution = obj.gBestPosition;
            end

            obj.convergenceCurve(currentIter) = obj.bestFitness;

            if obj.config.verbose && mod(currentIter, 50) == 0
                obj.displayProgress(sprintf('Best fitness: %.6e', obj.bestFitness));
            end
        end

        function tf = shouldStop(obj)
            % shouldStop 判断是否停止迭代
            %
            % 输出参数:
            %   tf - true表示停止，false表示继续

            tf = obj.currentIteration >= obj.config.maxIterations;
        end

        function validatedConfig = validateConfig(obj, config)
            % validateConfig 验证并规范化配置参数
            %
            % 输入参数:
            %   config - 原始配置结构体
            %
            % 输出参数:
            %   validatedConfig - 验证后的配置结构体

            validatedConfig = struct();

            if isfield(config, 'populationSize')
                validatedConfig.populationSize = config.populationSize;
            else
                validatedConfig.populationSize = 30;
            end

            if validatedConfig.populationSize < 10
                error('PSOGSA:InvalidConfig', 'populationSize must be >= 10');
            end

            if isfield(config, 'maxIterations')
                validatedConfig.maxIterations = config.maxIterations;
            else
                validatedConfig.maxIterations = 500;
            end

            if validatedConfig.maxIterations < 1
                error('PSOGSA:InvalidConfig', 'maxIterations must be >= 1');
            end

            if isfield(config, 'wMax')
                validatedConfig.wMax = config.wMax;
            else
                validatedConfig.wMax = 0.9;
            end

            if isfield(config, 'wMin')
                validatedConfig.wMin = config.wMin;
            else
                validatedConfig.wMin = 0.5;
            end

            if isfield(config, 'G0')
                validatedConfig.G0 = config.G0;
            else
                validatedConfig.G0 = 1;
            end

            if isfield(config, 'alpha')
                validatedConfig.alpha = config.alpha;
            else
                validatedConfig.alpha = 20;
            end

            if isfield(config, 'c1')
                validatedConfig.c1 = config.c1;
            else
                validatedConfig.c1 = 0.5;
            end

            if isfield(config, 'c2')
                validatedConfig.c2 = config.c2;
            else
                validatedConfig.c2 = 0.5;
            end

            if isfield(config, 'verbose')
                validatedConfig.verbose = config.verbose;
            else
                validatedConfig.verbose = true;
            end
        end
    end

    methods (Static)
        function register()
            % register 将PSOGSA算法注册到算法注册表
            %
            % 示例:
            %   PSOGSA.register();
            %   algClass = AlgorithmRegistry.getAlgorithm('PSOGSA');

            AlgorithmRegistry.register('PSOGSA', '2.0.0', @PSOGSA);
        end
    end
end
