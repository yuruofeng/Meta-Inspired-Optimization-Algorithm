classdef BA < BaseAlgorithm
    % BA Continuous Bat Algorithm clean-room implementation.

    properties (Access = protected)
        positions
        velocities
        fitness
        loudness
        pulseRates
        initialPulseRates
    end

    properties (Constant)
        PARAM_SCHEMA = struct( ...
            'populationSize', struct('type', 'integer', 'default', 30, 'min', 5, 'max', 10000, 'description', 'Bat population size'), ...
            'maxIterations', struct('type', 'integer', 'default', 500, 'min', 1, 'max', 100000, 'description', 'Maximum number of iterations'), ...
            'frequencyMin', struct('type', 'float', 'default', 0.0, 'min', 0.0, 'description', 'Minimum frequency'), ...
            'frequencyMax', struct('type', 'float', 'default', 2.0, 'min', 0.0, 'description', 'Maximum frequency'), ...
            'loudness', struct('type', 'float', 'default', 0.5, 'min', 0.0, 'max', 1.0, 'description', 'Initial loudness'), ...
            'pulseRate', struct('type', 'float', 'default', 0.5, 'min', 0.0, 'max', 1.0, 'description', 'Initial pulse rate'), ...
            'alpha', struct('type', 'float', 'default', 0.9, 'min', 0.0, 'max', 1.0, 'description', 'Loudness damping factor'), ...
            'gamma', struct('type', 'float', 'default', 0.9, 'min', 0.0, 'description', 'Pulse-rate growth factor'), ...
            'localSearchScale', struct('type', 'float', 'default', 0.001, 'min', 0.0, 'description', 'Local random-walk scale'), ...
            'verbose', struct('type', 'boolean', 'default', true, 'description', 'Show progress') ...
        )
    end

    methods
        function obj = BA(configStruct)
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
            obj.velocities = zeros(n, dim);
            obj.fitness = obj.evaluatePopulation(obj.positions);
            obj.loudness = obj.config.loudness * ones(n, 1);
            obj.initialPulseRates = obj.config.pulseRate * ones(n, 1);
            obj.pulseRates = obj.initialPulseRates;

            [obj.bestFitness, bestIdx] = min(obj.fitness);
            obj.bestSolution = obj.positions(bestIdx, :);
            obj.convergenceCurve = zeros(obj.config.maxIterations, 1);
        end

        function iterate(obj)
            lb = obj.problem.lb(:)';
            ub = obj.problem.ub(:)';
            n = obj.config.populationSize;
            iter = double(obj.currentIteration) + 1;
            averageLoudness = max(mean(obj.loudness), eps);

            for i = 1:n
                frequency = obj.config.frequencyMin + ...
                    (obj.config.frequencyMax - obj.config.frequencyMin) * rand();
                obj.velocities(i, :) = obj.velocities(i, :) + ...
                    (obj.positions(i, :) - obj.bestSolution) * frequency;
                candidate = obj.positions(i, :) + obj.velocities(i, :);

                if rand() > obj.pulseRates(i)
                    scale = obj.config.localSearchScale * averageLoudness .* (ub - lb);
                    candidate = obj.bestSolution + scale .* randn(size(obj.bestSolution));
                end

                candidate = obj.clampToBounds(candidate, lb, ub);
                candidateFitness = obj.evaluateSolution(candidate);

                if candidateFitness <= obj.fitness(i) && rand() < obj.loudness(i)
                    obj.positions(i, :) = candidate;
                    obj.fitness(i) = candidateFitness;
                    obj.loudness(i) = obj.config.alpha * obj.loudness(i);
                    obj.pulseRates(i) = obj.initialPulseRates(i) * ...
                        (1 - exp(-obj.config.gamma * iter));

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
            if validatedConfig.frequencyMax < validatedConfig.frequencyMin
                error('BA:InvalidConfig', 'frequencyMax must be greater than or equal to frequencyMin');
            end
        end
    end

    methods (Access = private)
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
                'fullName', 'Bat Algorithm', ...
                'description', 'Echolocation-inspired optimizer using frequency, velocity, loudness, and pulse-rate adaptation.', ...
                'category', 'swarm', ...
                'reference', struct( ...
                    'authors', 'X. S. Yang', ...
                    'year', 2010, ...
                    'title', 'A new metaheuristic bat-inspired algorithm', ...
                    'url', 'https://github.com/thieu1995/mealpy; https://github.com/NiaOrg/NiaPy' ...
                ) ...
            );
            AlgorithmRegistry.register('BA', '1.0.0', @BA, metadata);
        end
    end
end
