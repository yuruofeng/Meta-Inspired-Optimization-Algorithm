classdef CleanRoomAlgorithmsTest < matlab.unittest.TestCase
    % CleanRoomAlgorithmsTest Smoke tests for clean-room single-objective algorithms.

    properties (Constant)
        TestConfig = struct( ...
            'populationSize', 20, ...
            'maxIterations', 20, ...
            'verbose', false ...
        )

        AlgorithmNames = {'JAYA', 'BA', 'FPA', 'HS', 'BFO'}
    end

    properties
        TestProblem
    end

    methods (TestMethodSetup)
        function setupProblem(obj)
            rng(42, 'twister');

            obj.TestProblem = struct();
            obj.TestProblem.evaluate = @(x) sum(x.^2);
            obj.TestProblem.lb = [-5 -5 -5];
            obj.TestProblem.ub = [5 5 5];
            obj.TestProblem.dim = 3;
        end
    end

    methods (Test)
        function testCleanRoomAlgorithmsRunOnSphere(obj)
            for i = 1:numel(obj.AlgorithmNames)
                name = obj.AlgorithmNames{i};
                constructor = str2func(name);
                algorithm = constructor(obj.TestConfig);
                result = algorithm.run(obj.TestProblem);

                obj.verifyTrue(isfinite(result.bestFitness), ...
                    sprintf('%s bestFitness should be finite', name));
                obj.verifyEqual(length(result.convergenceCurve), obj.TestConfig.maxIterations, ...
                    sprintf('%s convergence curve length should match maxIterations', name));
                obj.verifyTrue(all(result.bestSolution >= obj.TestProblem.lb), ...
                    sprintf('%s bestSolution should satisfy lower bounds', name));
                obj.verifyTrue(all(result.bestSolution <= obj.TestProblem.ub), ...
                    sprintf('%s bestSolution should satisfy upper bounds', name));
            end
        end

        function testCleanRoomAlgorithmsExposeParamSchema(obj)
            for i = 1:numel(obj.AlgorithmNames)
                name = obj.AlgorithmNames{i};
                constructor = str2func(name);
                algorithm = constructor();
                schema = algorithm.PARAM_SCHEMA;

                obj.verifyTrue(isfield(schema, 'populationSize'), ...
                    sprintf('%s PARAM_SCHEMA should include populationSize', name));
                obj.verifyTrue(isfield(schema, 'maxIterations'), ...
                    sprintf('%s PARAM_SCHEMA should include maxIterations', name));
            end
        end
    end
end
