classdef MSSA < MOBaseAlgorithm
    % MSSA 多目标樽海鞘群算法 (Multi-Objective Salp Swarm Algorithm)
    %
    % 一种模拟樽海鞘链状群体行为的多目标元启发式算法。通过领导者-
    % 跟随者机制实现Pareto前沿搜索。
    %
    % 算法特点:
    %   - 链式结构: 樽海鞘形成链状群体
    %   - 领导者-跟随者: 前端为领导者，后端为跟随者
    %   - 食物源引导: 以存档中的最优解作为食物源
    %   - 自适应参数c1: 控制探索和开发的平衡
    %
    % 参考文献:
    %   S. Mirjalili, A.H. Gandomi, S.Z. Mirjalili, S. Saremi, H. Faris, S.M. Mirjalili
    %   "Salp Swarm Algorithm: A bio-inspired optimizer for engineering design problems"
    %   Advances in Engineering Software, 2017
    %   DOI: 10.1016/j.advengsoft.2017.07.002
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(ArchiveSize × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 200, 'maxIterations', 100);
    %   mssa = MSSA(config);
    %   problem.lb = 0; problem.ub = 1; problem.dim = 5;
    %   problem.objCount = 2;
    %   problem.evaluate = @(x) ZDT1(x);
    %   result = mssa.run(problem);
    %   result.plot();
    %
    % 原始作者: Seyedali Mirjalili
    % 重构版本: 2.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 樽海鞘位置矩阵 (N x Dim)
        fitness              % 适应度矩阵 (N x objCount)
        foodPosition         % 食物位置 (1 x Dim)
        foodFitness          % 食物适应度 (1 x objCount)
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 200, ...
                'min', 10, ...
                'max', 10000, ...
                'description', '樽海鞘种群大小'), ...
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
        function obj = MSSA(configStruct)
            % MSSA 构造函数
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

            obj.positions = Initialization(N, dim, ub, lb);
            obj.fitness = zeros(N, obj.objCount);

            obj.foodPosition = zeros(1, dim);
            obj.foodFitness = inf(1, obj.objCount);

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

            c1 = 2 * exp(-(4 * currentIter / MaxIter)^2);

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

            for i = 1:N
                if i <= N / 2
                    for j = 1:dim
                        c2 = rand();
                        c3 = rand();

                        if c3 < 0.5
                            obj.positions(i, j) = obj.foodPosition(j) + ...
                                c1 * ((ub(j) - lb(j)) * c2 + lb(j));
                        else
                            obj.positions(i, j) = obj.foodPosition(j) - ...
                                c1 * ((ub(j) - lb(j)) * c2 + lb(j));
                        end
                    end
                else
                    point1 = obj.positions(i - 1, :);
                    point2 = obj.positions(i, :);
                    obj.positions(i, :) = (point1 + point2) / 2;
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
                'populationSize', 200, ...
                'maxIterations', 100, ...
                'archiveMaxSize', 100, ...
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

    methods (Static)
        function register()
            AlgorithmRegistry.register('MSSA', '1.0.0', @MSSA);
        end
    end
end
