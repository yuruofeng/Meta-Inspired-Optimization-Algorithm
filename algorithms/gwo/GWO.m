classdef GWO < BaseAlgorithm
    % GWO 灰狼优化器 (Grey Wolf Optimizer)
    %
    % 一种模拟灰狼社会等级和狩猎行为的元启发式算法。通过Alpha、Beta、Delta
    % 三层领导机制引导种群搜索，模拟包围、追捕和攻击猎物过程。
    %
    % 参考文献:
    %   S. Mirjalili, S. M. Mirjalili, A. Lewis
    %   "Grey Wolf Optimizer"
    %   Advances in Engineering Software, 2014
    %   DOI: 10.1016/j.advengsoft.2013.12.007
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   gwo = GWO(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = gwo.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Seyedali Mirjalili
    % 重构版本: 2.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 种群位置矩阵 (N x Dim)
        alphaPosition        % Alpha狼位置 (最优, 1 x Dim)
        alphaFitness         % Alpha狼适应度
        betaPosition         % Beta狼位置 (次优, 1 x Dim)
        betaFitness          % Beta狼适应度
        deltaPosition        % Delta狼位置 (第三优, 1 x Dim)
        deltaFitness         % Delta狼适应度
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 10, ...
                'max', 10000, ...
                'description', '灰狼种群个体数量'), ...
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
        function obj = GWO(configStruct)
            % GWO 构造函数
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

            % 获取问题参数
            lb = problem.lb;
            ub = problem.ub;
            dim = problem.dim;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;

            % 初始化种群
            obj.positions = Initialization(N, dim, ub, lb);

            % 初始化Alpha, Beta, Delta
            obj.alphaPosition = zeros(1, dim);
            obj.alphaFitness = Inf;
            obj.betaPosition = zeros(1, dim);
            obj.betaFitness = Inf;
            obj.deltaPosition = zeros(1, dim);
            obj.deltaFitness = Inf;

            % 初始评估和排序
            fitness = obj.evaluatePopulation(obj.positions);

            % 更新Alpha, Beta, Delta
            [sortedFitness, sortedIndices] = sort(fitness);
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
            %
            % 包括评估适应度、更新Alpha/Beta/Delta、位置更新

            lb = obj.problem.lb;
            ub = obj.problem.ub;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;
            currentIter = obj.currentIteration + 1;

            % 边界检查并评估适应度
            for i = 1:N
                % 边界约束
                flagUb = obj.positions(i, :) > ub;
                flagLb = obj.positions(i, :) < lb;
                obj.positions(i, :) = obj.positions(i, :) .* ~(flagUb | flagLb) + ...
                    ub .* flagUb + lb .* flagLb;

                % 评估适应度
                fitness = obj.evaluateSolution(obj.positions(i, :));

                % 更新Alpha, Beta, Delta
                if fitness < obj.alphaFitness
                    % 更新Delta为旧Beta
                    obj.deltaFitness = obj.betaFitness;
                    obj.deltaPosition = obj.betaPosition;
                    % 更新Beta为旧Alpha
                    obj.betaFitness = obj.alphaFitness;
                    obj.betaPosition = obj.alphaPosition;
                    % 更新Alpha
                    obj.alphaFitness = fitness;
                    obj.alphaPosition = obj.positions(i, :);
                elseif fitness > obj.alphaFitness && fitness < obj.betaFitness
                    % 更新Delta为旧Beta
                    obj.deltaFitness = obj.betaFitness;
                    obj.deltaPosition = obj.betaPosition;
                    % 更新Beta
                    obj.betaFitness = fitness;
                    obj.betaPosition = obj.positions(i, :);
                elseif fitness > obj.alphaFitness && fitness > obj.betaFitness && ...
                       fitness < obj.deltaFitness
                    % 更新Delta
                    obj.deltaFitness = fitness;
                    obj.deltaPosition = obj.positions(i, :);
                end
            end

            % 计算衰减参数 a (从2线性递减到0)
            a = 2 - currentIter * (2 / MaxIter);

            % 更新所有个体位置
            for i = 1:N
                for j = 1:size(obj.positions, 2)
                    % Alpha引导 (Equation 3.3-3.6)
                    [X1, ~] = obj.calculatePositionUpdate(...
                        obj.alphaPosition(j), obj.positions(i, j), a);

                    % Beta引导
                    [X2, ~] = obj.calculatePositionUpdate(...
                        obj.betaPosition(j), obj.positions(i, j), a);

                    % Delta引导
                    [X3, ~] = obj.calculatePositionUpdate(...
                        obj.deltaPosition(j), obj.positions(i, j), a);

                    % 平均位置 (Equation 3.7)
                    obj.positions(i, j) = (X1 + X2 + X3) / 3;
                end
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

            validatedConfig = struct();

            % 种群大小
            if isfield(config, 'populationSize')
                validatedConfig.populationSize = config.populationSize;
            else
                validatedConfig.populationSize = 30;
            end

            if validatedConfig.populationSize < 10
                error('GWO:InvalidConfig', 'populationSize must be >= 10');
            end

            % 最大迭代次数
            if isfield(config, 'maxIterations')
                validatedConfig.maxIterations = config.maxIterations;
            else
                validatedConfig.maxIterations = 500;
            end

            if validatedConfig.maxIterations < 1
                error('GWO:InvalidConfig', 'maxIterations must be >= 1');
            end

            % 详细输出
            if isfield(config, 'verbose')
                validatedConfig.verbose = config.verbose;
            else
                validatedConfig.verbose = true;
            end
        end
    end

    methods (Access = protected)
        function [newPos, D] = calculatePositionUpdate(obj, leaderPos, currentPos, a)
            % calculatePositionUpdate 计算位置更新 (辅助函数)
            %
            % 输入参数:
            %   leaderPos - 领导者位置 (Alpha/Beta/Delta)
            %   currentPos - 当前个体位置
            %   a - 衰减参数
            %
            % 输出参数:
            %   newPos - 更新后的位置
            %   D - 距离向量
            %
            % 参考: Equation 3.3-3.6 in the paper

            r1 = rand();
            r2 = rand();

            A = 2 * a * r1 - a;       % Equation 3.3
            C = 2 * r2;               % Equation 3.4

            D = abs(C * leaderPos - currentPos);  % Equation 3.5
            newPos = leaderPos - A * D;           % Equation 3.6
        end
    end

    methods (Static)
        function register()
            % register 将GWO算法注册到算法注册表
            %
            % 示例:
            %   GWO.register();
            %   algClass = AlgorithmRegistry.getAlgorithm('GWO');

            AlgorithmRegistry.register('GWO', '2.0.0', @GWO);
        end
    end
end
