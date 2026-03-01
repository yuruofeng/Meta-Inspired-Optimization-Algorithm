classdef SATest < AlgorithmTestTemplate
    % SATest 模拟退火算法单元测试

    properties
        AlgorithmClass = @SA
        AlgorithmName = 'SA'
    end

    methods (Test)
        function testCoolingSchedule(obj)
            rng(42, 'twister');
            
            config = struct('populationSize', 30, 'maxIterations', 50, 'verbose', false);
            sa = SA(config);
            
            problem = struct();
            problem.evaluate = @(x) sum(x.^2);
            problem.lb = [-5 -5 -5];
            problem.ub = [5 5 5];
            problem.dim = 3;
            
            result = sa.run(problem);
            
            obj.assertTrue(isfinite(result.bestFitness));
        end

        function testNeighborTypes(obj)
            rng(42, 'twister');
            
            neighborTypes = {'gaussian', 'uniform', 'cauchy'};
            
            for i = 1:length(neighborTypes)
                config = struct('populationSize', 20, 'maxIterations', 30, ...
                    'neighborType', neighborTypes{i}, 'verbose', false);
                sa = SA(config);
                
                problem = struct();
                problem.evaluate = @(x) sum(x.^2);
                problem.lb = [-5 -5];
                problem.ub = [5 5];
                problem.dim = 2;
                
                result = sa.run(problem);
                obj.assertTrue(isfinite(result.bestFitness));
            end
        end

        function testRegistration(obj)
            SA.register();
            algClass = AlgorithmRegistry.getAlgorithm('SA');
            obj.assertEqual(algClass, @SA);
        end
    end
end
