classdef GWOTest < AlgorithmTestTemplate
    % GWOTest 灰狼优化算法单元测试

    properties
        AlgorithmClass = @GWO
        AlgorithmName = 'GWO'
    end

    methods (Test)
        function testAlphaBetaDelta(obj)
            rng(42, 'twister');
            
            config = struct('populationSize', 30, 'maxIterations', 50, 'verbose', false);
            gwo = GWO(config);
            
            problem = struct();
            problem.evaluate = @(x) sum(x.^2);
            problem.lb = [-5 -5 -5];
            problem.ub = [5 5 5];
            problem.dim = 3;
            
            result = gwo.run(problem);
            
            obj.assertTrue(isfinite(result.bestFitness));
            obj.assertTrue(result.bestFitness >= 0);
        end

        function testRegistration(obj)
            GWO.register();
            algClass = AlgorithmRegistry.getAlgorithm('GWO');
            obj.assertEqual(algClass, @GWO);
        end
    end
end
