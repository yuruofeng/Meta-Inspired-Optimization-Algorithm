classdef HHO < BaseAlgorithm
    % HHO 哈里斯鹰优化算法 (Harris Hawks Optimization)
    %
    % 一种模拟哈里斯鹰协作捕食行为的元启发式算法。通过多种攻击
    % 策略（软围攻、硬围攻、渐进式俯冲等）实现探索与开发的平衡。
    %
    % 算法阶段:
    %   1. 探索阶段: 随机搜索或基于全局最优搜索
    %   2. 探索到开发过渡: 基于逃逸能量E
    %   3. 开发阶段:
    %      - 软围攻 (|E| >= 0.5, r >= 0.5)
    %      - 硬围攻 (|E| < 0.5, r >= 0.5)
    %      - 渐进式软俯冲 (|E| >= 0.5, r < 0.5)
    %      - 渐进式硬俯冲 (|E| < 0.5, r < 0.5)
    %
    % 参考文献:
    %   A.A. Heidari, S. Mirjalili, H. Faris, I. Aljarah, M. Mafarja, H. Chen
    %   "Harris hawks optimization: Algorithm and applications"
    %   Future Generation Computer Systems, 2019
    %   DOI: 10.1016/j.future.2019.02.028
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   hho = HHO(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = hho.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Ali Asghar Heidari
    % 实现版本: 1.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 种群位置矩阵 (N x Dim)
        rabbitPosition       % 兔子位置 (最优解, 1 x Dim)
        rabbitFitness        % 兔子适应度
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 5, ...
                'max', 10000, ...
                'description', '鹰群种群大小'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 500, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = HHO(configStruct)
            % HHO 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，可选字段:
            %     - populationSize: 种群大小 (默认: 30)
            %     - maxIterations: 最大迭代次数 (默认: 500)
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

            obj.rabbitPosition = zeros(1, dim);
            obj.rabbitFitness = Inf;

            fitness = obj.evaluatePopulation(obj.positions);
            [obj.rabbitFitness, bestIdx] = min(fitness);
            obj.rabbitPosition = obj.positions(bestIdx, :);

            obj.bestFitness = obj.rabbitFitness;
            obj.bestSolution = obj.rabbitPosition;

            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代
            %
            % 包括探索阶段和开发阶段的多种攻击策略

            lb = obj.problem.lb;
            ub = obj.problem.ub;
            dim = obj.problem.dim;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;
            t = obj.currentIteration + 1;

            for i = 1:N
                obj.positions(i, :) = obj.clampToBounds(obj.positions(i, :), lb, ub);

                fitness = obj.evaluateSolution(obj.positions(i, :));
                if fitness < obj.rabbitFitness
                    obj.rabbitFitness = fitness;
                    obj.rabbitPosition = obj.positions(i, :);
                end
            end

            E0 = 2 * rand() - 1;
            E = 2 * E0 * (1 - t / MaxIter);

            for i = 1:N
                if abs(E) >= 1
                    obj.positions(i, :) = obj.explorationPhase(i, N, dim, lb, ub);
                else
                    if rand() >= 0.5
                        if abs(E) >= 0.5
                            obj.positions(i, :) = obj.softBesiege(i, dim, E);
                        else
                            obj.positions(i, :) = obj.hardBesiege(i, dim, E);
                        end
                    else
                        if abs(E) >= 0.5
                            obj.positions(i, :) = obj.softBesiegeWithDive(i, dim, E, lb, ub);
                        else
                            obj.positions(i, :) = obj.hardBesiegeWithDive(i, N, dim, E, lb, ub);
                        end
                    end
                end
            end

            obj.bestFitness = obj.rabbitFitness;
            obj.bestSolution = obj.rabbitPosition;
        end

        function tf = shouldStop(obj)
            % shouldStop 判断是否应该停止迭代
            %
            % 输出参数:
            %   tf - true表示停止，false表示继续

            tf = obj.currentIteration >= obj.config.maxIterations;
        end
    end

    methods (Access = protected)
        function newPos = explorationPhase(obj, i, N, dim, lb, ub)
            % explorationPhase 探索阶段
            %
            % 输入参数:
            %   i - 当前个体索引
            %   N - 种群大小
            %   dim - 问题维度
            %   lb - 下界
            %   ub - 上界
            %
            % 输出参数:
            %   newPos - 新位置

            q = rand();
            rIdx = randi(N);
            while rIdx == i
                rIdx = randi(N);
            end

            if q < 0.5
                newPos = obj.rabbitPosition - ...
                         rand(1, dim) .* abs(obj.rabbitPosition - obj.positions(rIdx, :));
            else
                Xmean = mean(obj.positions, 1);
                newPos = (Xmean - obj.rabbitPosition) - ...
                         rand(1, dim) .* (lb + rand(1, dim) .* (ub - lb));
            end
        end

        function newPos = softBesiege(obj, i, dim, E)
            % softBesiege 软围攻
            %
            % 输入参数:
            %   i - 当前个体索引
            %   dim - 问题维度
            %   E - 逃逸能量
            %
            % 输出参数:
            %   newPos - 新位置

            J = 2 * (1 - rand());
            delta = obj.rabbitPosition - obj.positions(i, :);
            newPos = delta - E .* abs(J .* obj.rabbitPosition - obj.positions(i, :));
        end

        function newPos = hardBesiege(obj, i, dim, E)
            % hardBesiege 硬围攻
            %
            % 输入参数:
            %   i - 当前个体索引
            %   dim - 问题维度
            %   E - 逃逸能量
            %
            % 输出参数:
            %   newPos - 新位置

            delta = obj.rabbitPosition - obj.positions(i, :);
            newPos = obj.rabbitPosition - E .* abs(delta);
        end

        function newPos = softBesiegeWithDive(obj, i, dim, E, lb, ub)
            % softBesiegeWithDive 渐进式软俯冲
            %
            % 输入参数:
            %   i - 当前个体索引
            %   dim - 问题维度
            %   E - 逃逸能量
            %   lb - 下界
            %   ub - 上界
            %
            % 输出参数:
            %   newPos - 新位置

            J = 2 * (1 - rand());

            Y = obj.rabbitPosition - E .* abs(J .* obj.rabbitPosition - obj.positions(i, :));

            Z = Y + rand(1, dim) .* obj.levyFlight(dim);

            posY = obj.problem.evaluate(Y);
            posZ = obj.problem.evaluate(Z);
            obj.totalEvaluations = obj.totalEvaluations + 2;

            currentFitness = obj.problem.evaluate(obj.positions(i, :));
            obj.totalEvaluations = obj.totalEvaluations + 1;

            if posY < currentFitness
                newPos = Y;
            elseif posZ < currentFitness
                newPos = Z;
            else
                newPos = obj.positions(i, :);
            end
        end

        function newPos = hardBesiegeWithDive(obj, i, N, dim, E, lb, ub)
            % hardBesiegeWithDive 渐进式硬俯冲
            %
            % 输入参数:
            %   i - 当前个体索引
            %   N - 种群大小
            %   dim - 问题维度
            %   E - 逃逸能量
            %   lb - 下界
            %   ub - 上界
            %
            % 输出参数:
            %   newPos - 新位置

            J = 2 * (1 - rand());

            Xmean = mean(obj.positions, 1);
            Y = obj.rabbitPosition - E .* abs(J .* obj.rabbitPosition - Xmean);

            Z = Y + rand(1, dim) .* obj.levyFlight(dim);

            posY = obj.problem.evaluate(Y);
            posZ = obj.problem.evaluate(Z);
            obj.totalEvaluations = obj.totalEvaluations + 2;

            currentFitness = obj.problem.evaluate(obj.positions(i, :));
            obj.totalEvaluations = obj.totalEvaluations + 1;

            if posY < currentFitness
                newPos = Y;
            elseif posZ < currentFitness
                newPos = Z;
            else
                newPos = obj.positions(i, :);
            end
        end

        function steps = levyFlight(obj, dim)
            % levyFlight Levy飞行步长
            %
            % 输入参数:
            %   dim - 问题维度
            %
            % 输出参数:
            %   steps - Levy步长向量

            beta = 1.5;
            sigma = (gamma(1 + beta) * sin(pi * beta / 2) / ...
                     (gamma((1 + beta) / 2) * beta * 2^((beta - 1) / 2)))^(1 / beta);

            u = randn(1, dim) * sigma;
            v = randn(1, dim);
            steps = u ./ (abs(v).^(1 / beta));
        end

        function validatedConfig = validateConfig(obj, configStruct)
            % validateConfig 验证并规范化配置参数
            %
            % 输入参数:
            %   configStruct - 原始配置结构体
            %
            % 输出参数:
            %   validatedConfig - 验证后的配置结构体

            validatedConfig = struct();
            
            fields = fieldnames(obj.PARAM_SCHEMA);
            for i = 1:length(fields)
                field = fields{i};
                schema = obj.PARAM_SCHEMA.(field);
                
                if isfield(configStruct, field)
                    validatedConfig.(field) = configStruct.(field);
                else
                    validatedConfig.(field) = schema.default;
                end
            end
        end
    end

    methods (Static)
        function register()
            % register 注册算法到算法注册表
            %
            % 调用此方法后可通过 AlgorithmRegistry.getAlgorithm('HHO') 获取

            AlgorithmRegistry.register('HHO', @HHO);
        end
    end
end
