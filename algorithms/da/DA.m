classdef DA < BaseAlgorithm
    % DA 蜻蜓算法 (Dragonfly Algorithm)
    %
    % 一种模拟蜻蜓静态和动态群集行为的元启发式算法。通过分离、对齐、
    % 凝聚、食物吸引和敌人排斥五种行为实现群体智能优化。
    %
    % 算法特点:
    %   - 分离(S): 避免与邻居碰撞
    %   - 对齐(A): 与邻居速度匹配
    %   - 凝聚(C): 向邻居中心移动
    %   - 食物吸引(F): 向食物(最优解)移动
    %   - 敌人排斥(E): 远离敌人(最差解)
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
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   da = algorithms.da.DA(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = da.run(problem);
    %
    % 原始作者: Seyedali Mirjalili
    % 重构版本: 2.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 位置矩阵 (N x Dim)
        stepVectors          % 步长向量矩阵 (N x Dim)
        foodPosition         % 食物位置 (最优解)
        foodFitness          % 食物适应度
        enemyPosition        % 敌人位置 (最差解，用于排斥)
        enemyFitness         % 敌人适应度
        neighborhoodRadius   % 邻域半径
        maxStep              % 最大步长
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 5, ...
                'max', 10000, ...
                'description', '蜻蜓种群大小'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 500, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
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
                'default', 0.4, ...
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
        function obj = DA(configStruct)
            % DA 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，可选字段:
            %     - populationSize: 蜻蜓种群大小 (默认: 30)
            %     - maxIterations: 最大迭代次数 (默认: 500)
            %     - separationWeight: 分离权重 (默认: 0.1)
            %     - alignmentWeight: 对齐权重 (默认: 0.1)
            %     - cohesionWeight: 凝聚权重 (默认: 0.1)
            %     - foodWeight: 食物吸引权重 (默认: 0.1)
            %     - enemyWeight: 敌人排斥权重 (默认: 0.1)
            %     - wMax, wMin: 惯性权重范围 (默认: 0.9, 0.4)
            %     - verbose: 是否显示进度 (默认: true)

            if nargin < 1 || isempty(configStruct)
                configStruct = struct();
            end

            obj = obj@BaseAlgorithm(configStruct);
        end

        function initialize(obj, problem)
            % initialize 初始化种群

            lb = problem.lb;
            ub = problem.ub;
            dim = problem.dim;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;

            % 扩展边界为向量
            if isscalar(lb)
                lb = lb * ones(1, dim);
                ub = ub * ones(1, dim);
            end
            obj.problem.lb = lb;
            obj.problem.ub = ub;

            % 初始化邻域半径和最大步长
            obj.neighborhoodRadius = (ub - lb) / 10;
            obj.maxStep = (ub - lb) / 10;

            % 初始化位置和步长
            obj.positions = Initialization(N, dim, ub, lb);
            obj.stepVectors = Initialization(N, dim, ub, lb);

            % 初始化食物和敌人
            obj.foodPosition = zeros(1, dim);
            obj.foodFitness = Inf;
            obj.enemyPosition = zeros(1, dim);
            obj.enemyFitness = -Inf;

            % 评估初始种群
            for i = 1:N
                fitness = obj.evaluateSolution(obj.positions(i, :));
                if fitness < obj.foodFitness
                    obj.foodFitness = fitness;
                    obj.foodPosition = obj.positions(i, :);
                end
                if fitness > obj.enemyFitness
                    obj.enemyFitness = fitness;
                    obj.enemyPosition = obj.positions(i, :);
                end
            end

            % 初始化全局最优
            obj.bestSolution = obj.foodPosition;
            obj.bestFitness = obj.foodFitness;

            % 预分配收敛曲线
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

            % 动态调整参数
            obj.neighborhoodRadius = (ub - lb) / 4 + ((ub - lb) * (currentIter / MaxIter) * 2);
            w = obj.config.wMax - currentIter * ((obj.config.wMax - obj.config.wMin) / MaxIter);

            % 自适应权重因子
            my_c = 0.1 - currentIter * ((0.1 - 0) / (MaxIter / 2));
            if my_c < 0
                my_c = 0;
            end

            s = 2 * rand * my_c * obj.config.separationWeight;
            a = 2 * rand * my_c * obj.config.alignmentWeight;
            c = 2 * rand * my_c * obj.config.cohesionWeight;
            f = 2 * rand * obj.config.foodWeight;
            e = my_c * obj.config.enemyWeight;

            % 更新食物和敌人
            for i = 1:N
                fitness = obj.problem.evaluate(obj.positions(i, :));
                if fitness < obj.foodFitness
                    obj.foodFitness = fitness;
                    obj.foodPosition = obj.positions(i, :);
                end
                if fitness > obj.enemyFitness
                    if all(obj.positions(i, :) <= ub) && all(obj.positions(i, :) >= lb)
                        obj.enemyFitness = fitness;
                        obj.enemyPosition = obj.positions(i, :);
                    end
                end
            end

            % 更新每个蜻蜓
            for i = 1:N
                % 找邻居
                neighbors = zeros(N, dim);
                neighborSteps = zeros(N, dim);
                for j = 1:N
                    dist = abs(obj.positions(i, :) - obj.positions(j, :));
                    if all(dist <= obj.neighborhoodRadius) && j ~= i
                        neighbors = [neighbors; obj.positions(j, :)];
                        neighborSteps = [neighborSteps; obj.stepVectors(j, :)];
                    end
                end
                numNeighbors = size(neighbors, 1);

                % 计算五个行为向量
                % 分离 (S)
                if numNeighbors > 0
                    S = -sum(neighbors - obj.positions(i, :), 1);
                else
                    S = zeros(1, dim);
                end

                % 对齐 (A)
                if numNeighbors > 0
                    A = mean(neighborSteps, 1);
                else
                    A = obj.stepVectors(i, :);
                end

                % 凝聚 (C)
                if numNeighbors > 0
                    C = mean(neighbors, 1) - obj.positions(i, :);
                else
                    C = zeros(1, dim);
                end

                % 食物吸引 (F)
                distToFood = abs(obj.positions(i, :) - obj.foodPosition);
                if all(distToFood <= obj.neighborhoodRadius)
                    F = obj.foodPosition - obj.positions(i, :);
                else
                    F = zeros(1, dim);
                end

                % 敌人排斥 (E)
                distToEnemy = abs(obj.positions(i, :) - obj.enemyPosition);
                if all(distToEnemy <= obj.neighborhoodRadius)
                    E = obj.enemyPosition + obj.positions(i, :);
                else
                    E = zeros(1, dim);
                end

                % 更新步长和位置
                distToFoodAll = abs(obj.positions(i, :) - obj.foodPosition);
                if any(distToFoodAll > obj.neighborhoodRadius)
                    if numNeighbors > 0
                        % 有邻居，使用群集行为
                        obj.stepVectors(i, :) = w * obj.stepVectors(i, :) + rand * A + rand * C + rand * S;
                        obj.positions(i, :) = obj.positions(i, :) + obj.stepVectors(i, :);
                    else
                        % 无邻居，使用Levy飞行
                        levy = algorithms.da.operators.LevyFlight.generate(dim);
                        obj.positions(i, :) = obj.positions(i, :) + levy .* obj.positions(i, :);
                        obj.stepVectors(i, :) = zeros(1, dim);
                    end
                else
                    % 接近食物，使用所有行为
                    obj.stepVectors(i, :) = (a * A + c * C + s * S + f * F + e * E) + w * obj.stepVectors(i, :);
                    obj.positions(i, :) = obj.positions(i, :) + obj.stepVectors(i, :);
                end

                obj.stepVectors(i, :) = max(obj.stepVectors(i, :), -obj.maxStep);
                obj.stepVectors(i, :) = min(obj.stepVectors(i, :), obj.maxStep);

                obj.positions(i, :) = obj.clampToBounds(obj.positions(i, :), lb, ub);
            end

            % 更新全局最优
            if obj.foodFitness < obj.bestFitness
                obj.bestFitness = obj.foodFitness;
                obj.bestSolution = obj.foodPosition;
            end

            % 记录收敛曲线
            obj.convergenceCurve(currentIter) = obj.bestFitness;

            % 显示进度
            if obj.config.verbose && mod(currentIter, 50) == 0
                obj.displayProgress(sprintf('Best fitness: %.6e', obj.bestFitness));
            end
        end

        function tf = shouldStop(obj)
            tf = obj.currentIteration >= obj.config.maxIterations;
        end

        function validatedConfig = validateConfig(obj, config)
            validatedConfig = BaseAlgorithm.validateFromSchema(config, obj.PARAM_SCHEMA);
        end
    end

    methods (Static)
        function register()
            % register 将DA算法注册到算法注册表
            %
            % 示例:
            %   DA.register();
            %   algClass = AlgorithmRegistry.getAlgorithm('DA');

            AlgorithmRegistry.register('DA', '2.0.0', @DA);
        end
    end
end
