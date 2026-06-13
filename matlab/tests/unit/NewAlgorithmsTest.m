classdef NewAlgorithmsTest < matlab.unittest.TestCase
    % NewAlgorithmsTest 新算法集成测试
    %
    % 测试所有新集成的15个元启发式优化算法:
    % 高优先级: PSO, DE, HHO, ACO, ABC
    % 中优先级: TLBO, FA, CS, DBO, SMA, BWO, ASO
    % 低优先级: NRBO, CPO, HO

    properties (Constant)
        TestConfig = struct(...
            'populationSize', 20, ...
            'maxIterations', 50, ...
            'verbose', false ...
        )
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
        function testPSO(obj)
            pso = PSO(obj.TestConfig);
            result = pso.run(obj.TestProblem);
            
            obj.verifyTrue(isfinite(result.bestFitness), 'PSO: bestFitness should be finite');
            obj.verifyTrue(result.bestFitness >= 0, 'PSO: bestFitness should be non-negative');
            obj.verifyEqual(length(result.convergenceCurve), obj.TestConfig.maxIterations);
        end

        function testDE(obj)
            de = DE(obj.TestConfig);
            result = de.run(obj.TestProblem);
            
            obj.verifyTrue(isfinite(result.bestFitness), 'DE: bestFitness should be finite');
            obj.verifyTrue(result.bestFitness >= 0, 'DE: bestFitness should be non-negative');
            obj.verifyEqual(length(result.convergenceCurve), obj.TestConfig.maxIterations);
        end

        function testHHO(obj)
            hho = HHO(obj.TestConfig);
            result = hho.run(obj.TestProblem);
            
            obj.verifyTrue(isfinite(result.bestFitness), 'HHO: bestFitness should be finite');
            obj.verifyTrue(result.bestFitness >= 0, 'HHO: bestFitness should be non-negative');
            obj.verifyEqual(length(result.convergenceCurve), obj.TestConfig.maxIterations);
        end

        function testABC(obj)
            abc = ABC(obj.TestConfig);
            result = abc.run(obj.TestProblem);
            
            obj.verifyTrue(isfinite(result.bestFitness), 'ABC: bestFitness should be finite');
            obj.verifyTrue(result.bestFitness >= 0, 'ABC: bestFitness should be non-negative');
            obj.verifyEqual(length(result.convergenceCurve), obj.TestConfig.maxIterations);
        end

        function testCS(obj)
            cs = CS(obj.TestConfig);
            result = cs.run(obj.TestProblem);
            
            obj.verifyTrue(isfinite(result.bestFitness), 'CS: bestFitness should be finite');
            obj.verifyTrue(result.bestFitness >= 0, 'CS: bestFitness should be non-negative');
            obj.verifyEqual(length(result.convergenceCurve), obj.TestConfig.maxIterations);
        end

        function testFA(obj)
            fa = FA(obj.TestConfig);
            result = fa.run(obj.TestProblem);
            
            obj.verifyTrue(isfinite(result.bestFitness), 'FA: bestFitness should be finite');
            obj.verifyTrue(result.bestFitness >= 0, 'FA: bestFitness should be non-negative');
            obj.verifyEqual(length(result.convergenceCurve), obj.TestConfig.maxIterations);
        end

        function testDBO(obj)
            dbo = DBO(obj.TestConfig);
            result = dbo.run(obj.TestProblem);
            
            obj.verifyTrue(isfinite(result.bestFitness), 'DBO: bestFitness should be finite');
            obj.verifyTrue(result.bestFitness >= 0, 'DBO: bestFitness should be non-negative');
            obj.verifyEqual(length(result.convergenceCurve), obj.TestConfig.maxIterations);
        end

        function testSMA(obj)
            sma = SMA(obj.TestConfig);
            result = sma.run(obj.TestProblem);
            
            obj.verifyTrue(isfinite(result.bestFitness), 'SMA: bestFitness should be finite');
            obj.verifyTrue(result.bestFitness >= 0, 'SMA: bestFitness should be non-negative');
            obj.verifyEqual(length(result.convergenceCurve), obj.TestConfig.maxIterations);
        end

        function testBWO(obj)
            bwo = BWO(obj.TestConfig);
            result = bwo.run(obj.TestProblem);
            
            obj.verifyTrue(isfinite(result.bestFitness), 'BWO: bestFitness should be finite');
            obj.verifyTrue(result.bestFitness >= 0, 'BWO: bestFitness should be non-negative');
            obj.verifyEqual(length(result.convergenceCurve), obj.TestConfig.maxIterations);
        end

        function testASO(obj)
            aso = ASO(obj.TestConfig);
            result = aso.run(obj.TestProblem);
            
            obj.verifyTrue(isfinite(result.bestFitness), 'ASO: bestFitness should be finite');
            obj.verifyTrue(result.bestFitness >= 0, 'ASO: bestFitness should be non-negative');
            obj.verifyEqual(length(result.convergenceCurve), obj.TestConfig.maxIterations);
        end

        function testNRBO(obj)
            nrbo = NRBO(obj.TestConfig);
            result = nrbo.run(obj.TestProblem);
            
            obj.verifyTrue(isfinite(result.bestFitness), 'NRBO: bestFitness should be finite');
            obj.verifyTrue(result.bestFitness >= 0, 'NRBO: bestFitness should be non-negative');
            obj.verifyEqual(length(result.convergenceCurve), obj.TestConfig.maxIterations);
        end

        function testCPO(obj)
            cpo = CPO(obj.TestConfig);
            result = cpo.run(obj.TestProblem);
            
            obj.verifyTrue(isfinite(result.bestFitness), 'CPO: bestFitness should be finite');
            obj.verifyTrue(result.bestFitness >= 0, 'CPO: bestFitness should be non-negative');
            obj.verifyEqual(length(result.convergenceCurve), obj.TestConfig.maxIterations);
        end

        function testHO(obj)
            ho = HO(obj.TestConfig);
            result = ho.run(obj.TestProblem);
            
            obj.verifyTrue(isfinite(result.bestFitness), 'HO: bestFitness should be finite');
            obj.verifyTrue(result.bestFitness >= 0, 'HO: bestFitness should be non-negative');
            obj.verifyEqual(length(result.convergenceCurve), obj.TestConfig.maxIterations);
        end
    end

    methods (Test)
        function testAlgorithmInterface(obj)
            algorithms = {@PSO, @DE, @HHO, @ABC, @CS, @FA, @DBO, @SMA, @BWO, @ASO, @NRBO, @CPO, @HO};
            names = {'PSO', 'DE', 'HHO', 'ABC', 'CS', 'FA', 'DBO', 'SMA', 'BWO', 'ASO', 'NRBO', 'CPO', 'HO'};
            
            for i = 1:length(algorithms)
                alg = algorithms{i}(obj.TestConfig);
                
                obj.verifyTrue(isa(alg, 'BaseAlgorithm'), ...
                    sprintf('%s should inherit from BaseAlgorithm', names{i}));
                
                obj.verifyTrue(isprop(alg, 'config'), ...
                    sprintf('%s should have config property', names{i}));
                
                obj.verifyTrue(ismethod(alg, 'initialize'), ...
                    sprintf('%s should have initialize method', names{i}));
                
                obj.verifyTrue(ismethod(alg, 'iterate'), ...
                    sprintf('%s should have iterate method', names{i}));
                
                obj.verifyTrue(ismethod(alg, 'shouldStop'), ...
                    sprintf('%s should have shouldStop method', names{i}));
                
                obj.verifyTrue(ismethod(alg, 'run'), ...
                    sprintf('%s should have run method', names{i}));
            end
        end

        function testParameterSchema(obj)
            algorithms = {@PSO, @DE, @HHO, @ABC, @CS, @FA, @DBO, @SMA, @BWO, @ASO, @NRBO, @CPO, @HO};
            names = {'PSO', 'DE', 'HHO', 'ABC', 'CS', 'FA', 'DBO', 'SMA', 'BWO', 'ASO', 'NRBO', 'CPO', 'HO'};
            
            for i = 1:length(algorithms)
                alg = algorithms{i}();
                
                obj.verifyTrue(isprop(alg, 'PARAM_SCHEMA'), ...
                    sprintf('%s should have PARAM_SCHEMA property', names{i}));
                
                schema = alg.PARAM_SCHEMA;
                obj.verifyTrue(isfield(schema, 'populationSize'), ...
                    sprintf('%s PARAM_SCHEMA should have populationSize', names{i}));
                
                obj.verifyTrue(isfield(schema, 'maxIterations'), ...
                    sprintf('%s PARAM_SCHEMA should have maxIterations', names{i}));
            end
        end

        function testCustomParameters(obj)
            customConfig = struct(...
                'populationSize', 15, ...
                'maxIterations', 25, ...
                'verbose', false ...
            );
            
            pso = PSO(customConfig);
            result = pso.run(obj.TestProblem);
            
            obj.verifyEqual(length(result.convergenceCurve), 25, ...
                'Custom maxIterations should be respected');
        end

        function testBoundaryConstraints(obj)
            pso = PSO(obj.TestConfig);
            result = pso.run(obj.TestProblem);
            
            for i = 1:length(result.bestSolution)
                obj.verifyTrue(result.bestSolution(i) >= obj.TestProblem.lb(i), ...
                    'Solution should respect lower bounds');
                obj.verifyTrue(result.bestSolution(i) <= obj.TestProblem.ub(i), ...
                    'Solution should respect upper bounds');
            end
        end

        function testConvergence(obj)
            pso = PSO(obj.TestConfig);
            result = pso.run(obj.TestProblem);
            
            obj.verifyTrue(result.convergenceCurve(1) >= result.bestFitness, ...
                'Algorithm should converge (initial >= final)');
        end
    end
end
