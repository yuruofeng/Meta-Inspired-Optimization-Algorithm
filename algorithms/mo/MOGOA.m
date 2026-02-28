classdef MOGOA < MOBaseAlgorithm
    % MOGOA 多目标蚱蜢优化算法 (Multi-Objective Grasshopper Optimization Algorithm)
    %
    % 一种模拟蚱蜢群体行为的多目标元启发式算法。通过蚱蜢群体的
    % 社会相互作用（吸引和排斥）实现Pareto前沿搜索。
    %
    % 算法特点:
    %   - 社会相互作用: 蚱蜢之间的吸引和排斥力
    %   - 舒适区: 距离太近时排斥，太远时吸引
    %   - 重力影响: 模拟重力对群体的影响
    %   - 风力影响: 模拟风对群体移动的影响
    %   - 自适应参数c: 控制探索和开发平衡
    %
    % 参考文献:
    %   S. Z. Mirjalili, S. Mirjalili, S. Saremi, H. Faris, H. Aljarah
    %   "Grasshopper optimization algorithm for multi-objective optimization problems"
    %   Applied Intelligence, 2017
    %   DOI: 10.1007/s10489-017-1019-8
    %
    % 时间复杂度: O(MaxIter × N² × Dim)
    % 空间复杂度: O(ArchiveSize × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 200, 'maxIterations', 100);
    %   mogoa = MOGOA(config);
    %   problem.lb = 0; problem.ub = 1; problem.dim = 5;
    %   problem.objCount = 2;
    %   problem.evaluate = @(x) ZDT1(x);
    %   result = mogoa.run(problem);
    %   result.plot();
    %
    % 原始作者: Seyedali Mirjalili
    % 重构版本: 2.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 蚱蜢位置矩阵 (N x Dim)
        fitness              % 适应度矩阵 (N x objCount)
        targetPosition       % 目标位置 (1 x Dim)
        targetFitness        % 目标适应度 (1 x objCount)
        cMax                 % 最大自适应参数
        cMin                 % 最小自适应参数
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 200, ...
                'min', 10, ...
                'max', 10000, ...
                'description', '蚱蜢种群大小'), ...
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
            'cMax', struct(...
                'type', 'float', ...
                'default', 1, ...
                'min', 0.1, ...
                'max', 10, ...
                'description', '最大自适应参数c'), ...
            'cMin', struct(...
                'type', 'float', ...
                'default', 0.00004, ...
                'min', 0, ...
                'max', 1, ...
                'description', '最小自适应参数c'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = MOGOA(configStruct)
            % MOGOA 构造函数
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

            obj.cMax = obj.config.cMax;
            obj.cMin = obj.config.cMin;

            obj.positions = Initialization(N, dim, ub, lb);
            obj.fitness = zeros(N, obj.objCount);

            obj.targetPosition = zeros(1, dim);
            obj.targetFitness = inf(1, obj.objCount);

            obj.archiveX = zeros(obj.archiveMaxSize, dim);
            obj.archiveF = inf(obj.archiveMaxSize, obj.objCount);
            obj.archiveSize = int32(0);

            for i = 1:N
                obj.fitness(i, :) = obj.evaluateSolution(obj.positions(i, :));
            end

            obj.updateArchive(obj.positions, obj.fitness);

            if obj.archiveSize > 0
                obj.targetFitness = obj.archiveF(1, :);
                obj.targetPosition = obj.archiveX(1, :);
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

            for i = 1:N
                obj.positions(i, :) = min(max(obj.positions(i, :), lb), ub);
                obj.fitness(i, :) = obj.evaluateSolution(obj.positions(i, :));
            end

            obj.updateArchive(obj.positions, obj.fitness);
            obj.archiveRanks = obj.rankingProcess(obj.archiveF(1:obj.archiveSize, :));

            targetIdx = obj.selectFromArchive(true);
            if targetIdx == 0
                targetIdx = 1;
            end
            obj.targetFitness = obj.archiveF(targetIdx, :);
            obj.targetPosition = obj.archiveX(targetIdx, :);

            c = obj.cMax - currentIter * ((obj.cMax - obj.cMin) / MaxIter);

            newPositions = zeros(N, dim);

            for i = 1:N
                S_i_total = zeros(1, dim);

                for j = 1:N
                    if i ~= j
                        dist = obj.calculateDistance(obj.positions(i, :), obj.positions(j, :));
                        r_ij_vec = (obj.positions(j, :) - obj.positions(i, :)) / (dist + eps);

                        xj_xi = 2 + mod(dist, 2);

                        s_ij = ((ub - lb) .* c / 2) .* obj.sFunc(xj_xi) .* r_ij_vec;
                        S_i_total = S_i_total + s_ij;
                    end
                end

                X_new = c * S_i_total + obj.targetPosition;
                newPositions(i, :) = X_new;
            end

            for i = 1:N
                newPositions(i, :) = min(max(newPositions(i, :), lb), ub);
            end

            obj.positions = newPositions;

            obj.convergenceCurve(currentIter) = obj.archiveSize;

            if obj.config.verbose && mod(currentIter, 10) == 0
                obj.displayProgress(sprintf('Target fitness: [%.4e, %.4e]', ...
                    obj.targetFitness(1), obj.targetFitness(2)));
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
                'cMax', 1, ...
                'cMin', 0.00004, ...
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
        function dist = calculateDistance(obj, x, y)
            % calculateDistance 计算两个解之间的欧氏距离
            %
            % 输入参数:
            %   x - 解1
            %   y - 解2
            %
            % 输出参数:
            %   dist - 欧氏距离向量

            dist = abs(x - y);
        end

        function s = sFunc(obj, r)
            % sFunc 社会相互作用函数
            %
            % 实现GOA的核心: 吸引和排斥机制
            % 当r < 2.079时排斥，r > 2.079时吸引
            %
            % 输入参数:
            %   r - 距离
            %
            % 输出参数:
            %   s - 相互作用强度

            f = 0.5;
            l = 1.5;

            s = f * exp(-r / l) - exp(-r);
        end
    end

    methods (Static)
        function register()
            AlgorithmRegistry.register('MOGOA', '1.0.0', @MOGOA);
        end
    end
end
