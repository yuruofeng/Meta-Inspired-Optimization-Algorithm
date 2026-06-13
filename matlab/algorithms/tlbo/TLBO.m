classdef TLBO < BaseAlgorithm
    % TLBO 教与学优化算法 (Teaching-Learning-Based Optimization)
    %
    % 一种模拟课堂教学过程的社会启发式算法。无需算法特有参数，
    % 通过教师阶段和学习者阶段实现迭代优化。
    %
    % 算法阶段:
    %   1. 教师阶段: 最优个体作为教师引导种群
    %   2. 学习者阶段: 学习者相互学习并改进
    %
    % 参考文献:
    %   R.V. Rao, V.J. Savsani, D.P. Vakharia
    %   "Teaching-learning-based optimization: A novel method for
    %       constrained mechanical design optimization problems"
    %   Computer-Aided Design, 2011
    %   DOI: 10.1016/j.cad.2010.12.007
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   tlbo = TLBO(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = tlbo.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: R. V. Rao
    % 实现版本: 1.0.0
    % 日期: 2025

    properties (Access = protected)
        population           % 种群矩阵 (N x Dim)
        fitness              % 适应度向量 (N x 1)
        teacherPosition      % 教师位置 (最优, 1 x Dim)
        teacherFitness       % 教师适应度
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 5, ...
                'max', 10000, ...
                'description', '班级大小(学生数量)'), ...
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
        function obj = TLBO(configStruct)
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

            obj.population = Initialization(N, dim, ub, lb);
            obj.fitness = obj.evaluatePopulation(obj.population);

            [obj.teacherFitness, bestIdx] = min(obj.fitness);
            obj.teacherPosition = obj.population(bestIdx, :);

            obj.bestFitness = obj.teacherFitness;
            obj.bestSolution = obj.teacherPosition;
            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            lb = obj.problem.lb;
            ub = problem.ub;
            dim = obj.problem.dim;
            N = obj.config.populationSize;

            meanPosition = mean(obj.population, 1);

            Tf = randi([1 2]);

            for i = 1:N
                r = rand(1, dim);

                diffMean = r .* (obj.teacherPosition - Tf * meanPosition);

                newPosition = obj.population(i, :) + diffMean;
                newPosition = obj.clampToBounds(newPosition, lb, ub);

                newFitness = obj.evaluateSolution(newPosition);

                if newFitness < obj.fitness(i)
                    obj.population(i, :) = newPosition;
                    obj.fitness(i) = newFitness;

                    if newFitness < obj.teacherFitness
                        obj.teacherFitness = newFitness;
                        obj.teacherPosition = newPosition;
                    end
                end
            end

            for i = 1:N
                j = randi(N);
                while j == i
                    j = randi(N);
                end

                if obj.fitness(i) < obj.fitness(j)
                    newPosition = obj.population(i, :) + rand(1, dim) .* ...
                                 (obj.population(i, :) - obj.population(j, :));
                else
                    newPosition = obj.population(i, :) + rand(1, dim) .* ...
                                 (obj.population(j, :) - obj.population(i, :));
                end

                newPosition = obj.clampToBounds(newPosition, lb, ub);

                newFitness = obj.evaluateSolution(newPosition);

                if newFitness < obj.fitness(i)
                    obj.population(i, :) = newPosition;
                    obj.fitness(i) = newFitness;

                    if newFitness < obj.teacherFitness
                        obj.teacherFitness = newFitness;
                        obj.teacherPosition = newPosition;
                    end
                end
            end

            obj.bestFitness = obj.teacherFitness;
            obj.bestSolution = obj.teacherPosition;
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
            AlgorithmRegistry.register('TLBO', @TLBO);
        end
    end
end
