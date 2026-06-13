classdef MFO < BaseAlgorithm
    % MFO 飞蛾火焰优化算法 (Moth-Flame Optimization Algorithm)
    %
    % 一种模拟飞蛾横向导航行为的元启发式算法。飞蛾利用月光进行横向导航，
    % 通过维持与光源的固定角度来直线飞行。MFO算法模拟这种机制，
    % 飞蛾围绕火焰（最优解）以螺旋方式移动，实现全局搜索和局部开发。
    %
    % 算法特点:
    %   - 火焰数量自适应递减机制，平衡全局搜索和局部开发
    %   - 对数螺旋移动模式，实现围绕火焰的搜索
    %   - 双阶段更新策略（对应火焰更新 vs 单个火焰更新）
    %
    % 参考文献:
    %   S. Mirjalili, "Moth-Flame Optimization Algorithm: A Novel Nature-inspired Heuristic Paradigm"
    %   Knowledge-Based Systems, 2015
    %   DOI: http://dx.doi.org/10.1016/j.knosys.2015.07.006
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   mfo = MFO(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = mfo.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Seyedali Mirjalili
    % 重构版本: 2.0.0
    % 日期: 2026

    properties (Access = protected)
        mothPositions           % 飞蛾位置矩阵 (N x Dim)
        flamePositions          % 火焰位置矩阵 (N x Dim)
        flameFitness            % 火焰适应度 (1 x N)
        previousMothPositions   % 前一代飞蛾位置
        previousMothFitness     % 前一代飞蛾适应度
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 10, ...
                'max', 10000, ...
                'description', '飞蛾种群个体数量'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 500, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'b', struct(...
                'type', 'double', ...
                'default', 1, ...
                'min', 0, ...
                'max', 10, ...
                'description', '对数螺旋形状常数'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = MFO(configStruct)
            % MFO 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，可选字段:
            %     - populationSize: 种群大小 (默认: 30)
            %     - maxIterations: 最大迭代次数 (默认: 500)
            %     - b: 螺旋形状常数 (默认: 1)
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
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;

            % 初始化飞蛾位置
            obj.mothPositions = Initialization(N, dim, ub, lb);

            % 评估初始飞蛾适应度
            mothFitness = obj.evaluatePopulation(obj.mothPositions);

            % 排序飞蛾以初始化火焰
            [sortedFitness, sortedIndices] = sort(mothFitness);
            obj.flamePositions = obj.mothPositions(sortedIndices, :);
            obj.flameFitness = sortedFitness;

            % 初始化前一代数据
            obj.previousMothPositions = obj.mothPositions;
            obj.previousMothFitness = mothFitness;

            % 初始化全局最优
            obj.bestFitness = sortedFitness(1);
            obj.bestSolution = obj.flamePositions(1, :);

            % 预分配收敛曲线
            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代
            %
            % 包括适应度评估、火焰更新、螺旋位置更新

            lb = obj.problem.lb;
            ub = obj.problem.ub;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;
            currentIter = obj.currentIteration + 1;

            % 计算当前火焰数量 (Equation 3.14)
            flameNo = round(N - currentIter * ((N - 1) / MaxIter));

            for i = 1:N
                obj.mothPositions(i, :) = obj.clampToBounds(obj.mothPositions(i, :), lb, ub);
                mothFitness(i) = obj.evaluateSolution(obj.mothPositions(i, :));
            end

            % 更新火焰（合并当前飞蛾和前一代火焰）
            if currentIter == 1
                % 第一次迭代：仅排序飞蛾
                [sortedFitness, sortedIndices] = sort(mothFitness);
                obj.flamePositions = obj.mothPositions(sortedIndices, :);
                obj.flameFitness = sortedFitness;
            else
                % 合并前一代火焰和当前飞蛾
                doublePopulation = [obj.previousMothPositions; obj.flamePositions];
                doubleFitness = [obj.previousMothFitness, obj.flameFitness];

                [sortedFitness, sortedIndices] = sort(doubleFitness);
                sortedPopulation = doublePopulation(sortedIndices, :);

                % 选择前N个作为新火焰
                obj.flameFitness = sortedFitness(1:N);
                obj.flamePositions = sortedPopulation(1:N, :);
            end

            % 更新全局最优
            if obj.flameFitness(1) < obj.bestFitness
                obj.bestFitness = obj.flameFitness(1);
                obj.bestSolution = obj.flamePositions(1, :);
            end

            % 保存当前飞蛾数据供下一代使用
            obj.previousMothPositions = obj.mothPositions;
            obj.previousMothFitness = mothFitness;

            % 计算螺旋参数 a (从-1线性递减到-2)
            a = -1 + currentIter * ((-1) / MaxIter);

            % 更新飞蛾位置
            b = obj.config.b;
            for i = 1:N
                for j = 1:size(obj.mothPositions, 2)
                    if i <= flameNo
                        % 阶段1: 飞蛾围绕对应的火焰移动 (Equation 3.12, 3.13)
                        distanceToFlame = abs(obj.flamePositions(i, j) - obj.mothPositions(i, j));
                        t = (a - 1) * rand + 1;

                        % 对数螺旋更新
                        obj.mothPositions(i, j) = distanceToFlame * exp(b * t) * cos(t * 2 * pi) + ...
                            obj.flamePositions(i, j);
                    else
                        % 阶段2: 飞蛾围绕最后一个火焰移动
                        distanceToFlame = abs(obj.flamePositions(i, j) - obj.mothPositions(i, j));
                        t = (a - 1) * rand + 1;

                        % 对数螺旋更新
                        obj.mothPositions(i, j) = distanceToFlame * exp(b * t) * cos(t * 2 * pi) + ...
                            obj.flamePositions(flameNo, j);
                    end
                end
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
            %
            % 输入参数:
            %   config - 原始配置结构体
            %
            % 输出参数:
            %   validatedConfig - 验证后的配置结构体

            validatedConfig = BaseAlgorithm.validateFromSchema(config, obj.PARAM_SCHEMA);
        end
    end

    methods (Static)
        function register()
            % register 将MFO算法注册到算法注册表
            %
            % 示例:
            %   MFO.register();
            %   algClass = AlgorithmRegistry.getAlgorithm('MFO');

            AlgorithmRegistry.register('MFO', '2.0.0', @MFO);
        end
    end
end
