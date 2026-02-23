classdef WOA < BaseAlgorithm
    % WOA 鲸鱼优化算法 (Whale Optimization Algorithm)
    %
    % 一种模拟座头鲸气泡网狩猎行为的元启发式算法。通过包围猎物、
    % 螺旋更新和随机搜索三个阶段实现全局优化。
    %
    % 算法特点:
    %   - 包围猎物: |A|<1时向领导者靠近
    %   - 随机搜索: |A|>=1时随机探索搜索空间
    %   - 螺旋更新: p>=0.5时沿螺旋路径逼近猎物
    %
    % 参考文献:
    %   S. Mirjalili, A. Lewis
    %   "The Whale Optimization Algorithm"
    %   Advances in Engineering Software, 2016
    %   DOI: 10.1016/j.advengsoft.2016.01.008
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   woa = WOA(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = woa.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Seyedali Mirjalili
    % 重构版本: 2.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 种群位置矩阵 (N x Dim)
        leaderPosition       % 领导者位置 (最优解, 1 x Dim)
        leaderFitness        % 领导者适应度
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 5, ...
                'max', 10000, ...
                'description', '鲸鱼种群个体数量'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 500, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'b', struct(...
                'type', 'float', ...
                'default', 1, ...
                'min', 0, ...
                'max', 10, ...
                'description', '螺旋形状参数'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = WOA(configStruct)
            % WOA 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，可选字段:
            %     - populationSize: 种群大小 (默认: 30)
            %     - maxIterations: 最大迭代次数 (默认: 500)
            %     - b: 螺旋参数 (默认: 1)
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

            % 获取问题参数
            lb = problem.lb;
            ub = problem.ub;
            dim = problem.dim;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;

            % 初始化种群
            obj.positions = Initialization(N, dim, ub, lb);

            % 初始化领导者
            obj.leaderPosition = zeros(1, dim);
            obj.leaderFitness = Inf;

            % 初始评估找出最优
            fitness = obj.evaluatePopulation(obj.positions);
            [~, bestIdx] = min(fitness);
            obj.leaderFitness = fitness(bestIdx);
            obj.leaderPosition = obj.positions(bestIdx, :);

            % 初始化全局最优
            obj.bestFitness = obj.leaderFitness;
            obj.bestSolution = obj.leaderPosition;

            % 预分配收敛曲线
            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代
            %
            % 包括边界检查、适应度评估、领导者更新、位置更新

            lb = obj.problem.lb;
            ub = obj.problem.ub;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;
            currentIter = obj.currentIteration + 1;

            % 边界检查并评估适应度
            for i = 1:N
                % 边界约束
                flagUb = obj.positions(i, :) > ub;
                flagLb = obj.positions(i, :) < lb;
                obj.positions(i, :) = obj.positions(i, :) .* ~(flagUb | flagLb) + ...
                    ub .* flagUb + lb .* flagLb;

                % 评估适应度
                fitness = obj.evaluateSolution(obj.positions(i, :));

                % 更新领导者
                if fitness < obj.leaderFitness
                    obj.leaderFitness = fitness;
                    obj.leaderPosition = obj.positions(i, :);
                end
            end

            % 计算衰减参数 a (从2线性递减到0)
            a = 2 - currentIter * (2 / MaxIter);
            % a2 用于计算螺旋参数 l (从-1线性递减到-2)
            a2 = -1 + currentIter * ((-1) / MaxIter);

            % 更新所有个体位置
            for i = 1:N
                r1 = rand();
                r2 = rand();

                A = 2 * a * r1 - a;  % Eq. (2.3)
                C = 2 * r2;          % Eq. (2.4)

                b = obj.config.b;
                l = (a2 - 1) * rand + 1;  % 螺旋参数 l ∈ [-1, 1]

                p = rand();  % 概率选择

                for j = 1:size(obj.positions, 2)
                    if p < 0.5
                        if abs(A) >= 1
                            % 随机搜索阶段 (Eq. 2.7-2.8)
                            randLeaderIdx = floor(N * rand() + 1);
                            X_rand = obj.positions(randLeaderIdx, :);
                            D_X_rand = abs(C * X_rand(j) - obj.positions(i, j));
                            obj.positions(i, j) = X_rand(j) - A * D_X_rand;
                        else
                            % 包围猎物阶段 (Eq. 2.1-2.2)
                            D_Leader = abs(C * obj.leaderPosition(j) - obj.positions(i, j));
                            obj.positions(i, j) = obj.leaderPosition(j) - A * D_Leader;
                        end
                    else
                        % 螺旋更新阶段 (Eq. 2.5)
                        distance2Leader = abs(obj.leaderPosition(j) - obj.positions(i, j));
                        obj.positions(i, j) = distance2Leader * exp(b * l) * cos(l * 2 * pi) + ...
                            obj.leaderPosition(j);
                    end
                end
            end

            % 更新全局最优
            if obj.leaderFitness < obj.bestFitness
                obj.bestFitness = obj.leaderFitness;
                obj.bestSolution = obj.leaderPosition;
            end

            % 记录收敛曲线
            obj.convergenceCurve(currentIter) = obj.bestFitness;

            % 显示进度
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

            % 种群大小
            if isfield(config, 'populationSize')
                validatedConfig.populationSize = config.populationSize;
            else
                validatedConfig.populationSize = 30;
            end

            if validatedConfig.populationSize < 5
                error('WOA:InvalidConfig', 'populationSize must be >= 5');
            end

            % 最大迭代次数
            if isfield(config, 'maxIterations')
                validatedConfig.maxIterations = config.maxIterations;
            else
                validatedConfig.maxIterations = 500;
            end

            if validatedConfig.maxIterations < 1
                error('WOA:InvalidConfig', 'maxIterations must be >= 1');
            end

            % 螺旋参数 b
            if isfield(config, 'b')
                validatedConfig.b = config.b;
            else
                validatedConfig.b = 1;
            end

            if validatedConfig.b < 0
                error('WOA:InvalidConfig', 'b must be >= 0');
            end

            % 详细输出
            if isfield(config, 'verbose')
                validatedConfig.verbose = config.verbose;
            else
                validatedConfig.verbose = true;
            end
        end
    end

    methods (Static)
        function register()
            % register 将WOA算法注册到算法注册表
            %
            % 示例:
            %   WOA.register();
            %   algClass = AlgorithmRegistry.getAlgorithm('WOA');

            AlgorithmRegistry.register('WOA', '2.0.0', @WOA);
        end
    end
end
