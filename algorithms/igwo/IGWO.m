classdef IGWO < BaseAlgorithm
    % IGWO 改进灰狼优化器 (Improved Grey Wolf Optimizer)
    %
    % 在标准GWO基础上引入距离学习启发式搜索(DLH)机制和个人最优记忆，
    % 提高收敛速度和全局搜索能力。
    %
    % 参考文献:
    %   M. H. Nadimi-Shahraki, S. Taghian, S. Mirjalili
    %   "An Improved Grey Wolf Optimizer for Solving Engineering Problems"
    %   Expert Systems with Applications, 2021
    %   DOI: 10.1016/j.eswa.2020.113917
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   igwo = IGWO(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = igwo.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: M. H. Nadimi-Shahraki, S. Taghian, S. Mirjalili
    % 重构版本: 2.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 种群位置矩阵 (N x Dim)
        pBestPositions       % 个人最优位置 (N x Dim)
        pBestFitness         % 个人最优适应度 (1 x N)
        alphaPosition        % Alpha狼位置
        alphaFitness         % Alpha狼适应度
        betaPosition         % Beta狼位置
        betaFitness          % Beta狼适应度
        deltaPosition        % Delta狼位置
        deltaFitness         % Delta狼适应度
        boundConstrainer     % 边界约束器
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 10, ...
                'max', 10000, ...
                'description', '种群个体数量'), ...
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
        function obj = IGWO(configStruct)
            % IGWO 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，可选字段:
            %     - populationSize: 种群个体数量 (默认: 30)
            %     - maxIterations: 最大迭代次数 (默认: 500)
            %     - verbose: 是否显示进度 (默认: true)

            if nargin < 1 || isempty(configStruct)
                configStruct = struct();
            end

            obj = obj@BaseAlgorithm(configStruct);
            obj.boundConstrainer = BoundConstraint();
        end

        function initialize(obj, problem)
            % initialize 初始化种群

            lb = problem.lb;
            ub = problem.ub;
            dim = problem.dim;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;

            % 初始化种群
            obj.positions = Initialization(N, dim, ub, lb);

            % 初始化个人最优
            obj.pBestPositions = obj.positions;
            obj.pBestFitness = obj.evaluatePopulation(obj.positions);

            % 初始化Alpha, Beta, Delta
            [sortedFitness, sortedIndices] = sort(obj.pBestFitness);
            obj.alphaFitness = sortedFitness(1);
            obj.alphaPosition = obj.positions(sortedIndices(1), :);
            obj.betaFitness = sortedFitness(2);
            obj.betaPosition = obj.positions(sortedIndices(2), :);
            obj.deltaFitness = sortedFitness(3);
            obj.deltaPosition = obj.positions(sortedIndices(3), :);

            % 初始化全局最优
            obj.bestFitness = obj.alphaFitness;
            obj.bestSolution = obj.alphaPosition;

            % 预分配收敛曲线
            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代

            lb = obj.problem.lb;
            ub = obj.problem.ub;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;
            dim = obj.problem.dim;
            currentIter = obj.currentIteration + 1;

            % 计算衰减参数 a
            a = 2 - currentIter * (2 / MaxIter);

            % 准备边界矩阵
            if numel(lb) == 1
                lu = [repmat(lb, 1, dim); repmat(ub, 1, dim)];
            else
                lu = [lb; ub];
            end

            % 更新每个个体
            for i = 1:N
                % 计算X_GWO (传统GWO位置更新)
                X_GWO = obj.calculateGWOUpdate(obj.positions(i, :), a);

                % 计算X_DLH (距离学习启发式)
                X_DLH = obj.calculateDLHUpdate(i);

                % 评估两个候选解
                % 先应用边界约束
                X_GWO_constrained = X_GWO;
                X_DLH_constrained = X_DLH;

                temp_GWO = obj.positions;
                temp_DLH = obj.positions;
                temp_GWO(i, :) = X_GWO;
                temp_DLH(i, :) = X_DLH;

                temp_GWO(i, :) = obj.boundConstrainer.apply(temp_GWO(i, :), ...
                    obj.positions(i, :), lu);
                temp_DLH(i, :) = obj.boundConstrainer.apply(temp_DLH(i, :), ...
                    obj.positions(i, :), lu);

                fitness_GWO = obj.problem.evaluate(temp_GWO(i, :));
                fitness_DLH = obj.problem.evaluate(temp_DLH(i, :));
                obj.totalEvaluations = obj.totalEvaluations + 2;

                % 选择更优的解
                if fitness_GWO < fitness_DLH
                    obj.positions(i, :) = temp_GWO(i, :);
                    tempFitness = fitness_GWO;
                else
                    obj.positions(i, :) = temp_DLH(i, :);
                    tempFitness = fitness_DLH;
                end

                % 更新个人最优
                if tempFitness < obj.pBestFitness(i)
                    obj.pBestFitness(i) = tempFitness;
                    obj.pBestPositions(i, :) = obj.positions(i, :);
                end
            end

            % 更新Alpha, Beta, Delta
            [sortedFitness, sortedIndices] = sort(obj.pBestFitness);
            if sortedFitness(1) < obj.alphaFitness
                obj.deltaFitness = obj.betaFitness;
                obj.deltaPosition = obj.betaPosition;
                obj.betaFitness = obj.alphaFitness;
                obj.betaPosition = obj.alphaPosition;
                obj.alphaFitness = sortedFitness(1);
                obj.alphaPosition = obj.pBestPositions(sortedIndices(1), :);
            end
            if sortedFitness(2) < obj.betaFitness
                obj.deltaFitness = obj.betaFitness;
                obj.deltaPosition = obj.betaPosition;
                obj.betaFitness = sortedFitness(2);
                obj.betaPosition = obj.pBestPositions(sortedIndices(2), :);
            end
            if sortedFitness(3) < obj.deltaFitness
                obj.deltaFitness = sortedFitness(3);
                obj.deltaPosition = obj.pBestPositions(sortedIndices(3), :);
            end

            % 更新全局最优
            if obj.alphaFitness < obj.bestFitness
                obj.bestFitness = obj.alphaFitness;
                obj.bestSolution = obj.alphaPosition;
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

            tf = obj.currentIteration >= obj.config.maxIterations;
        end

        function validatedConfig = validateConfig(obj, config)
            % validateConfig 验证并规范化配置参数

            validatedConfig = struct();

            if isfield(config, 'populationSize')
                validatedConfig.populationSize = config.populationSize;
            else
                validatedConfig.populationSize = 30;
            end

            if validatedConfig.populationSize < 10
                error('IGWO:InvalidConfig', 'populationSize must be >= 10');
            end

            if isfield(config, 'maxIterations')
                validatedConfig.maxIterations = config.maxIterations;
            else
                validatedConfig.maxIterations = 500;
            end

            if validatedConfig.maxIterations < 1
                error('IGWO:InvalidConfig', 'maxIterations must be >= 1');
            end

            if isfield(config, 'verbose')
                validatedConfig.verbose = config.verbose;
            else
                validatedConfig.verbose = true;
            end
        end
    end

    methods (Access = protected)
        function X_GWO = calculateGWOUpdate(obj, currentPos, a)
            % calculateGWOUpdate 计算GWO位置更新
            %
            % 输入参数:
            %   currentPos - 当前位置 (1 x Dim)
            %   a - 衰减参数
            %
            % 输出参数:
            %   X_GWO - 更新后的位置

            dim = length(currentPos);
            X_GWO = zeros(1, dim);

            for j = 1:dim
                r1 = rand(); r2 = rand();
                A1 = 2 * a * r1 - a;
                C1 = 2 * r2;
                D_alpha = abs(C1 * obj.alphaPosition(j) - currentPos(j));
                X1 = obj.alphaPosition(j) - A1 * D_alpha;

                r1 = rand(); r2 = rand();
                A2 = 2 * a * r1 - a;
                C2 = 2 * r2;
                D_beta = abs(C2 * obj.betaPosition(j) - currentPos(j));
                X2 = obj.betaPosition(j) - A2 * D_beta;

                r1 = rand(); r2 = rand();
                A3 = 2 * a * r1 - a;
                C3 = 2 * r2;
                D_delta = abs(C3 * obj.deltaPosition(j) - currentPos(j));
                X3 = obj.deltaPosition(j) - A3 * D_delta;

                X_GWO(j) = (X1 + X2 + X3) / 3;
            end
        end

        function X_DLH = calculateDLHUpdate(obj, currentIndex)
            % calculateDLHUpdate 计算距离学习启发式更新
            %
            % 输入参数:
            %   currentIndex - 当前个体索引
            %
            % 输出参数:
            %   X_DLH - 基于DLH的位置更新
            %
            % 算法:
            %   基于欧氏距离选择邻域个体，进行局部搜索

            N = obj.config.populationSize;
            dim = obj.problem.dim;
            X_DLH = zeros(1, dim);

            % 计算到所有其他个体的距离
            distances = zeros(1, N);
            for i = 1:N
                if i ~= currentIndex
                    distances(i) = norm(obj.positions(i, :) - obj.positions(currentIndex, :));
                else
                    distances(i) = Inf;
                end
            end

            % 找到最近的邻域个体
            [~, sortedIndices] = sort(distances);
            neighborIdx = sortedIndices(1);

            % 随机选择一个其他个体
            randomIdx = randi(N);
            while randomIdx == currentIndex
                randomIdx = randi(N);
            end

            % DLH更新 (Equation 12 in paper)
            for d = 1:dim
                X_DLH(d) = obj.positions(currentIndex, d) + rand() * ...
                    (obj.positions(neighborIdx, d) - obj.positions(randomIdx, d));
            end
        end
    end

    methods (Static)
        function register()
            % register 将IGWO算法注册到算法注册表
            %
            % 示例:
            %   IGWO.register();
            %   algClass = AlgorithmRegistry.getAlgorithm('IGWO');

            AlgorithmRegistry.register('IGWO', '2.0.0', @IGWO);
        end
    end
end
