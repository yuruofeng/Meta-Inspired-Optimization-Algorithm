classdef FPA < BaseAlgorithm
    % FPA Flower Pollination Algorithm clean-room implementation.

    properties (Access = protected)
        population
        fitness
    end

    properties (Constant)
        PARAM_SCHEMA = struct( ...
            'populationSize', struct('type', 'integer', 'default', 30, 'min', 5, 'max', 10000, 'description', 'Flower population size'), ...
            'maxIterations', struct('type', 'integer', 'default', 500, 'min', 1, 'max', 100000, 'description', 'Maximum number of iterations'), ...
            'switchProbability', struct('type', 'float', 'default', 0.8, 'min', 0.0, 'max', 1.0, 'description', 'Global pollination probability'), ...
            'levyScale', struct('type', 'float', 'default', 0.01, 'min', 0.0, 'description', 'Levy-flight step scale'), ...
            'verbose', struct('type', 'boolean', 'default', true, 'description', 'Show progress') ...
        )
    end

    methods
        function obj = FPA(configStruct)
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
            [obj.bestFitness, bestIdx] = min(obj.fitness);
            obj.bestSolution = obj.population(bestIdx, :);
            obj.convergenceCurve = zeros(obj.config.maxIterations, 1);
        end

        function iterate(obj)
            lb = obj.problem.lb(:)';
            ub = obj.problem.ub(:)';
            dim = obj.problem.dim;
            n = obj.config.populationSize;

            for i = 1:n
                if rand() < obj.config.switchProbability
                    step = obj.levyFlight(dim);
                    candidate = obj.population(i, :) + obj.config.levyScale * ...
                        step .* (obj.bestSolution - obj.population(i, :));
                else
                    pair = randperm(n, 2);
                    epsilon = rand();
                    candidate = obj.population(i, :) + epsilon * ...
                        (obj.population(pair(1), :) - obj.population(pair(2), :));
                end

                candidate = obj.clampToBounds(candidate, lb, ub);
                candidateFitness = obj.evaluateSolution(candidate);

                if candidateFitness < obj.fitness(i)
                    obj.population(i, :) = candidate;
                    obj.fitness(i) = candidateFitness;
                    if candidateFitness < obj.bestFitness
                        obj.bestFitness = candidateFitness;
                        obj.bestSolution = candidate;
                    end
                end
            end
        end

        function tf = shouldStop(obj)
            tf = double(obj.currentIteration) >= obj.config.maxIterations;
        end

        function validatedConfig = validateConfig(obj, configStruct)
            validatedConfig = obj.fillDefaults(configStruct);
        end
    end

    methods (Access = private)
        function steps = levyFlight(~, dim)
            beta = 1.5;
            sigma = (gamma(1 + beta) * sin(pi * beta / 2) / ...
                (gamma((1 + beta) / 2) * beta * 2^((beta - 1) / 2)))^(1 / beta);
            u = randn(1, dim) * sigma;
            v = randn(1, dim);
            steps = u ./ (abs(v).^(1 / beta) + eps);
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
                'fullName', 'Flower Pollination Algorithm', ...
                'description', 'Pollination-inspired optimizer combining global Levy flights and local neighborhood pollination.', ...
                'category', 'swarm', ...
                'reference', struct( ...
                    'authors', 'X. S. Yang', ...
                    'year', 2012, ...
                    'title', 'Flower pollination algorithm for global optimization', ...
                    'url', 'https://github.com/thieu1995/mealpy; https://github.com/NiaOrg/NiaPy' ...
                ) ...
            );
            AlgorithmRegistry.register('FPA', '1.0.0', @FPA, metadata);
        end
    end
end
