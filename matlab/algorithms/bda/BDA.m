classdef BDA < BaseAlgorithm
    % BDA 二进制蜻蜓算法 (Binary Dragonfly Algorithm)
    %
    % DA的二进制版本，使用V3传递函数将连续步长转换为二进制位置更新概率。
    %
    % 算法特点:
    %   - 五种行为: 分离、对齐、凝聚、食物吸引、敌人排斥
    %   - V3传递函数: T = |v / sqrt(1 + v²)|
    %   - 全局邻域: 所有蜻蜓作为邻居
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
    %   bda = algorithms.bda.BDA(config);
    %   problem = struct('evaluate', @myBinaryFitness, 'lb', 0, 'ub', 1, 'dim', 50);
    %   result = bda.run(problem);
    %
    % 原始作者: Seyedali Mirjalili
    % 重构版本: 2.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 二进制位置 (N x Dim, logical)
        stepVectors          % 步长向量 (N x Dim, double)
        foodPosition         % 食物位置 (最优)
        foodFitness          % 食物适应度
        enemyPosition        % 敌人位置 (最差)
        enemyFitness         % 敌人适应度
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
            'separationWeight', struct(...
                'type', 'float', ...
                'default', 0.1, ...
                'min', 0, ...
                'description', '分离权重'), ...
            'alignmentWeight', struct(...
                'type', 'float', ...
                'default', 0.1, ...
                'min', 0, ...
                'description', '对齐权重'), ...
            'cohesionWeight', struct(...
                'type', 'float', ...
                'default', 0.1, ...
                'min', 0, ...
                'description', '凝聚权重'), ...
            'foodWeight', struct(...
                'type', 'float', ...
                'default', 0.1, ...
                'min', 0, ...
                'description', '食物吸引权重'), ...
            'enemyWeight', struct(...
                'type', 'float', ...
                'default', 0.1, ...
                'min', 0, ...
                'description', '敌人排斥权重'), ...
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
            'maxStep', struct(...
                'type', 'float', ...
                'default', 6, ...
                'min', 0, ...
                'description', '最大步长'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = BDA(configStruct)
            % BDA 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，可选字段:
            %     - populationSize: 种群大小 (默认: 30)
            %     - maxIterations: 最大迭代次数 (默认: 500)
            %     - separationWeight: 分离权重 (默认: 0.1)
            %     - alignmentWeight: 对齐权重 (默认: 0.1)
            %     - cohesionWeight: 凝聚权重 (默认: 0.1)
            %     - foodWeight: 食物吸引权重 (默认: 0.1)
            %     - enemyWeight: 敌人排斥权重 (默认: 0.1)
            %     - wMax, wMin: 惯性权重范围 (默认: 0.9, 0.4)
            %     - maxStep: 最大步长 (默认: 6)
            %     - verbose: 是否显示进度 (默认: true)

            if nargin < 1 || isempty(configStruct)
                configStruct = struct();
            end
            obj = obj@BaseAlgorithm(configStruct);
        end

        function initialize(obj, problem)
            dim = problem.dim;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;

            % 初始化二进制位置
            obj.positions = rand(N, dim) > 0.5;
            obj.stepVectors = rand(N, dim) > 0.5;

            % 初始化食物和敌人
            obj.foodPosition = false(1, dim);
            obj.foodFitness = Inf;
            obj.enemyPosition = false(1, dim);
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

            obj.bestSolution = obj.foodPosition;
            obj.bestFitness = obj.foodFitness;
            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            N = obj.config.populationSize;
            dim = size(obj.positions, 2);
            MaxIter = obj.config.maxIterations;
            currentIter = obj.currentIteration + 1;

            % 动态参数
            w = obj.config.wMax - currentIter * ((obj.config.wMax - obj.config.wMin) / MaxIter);
            my_c = 0.1 - currentIter * ((0.1 - 0) / (MaxIter / 2));
            if my_c < 0
                my_c = 0;
            end

            s = 2 * rand * my_c * obj.config.separationWeight;
            a = 2 * rand * my_c * obj.config.alignmentWeight;
            c = 2 * rand * my_c * obj.config.cohesionWeight;
            f = 2 * rand * obj.config.foodWeight;
            e = my_c * obj.config.enemyWeight;

            % 后期禁用敌人排斥
            if currentIter > (3 * MaxIter / 4)
                e = 0;
            end

            % 更新食物和敌人
            for i = 1:N
                fitness = obj.problem.evaluate(obj.positions(i, :));
                if fitness < obj.foodFitness
                    obj.foodFitness = fitness;
                    obj.foodPosition = obj.positions(i, :);
                end
                if fitness > obj.enemyFitness
                    obj.enemyFitness = fitness;
                    obj.enemyPosition = obj.positions(i, :);
                end
            end

            % 更新每个蜻蜓 (全局邻域)
            for i = 1:N
                % 计算邻居 (所有其他蜻蜓)
                neighbors = obj.positions(setdiff(1:N, i), :);
                neighborSteps = obj.stepVectors(setdiff(1:N, i), :);

                % 分离 (S)
                S = -sum(neighbors - obj.positions(i, :), 1);

                % 对齐 (A)
                A = mean(neighborSteps, 1);

                % 凝聚 (C)
                C = mean(neighbors, 1) - double(obj.positions(i, :));

                % 食物吸引 (F)
                F = double(obj.foodPosition) - double(obj.positions(i, :));

                % 敌人排斥 (E)
                E = double(obj.enemyPosition) + double(obj.positions(i, :));

                % 更新步长
                obj.stepVectors(i, :) = s * S + a * A + c * C + f * F + e * E + w * obj.stepVectors(i, :);

                % 步长限制
                obj.stepVectors(i, :) = max(obj.stepVectors(i, :), -obj.config.maxStep);
                obj.stepVectors(i, :) = min(obj.stepVectors(i, :), obj.config.maxStep);

                % V3传递函数并更新位置
                for j = 1:dim
                    T = abs(obj.stepVectors(i, j) / sqrt(1 + obj.stepVectors(i, j)^2));
                    if rand < T
                        obj.positions(i, j) = ~obj.positions(i, j);
                    end
                end
            end

            % 更新全局最优
            if obj.foodFitness < obj.bestFitness
                obj.bestFitness = obj.foodFitness;
                obj.bestSolution = obj.foodPosition;
            end

            obj.convergenceCurve(currentIter) = obj.bestFitness;

            if obj.config.verbose && mod(currentIter, 50) == 0
                obj.displayProgress(sprintf('Best: %.6f, Ones: %d', obj.bestFitness, sum(obj.bestSolution)));
            end
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

            validatedConfig = BaseAlgorithm.validateFromSchema(config, obj.PARAM_SCHEMA);
            
            if validatedConfig.wMin > validatedConfig.wMax
                error('BDA:InvalidConfig', 'wMin must be <= wMax');
            end
            if validatedConfig.maxStep <= 0
                error('BDA:InvalidConfig', 'maxStep must be > 0');
            end
        end
    end

    methods (Static)
        function register()
            % register 将BDA算法注册到算法注册表
            %
            % 示例:
            %   BDA.register();
            %   algClass = AlgorithmRegistry.getAlgorithm('BDA');

            AlgorithmRegistry.register('BDA', '2.0.0', @BDA);
        end
    end
end
