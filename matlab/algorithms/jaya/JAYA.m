classdef JAYA < BaseAlgorithm
    % JAYA Parameter-light population optimizer.

    properties (Access = protected)
        population
        fitness
        worstPosition
    end

    properties (Constant)
        PARAM_SCHEMA = struct( ...
            'populationSize', struct( ...
                'type', 'integer', ...
                'default', 30, ...
                'min', 5, ...
                'max', 10000, ...
                'description', 'Population size'), ...
            'maxIterations', struct( ...
                'type', 'integer', ...
                'default', 500, ...
                'min', 1, ...
                'max', 100000, ...
                'description', 'Maximum number of iterations'), ...
            'verbose', struct( ...
                'type', 'boolean', ...
                'default', true, ...
                'description', 'Show progress') ...
        )
    end

    methods
        function obj = JAYA(configStruct)
            if nargin < 1 || isempty(configStruct)
                configStruct = struct();
            end
            obj = obj@BaseAlgorithm(configStruct);
        end

        function initialize(obj, problem)
            lb = problem.lb(:)';
            ub = problem.ub(:)';
            dim = problem.dim;
            n = obj.config.populationSize;

            obj.population = Initialization(n, dim, ub, lb);
            obj.fitness = obj.evaluatePopulation(obj.population);
            obj.updateBestAndWorst();
            obj.convergenceCurve = zeros(obj.config.maxIterations, 1);
        end

        function iterate(obj)
            lb = obj.problem.lb(:)';
            ub = obj.problem.ub(:)';
            n = obj.config.populationSize;

            for i = 1:n
                r1 = rand(size(obj.population(i, :)));
                r2 = rand(size(obj.population(i, :)));
                candidate = obj.population(i, :) ...
                    + r1 .* (obj.bestSolution - abs(obj.population(i, :))) ...
                    - r2 .* (obj.worstPosition - abs(obj.population(i, :)));
                candidate = obj.clampToBounds(candidate, lb, ub);
                candidateFitness = obj.evaluateSolution(candidate);

                if candidateFitness < obj.fitness(i)
                    obj.population(i, :) = candidate;
                    obj.fitness(i) = candidateFitness;
                end
            end

            obj.updateBestAndWorst();
        end

        function tf = shouldStop(obj)
            tf = double(obj.currentIteration) >= obj.config.maxIterations;
        end

        function validatedConfig = validateConfig(obj, configStruct)
            validatedConfig = obj.fillDefaults(configStruct);
        end
    end

    methods (Access = private)
        function updateBestAndWorst(obj)
            [obj.bestFitness, bestIdx] = min(obj.fitness);
            [~, worstIdx] = max(obj.fitness);
            obj.bestSolution = obj.population(bestIdx, :);
            obj.worstPosition = obj.population(worstIdx, :);
        end

        function validatedConfig = fillDefaults(obj, configStruct)
            validatedConfig = struct();
            fields = fieldnames(obj.PARAM_SCHEMA);
            for i = 1:numel(fields)
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
            metadata = struct( ...
                'fullName', 'JAYA Algorithm', ...
                'description', 'Parameter-light optimizer that moves each candidate toward the current best and away from the current worst solution.', ...
                'category', 'evolutionary', ...
                'reference', struct( ...
                    'authors', 'R. V. Rao', ...
                    'year', 2016, ...
                    'title', 'Jaya: A simple and new optimization algorithm for solving constrained and unconstrained optimization problems', ...
                    'url', 'https://github.com/thieu1995/mealpy; https://github.com/NiaOrg/NiaPy' ...
                ) ...
            );
            AlgorithmRegistry.register('JAYA', '1.0.0', @JAYA, metadata);
        end
    end
end
