classdef DBO < BaseAlgorithm
    % DBO 蜣螂优化算法 (Dung Beetle Optimizer)
    %
    % 一种模拟蜣螂滚球、跳舞、觅食、偷窃和繁殖行为的2022年新算法，
    % 具有优秀的探索与开发能力平衡。
    %
    % 算法阶段:
    %   1. 滚球行为: 在搜索空间中随机探索
    %   2. 舞蹈行为: 利用天体定位辅助导航
    %   3. 觅食行为: 在优质食物源附近搜索
    %   4. 繁殖行为: 在安全地点产卵
    %   5. 偷窃行为: 抢占他人的粪球
    %
    % 参考文献:
    %   J. Xue, B. Shen
    %   "Dung beetle optimizer: A new meta-heuristic algorithm for global optimization"
    %   The Journal of Supercomputing, 2022
    %   DOI: 10.1007/s11227-022-04959-6
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   dbo = DBO(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = dbo.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Jiankai Xue, Bo Shen
    % 实现版本: 1.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 种群位置矩阵 (N x Dim)
        fitness              % 适应度向量 (N x 1)
        bestPosition         % 最优位置 (1 x Dim)
        bestFitness          % 最优适应度
        Xworst               % 最差位置 (1 x Dim)
        worstFitness         % 最差适应度
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 5, ...
                'max', 10000, ...
                'description', '蜣螂种群大小'), ...
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
        function obj = DBO(configStruct)
            if nargin < 1 || isempty(configStruct)
                configStruct = struct();
            end
            obj = obj@BaseAlgorithm(configStruct);
        end

        function initialize(obj, problem)
            lb = problem.lb;
            ub = problem.ub;
            dim = problem.dim;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;

            obj.positions = Initialization(N, dim, ub, lb);
            obj.fitness = obj.evaluatePopulation(obj.positions);

            [obj.bestFitness, bestIdx] = min(obj.fitness);
            obj.bestPosition = obj.positions(bestIdx, :);

            [obj.worstFitness, worstIdx] = max(obj.fitness);
            obj.Xworst = obj.positions(worstIdx, :);

            obj.bestSolution = obj.bestPosition;
            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            lb = obj.problem.lb;
            ub = problem.ub;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;
            t = obj.currentIteration + 1;

            for i = 1:N
                if rand() < 0.8
                    alpha = 1 - t / MaxIter;
                    if rand() > 0.5
                        deltaX = abs(obj.positions(i, :) - obj.bestPosition);
                        b = 0.3;
                        k = 0.1;
                        obj.positions(i, :) = obj.bestPosition + ...
                            b * obj.positions(i, :) + ...
                            alpha * (randn() * deltaX - ...
                            k * obj.positions(i, :) .* tan(rand()));
                    else
                        theta = rand() * 2 * pi;
                        obj.positions(i, :) = obj.bestPosition + ...
                            tan(theta) .* abs(obj.positions(i, :) - obj.bestPosition);
                    end
                else
                    theta = rand() * 2 * pi;
                    obj.positions(i, :) = obj.positions(i, :) + ...
                        tan(theta) .* abs(obj.positions(i, :) - obj.bestPosition);
                end

                obj.positions(i, :) = obj.clampToBounds(obj.positions(i, :), lb, ub);
            end

            newFitness = obj.evaluatePopulation(obj.positions);

            for i = 1:N
                if newFitness(i) < obj.fitness(i)
                    obj.fitness(i) = newFitness(i);

                    if newFitness(i) < obj.bestFitness
                        obj.bestFitness = newFitness(i);
                        obj.bestPosition = obj.positions(i, :);
                    end
                else
                    if newFitness(i) > obj.worstFitness
                        obj.worstFitness = newFitness(i);
                        obj.Xworst = obj.positions(i, :);
                    end
                end
            end

            for i = 1:N
                if rand() < 0.5
                    R = 1 - t / MaxIter;
                    Xnew = obj.positions(i, :) + ...
                        R * (2 * rand() - 1) .* ...
                        (obj.bestPosition - obj.positions(i, :));
                else
                    b = 0.3;
                    k = 0.1;
                    Xnew = obj.positions(i, :) + ...
                        b * (obj.positions(i, :) - obj.Xworst) + ...
                        k * (rand() - 0.5) .* (ub - lb);
                end

                Xnew = obj.clampToBounds(Xnew, lb, ub);
                newFit = obj.evaluateSolution(Xnew);

                if newFit < obj.fitness(i)
                    obj.positions(i, :) = Xnew;
                    obj.fitness(i) = newFit;

                    if newFit < obj.bestFitness
                        obj.bestFitness = newFit;
                        obj.bestPosition = Xnew;
                    end
                end
            end

            obj.bestSolution = obj.bestPosition;
        end

        function tf = shouldStop(obj)
            tf = obj.currentIteration >= obj.config.maxIterations;
        end
    end

    methods (Access = protected)
        function validatedConfig = validateConfig(obj, configStruct)
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
            AlgorithmRegistry.register('DBO', @DBO);
        end
    end
end
