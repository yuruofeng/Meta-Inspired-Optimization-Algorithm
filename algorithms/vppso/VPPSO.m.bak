classdef VPPSO < BaseAlgorithm
    % VPPSO 速度暂停粒子群优化 (Velocity Pausing Particle Swarm Optimization)
    %
    % 一种改进的PSO算法，采用双种群机制。第一种群执行带速度暂停的
    % 传统PSO，第二种群围绕全局最优进行搜索。
    %
    % 算法特点:
    %   - 双种群: 第一种群N个粒子，第二种群N+15个粒子
    %   - 速度暂停: 第一种群以概率暂停速度更新
    %   - 动态权重: ww(t) = exp(-(2.5*t/max_iter)^2.5)
    %   - 围绕最优搜索: 第二种群围绕全局最优探索
    %
    % 参考文献:
    %   T. M. Shami, S. Mirjalili, et al.
    %   "Velocity pausing particle swarm optimization: a novel variant
    %    for global optimization"
    %   Applied Intelligence, 2022
    %
    % 时间复杂度: O(MaxIter × (N+NT) × Dim)
    % 空间复杂度: O((N+NT) × Dim)
    %
    % 使用示例:
    %   config = struct('swarm1Size', 15, 'swarm2AddSize', 15, 'maxIterations', 500);
    %   vppso = VPPSO(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = vppso.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Tareq M. Shami, Seyedali Mirjalili
    % 重构版本: 2.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 位置矩阵 ((N+NT) x Dim)
        velocities           % 速度矩阵 (N x Dim)，仅第一种群有速度
        pbestPositions       % 个体最优位置 (N x Dim)，仅第一种群
        pbestFitness         % 个体最优适应度 (N x 1)
        gbestPosition        % 全局最优位置 (1 x Dim)
        gbestFitness         % 全局最优适应度
        swarm1Size           % 第一种群大小
        swarm2Size           % 第二种群大小 (新增粒子数)
        totalSize            % 总粒子数
        Vmax                 % 最大速度
        Vmin                 % 最小速度
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'swarm1Size', struct(...
                'type', 'integer', ...
                'default', 15, ...
                'min', 5, ...
                'max', 10000, ...
                'description', '第一种群粒子数量'), ...
            'swarm2AddSize', struct(...
                'type', 'integer', ...
                'default', 15, ...
                'min', 0, ...
                'max', 10000, ...
                'description', '第二种群额外粒子数量'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 500, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'wMax', struct(...
                'type', 'float', ...
                'default', 0.9, ...
                'min', 0, ...
                'max', 1, ...
                'description', '最大惯性权重'), ...
            'wMin', struct(...
                'type', 'float', ...
                'default', 0.1, ...
                'min', 0, ...
                'max', 1, ...
                'description', '最小惯性权重'), ...
            'c1', struct(...
                'type', 'float', ...
                'default', 2, ...
                'min', 0, ...
                'description', '认知系数'), ...
            'c2', struct(...
                'type', 'float', ...
                'default', 2, ...
                'min', 0, ...
                'description', '社会系数'), ...
            'velocityPauseRate', struct(...
                'type', 'float', ...
                'default', 0.3, ...
                'min', 0, ...
                'max', 1, ...
                'description', '速度暂停概率'), ...
            'velocityClampFactor', struct(...
                'type', 'float', ...
                'default', 0.1, ...
                'min', 0, ...
                'max', 1, ...
                'description', '速度钳制因子 (相对于搜索范围)'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = VPPSO(configStruct)
            % VPPSO 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，可选字段:
            %     - swarm1Size: 第一种群大小 (默认: 15)
            %     - swarm2AddSize: 第二种群额外粒子 (默认: 15)
            %     - maxIterations: 最大迭代次数 (默认: 500)
            %     - wMax, wMin: 惯性权重范围 (默认: 0.9, 0.1)
            %     - c1, c2: 学习因子 (默认: 2, 2)
            %     - velocityPauseRate: 速度暂停概率 (默认: 0.3)
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
            obj.swarm1Size = obj.config.swarm1Size;
            obj.swarm2Size = obj.config.swarm2AddSize;
            obj.totalSize = obj.swarm1Size + obj.swarm2Size;
            MaxIter = obj.config.maxIterations;

            % 扩展边界为向量
            if isscalar(lb)
                lb = lb * ones(1, dim);
                ub = ub * ones(1, dim);
            end

            % 存储边界
            obj.problem.lb = lb;
            obj.problem.ub = ub;

            % 初始化速度限制
            obj.Vmax = obj.config.velocityClampFactor * (ub - lb);
            obj.Vmin = -obj.Vmax;

            % 初始化第一种群位置和速度
            obj.positions = zeros(obj.totalSize, dim);
            obj.velocities = zeros(obj.swarm1Size, dim);

            for i = 1:obj.swarm1Size
                obj.positions(i, :) = lb + (ub - lb) .* rand(1, dim);
                obj.velocities(i, :) = zeros(1, dim);
            end

            % 初始化第二种群位置 (将在迭代中动态更新)
            for i = (obj.swarm1Size + 1):obj.totalSize
                obj.positions(i, :) = lb + (ub - lb) .* rand(1, dim);
            end

            % 初始化个体最优和全局最优
            obj.pbestPositions = zeros(obj.swarm1Size, dim);
            obj.pbestFitness = Inf(obj.swarm1Size, 1);
            obj.gbestPosition = zeros(1, dim);
            obj.gbestFitness = Inf;

            % 评估第一种群并初始化个体最优
            for i = 1:obj.swarm1Size
                fitness = obj.evaluateSolution(obj.positions(i, :));
                obj.pbestPositions(i, :) = obj.positions(i, :);
                obj.pbestFitness(i) = fitness;

                if fitness < obj.gbestFitness
                    obj.gbestFitness = fitness;
                    obj.gbestPosition = obj.positions(i, :);
                end
            end

            % 评估第二种群
            for i = (obj.swarm1Size + 1):obj.totalSize
                fitness = obj.evaluateSolution(obj.positions(i, :));
                if fitness < obj.gbestFitness
                    obj.gbestFitness = fitness;
                    obj.gbestPosition = obj.positions(i, :);
                end
            end

            % 初始化全局最优
            obj.bestFitness = obj.gbestFitness;
            obj.bestSolution = obj.gbestPosition;

            % 预分配收敛曲线
            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代
            %
            % 包括第一种群速度暂停PSO更新、第二种群围绕最优搜索

            lb = obj.problem.lb;
            ub = obj.problem.ub;
            dim = size(obj.positions, 2);
            currentIter = obj.currentIteration + 1;
            MaxIter = obj.config.maxIterations;

            % 计算动态权重 (Eq. 12)
            ww = exp(-(2.5 * currentIter / MaxIter)^2.5);

            % 第一种群: 带速度暂停的PSO
            for i = 1:obj.swarm1Size
                if rand < obj.config.velocityPauseRate
                    % 速度暂停更新 (Eq. 13)
                    obj.velocities(i, :) = abs(obj.velocities(i, :)).^(rand * ww) + ...
                        rand * obj.config.c1 * (obj.pbestPositions(i, :) - obj.positions(i, :)) + ...
                        rand * obj.config.c2 * (obj.gbestPosition - obj.positions(i, :));
                end
                % 若不满足暂停概率，速度保持不变

                % 速度钳制
                velTooHigh = obj.velocities(i, :) > obj.Vmax;
                velTooLow = obj.velocities(i, :) < obj.Vmin;
                obj.velocities(i, velTooHigh) = obj.Vmax(velTooHigh);
                obj.velocities(i, velTooLow) = obj.Vmin(velTooLow);

                % 位置更新
                obj.positions(i, :) = obj.positions(i, :) + obj.velocities(i, :);

                % 边界检查
                posTooHigh = obj.positions(i, :) > ub;
                posTooLow = obj.positions(i, :) < lb;
                obj.positions(i, posTooHigh) = ub(posTooHigh);
                obj.positions(i, posTooLow) = lb(posTooLow);
            end

            % 第二种群: 围绕全局最优搜索
            for i = (obj.swarm1Size + 1):obj.totalSize
                for j = 1:dim
                    % Eq. 15
                    CC = ww * rand * abs(obj.gbestPosition(j))^ww;

                    if rand < 0.5
                        obj.positions(i, j) = obj.gbestPosition(j) + CC;
                    else
                        obj.positions(i, j) = obj.gbestPosition(j) - CC;
                    end
                end

                % 边界检查
                posTooHigh = obj.positions(i, :) > ub;
                posTooLow = obj.positions(i, :) < lb;
                obj.positions(i, posTooHigh) = ub(posTooHigh);
                obj.positions(i, posTooLow) = lb(posTooLow);
            end

            % 评估并更新最优
            for i = 1:obj.totalSize
                fitness = obj.evaluateSolution(obj.positions(i, :));

                if i <= obj.swarm1Size
                    % 第一种群: 更新个体最优和全局最优
                    if fitness < obj.pbestFitness(i)
                        obj.pbestPositions(i, :) = obj.positions(i, :);
                        obj.pbestFitness(i) = fitness;

                        if fitness < obj.gbestFitness
                            obj.gbestFitness = fitness;
                            obj.gbestPosition = obj.positions(i, :);
                        end
                    end
                else
                    % 第二种群: 仅更新全局最优
                    if fitness < obj.gbestFitness
                        obj.gbestFitness = fitness;
                        obj.gbestPosition = obj.positions(i, :);
                    end
                end
            end

            % 更新全局最优
            if obj.gbestFitness < obj.bestFitness
                obj.bestFitness = obj.gbestFitness;
                obj.bestSolution = obj.gbestPosition;
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

            validatedConfig = struct();

            % 第一种群大小
            if isfield(config, 'swarm1Size')
                validatedConfig.swarm1Size = config.swarm1Size;
            else
                validatedConfig.swarm1Size = 15;
            end

            if validatedConfig.swarm1Size < 5
                error('VPPSO:InvalidConfig', 'swarm1Size must be >= 5');
            end

            % 第二种群额外粒子数
            if isfield(config, 'swarm2AddSize')
                validatedConfig.swarm2AddSize = config.swarm2AddSize;
            else
                validatedConfig.swarm2AddSize = 15;
            end

            if validatedConfig.swarm2AddSize < 0
                error('VPPSO:InvalidConfig', 'swarm2AddSize must be >= 0');
            end

            % 最大迭代次数
            if isfield(config, 'maxIterations')
                validatedConfig.maxIterations = config.maxIterations;
            else
                validatedConfig.maxIterations = 500;
            end

            if validatedConfig.maxIterations < 1
                error('VPPSO:InvalidConfig', 'maxIterations must be >= 1');
            end

            % 惯性权重
            if isfield(config, 'wMax')
                validatedConfig.wMax = config.wMax;
            else
                validatedConfig.wMax = 0.9;
            end

            if isfield(config, 'wMin')
                validatedConfig.wMin = config.wMin;
            else
                validatedConfig.wMin = 0.1;
            end

            % 学习因子
            if isfield(config, 'c1')
                validatedConfig.c1 = config.c1;
            else
                validatedConfig.c1 = 2;
            end

            if isfield(config, 'c2')
                validatedConfig.c2 = config.c2;
            else
                validatedConfig.c2 = 2;
            end

            % 速度暂停概率
            if isfield(config, 'velocityPauseRate')
                validatedConfig.velocityPauseRate = config.velocityPauseRate;
            else
                validatedConfig.velocityPauseRate = 0.3;
            end

            if validatedConfig.velocityPauseRate < 0 || validatedConfig.velocityPauseRate > 1
                error('VPPSO:InvalidConfig', 'velocityPauseRate must be in [0, 1]');
            end

            % 速度钳制因子
            if isfield(config, 'velocityClampFactor')
                validatedConfig.velocityClampFactor = config.velocityClampFactor;
            else
                validatedConfig.velocityClampFactor = 0.1;
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
            % register 将VPPSO算法注册到算法注册表
            %
            % 示例:
            %   VPPSO.register();
            %   algClass = AlgorithmRegistry.getAlgorithm('VPPSO');

            AlgorithmRegistry.register('VPPSO', '2.0.0', @VPPSO);
        end
    end
end
