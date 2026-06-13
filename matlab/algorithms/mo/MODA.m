classdef MODA < MOBaseAlgorithm
    % MODA 多目标蜻蜓算法 (Multi-Objective Dragonfly Algorithm)
    %
    % 一种模拟蜻蜓静态和动态群集行为的多目标元启发式算法。通过分离、
    % 对齐、凝聚、食物吸引和敌人排斥五种行为实现Pareto前沿搜索。
    %
    % 算法特点:
    %   - 分离(S): 避免与邻居碰撞
    %   - 对齐(A): 与邻居速度匹配
    %   - 凝聚(C): 向邻居中心移动
    %   - 食物吸引(F): 向Pareto前沿移动
    %   - 敌人排斥(E): 远离被支配区域
    %   - Levy飞行: 无邻居时进行探索
    %
    % 参考文献:
    %   S. Mirjalili
    %   "Dragonfly algorithm: a new meta-heuristic optimization technique
    %    for solving single-objective, discrete, and multi-objective problems"
    %   Neural Computing and Applications, 2016
    %   DOI: 10.1007/s00521-015-1920-1
    %
    % 时间复杂度: O(MaxIter × N² × Dim)
    % 空间复杂度: O(ArchiveSize × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 100, 'maxIterations', 100);
    %   moda = MODA(config);
    %   problem.lb = 0; problem.ub = 1; problem.dim = 5;
    %   problem.objCount = 2;
    %   problem.evaluate = @(x) ZDT1(x);
    %   result = moda.run(problem);
    %   result.plot();
    %
    % 原始作者: Seyedali Mirjalili
    % 重构版本: 2.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 蜻蜓位置矩阵 (N x Dim)
        stepVectors          % 步长向量矩阵 (N x Dim)
        fitness              % 适应度矩阵 (N x objCount)
        foodPosition         % 食物位置 (1 x Dim)
        foodFitness          % 食物适应度 (1 x objCount)
        enemyPosition        % 敌人位置 (1 x Dim)
        enemyFitness         % 敌人适应度 (1 x objCount)
        neighborhoodRadius   % 邻域半径
        maxStep              % 最大步长
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 100, ...
                'min', 10, ...
                'max', 10000, ...
                'description', '蜻蜓种群大小'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 100, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'archiveMaxSize', struct(...
                'type', 'integer', ...
                'default', 100, ...
                'min', 10, ...
                'max', 1000, ...
                'description', 'Pareto存档最大容量'), ...
            'separationWeight', struct(...
                'type', 'float', ...
                'default', 0.1, ...
                'min', 0, ...
                'description', '分离权重 (s)'), ...
            'alignmentWeight', struct(...
                'type', 'float', ...
                'default', 0.1, ...
                'min', 0, ...
                'description', '对齐权重 (a)'), ...
            'cohesionWeight', struct(...
                'type', 'float', ...
                'default', 0.1, ...
                'min', 0, ...
                'description', '凝聚权重 (c)'), ...
            'foodWeight', struct(...
                'type', 'float', ...
                'default', 0.1, ...
                'min', 0, ...
                'description', '食物吸引权重 (f)'), ...
            'enemyWeight', struct(...
                'type', 'float', ...
                'default', 0.1, ...
                'min', 0, ...
                'description', '敌人排斥权重 (e)'), ...
            'wMax', struct(...
                'type', 'float', ...
                'default', 0.9, ...
                'min', 0, ...
                'max', 1, ...
                'description', '最大惯性权重'), ...
            'wMin', struct(...
                'type', 'float', ...
                'default', 0.2, ...
                'min', 0, ...
                'max', 1, ...
                'description', '最小惯性权重'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = MODA(configStruct)
            % MODA 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体

            if nargin < 1 || isempty(configStruct)
                configStruct = struct();
            end

            obj = obj@MOBaseAlgorithm(configStruct);
        end

        function initialize(obj, problem)
            % initialize 初始化种群和存档

            lb = problem.lb;
            ub = problem.ub;
            dim = problem.dim;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;
            obj.archiveMaxSize = int32(obj.config.archiveMaxSize);

            if isscalar(lb)
                lb = lb * ones(1, dim);
                ub = ub * ones(1, dim);
            end
            obj.problem.lb = lb;
            obj.problem.ub = ub;

            obj.neighborhoodRadius = (ub - lb) / 10;
            obj.maxStep = (ub - lb) / 10;

            obj.positions = Initialization(N, dim, ub, lb);
            obj.stepVectors = Initialization(N, dim, ub, lb);
            obj.fitness = zeros(N, obj.objCount);

            obj.foodPosition = zeros(1, dim);
            obj.foodFitness = inf(1, obj.objCount);
            obj.enemyPosition = zeros(1, dim);
            obj.enemyFitness = -inf(1, obj.objCount);

            obj.archiveX = zeros(obj.archiveMaxSize, dim);
            obj.archiveF = inf(obj.archiveMaxSize, obj.objCount);
            obj.archiveSize = int32(0);

            for i = 1:N
                obj.fitness(i, :) = obj.evaluateSolution(obj.positions(i, :));
            end

            obj.updateArchive(obj.positions, obj.fitness);

            if obj.archiveSize > 0
                obj.foodFitness = obj.archiveF(1, :);
                obj.foodPosition = obj.archiveX(1, :);
            end

            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代

            lb = obj.problem.lb;
            ub = obj.problem.ub;
            N = obj.config.populationSize;
            dim = size(obj.positions, 2);
            MaxIter = obj.config.maxIterations;
            currentIter = obj.currentIteration + 1;

            obj.neighborhoodRadius = (ub - lb) / 4 + ((ub - lb) * (currentIter / MaxIter) * 2);
            w = obj.config.wMax - currentIter * ((obj.config.wMax - obj.config.wMin) / MaxIter);

            my_c = 0.1 - currentIter * ((0.1 - 0) / (MaxIter / 2));
            if my_c < 0
                my_c = 0;
            end

            if currentIter < (3 * MaxIter / 4)
                s = my_c * obj.config.separationWeight;
                a = my_c * obj.config.alignmentWeight;
                c = my_c * obj.config.cohesionWeight;
                f = 2 * rand * obj.config.foodWeight;
                e = my_c * obj.config.enemyWeight;
            else
                s = my_c / currentIter * obj.config.separationWeight;
                a = my_c / currentIter * obj.config.alignmentWeight;
                c = my_c / currentIter * obj.config.cohesionWeight;
                f = 2 * rand * obj.config.foodWeight;
                e = my_c / currentIter * obj.config.enemyWeight;
            end

            for i = 1:N
                obj.fitness(i, :) = obj.evaluateSolution(obj.positions(i, :));
            end

            obj.updateArchive(obj.positions, obj.fitness);
            obj.archiveRanks = obj.rankingProcess(obj.archiveF(1:obj.archiveSize, :));

            foodIdx = obj.selectFromArchive(true);
            if foodIdx == 0
                foodIdx = 1;
            end
            obj.foodFitness = obj.archiveF(foodIdx, :);
            obj.foodPosition = obj.archiveX(foodIdx, :);

            enemyIdx = obj.selectFromArchive(false);
            if enemyIdx == 0
                enemyIdx = foodIdx;
            end
            obj.enemyFitness = obj.archiveF(enemyIdx, :);
            obj.enemyPosition = obj.archiveX(enemyIdx, :);

            for i = 1:N
                [S, A, C, F, E, hasNeighbors] = obj.calculateBehaviors(i);

                if hasNeighbors
                    for j = 1:dim
                        obj.stepVectors(i, j) = s * S(j) + a * A(j) + c * C(j) + ...
                            f * F(j) + e * E(j) + w * obj.stepVectors(i, j);

                        obj.stepVectors(i, j) = max(-obj.maxStep(j), ...
                            min(obj.maxStep(j), obj.stepVectors(i, j)));

                        obj.positions(i, j) = obj.positions(i, j) + obj.stepVectors(i, j);
                    end
                else
                    levyStep = obj.levyFlight(dim);
                    obj.positions(i, :) = obj.positions(i, :) + levyStep .* obj.positions(i, :);
                    obj.stepVectors(i, :) = 0;
                end

                obj.positions(i, :) = min(max(obj.positions(i, :), lb), ub);
            end

            obj.convergenceCurve(currentIter) = obj.archiveSize;

            if obj.config.verbose && mod(currentIter, 10) == 0
                obj.displayProgress(sprintf('Food fitness: [%.4e, %.4e]', ...
                    obj.foodFitness(1), obj.foodFitness(2)));
            end
        end

        function tf = shouldStop(obj)
            tf = obj.currentIteration >= obj.config.maxIterations;
        end

        function validated = validateConfig(obj, config)
            validated = config;

            defaults = struct(...
                'populationSize', 100, ...
                'maxIterations', 100, ...
                'archiveMaxSize', 100, ...
                'separationWeight', 0.1, ...
                'alignmentWeight', 0.1, ...
                'cohesionWeight', 0.1, ...
                'foodWeight', 0.1, ...
                'enemyWeight', 0.1, ...
                'wMax', 0.9, ...
                'wMin', 0.2, ...
                'verbose', true ...
            );

            fields = fieldnames(defaults);
            for i = 1:length(fields)
                if ~isfield(validated, fields{i})
                    validated.(fields{i}) = defaults.(fields{i});
                end
            end

            validated.populationSize = max(10, round(validated.populationSize));
            validated.maxIterations = max(1, round(validated.maxIterations));
            validated.archiveMaxSize = max(10, round(validated.archiveMaxSize));
        end
    end

    methods (Access = protected)
        function [S, A, C, F, E, hasNeighbors] = calculateBehaviors(obj, idx)
            % calculateBehaviors 计算五种行为向量
            %
            % 输入参数:
            %   idx - 当前蜻蜓索引
            %
            % 输出参数:
            %   S - 分离向量
            %   A - 对齐向量
            %   C - 凝聚向量
            %   F - 食物吸引向量
            %   E - 敌人排斥向量
            %   hasNeighbors - 是否有邻居

            N = obj.config.populationSize;
            dim = size(obj.positions, 2);

            S = zeros(1, dim);
            A = zeros(1, dim);
            C = zeros(1, dim);
            F = zeros(1, dim);
            E = zeros(1, dim);

            neighborsCount = 0;
            neighborsVel = zeros(1, dim);
            neighborsPos = zeros(1, dim);

            for j = 1:N
                if j ~= idx
                    dist = abs(obj.positions(idx, :) - obj.positions(j, :));
                    if all(dist <= obj.neighborhoodRadius)
                        neighborsCount = neighborsCount + 1;

                        S = S + (obj.positions(j, :) - obj.positions(idx, :));
                        neighborsVel = neighborsVel + obj.stepVectors(j, :);
                        neighborsPos = neighborsPos + obj.positions(j, :);
                    end
                end
            end

            hasNeighbors = neighborsCount > 0;

            if hasNeighbors
                S = -S;
                A = neighborsVel / neighborsCount;
                C = (neighborsPos / neighborsCount) - obj.positions(idx, :);
            end

            distToFood = abs(obj.positions(idx, :) - obj.foodPosition);
            if all(distToFood <= obj.neighborhoodRadius)
                F = obj.foodPosition - obj.positions(idx, :);
            end

            distToEnemy = abs(obj.positions(idx, :) - obj.enemyPosition);
            if all(distToEnemy <= obj.neighborhoodRadius)
                E = obj.enemyPosition + obj.positions(idx, :);
            end
        end

        function step = levyFlight(obj, dim)
            % levyFlight Levy飞行
            %
            % 输入参数:
            %   dim - 维度
            %
            % 输出参数:
            %   step - Levy步长向量

            beta = 1.5;
            sigma = (gamma(1 + beta) * sin(pi * beta / 2) / ...
                (gamma((1 + beta) / 2) * beta * 2^((beta - 1) / 2)))^(1 / beta);

            u = randn(1, dim) * sigma;
            v = randn(1, dim);
            step = u ./ (abs(v).^(1 / beta));
        end
    end

    methods (Static)
        function register()
            AlgorithmRegistry.register('MODA', '1.0.0', @MODA);
        end
    end
end
