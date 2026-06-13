classdef HS < BaseAlgorithm
    % HS Harmony Search clean-room implementation.

    properties (Access = protected)
        memory
        fitness
    end

    properties (Constant)
        PARAM_SCHEMA = struct( ...
            'populationSize', struct('type', 'integer', 'default', 30, 'min', 5, 'max', 10000, 'description', 'Harmony memory size'), ...
            'maxIterations', struct('type', 'integer', 'default', 500, 'min', 1, 'max', 100000, 'description', 'Maximum number of iterations'), ...
            'harmonyMemoryConsideringRate', struct('type', 'float', 'default', 0.9, 'min', 0.0, 'max', 1.0, 'description', 'Harmony memory considering rate'), ...
            'pitchAdjustingRate', struct('type', 'float', 'default', 0.3, 'min', 0.0, 'max', 1.0, 'description', 'Pitch adjusting rate'), ...
            'bandwidth', struct('type', 'float', 'default', 0.01, 'min', 0.0, 'description', 'Pitch bandwidth as a fraction of search range'), ...
            'verbose', struct('type', 'boolean', 'default', true, 'description', 'Show progress') ...
        )
    end

    methods
        function obj = HS(configStruct)
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

            obj.memory = Initialization(n, dim, ub, lb);
            obj.fitness = obj.evaluatePopulation(obj.memory);
            obj.updateBest();
            obj.convergenceCurve = zeros(obj.config.maxIterations, 1);
        end

        function iterate(obj)
            lb = obj.problem.lb(:)';
            ub = obj.problem.ub(:)';
            dim = obj.problem.dim;
            n = obj.config.populationSize;
            range = ub - lb;

            for candidateIdx = 1:n
                candidate = zeros(1, dim);
                for d = 1:dim
                    if rand() < obj.config.harmonyMemoryConsideringRate
                        source = randi(n);
                        candidate(d) = obj.memory(source, d);
                        if rand() < obj.config.pitchAdjustingRate
                            candidate(d) = candidate(d) + ...
                                obj.config.bandwidth * range(d) * randn();
                        end
                    else
                        candidate(d) = lb(d) + rand() * range(d);
                    end
                end

                candidate = obj.clampToBounds(candidate, lb, ub);
                candidateFitness = obj.evaluateSolution(candidate);
                [worstFitness, worstIdx] = max(obj.fitness);
                if candidateFitness < worstFitness
                    obj.memory(worstIdx, :) = candidate;
                    obj.fitness(worstIdx) = candidateFitness;
                end
            end

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
        function updateBest(obj)
            [obj.bestFitness, bestIdx] = min(obj.fitness);
            obj.bestSolution = obj.memory(bestIdx, :);
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
                'fullName', 'Harmony Search', ...
                'description', 'Music improvisation-inspired optimizer using harmony memory, pitch adjustment, and random consideration.', ...
                'category', 'physics', ...
                'reference', struct( ...
                    'authors', 'Z. W. Geem, J. H. Kim, G. V. Loganathan', ...
                    'year', 2001, ...
                    'title', 'A new heuristic optimization algorithm: harmony search', ...
                    'url', 'https://github.com/thieu1995/mealpy; https://github.com/NiaOrg/NiaPy' ...
                ) ...
            );
            AlgorithmRegistry.register('HS', '1.0.0', @HS, metadata);
        end
    end
end
