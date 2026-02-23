classdef EWOA < BaseAlgorithm
    % EWOA 增强鲸鱼优化算法 (Enhanced Whale Optimization Algorithm)
    %
    % 在标准WOA基础上引入汇聚机制、Cauchy分布和三种搜索策略。
    %
    % 算法特点:
    %   - 汇聚机制(Pooling): 存储和重利用历史较差解
    %   - Cauchy分布: 参数A的生成
    %   - 增强包围策略: A<0.5时
    %   - 偏好选择策略: A>=0.5时
    %   - 螺旋气泡网攻击: p>=0.5时
    %   - 迁移搜索策略: 部分鲸鱼随机迁移
    %
    % 参考文献:
    %   M.H. Nadimi-Shahraki, H. Zamani, S. Mirjalili
    %   "Enhanced whale optimization algorithm for medical feature selection"
    %   Computers in Biology and Medicine, 2022
    %   DOI: 10.1016/j.compbiomed.2022.105858
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(N × Dim + PoolSize)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   ewoa = algorithms.ewoa.EWOA(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = ewoa.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Mohammad H.Nadimi-Shahraki, Hoda Zamani, Seyedali Mirjalili
    % 重构版本: 2.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 位置矩阵 (N x Dim)
        bestPosition         % 全局最优位置
        bestFitness          % 全局最优适应度
        pool                 % 汇聚池结构体
        portionRate          % 迁移比例
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
            'b', struct(...
                'type', 'float', ...
                'default', 1, ...
                'min', 0, ...
                'description', '螺旋参数'), ...
            'poolKappa', struct(...
                'type', 'float', ...
                'default', 1.5, ...
                'min', 1, ...
                'description', '汇聚池大小倍数'), ...
            'portionRate', struct(...
                'type', 'integer', ...
                'default', 20, ...
                'min', 1, ...
                'description', '迁移比例(数量)'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = EWOA(configStruct)
            % EWOA 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，可选字段:
            %     - populationSize: 种群大小 (默认: 30)
            %     - maxIterations: 最大迭代次数 (默认: 500)
            %     - b: 螺旋参数 (默认: 1)
            %     - poolKappa: 汇聚池大小倍数 (默认: 1.5)
            %     - portionRate: 迁移比例数量 (默认: 20)
            %     - verbose: 是否显示进度 (默认: true)

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

            % 初始化位置
            obj.positions = Initialization(N, dim, ub, lb);

            % 初始化最优
            fitness = obj.evaluatePopulation(obj.positions);
            [obj.bestFitness, bestIdx] = min(fitness);
            obj.bestPosition = obj.positions(bestIdx, :);

            obj.bestSolution = obj.bestPosition;

            % 初始化汇聚池
            obj.pool.Kappa = floor(obj.config.poolKappa * N);
            obj.pool.positions = [];

            % 初始化较差点加入池
            [~, sortedIdx] = sort(fitness, 'descend');
            worstStart = max(1, N - floor(obj.pool.Kappa * 0.3) + 1);
            worstPositions = obj.positions(sortedIdx(worstStart:N), :);
            obj.pool = obj.updatePool(worstPositions, obj.bestPosition);

            obj.portionRate = min(obj.config.portionRate, N);

            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            lb = obj.problem.lb;
            ub = obj.problem.ub;
            N = obj.config.populationSize;
            dim = size(obj.positions, 2);
            MaxIter = obj.config.maxIterations;
            currentIter = obj.currentIteration + 1;

            a2 = -1 + currentIter * ((-1) / MaxIter);

            % 选择迁移部分
            portionIndices = randperm(N, obj.portionRate);

            % 从汇聚池获取位置
            poolPositions = obj.pool.positions;
            if isempty(poolPositions)
                poolPositions = obj.positions;
            end

            % 随机索引
            rndIdx1 = randi(size(poolPositions, 1), N, 1);
            rndIdx2 = randi(size(poolPositions, 1), N, 1);

            % 概率p
            p = rand(N, 1);

            % Cauchy分布生成A
            A = obj.generateCauchyA(N);

            for i = 1:N
                if ~ismember(i, portionIndices)
                    C = 2 * rand;
                    b = obj.config.b;

                    for j = 1:dim
                        l = (a2 - 1) * rand + 1;

                        if p(i) < 0.5
                            if A(i) < 0.5
                                % 增强包围策略
                                randPoolIdx = randi(size(poolPositions, 1));
                                P_rnd3 = poolPositions(randPoolIdx, j);
                                D_prim = abs(C * obj.bestPosition(j) - P_rnd3);
                                obj.positions(i, j) = obj.bestPosition(j) - A(i) * D_prim;
                            else
                                % 偏好选择策略
                                obj.positions(i, j) = obj.positions(i, j) + A(i) * ...
                                    (C * poolPositions(rndIdx1(i), j) - poolPositions(rndIdx2(i), j));
                            end
                        else
                            % 螺旋气泡网攻击
                            D_prim = abs(obj.bestPosition(j) - obj.positions(i, j));
                            obj.positions(i, j) = D_prim * exp(b * l) * cos(2 * pi * l) + obj.bestPosition(j);
                        end
                    end
                end
            end

            % 迁移搜索策略
            bestMax = max(obj.bestPosition);
            bestMin = min(obj.bestPosition);
            X_rnd = rand(obj.portionRate, dim) .* (ub - lb) + lb;
            X_brnd = rand(obj.portionRate, dim) .* (bestMax - bestMin) + bestMin;
            obj.positions(portionIndices, :) = X_rnd - X_brnd;

            % 边界约束和评估
            newFitness = zeros(N, 1);
            for i = 1:N
                obj.positions(i, :) = obj.boundConstraint(obj.positions(i, :), lb, ub);
                newFitness(i) = obj.evaluateSolution(obj.positions(i, :));

                if newFitness(i) < obj.bestFitness
                    obj.bestFitness = newFitness(i);
                    obj.bestPosition = obj.positions(i, :);
                end
            end

            % 更新汇聚池
            improved = newFitness < obj.problem.evaluate(obj.positions);
            if any(~improved)
                worstPositions = obj.positions(find(~improved), :);
                obj.pool = obj.updatePool(worstPositions, obj.bestPosition);
            end

            obj.bestSolution = obj.bestPosition;
            obj.convergenceCurve(currentIter) = obj.bestFitness;

            if obj.config.verbose && mod(currentIter, 50) == 0
                obj.displayProgress(sprintf('Best: %.6e', obj.bestFitness));
            end
        end

        function A = generateCauchyA(obj, N)
            % 使用Cauchy分布生成参数A
            A = 0.5 + 0.1 * tan(pi * (rand(N, 1) - 0.5));
            while any(A <= 0)
                idx = A <= 0;
                A(idx) = 0.5 + 0.1 * tan(pi * (rand(sum(idx), 1) - 0.5));
            end
            A = min(A, 1);
        end

        function pool = updatePool(obj, worstPositions, bestPos)
            % 更新汇聚池
            pool = obj.pool;
            for i = 1:size(worstPositions, 1)
                if size(pool.positions, 1) < pool.Kappa
                    pool.positions = [pool.positions; worstPositions(i, :); bestPos];
                else
                    % 替换最旧的
                    pool.positions(1:end-2, :) = pool.positions(3:end, :);
                    pool.positions(end-1, :) = worstPositions(i, :);
                    pool.positions(end, :) = bestPos;
                end
            end
        end

        function pos = boundConstraint(obj, pos, lb, ub)
            % 边界约束
            flagUb = pos > ub;
            flagLb = pos < lb;
            pos = pos .* ~(flagUb | flagLb) + ub .* flagUb + lb .* flagLb;
        end

        function tf = shouldStop(obj)
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
                error('EWOA:InvalidConfig', 'populationSize must be >= 5');
            end

            % 最大迭代次数
            if isfield(config, 'maxIterations')
                validatedConfig.maxIterations = config.maxIterations;
            else
                validatedConfig.maxIterations = 500;
            end

            if validatedConfig.maxIterations < 1
                error('EWOA:InvalidConfig', 'maxIterations must be >= 1');
            end

            % 螺旋参数
            if isfield(config, 'b')
                validatedConfig.b = config.b;
            else
                validatedConfig.b = 1;
            end

            if validatedConfig.b < 0
                error('EWOA:InvalidConfig', 'b must be >= 0');
            end

            % 汇聚池大小倍数
            if isfield(config, 'poolKappa')
                validatedConfig.poolKappa = config.poolKappa;
            else
                validatedConfig.poolKappa = 1.5;
            end

            if validatedConfig.poolKappa < 1
                error('EWOA:InvalidConfig', 'poolKappa must be >= 1');
            end

            % 迁移比例
            if isfield(config, 'portionRate')
                validatedConfig.portionRate = config.portionRate;
            else
                validatedConfig.portionRate = 20;
            end

            if validatedConfig.portionRate < 1
                error('EWOA:InvalidConfig', 'portionRate must be >= 1');
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
            % register 将EWOA算法注册到算法注册表
            %
            % 示例:
            %   EWOA.register();
            %   algClass = AlgorithmRegistry.getAlgorithm('EWOA');

            AlgorithmRegistry.register('EWOA', '2.0.0', @EWOA);
        end
    end
end
