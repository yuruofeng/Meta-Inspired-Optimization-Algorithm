classdef CS < BaseAlgorithm
    % CS 布谷鸟搜索算法 (Cuckoo Search)
    %
    % 一种模拟布谷鸟巢寄生行为的元启发式算法。结合Levy飞行模式
    % 实现高效的全局探索能力。
    %
    % 算法原理:
    %   1. 布谷鸟随机选择巢穴产蛋
    %   2. 宿主鸟以概率pa发现外来蛋
    %   3. 宿主发现外来蛋后，以概率pa抛弃或重新筑巢
    %   4. 新巢穴位置通过Levy飞行生成
    %
    % 参考文献:
    %   X.-S. Yang, S. Deb
    %   "Cuckoo Search via Levy Flights"
    %   World Congress on Nature & Biologically Inspired Computing, 2009
    %   DOI: 10.1109/WCNC.2009.4853902
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   cs = CS(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = cs.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Xin-She Yang, Suash Deb
    % 实现版本: 1.0.0
    % 日期: 2025

    properties (Access = protected)
        nests               % 巢穴位置矩阵 (N x Dim)
        nestFitness         % 巢穴适应度向量 (N x 1)
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 5, ...
                'max', 10000, ...
                'description', '巢穴数量'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 500, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'pa', struct(...
                'type', 'float', ...
                'default', 0.25, ...
                'min', 0, ...
                'max', 1, ...
                'description', '宿主发现外来蛋概率'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = CS(configStruct)
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

            obj.nests = Initialization(N, dim, ub, lb);
            obj.nestFitness = obj.evaluatePopulation(obj.nests);

            [obj.bestFitness, bestIdx] = min(obj.nestFitness);
            obj.bestSolution = obj.nests(bestIdx, :);

            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            lb = obj.problem.lb;
            ub = problem.ub;
            dim = obj.problem.dim;
            N = obj.config.populationSize;
            pa = obj.config.pa;

            for i = 1:N
                step = obj.levyFlight(dim);
                newPos = obj.nests(i, :) + step .* (obj.nests(i, :) - obj.bestSolution);
                newPos = obj.clampToBounds(newPos, lb, ub);

                j = randi(N);
                while j == i
                    j = randi(N);
                end

                newFitness = obj.evaluateSolution(newPos);

                if newFitness < obj.nestFitness(j)
                    obj.nests(j, :) = newPos;
                    obj.nestFitness(j) = newFitness;

                    if newFitness < obj.bestFitness
                        obj.bestFitness = newFitness;
                        obj.bestSolution = newPos;
                    end
                end
            end

            for i = 1:N
                if rand() < pa
                    j = randi(N);
                    while j == i
                        j = randi(N);
                    end
                    k = randi(N);
                    while k == i || k == j
                        k = randi(N);
                    end

                    newPos = obj.nests(i, :) + rand() .* (obj.nests(j, :) - obj.nests(k, :));
                    newPos = obj.clampToBounds(newPos, lb, ub);

                    newFitness = obj.evaluateSolution(newPos);

                    if newFitness < obj.nestFitness(i)
                        obj.nests(i, :) = newPos;
                        obj.nestFitness(i) = newFitness;

                        if newFitness < obj.bestFitness
                            obj.bestFitness = newFitness;
                            obj.bestSolution = newPos;
                        end
                    end
                end
            end
        end

        function tf = shouldStop(obj)
            tf = obj.currentIteration >= obj.config.maxIterations;
        end
    end

    methods (Access = protected)
        function steps = levyFlight(obj, dim)
            beta = 1.5;
            sigma = (gamma(1 + beta) * sin(pi * beta / 2) / ...
                     (gamma((1 + beta) / 2) * beta * 2^((beta - 1) / 2)))^(1 / beta);

            u = randn(1, dim) * sigma;
            v = randn(1, dim);
            steps = u ./ (abs(v).^(1 / beta));
        end

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
            AlgorithmRegistry.register('CS', @CS);
        end
    end
end
