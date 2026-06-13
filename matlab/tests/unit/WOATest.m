classdef WOATest < AlgorithmTestTemplate
    % WOATest 鲸鱼优化算法单元测试

    properties
        AlgorithmClass = @WOA
        AlgorithmName = 'WOA'
    end

    methods (Test)
        function testSpiralUpdate(obj)
            rng(42, 'twister');
            
            config = struct('populationSize', 30, 'maxIterations', 50, 'verbose', false);
            woa = WOA(config);
            
            problem = struct();
            problem.evaluate = @(x) sum(x.^2);
            problem.lb = [-5 -5 -5];
            problem.ub = [5 5 5];
            problem.dim = 3;
            
            result = woa.run(problem);
            
            obj.assertTrue(isfinite(result.bestFitness));
        end

        function testRegistration(obj)
            WOA.register();
            algClass = AlgorithmRegistry.getAlgorithm('WOA');
            obj.assertEqual(algClass, @WOA);
        end
    end
end
