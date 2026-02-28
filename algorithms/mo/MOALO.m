classdef MOALO < MOBaseAlgorithm
    % MOALO 多目标蚁狮优化器 (Multi-Objective Ant Lion Optimizer)
    %
    % 一种基于蚁狮狩猎行为的元启发式多目标优化算法。通过蚂蚁在沙坑中的
    % 随机游走行为和蚁狮的捕食机制实现Pareto前沿搜索。
    %
    % 算法特点:
    %   - 蚂蚁随机游走: 模拟蚂蚁在蚁狮陷阱周围的随机移动
    %   - 蚁狮陷阱构建: 根据适应度构建圆锥形陷阱
    %   - 精英策略: 最优蚁狮引导搜索方向
    %   - 存档机制: 维护Pareto前沿存档
    %
    % 参考文献:
    %   S. Mirjalili, P. Jangir, S. Saremi
    %   "Multi-objective ant lion optimizer: a multi-objective optimization
    %    algorithm for solving engineering problems"
    %   Applied Intelligence, 2016
    %   DOI: 10.1007/s10489-016-0825-8
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(ArchiveSize × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 100, 'maxIterations', 100, 'archiveMaxSize', 100);
    %   moalo = MOALO(config);
    %   problem.lb = 0; problem.ub = 1; problem.dim = 5;
    %   problem.objCount = 2;
    %   problem.evaluate = @(x) ZDT1(x);
    %   result = moalo.run(problem);
    %   result.plot();
    %
    % 原始作者: Seyedali Mirjalili
    % 重构版本: 2.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 蚂蚁位置矩阵 (N x Dim)
        fitness              % 蚂蚁适应度矩阵 (N x objCount)
        elitePosition        % 精英蚁狮位置 (1 x Dim)
        eliteFitness         % 精英蚁狮适应度 (1 x objCount)
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 100, ...
                'min', 10, ...
                'max', 10000, ...
                'description', '蚂蚁/蚁狮种群大小'), ...
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
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = MOALO(configStruct)
            % MOALO 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，可选字段:
            %     - populationSize: 种群大小 (默认: 100)
            %     - maxIterations: 最大迭代次数 (默认: 100)
            %     - archiveMaxSize: 存档最大容量 (默认: 100)
            %     - verbose: 是否显示进度 (默认: true)

            if nargin < 1 || isempty(configStruct)
                configStruct = struct();
            end

            obj = obj@MOBaseAlgorithm(configStruct);
        end

        function initialize(obj, problem)
            % initialize 初始化种群和存档
            %
            % 输入参数:
            %   problem - 问题对象，需包含 lb, ub, dim, objCount 字段

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

            obj.positions = Initialization(N, dim, ub, lb);
            obj.fitness = zeros(N, obj.objCount);

            obj.archiveX = zeros(obj.archiveMaxSize, dim);
            obj.archiveF = inf(obj.archiveMaxSize, obj.objCount);
            obj.archiveSize = int32(0);

            obj.elitePosition = zeros(1, dim);
            obj.eliteFitness = inf(1, obj.objCount);

            for i = 1:N
                obj.fitness(i, :) = obj.evaluateSolution(obj.positions(i, :));
            end

            obj.updateArchive(obj.positions, obj.fitness);

            if obj.archiveSize > 0
                obj.eliteFitness = obj.archiveF(1, :);
                obj.elitePosition = obj.archiveX(1, :);
            end

            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代
            %
            % 包括选择蚁狮、随机游走、更新位置和存档

            lb = obj.problem.lb;
            ub = obj.problem.ub;
            N = obj.config.populationSize;
            dim = size(obj.positions, 2);
            MaxIter = obj.config.maxIterations;
            currentIter = obj.currentIteration + 1;

            obj.archiveRanks = obj.rankingProcess(obj.archiveF(1:obj.archiveSize, :));

            randomAntlionIdx = obj.selectFromArchive(true);
            if randomAntlionIdx == 0
                randomAntlionIdx = 1;
            end
            randomAntlionPos = obj.archiveX(randomAntlionIdx, :);

            for i = 1:N
                walkElite = obj.randomWalkAroundAntlion(obj.elitePosition, dim, MaxIter, currentIter, lb, ub);
                walkRandom = obj.randomWalkAroundAntlion(randomAntlionPos, dim, MaxIter, currentIter, lb, ub);

                newPos = (walkElite + walkRandom) / 2;

                newPos = min(max(newPos, lb), ub);

                obj.positions(i, :) = newPos;
                obj.fitness(i, :) = obj.evaluateSolution(newPos);
            end

            obj.updateArchive(obj.positions, obj.fitness);

            if obj.archiveSize > 0
                obj.archiveRanks = obj.rankingProcess(obj.archiveF(1:obj.archiveSize, :));
                bestIdx = obj.selectFromArchive(true);
                if bestIdx == 0
                    bestIdx = 1;
                end
                obj.eliteFitness = obj.archiveF(bestIdx, :);
                obj.elitePosition = obj.archiveX(bestIdx, :);
            end

            obj.convergenceCurve(currentIter) = obj.archiveSize;

            if obj.config.verbose && mod(currentIter, 10) == 0
                obj.displayProgress(sprintf('Best fitness: [%.4e, %.4e]', ...
                    obj.eliteFitness(1), obj.eliteFitness(2)));
            end
        end

        function tf = shouldStop(obj)
            % shouldStop 判断是否应该停止迭代
            %
            % 输出参数:
            %   tf - true表示停止

            tf = obj.currentIteration >= obj.config.maxIterations;
        end

        function validated = validateConfig(obj, config)
            % validateConfig 验证并规范化配置参数
            %
            % 输入参数:
            %   config - 原始配置结构体
            %
            % 输出参数:
            %   validated - 验证后的配置结构体

            validated = config;

            if ~isfield(validated, 'populationSize')
                validated.populationSize = 100;
            end

            if ~isfield(validated, 'maxIterations')
                validated.maxIterations = 100;
            end

            if ~isfield(validated, 'archiveMaxSize')
                validated.archiveMaxSize = 100;
            end

            if ~isfield(validated, 'verbose')
                validated.verbose = true;
            end

            validated.populationSize = max(10, round(validated.populationSize));
            validated.maxIterations = max(1, round(validated.maxIterations));
            validated.archiveMaxSize = max(10, round(validated.archiveMaxSize));
        end
    end

    methods (Access = protected)
        function walk = randomWalkAroundAntlion(obj, antlionPos, dim, maxIter, currentIter, lb, ub)
            % randomWalkAroundAntlion 围绕蚁狮进行随机游走
            %
            % 实现ALO算法的核心随机游走机制
            %
            % 输入参数:
            %   antlionPos - 蚁狮位置 (1 x dim)
            %   dim - 维度
            %   maxIter - 最大迭代次数
            %   currentIter - 当前迭代次数
            %   lb - 下边界
            %   ub - 上边界
            %
            % 输出参数:
            %   walk - 随机游走后的位置 (1 x dim)

            I = 1;
            ratioIter = currentIter / maxIter;

            if ratioIter > 0.1
                I = 1 + 100 * ratioIter;
            end
            if ratioIter > 0.5
                I = 1 + 1000 * ratioIter;
            end
            if ratioIter > 0.75
                I = 1 + 10000 * ratioIter;
            end
            if ratioIter > 0.9
                I = 1 + 100000 * ratioIter;
            end
            if ratioIter > 0.95
                I = 1 + 1000000 * ratioIter;
            end

            adaptiveLb = lb / I;
            adaptiveUb = ub / I;

            if rand < 0.5
                adaptiveLb = adaptiveLb + antlionPos;
            else
                adaptiveLb = -adaptiveLb + antlionPos;
            end

            if rand >= 0.5
                adaptiveUb = adaptiveUb + antlionPos;
            else
                adaptiveUb = -adaptiveUb + antlionPos;
            end

            walk = zeros(1, dim);
            for d = 1:dim
                X = [0, cumsum(2 * (rand(1, maxIter) > 0.5) - 1)];

                a = min(X);
                b = max(X);
                c = adaptiveLb(d);
                d_val = adaptiveUb(d);

                if b - a > 0
                    X_normalized = (X - a) * (d_val - c) / (b - a) + c;
                else
                    X_normalized = zeros(1, maxIter + 1);
                end

                walk(d) = X_normalized(currentIter + 1);
            end
        end
    end

    methods (Static)
        function register()
            AlgorithmRegistry.register('MOALO', '1.0.0', @MOALO);
        end
    end
end
