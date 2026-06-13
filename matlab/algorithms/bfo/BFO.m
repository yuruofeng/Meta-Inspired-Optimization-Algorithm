classdef BFO < BaseAlgorithm
    % BFO Bacterial Foraging Optimization clean-room implementation.

    properties (Access = protected)
        positions
        fitness
        health
    end

    properties (Constant)
        PARAM_SCHEMA = struct( ...
            'populationSize', struct('type', 'integer', 'default', 30, 'min', 6, 'max', 10000, 'description', 'Bacteria population size'), ...
            'maxIterations', struct('type', 'integer', 'default', 500, 'min', 1, 'max', 100000, 'description', 'Maximum number of iterations'), ...
            'stepSize', struct('type', 'float', 'default', 0.1, 'min', 0.0, 'description', 'Chemotactic step size as a fraction of search range'), ...
            'swimLength', struct('type', 'integer', 'default', 4, 'min', 1, 'max', 1000, 'description', 'Maximum swim steps after a successful tumble'), ...
            'reproductionInterval', struct('type', 'integer', 'default', 10, 'min', 1, 'max', 100000, 'description', 'Iterations between reproduction events'), ...
            'eliminationProbability', struct('type', 'float', 'default', 0.05, 'min', 0.0, 'max', 1.0, 'description', 'Elimination-dispersal probability'), ...
            'verbose', struct('type', 'boolean', 'default', true, 'description', 'Show progress') ...
        )
    end

    methods
        function obj = BFO(configStruct)
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

            obj.positions = Initialization(n, dim, ub, lb);
            obj.fitness = obj.evaluatePopulation(obj.positions);
            obj.health = zeros(n, 1);
            obj.updateBest();
            obj.convergenceCurve = zeros(obj.config.maxIterations, 1);
        end

        function iterate(obj)
            lb = obj.problem.lb(:)';
            ub = obj.problem.ub(:)';
            dim = obj.problem.dim;
            n = obj.config.populationSize;
            range = ub - lb;
            step = obj.config.stepSize .* range;

            for i = 1:n
                direction = randn(1, dim);
                directionNorm = norm(direction);
                if directionNorm == 0
                    directionNorm = 1;
                end
                direction = direction / directionNorm;

                currentPosition = obj.positions(i, :);
                currentFitness = obj.fitness(i);

                for swim = 1:obj.config.swimLength
                    candidate = currentPosition + step .* direction;
                    candidate = obj.clampToBounds(candidate, lb, ub);
                    candidateFitness = obj.evaluateSolution(candidate);

                    if candidateFitness < currentFitness
                        currentPosition = candidate;
                        currentFitness = candidateFitness;
                    else
                        break;
                    end
                end

                obj.positions(i, :) = currentPosition;
                obj.fitness(i) = currentFitness;
                obj.health(i) = obj.health(i) + currentFitness;

                if currentFitness < obj.bestFitness
                    obj.bestFitness = currentFitness;
                    obj.bestSolution = currentPosition;
                end
            end

            iter = double(obj.currentIteration) + 1;
            if mod(iter, obj.config.reproductionInterval) == 0
                obj.reproduce();
            end

            obj.eliminateAndDisperse(lb, ub);
            obj.updateBest();
        end

        function tf = shouldStop(obj)
            tf = double(obj.currentIteration) >= obj.config.maxIterations;
        end

        function validatedConfig = validateConfig(obj, configStruct)
            validatedConfig = obj.fillDefaults(configStruct);
        end
    end

    methods (Access = private)
        function reproduce(obj)
            n = obj.config.populationSize;
            [~, order] = sort(obj.health, 'ascend');
            obj.positions = obj.positions(order, :);
            obj.fitness = obj.fitness(order);
            survivors = max(1, floor(n / 2));
            for i = survivors + 1:n
                source = i - survivors;
                obj.positions(i, :) = obj.positions(source, :);
                obj.fitness(i) = obj.fitness(source);
            end
            obj.health = zeros(n, 1);
        end

        function eliminateAndDisperse(obj, lb, ub)
            n = obj.config.populationSize;
            dim = numel(lb);
            for i = 1:n
                if rand() < obj.config.eliminationProbability
                    obj.positions(i, :) = lb + rand(1, dim) .* (ub - lb);
                    obj.fitness(i) = obj.evaluateSolution(obj.positions(i, :));
                end
            end
        end

        function updateBest(obj)
            [obj.bestFitness, bestIdx] = min(obj.fitness);
            obj.bestSolution = obj.positions(bestIdx, :);
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
                'fullName', 'Bacterial Foraging Optimization', ...
                'description', 'Bacterial chemotaxis-inspired optimizer with swim, reproduction, and elimination-dispersal phases.', ...
                'category', 'swarm', ...
                'reference', struct( ...
                    'authors', 'K. M. Passino', ...
                    'year', 2002, ...
                    'title', 'Biomimicry of bacterial foraging for distributed optimization and control', ...
                    'url', 'https://github.com/thieu1995/mealpy; https://github.com/NiaOrg/NiaPy' ...
                ) ...
            );
            AlgorithmRegistry.register('BFO', '1.0.0', @BFO, metadata);
        end
    end
end
